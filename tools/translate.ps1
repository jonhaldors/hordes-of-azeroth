param(
    [string]$Locale = 'zhCN',
    [int]$Port = 8765,
    [string]$MariaDb = '',
    [string]$ExportFile = '',
    [switch]$NoBrowser
)

. "$PSScriptRoot\common.ps1"

if ($Locale -notmatch '^[a-z]{2}[A-Z]{2}$') { throw 'Locale must be a name like zhCN or deDE.' }

$WebDir     = Join-Path $PSScriptRoot 'translate'
$AddonDir   = Join-Path $RepoRoot 'Interface\AddOns\HordesOfAzeroth'
$BonkDir    = Join-Path $ServerDir 'core\src\game\Bonk'
$Migrations = Join-Path $ServerDir 'core\sql\migrations'
$LocaleDir  = Join-Path $RepoRoot "localization\$Locale"
if (-not $MariaDb) { $MariaDb = Join-Path $MariaDir 'bin\mariadb.exe' }
if (-not $ExportFile) { $ExportFile = Join-Path $LogDir "bonk-strings-$Locale.json" }

$Files = @{
    'strings-h'   = Join-Path $BonkDir 'BonkStrings.h'
    'strings-cpp' = Join-Path $BonkDir 'BonkStrings.cpp'
    'server'      = Join-Path $LocaleDir 'server.json'
    'glossary'    = Join-Path $LocaleDir 'glossary.json'
    'addon'       = Join-Path $AddonDir "VanillaBonkLocale$($Locale.Substring(0, 1).ToUpper())$($Locale.Substring(1)).lua"
    'toc'         = Join-Path $AddonDir 'HordesOfAzeroth.toc'
    'export'      = $ExportFile
}
$Writable     = @('server', 'glossary', 'addon', 'toc')
$Token        = [guid]::NewGuid().ToString('N')
$Utf8         = New-Object System.Text.UTF8Encoding($false)
$ContentTypes = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'; '.css' = 'text/css; charset=utf-8' }
$Reasons      = @{ 100 = 'Continue'; 200 = 'OK'; 403 = 'Forbidden'; 404 = 'Not Found'; 409 = 'Conflict'; 500 = 'Internal Server Error'; 503 = 'Service Unavailable' }
$LocaleTables = $null

function Read-Request($Stream) {
    $head = New-Object System.Collections.Generic.List[byte]
    while ($true) {
        $byte = $Stream.ReadByte()
        if ($byte -lt 0 -or $head.Count -gt 65536) { return $null }
        $head.Add([byte]$byte)
        $n = $head.Count
        if ($n -ge 4 -and $head[$n - 4] -eq 13 -and $head[$n - 3] -eq 10 -and $head[$n - 2] -eq 13 -and $head[$n - 1] -eq 10) { break }
    }
    $lines = [System.Text.Encoding]::ASCII.GetString($head.ToArray()) -split "`r`n"
    $first = $lines[0] -split ' '
    if ($first.Count -lt 2) { return $null }
    $headers = @{}
    foreach ($line in $lines | Select-Object -Skip 1) {
        $at = $line.IndexOf(':')
        if ($at -gt 0) { $headers[$line.Substring(0, $at).Trim().ToLowerInvariant()] = $line.Substring($at + 1).Trim() }
    }
    if ($headers['expect'] -eq '100-continue') {
        $continue = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 100 Continue`r`n`r`n")
        $Stream.Write($continue, 0, $continue.Length)
    }
    $length = 0
    if ($headers.ContainsKey('content-length')) { $length = [int]$headers['content-length'] }
    $body = New-Object byte[] $length
    $read = 0
    while ($read -lt $length) {
        $got = $Stream.Read($body, $read, $length - $read)
        if ($got -le 0) { break }
        $read += $got
    }
    $path = $first[1]
    $query = @{}
    $at = $path.IndexOf('?')
    if ($at -ge 0) {
        foreach ($pair in $path.Substring($at + 1) -split '&') {
            if (-not $pair) { continue }
            $kv = $pair -split '=', 2
            $value = ''
            if ($kv.Count -gt 1) { $value = [System.Uri]::UnescapeDataString($kv[1].Replace('+', ' ')) }
            $query[[System.Uri]::UnescapeDataString($kv[0])] = $value
        }
        $path = $path.Substring(0, $at)
    }
    [pscustomobject]@{ Method = $first[0]; Path = $path; Query = $query; Headers = $headers; Body = $Utf8.GetString($body, 0, $read) }
}

function Send-Response($Stream, [int]$Status, [string]$Type, $Body) {
    if ($Body -is [byte[]]) { $bytes = $Body } else { $bytes = $Utf8.GetBytes([string]$Body) }
    $head = "HTTP/1.1 $Status $($Reasons[$Status])`r`nContent-Type: $Type`r`nContent-Length: $($bytes.Length)`r`n" +
        "Cache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
    $headBytes = [System.Text.Encoding]::ASCII.GetBytes($head)
    $Stream.Write($headBytes, 0, $headBytes.Length)
    if ($bytes.Length) { $Stream.Write($bytes, 0, $bytes.Length) }
    $Stream.Flush()
}

function Send-Text($Stream, [int]$Status, [string]$Text) { Send-Response $Stream $Status 'text/plain; charset=utf-8' $Text }

function Send-Json($Stream, $Object) { Send-Response $Stream 200 'application/json; charset=utf-8' (ConvertTo-Json -InputObject $Object -Depth 5 -Compress) }

function Write-TextFile([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $temp = "$Path.saving"
    [System.IO.File]::WriteAllText($temp, $Text, $Utf8)
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Get-LocaleTables {
    if ($null -eq $script:LocaleTables) {
        $found = Select-String -Path (Join-Path $Migrations '*.sql') -Pattern 'CREATE TABLE IF NOT EXISTS `\w+_locale`' -List
        $script:LocaleTables = ($found | Sort-Object Path | ForEach-Object { [System.IO.File]::ReadAllText($_.Path) }) -join "`n"
    }
    $script:LocaleTables
}

function Invoke-Route($Request, $Stream) {
    $hostName = $Request.Headers['host']
    if ($hostName -ne "127.0.0.1:$Port" -and $hostName -ne "localhost:$Port") { return Send-Text $Stream 403 'Wrong host.' }

    if (-not $Request.Path.StartsWith('/api/')) {
        $name = $Request.Path.TrimStart('/')
        if (-not $name) { $name = 'index.html' }
        $file = Join-Path $WebDir $name
        if ($Request.Method -ne 'GET' -or $name -notmatch '^[a-z]+\.(html|js|css)$' -or -not (Test-Path -LiteralPath $file)) { return Send-Text $Stream 404 'Not found.' }
        return Send-Response $Stream 200 $ContentTypes[[System.IO.Path]::GetExtension($name)] ([System.IO.File]::ReadAllBytes($file))
    }

    if ($Request.Headers['x-token'] -ne $Token) { return Send-Text $Stream 403 'Missing or wrong token.' }
    $name = $Request.Query['name']

    switch ("$($Request.Method) $($Request.Path)") {
        'GET /api/info' {
            $exists = @{}
            foreach ($key in $Files.Keys) { $exists[$key] = Test-Path -LiteralPath $Files[$key] }
            $last = Get-ChildItem -LiteralPath $Migrations -Filter '*.sql' | Where-Object { $_.Name -match '^\d{14}_' } | ForEach-Object { $_.Name.Substring(0, 14) } | Sort-Object | Select-Object -Last 1
            return Send-Json $Stream @{ locale = $Locale; files = $exists; database = (Test-Path -LiteralPath $MariaDb); exportFile = $ExportFile; migrations = $Migrations; lastMigration = $last }
        }
        'GET /api/file' {
            if (-not $Files.ContainsKey([string]$name)) { return Send-Text $Stream 404 'Unknown file.' }
            if (-not (Test-Path -LiteralPath $Files[$name])) { return Send-Text $Stream 404 'Missing.' }
            return Send-Response $Stream 200 'text/plain; charset=utf-8' ([System.IO.File]::ReadAllBytes($Files[$name]))
        }
        'POST /api/file' {
            if ($Writable -notcontains [string]$name) { return Send-Text $Stream 403 'This file cannot be written.' }
            Write-TextFile $Files[$name] $Request.Body
            return Send-Json $Stream @{ written = $Files[$name] }
        }
        'GET /api/addon' {
            return Send-Json $Stream @(Get-ChildItem -LiteralPath $AddonDir -Filter '*.lua' | Sort-Object Name | ForEach-Object { $_.Name })
        }
        'GET /api/addon-file' {
            $file = Join-Path $AddonDir ([string]$name)
            if ($name -notmatch '^[A-Za-z0-9_]+\.lua$' -or -not (Test-Path -LiteralPath $file)) { return Send-Text $Stream 404 'Not found.' }
            return Send-Response $Stream 200 'text/plain; charset=utf-8' ([System.IO.File]::ReadAllBytes($file))
        }
        'GET /api/locale-tables' {
            return Send-Text $Stream 200 (Get-LocaleTables)
        }
        'GET /api/usage' {
            if ($name -notmatch '^BONK_STRING_\w+$') { return Send-Text $Stream 404 'Not a string id.' }
            $uses = Select-String -Path (Join-Path $BonkDir '*.cpp') -Pattern $name -SimpleMatch |
                Where-Object { $_.Filename -ne 'BonkStrings.cpp' } | Select-Object -First 8 |
                ForEach-Object { @{ file = $_.Filename; line = $_.LineNumber; text = $_.Line.Trim() } }
            return Send-Json $Stream @($uses)
        }
        'POST /api/apply' {
            if (-not (Test-Path -LiteralPath $MariaDb)) { return Send-Text $Stream 503 "No MariaDB client at $MariaDb. Start the tool with -MariaDb <path to mariadb.exe>." }
            if (-not (Test-DbUp)) { return Send-Text $Stream 503 'The database is not running.' }
            $sql = Join-Path ([System.IO.Path]::GetTempPath()) "hoa-translate-$Locale.sql"
            [System.IO.File]::WriteAllText($sql, $Request.Body, $Utf8)
            $output = & $MariaDb @DbRootArgs '--skip-ssl' '--default-character-set=utf8mb4' 'mangos' -e "source $($sql -replace '\\', '/')" 2>&1 | Out-String
            $ok = $LASTEXITCODE -eq 0
            Remove-Item -LiteralPath $sql -Force
            return Send-Json $Stream @{ ok = $ok; output = $output.Trim() }
        }
        'POST /api/migration' {
            $id = [string]$Request.Query['id']
            if ($id -notmatch '^\d{14}$') { return Send-Text $Stream 403 'A migration id has 14 digits.' }
            $file = Join-Path $Migrations "${id}_world.sql"
            if (Test-Path -LiteralPath $file) { return Send-Text $Stream 409 "$file already exists." }
            Write-TextFile $file $Request.Body
            return Send-Json $Stream @{ written = $file }
        }
        default { return Send-Text $Stream 404 'Not found.' }
    }
}

$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
$url = "http://127.0.0.1:$Port/#$Token"
Write-Host "Translating $Locale at $url"
Write-Host 'Press Ctrl+C to stop.'
if (-not $NoBrowser) { Start-Process $url }
try {
    while ($true) {
        if (-not $listener.Pending()) {
            Start-Sleep -Milliseconds 50
            continue
        }
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 15000
            $stream = $client.GetStream()
            $request = Read-Request $stream
            if ($request) {
                try { Invoke-Route $request $stream }
                catch { Send-Text $stream 500 $_.Exception.Message }
            }
        } catch {
            Write-Warning $_.Exception.Message
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}

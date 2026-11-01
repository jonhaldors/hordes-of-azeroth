param(
    [switch]$Publish,
    [string]$Version,
    [string]$Repository,
    [string]$PreviousManifest,
    [switch]$ReuseWorldDump,
    [string]$NotesFile,
    [switch]$OwnNotesOnly,
    [switch]$RepostDiscord,
    [int]$Hotfix = 0
)
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$releaseConfig = Get-Content (Join-Path $ConfigDir 'release.json') -Raw | ConvertFrom-Json
$repository = if ($Repository) { $Repository } else { $releaseConfig.repository }
$testChannel = $repository -ne $releaseConfig.repository
$statsUrl = if ($env:HOA_STATS_URL) { $env:HOA_STATS_URL } else { "$([Environment]::GetEnvironmentVariable('HOA_STATS_URL', 'User'))" }
if (-not $statsUrl) { Write-Warning 'HOA_STATS_URL is not set: this launcher will not send run data or bug reports.' }
$lobbyUrl = if ($env:HOA_LOBBY_URL) { $env:HOA_LOBBY_URL } else { "$([Environment]::GetEnvironmentVariable('HOA_LOBBY_URL', 'User'))" }
if (-not $lobbyUrl) { Write-Warning 'HOA_LOBBY_URL is not set: co-op will be off in this launcher.' }
$mirrorUrl = if ($env:HOA_MIRROR_URL) { $env:HOA_MIRROR_URL } else { "$([Environment]::GetEnvironmentVariable('HOA_MIRROR_URL', 'User'))" }
if (-not $mirrorUrl) { Write-Warning 'HOA_MIRROR_URL is not set: this launcher only downloads from GitHub.' }
if ($Publish -and $Version -and -not $testChannel) { throw 'A -Version test release only goes to a test repository (-Repository): change VERSION and CHANGELOG.md for a real one.' }
$version = if ($Version) { $Version } else { (Get-Content (Join-Path $RepoRoot 'VERSION') -Raw).Trim() }
$tag = "v$version"
$packageTag = if ($Hotfix) { "packages-$tag-hotfix$Hotfix" } else { "packages-$tag" }
$releaseRoot = Join-Path $RepoRoot 'release'
$buildDir = Join-Path $releaseRoot 'build'
$cacheDir = Join-Path $releaseRoot 'cache'
$outDir = Join-Path $releaseRoot $version
$assetsDir = Join-Path $outDir 'assets'
$serverSource = Join-Path $releaseRoot 'src\core'
$serverBuild = Join-Path $buildDir 'server'
$serverInstall = Join-Path $buildDir 'server-install'
$clientSource = Join-Path $releaseRoot 'src\client'
$clientTarget = Join-Path $buildDir 'client-target'
$clientOut = Join-Path $buildDir 'client'
$linuxOut = Join-Path $buildDir 'linux'
$runtimeDlls = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')
$fixedZipTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)

function Get-Sha256([string]$Path) { (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

function Get-TextSha256([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text)) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function Get-ReleaseNotes {
    $sections = [System.Collections.Generic.List[object]]::new()
    $current = $null
    foreach ($line in Get-Content (Join-Path $RepoRoot 'CHANGELOG.md') -Encoding UTF8) {
        if ($line -match '^## (\S+)') {
            $current = [ordered]@{ version = $Matches[1]; notes = [System.Collections.Generic.List[string]]::new() }
            $sections.Add($current)
        } elseif ($current) {
            $current.notes.Add($line)
        }
    }
    foreach ($section in $sections) { $section.notes = ($section.notes -join "`n").Trim() }
    $sections
}

function Get-StagedTestNotes([string]$Version) {
    $file = Join-Path $RepoRoot "release\$Version\notes.md"
    if (-not (Test-Path $file)) { return $null }
    $text = [System.IO.File]::ReadAllText($file).Replace("`r`n", "`n")
    $footer = $text.IndexOf("`n---`n")
    if ($footer -ge 0) { $text = $text.Substring(0, $footer) }
    $text.Trim()
}

function Add-EarlierTestNotes($Notes, $Previous) {
    $byVersion = [ordered]@{}
    foreach ($section in $Notes) { $byVersion[$section.version] = $section }
    if ($Previous -and $Previous.releaseNotes) {
        foreach ($section in $Previous.releaseNotes) {
            if (-not $byVersion.Contains($section.version)) { $byVersion[$section.version] = [ordered]@{ version = $section.version; notes = $section.notes } }
        }
    }
    foreach ($folder in Get-ChildItem (Join-Path $RepoRoot 'release') -Directory -ErrorAction SilentlyContinue) {
        if ($folder.Name -notmatch '^\d+\.\d+\.\d+$' -or $byVersion.Contains($folder.Name)) { continue }
        $staged = Get-StagedTestNotes $folder.Name
        if ($staged) { $byVersion[$folder.Name] = [ordered]@{ version = $folder.Name; notes = $staged } }
    }
    $byVersion.Values | Sort-Object { [version]$_.version } -Descending
}

function Get-DiscordWebhook {
    if ($env:HOA_DISCORD_WEBHOOK) { return $env:HOA_DISCORD_WEBHOOK.Trim() }
    $file = Join-Path $env:LOCALAPPDATA 'HordesOfAzeroth\discord-webhook.txt'
    if (Test-Path $file) { return (Get-Content $file -Raw).Trim() }
    return $null
}

$discordDescriptionLimit = 4096
$discordPartHeaderRoom = 24
$discordPostsFile = Join-Path $env:LOCALAPPDATA 'HordesOfAzeroth\discord-posts.txt'

function ConvertTo-DiscordChunks([string]$Notes, [string]$ReleaseUrl) {
    $lines = $Notes -split "`r?`n" | ForEach-Object { if ($_ -match '^####\s+(.+)$') { "**$($Matches[1].Trim())**" } else { $_ } }
    $more = "`n`n[Full patch notes and download]($ReleaseUrl)"
    $limit = $discordDescriptionLimit - $discordPartHeaderRoom
    $chunks = New-Object System.Collections.Generic.List[string]
    $current = ''
    $heading = ''
    foreach ($line in (($lines -join "`n").Trim() -split "`n")) {
        $candidate = if ($current) { "$current`n$line" } else { $line }
        if ($candidate.Length -gt $limit -and $current) {
            $chunks.Add($current.Trim())
            $current = if ($heading -and $line -notmatch '^### ') { "$heading`n$line" } else { $line }
        } else {
            $current = $candidate
        }
        if ($line -match '^### ') { $heading = $line }
    }
    if (($current + $more).Length -gt $limit) {
        $chunks.Add($current.Trim())
        $current = ''
    }
    $chunks.Add(($current + $more).Trim())
    if ($chunks.Count -gt 1) {
        for ($index = 0; $index -lt $chunks.Count; $index++) {
            $chunks[$index] = "**Part $($index + 1) of $($chunks.Count)**`n`n" + $chunks[$index]
        }
    }
    , $chunks.ToArray()
}

function Remove-DiscordPosts([string]$Webhook, [string]$Tag) {
    if (-not (Test-Path $discordPostsFile)) { return 0 }
    $kept = @()
    $removed = 0
    foreach ($line in Get-Content $discordPostsFile) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2 -and $parts[0] -eq $Tag) {
            try {
                Invoke-RestMethod -Method Delete -Uri "$Webhook/messages/$($parts[1])" | Out-Null
                $removed++
            } catch {
                Write-Warning "Couldn't delete Discord message $($parts[1]): $($_.Exception.Message)"
            }
        } else {
            $kept += $line
        }
    }
    [System.IO.File]::WriteAllLines($discordPostsFile, [string[]]$kept)
    $removed
}

function Send-DiscordAnnouncement([string]$Title, [string]$Notes, [string]$ReleaseUrl, [string]$Tag) {
    $webhook = Get-DiscordWebhook
    if (-not $webhook) {
        Write-Host 'No Discord webhook set up; skipping the #announcements post.'
        return
    }
    $chunks = ConvertTo-DiscordChunks $Notes $ReleaseUrl
    try {
        for ($index = 0; $index -lt $chunks.Count; $index++) {
            $embed = @{ description = $chunks[$index]; color = 0xB3261E }
            if ($index -eq 0) { $embed.title = $Title; $embed.url = $ReleaseUrl }
            if ($index -eq $chunks.Count - 1) { $embed.footer = @{ text = 'Start the launcher and press Update. Your characters are backed up first.' } }
            $payload = @{ username = $releaseConfig.productName; allowed_mentions = @{ parse = @() }; embeds = @($embed) }
            $body = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 6))
            $posted = Invoke-RestMethod -Method Post -Uri "$($webhook)?wait=true" -ContentType 'application/json; charset=utf-8' -Body $body
            New-Item -ItemType Directory -Force (Split-Path $discordPostsFile) | Out-Null
            Add-Content -Path $discordPostsFile -Value "$Tag=$($posted.id)"
            if ($index -lt $chunks.Count - 1) { Start-Sleep -Milliseconds 800 }
        }
        Write-Host "Posted the patch notes to Discord ($($chunks.Count) messages)."
    } catch {
        Write-Warning "The release is published, but the Discord post failed: $($_.Exception.Message)"
    }
}

if ($RepostDiscord) {
    $webhook = Get-DiscordWebhook
    if (-not $webhook) { throw 'No Discord webhook set up.' }
    Write-Host "Deleted $(Remove-DiscordPosts $webhook $tag) earlier Discord posts for $tag."
    $section = Get-ReleaseNotes | Where-Object { $_.version -eq $version } | Select-Object -First 1
    if (-not $section) { throw "CHANGELOG.md has no section for $version." }
    Send-DiscordAnnouncement "$($releaseConfig.productName) $version" $section.notes "https://github.com/$repository/releases/tag/$tag" $tag
    return
}

function Get-CMake {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) { throw 'Visual Studio 2022 Build Tools with the C++ workload are needed (see README).' }
    $instance = & $vswhere -all -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath |
        Where-Object { Test-Path (Join-Path $_ 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe') } |
        Select-Object -First 1
    if (-not $instance) { throw 'Visual Studio 2022 Build Tools with the C++ workload are needed (see README).' }
    [pscustomobject]@{ Exe = Join-Path $instance 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'; Instance = $instance }
}

function Invoke-Native([string]$What, [string]$Exe, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    & $Exe @Arguments 2>&1 | ForEach-Object { "$_" } | Select-String -Pattern ' error |error [A-Z]+[0-9]+|fatal' | Select-Object -First 20 | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$What failed with exit code $LASTEXITCODE." }
}

function Invoke-Quiet([string]$What, [string]$Exe, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    & $Exe @Arguments 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "$What failed with exit code $LASTEXITCODE." }
}

function Copy-Runtime([string]$Instance, [string[]]$Targets, [string]$Architecture = 'x64', [string[]]$Dlls = $runtimeDlls) {
    $redist = Get-ChildItem (Join-Path $Instance 'VC\Redist\MSVC') -Directory | Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "$Architecture\Microsoft.VC143.CRT" } | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $redist) { throw 'The Visual C++ redistributable files were not found in the Build Tools.' }
    foreach ($target in $Targets) {
        New-Item -ItemType Directory -Force $target | Out-Null
        foreach ($dll in $Dlls) { Copy-Item (Join-Path $redist $dll) $target -Force }
    }
}

function Save-ServerSymbols([string]$Commit) {
    $symbols = Join-Path $releaseRoot "symbols\$($Commit.Substring(0, 9))"
    New-Item -ItemType Directory -Force $symbols | Out-Null
    $pdb = Get-ChildItem @($serverBuild, (Join-Path $serverSource 'bin')) -Recurse -Filter 'mangosd.pdb' -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -like '*Release*' } | Select-Object -First 1
    if (-not $pdb) { throw 'mangosd.pdb was not built; crash dumps from this release could not be read.' }
    Copy-Item $pdb.FullName $symbols -Force
    Copy-Item (Join-Path $serverInstall 'mangosd.exe') $symbols -Force
}

function Invoke-ServerBuild {
    $commit = (git -C $RepoRoot rev-parse HEAD:server/core).Trim()
    $stamp = Join-Path $serverInstall 'commit.txt'
    if ((Test-Path $stamp) -and (Get-Content $stamp -Raw).Trim() -eq $commit) { return }

    $fork = Join-Path $ServerDir 'core'
    if (-not (Test-Path (Join-Path $serverSource '.git'))) {
        Invoke-Quiet 'git worktree add' 'git' @('-C', $fork, 'worktree', 'add', '--detach', $serverSource, $commit)
    } else {
        Invoke-Quiet 'git checkout' 'git' @('-C', $serverSource, 'checkout', '--quiet', '--force', '--detach', $commit)
    }

    Write-Host "Building the server from fork commit $($commit.Substring(0, 9)) (portable, not tuned to this CPU)..."
    $cmake = Get-CMake
    Invoke-Native 'CMake configure' $cmake.Exe @(
        '-S', $serverSource, '-B', $serverBuild, '-G', 'Visual Studio 17 2022', '-A', 'x64',
        "-DCMAKE_GENERATOR_INSTANCE=$($cmake.Instance)",
        '-DBUILD_EXTRACTORS=1', '-DBUILD_FOR_HOST_CPU=OFF', "-DCMAKE_INSTALL_PREFIX=$serverInstall",
        '-DCMAKE_CXX_FLAGS_RELEASE=/MD /O2 /Ob2 /DNDEBUG /Zi', '-DCMAKE_C_FLAGS_RELEASE=/MD /O2 /Ob2 /DNDEBUG /Zi',
        '-DCMAKE_EXE_LINKER_FLAGS_RELEASE=/DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF'
    )
    Invoke-Native 'Server build' $cmake.Exe @('--build', $serverBuild, '--config', 'Release', '--', '/m', '/v:minimal')
    if (Test-Path $serverInstall) { Remove-Item $serverInstall -Recurse -Force }
    Invoke-Native 'Server install' $cmake.Exe @('--install', $serverBuild, '--config', 'Release')
    Copy-Runtime $cmake.Instance @($serverInstall, (Join-Path $serverInstall 'Extractors'))
    Save-ServerSymbols $commit
    [System.IO.File]::WriteAllText($stamp, $commit)
}

function Write-ClientLicenses {
    if (-not (Get-Command cargo-about -ErrorAction SilentlyContinue)) { throw 'cargo-about is needed for the client licence list: cargo install cargo-about --locked --features cli' }
    $hoa = Join-Path $clientSource 'crates\hoa'
    Invoke-Native 'Client licence list' 'cargo' @('about', 'generate', '-c', (Join-Path $hoa 'about.toml'), '-m', (Join-Path $hoa 'Cargo.toml'), '--no-default-features', '--locked', '-o', (Join-Path $clientOut 'CLIENT-LICENSES.md'), (Join-Path $hoa 'about.hbs'))
}

function Invoke-ClientBuild {
    $commit = (git -C $RepoRoot rev-parse HEAD:client).Trim()
    $stamp = Join-Path $clientOut 'commit.txt'
    if ((Test-Path $stamp) -and (Get-Content $stamp -Raw).Trim() -eq $commit) { return }

    $fork = Join-Path $RepoRoot 'client'
    if (-not (Test-Path (Join-Path $clientSource '.git'))) {
        Invoke-Quiet 'git worktree add' 'git' @('-C', $fork, 'worktree', 'add', '--detach', $clientSource, $commit)
    } else {
        Invoke-Quiet 'git checkout' 'git' @('-C', $clientSource, 'checkout', '--quiet', '--force', '--detach', $commit)
    }

    Write-Host "Building the client from fork commit $($commit.Substring(0, 9)) (player build)..."
    $env:CARGO_TARGET_DIR = $clientTarget
    $env:RUSTFLAGS = '-C target-feature=+crt-static'
    try {
        Invoke-Native 'Client build' 'cargo' @('build', '--manifest-path', (Join-Path $clientSource 'Cargo.toml'), '--profile', 'ship', '--locked', '-p', 'hoa', '--no-default-features')
    } finally {
        Remove-Item Env:CARGO_TARGET_DIR, Env:RUSTFLAGS -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force $clientOut | Out-Null
    Copy-Item (Join-Path $clientTarget 'ship\HordesOfAzeroth.exe') (Join-Path $clientOut 'HordesOfAzeroth.exe') -Force
    Write-ClientLicenses
    [System.IO.File]::WriteAllText($stamp, $commit)
}

function Sync-ReleaseSource([string]$Fork, [string]$Directory, [string]$Commit) {
    if (-not (Test-Path (Join-Path $Directory '.git'))) {
        Invoke-Quiet 'git worktree add' 'git' @('-C', $Fork, 'worktree', 'add', '--detach', $Directory, $Commit)
    } else {
        Invoke-Quiet 'git checkout' 'git' @('-C', $Directory, 'checkout', '--quiet', '--force', '--detach', $Commit)
    }
}

function Invoke-LinuxBuild([string]$Part) {
    $submodule = if ($Part -eq 'server') { 'server/core' } else { 'client' }
    $source = if ($Part -eq 'server') { $serverSource } else { $clientSource }
    $commit = (git -C $RepoRoot rev-parse "HEAD:$submodule").Trim()
    $stamp = Join-Path $linuxOut "$Part-commit.txt"
    if ((Test-Path $stamp) -and (Get-Content $stamp -Raw).Trim() -eq $commit) { return }
    Sync-ReleaseSource (Join-Path $RepoRoot $submodule) $source $commit
    Write-Host "Building the Linux $Part from fork commit $($commit.Substring(0, 9)) in WSL..."
    & (Join-Path $PSScriptRoot 'build-linux.ps1') -Part $Part -ClientSource $clientSource -ServerSource $serverSource -Out $linuxOut
    [System.IO.File]::WriteAllText($stamp, $commit)
}

function Invoke-PackageBuild([string]$Name) {
    New-Item -ItemType Directory -Force $buildDir | Out-Null
    switch ($Name) {
        'telegraphkit' {
            $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
            $sources = Get-ChildItem (Join-Path (Get-CommittedTree) 'tools\telegraphs') -Filter '*.cs' | ForEach-Object FullName
            & $csc -nologo -optimize "-out:$(Join-Path $buildDir 'TelegraphKit.exe')" @sources | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'TelegraphKit did not compile.' }
        }
        'server' { Invoke-ServerBuild }
        'client' { Invoke-ClientBuild }
        'version' { [System.IO.File]::WriteAllText((Join-Path $buildDir 'VERSION'), "$version`n") }
        'launcher' {
            $project = Join-Path (Get-CommittedTree) 'tools\launcher\HordesOfAzerothLauncher.csproj'
            Invoke-Native 'Launcher build' 'dotnet' @('publish', $project, '-c', 'Release', '-r', 'win-x64', '-nologo', "-p:Repository=$repository", "-p:StatsUrl=$statsUrl", "-p:LobbyUrl=$lobbyUrl", "-p:MirrorUrl=$mirrorUrl", '-o', (Join-Path $buildDir 'launcher'))
        }
        'linux-launcher' {
            $project = Join-Path (Get-CommittedTree) 'tools\launcher\HordesOfAzerothLauncher.csproj'
            Invoke-Native 'Linux launcher build' 'dotnet' @('publish', $project, '-c', 'Release', '-r', 'linux-x64', '-nologo', "-p:Repository=$repository", "-p:StatsUrl=$statsUrl", "-p:LobbyUrl=$lobbyUrl", "-p:MirrorUrl=$mirrorUrl", '-o', (Join-Path $linuxOut 'launcher'))
        }
        'linux-server' { Invoke-LinuxBuild 'server' }
        'linux-client' { Invoke-LinuxBuild 'client' }
        'world-dump' {
            $dump = Join-Path $buildDir 'world.sql'
            if ($ReuseWorldDump -and (Test-Path $dump)) { return }
            if (-not (Test-DbUp)) { throw 'MariaDB is not running. Start it with tools\start-server.ps1 -DatabaseOnly.' }
            & (Join-Path $MariaDir 'bin\mariadb-dump.exe') @DbRootArgs --skip-dump-date --order-by-primary --single-transaction --ignore-table-data=mangos.variables "--result-file=$dump" mangos
            if ($LASTEXITCODE -ne 0) { throw 'mariadb-dump of the world database failed.' }
        }
        default { throw "Unknown build step $Name." }
    }
}

function Assert-WorldDumpMatchesServer {
    $dump = Join-Path $buildDir 'world.sql'
    $migrations = Join-Path $serverSource 'sql\migrations'
    if (-not (Test-Path $dump) -or -not (Test-Path $migrations)) { return }
    $needed = Get-ChildItem $migrations -Filter '*_world.sql' | ForEach-Object { $_.BaseName.Substring(0, 14) }
    $text = [System.IO.File]::ReadAllText($dump)
    $start = $text.IndexOf('INSERT INTO `migrations` VALUES')
    if ($start -lt 0) { throw 'The world dump has no migrations table rows.' }
    $end = $text.IndexOf(";`n", $start)
    $rows = $text.Substring($start, $end - $start)
    $missing = @($needed | Where-Object { -not $rows.Contains("'$_'") })
    if ($missing.Count -gt 0) {
        throw "The world dump is missing $($missing.Count) migration(s) of the server it ships with (first: $($missing[0])). Apply them with tools\apply-migrations.ps1 and run the release again without -ReuseWorldDump."
    }
}

function Get-CommittedTree {
    $tree = Join-Path $buildDir 'head'
    if (-not $script:committedTreeReady) {
        if (Test-Path $tree) { Remove-Item $tree -Recurse -Force }
        $archive = Join-Path $buildDir 'head.zip'
        Invoke-Quiet 'git archive' 'git' @('-C', $RepoRoot, 'archive', '--format=zip', '-o', $archive, 'HEAD')
        [System.IO.Compression.ZipFile]::ExtractToDirectory($archive, $tree)
        Remove-Item $archive
        $script:committedTreeReady = $true
    }
    $tree
}

function Get-CommittedCopy([string]$Relative, [string]$WorkingCopy) {
    $path = $Relative -replace '\\', '/'
    $committed = git -C $RepoRoot ls-tree --name-only HEAD -- $path
    if (-not $committed) { return $WorkingCopy }
    Join-Path (Get-CommittedTree) $path
}

function Get-CommittedCore {
    if (-not $script:committedCoreReady) {
        $commit = (git -C $RepoRoot rev-parse HEAD:server/core).Trim()
        Sync-ReleaseSource (Join-Path $ServerDir 'core') $serverSource $commit
        $script:committedCoreReady = $true
    }
    $serverSource
}

function Resolve-PackageSource([string]$From) {
    $relative = $From -replace '\\', '/'
    if ($relative.StartsWith('server/core/')) {
        return [pscustomobject]@{ Root = Get-CommittedCore; Path = $relative.Substring('server/core/'.Length); Committed = $true }
    }
    [pscustomobject]@{ Root = $RepoRoot; Path = $From; Committed = $false }
}

function Resolve-PackageFiles($Package) {
    $files = [System.Collections.Generic.List[object]]::new()
    foreach ($path in @($Package.git)) {
        if (-not $path) { continue }
        $tree = Get-CommittedTree
        foreach ($tracked in git -C $RepoRoot ls-tree -r --name-only HEAD -- $path) {
            $source = Join-Path $tree $tracked
            if (Test-Path $source -PathType Leaf) { $files.Add([pscustomobject]@{ Source = $source; Target = $tracked }) }
        }
    }
    foreach ($entry in @($Package.files)) {
        if (-not $entry) { continue }
        $source = Resolve-PackageSource $entry.from
        $pattern = Join-Path $source.Root $source.Path
        if ($entry.from -match '[*?]') {
            $matched = @(Get-ChildItem $pattern -File | Sort-Object Name)
            if (-not $matched) { return $null }
            $folder = if ($entry.to) { $entry.to } else { Split-Path $entry.from }
            foreach ($file in $matched) {
                $relative = $file.FullName.Substring($RepoRoot.TrimEnd('\').Length + 1)
                $copy = if ($source.Committed) { $file.FullName } else { Get-CommittedCopy $relative $file.FullName }
                $files.Add([pscustomobject]@{ Source = $copy; Target = "$folder/$($file.Name)" })
            }
        } else {
            if (-not (Test-Path $pattern -PathType Leaf)) { return $null }
            $target = if ($entry.to) { $entry.to } else { $entry.from }
            $copy = if ($source.Committed) { $pattern } else { Get-CommittedCopy $entry.from $pattern }
            $files.Add([pscustomobject]@{ Source = $copy; Target = $target })
        }
    }
    foreach ($file in $files) { $file.Target = $file.Target -replace '\\', '/' }
    $files
}

function New-PackageZip([string]$Name, $Files) {
    $zipPath = Join-Path $assetsDir "$Name.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $Files | Sort-Object Target) {
            $entry = $zip.CreateEntry($file.Target, [System.IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedZipTime
            $writer = $entry.Open()
            $reader = [System.IO.File]::OpenRead($file.Source)
            try { $reader.CopyTo($writer) } finally { $reader.Dispose(); $writer.Dispose() }
        }
    } finally {
        $zip.Dispose()
    }
    Get-Item $zipPath
}

function Get-PreviousManifest([string]$Name) {
    if ($PreviousManifest -and $Name -eq 'manifest.json') { return Get-Content $PreviousManifest -Raw | ConvertFrom-Json }
    $previousDir = Join-Path $releaseRoot 'previous'
    New-Item -ItemType Directory -Force $previousDir | Out-Null
    $target = Join-Path $previousDir $Name
    if (Test-Path $target) { Remove-Item $target -Force }
    $ErrorActionPreference = 'Continue'
    gh release download --repo $repository --pattern $Name --dir $previousDir 2>$null | Out-Null
    $ErrorActionPreference = 'Stop'
    if (Test-Path $target) { return Get-Content $target -Raw | ConvertFrom-Json }
    $null
}

function Get-ThirdPartyEntry($Item) {
    $file = $null
    if ($Item.localCopy) {
        $local = Join-Path $RepoRoot $Item.localCopy
        if (Test-Path $local) { $file = $local }
    }
    if (-not $file) {
        New-Item -ItemType Directory -Force $cacheDir | Out-Null
        $file = Join-Path $cacheDir ([System.IO.Path]::GetFileName(([Uri]$Item.url).AbsolutePath))
        if (-not (Test-Path $file)) { Invoke-WebRequest $Item.url -OutFile $file -UseBasicParsing }
    }
    [ordered]@{
        name = $Item.name
        version = $Item.version
        licence = $Item.licence
        url = $Item.url
        size = (Get-Item $file).Length
        sha256 = Get-Sha256 $file
        install = $Item.install
    }
}

function Get-NavGroupFiles($Group) {
    $mmaps = Join-Path $DataDir 'mmaps'
    foreach ($map in $Group.maps.PSObject.Properties) {
        $id = '{0:D3}' -f [int]$map.Name
        $header = Join-Path $mmaps "$id.mmap"
        if (Test-Path $header) { [pscustomobject]@{ Source = $header; Target = "$id.mmap" } }
        $tiles = if ($map.Value -eq 'all') {
            Get-ChildItem $mmaps -Filter "$id*.mmtile"
        } else {
            foreach ($tile in $map.Value) {
                $xy = $tile -split ','
                $path = Join-Path $mmaps ('{0}{1:D2}{2:D2}.mmtile' -f $id, [int]$xy[1], [int]$xy[0])
                if (Test-Path $path) { Get-Item $path }
            }
        }
        foreach ($tile in $tiles) { [pscustomobject]@{ Source = $tile.FullName; Target = $tile.Name } }
    }
}

function Get-NavFilesProblem($Group, $Files) {
    $headers = @($Files | Where-Object { $_.Target -like '*.mmap' }).Count
    if ($headers -lt @($Group.maps.PSObject.Properties).Count) { return "they aren't built in $(Join-Path $DataDir 'mmaps')" }
    $commit = (git -C $RepoRoot rev-parse HEAD:server/core).Trim()
    $generatorChanged = [DateTimeOffset]::Parse((git -C (Join-Path $ServerDir 'core') log -1 --format=%cI $commit -- contrib/mmap contrib/vmap_extractor contrib/vmap_assembler contrib/extractor).Trim())
    $stale = @($Files | Where-Object { (Get-Item $_.Source).LastWriteTimeUtc -lt $generatorChanged.UtcDateTime })
    if ($stale.Count) { return "$($stale.Count) files are older than the last map generator change in server/core ($($generatorChanged.ToString('yyyy-MM-dd')))" }
}

function Get-NavGroups($Previous) {
    $previousDownloads = @{}
    if ($Previous -and $Previous.navTiles) { foreach ($group in $Previous.navTiles) { if ($group.download) { $previousDownloads[$group.name] = $group.download } } }
    foreach ($group in (Get-Content (Join-Path $ConfigDir 'navtiles.json') -Raw | ConvertFrom-Json).groups) {
        $files = @(Get-NavGroupFiles $group)
        $problem = Get-NavFilesProblem $group $files
        if ($problem) {
            Write-Warning "Monster paths, $($group.name): $problem. The release has no download for them, so the launcher builds them on the player's processor. Build every tile with tools\extract-client-data.ps1 -MmapsOnly -AllTiles to ship them."
            [ordered]@{ name = $group.name; maps = $group.maps }
            continue
        }
        $contentHash = Get-TextSha256 (($files | Sort-Object Target | ForEach-Object { "$($_.Target):$(Get-Sha256 $_.Source)" }) -join "`n")
        $old = $previousDownloads[$group.name]
        $download = if ($old -and $old.contentHash -eq $contentHash) {
            Write-Host "monster paths, $($group.name): unchanged since $($old.release)"
            $old
        } else {
            $slug = ($group.name.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
            $zip = New-PackageZip "navmesh-$slug" $files
            $uploads.Add($zip.FullName)
            Write-Host ('monster paths, {0}: {1} files, {2:N1} MB zipped' -f $group.name, $files.Count, ($zip.Length / 1MB))
            [ordered]@{ release = $tag; url = "$baseUrl/$($zip.Name)"; size = $zip.Length; sha256 = Get-Sha256 $zip.FullName; contentHash = $contentHash }
        }
        [ordered]@{ name = $group.name; maps = $group.maps; download = $download }
    }
}

if (-not (Test-DbUp)) { throw 'MariaDB is not running. Start it with tools\start-server.ps1 -DatabaseOnly.' }
& (Join-Path $PSScriptRoot 'build-navtiles.ps1') | Out-Null
git -C $RepoRoot update-index -q --refresh -- config/navtiles.json
if (git -C $RepoRoot status --porcelain -- config/navtiles.json) { throw 'config/navtiles.json did not match the run zones and has been rebuilt: commit it, then release again.' }

if ($Publish -and -not $testChannel -and (git -C $RepoRoot status --porcelain --ignore-submodules=all)) { throw 'Commit or stash every change before publishing: the release is built from the working tree.' }

if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Force $assetsDir | Out-Null

$operatingSystems = @(
    [pscustomobject]@{ Name = 'windows'; Manifest = 'manifest.json'; ZipSuffix = ''; Launcher = 'HoALauncher.exe'; Download = 'HoALauncher.exe' },
    [pscustomobject]@{ Name = 'linux'; Manifest = 'manifest-linux.json'; ZipSuffix = '-linux'; Launcher = 'HoALauncher'; Download = 'HoALauncher-linux.tar.gz' }
)
$previousByOs = @{}
foreach ($os in $operatingSystems) {
    $previousByOs[$os.Name] = @{}
    $old = Get-PreviousManifest $os.Manifest
    if ($old) { foreach ($package in $old.packages) { $previousByOs[$os.Name][$package.name] = $package } }
    if ($os.Name -eq 'windows') { $previous = $old }
}
$baseUrl = "https://github.com/$repository/releases/download/$packageTag"

$uploads = [System.Collections.Generic.List[string]]::new()
$releaseUploads = [System.Collections.Generic.List[string]]::new()
$builtSteps = @{}
$sharedEntries = @{}
$packagesByOs = @{}
foreach ($os in $operatingSystems) {
    $packages = [System.Collections.Generic.List[object]]::new()
    foreach ($package in $releaseConfig.packages | Where-Object { -not $_.os -or $_.os -eq $os.Name }) {
        $shared = -not $package.os
        if ($shared -and $sharedEntries.ContainsKey($package.name)) {
            if ($sharedEntries[$package.name]) { $packages.Add($sharedEntries[$package.name]) }
            continue
        }
        if ($package.build -and -not $builtSteps.ContainsKey($package.build)) {
            Invoke-PackageBuild $package.build
            $builtSteps[$package.build] = $true
        }
        $label = "$($package.name)$($os.ZipSuffix)"
        $files = Resolve-PackageFiles $package
        if ($null -eq $files) {
            if ($package.optional) { Write-Host "${label}: skipped (not built yet)"; if ($shared) { $sharedEntries[$package.name] = $null }; continue }
            throw "Package $label is missing files: build them first."
        }
        $listed = @($files | Sort-Object Target | ForEach-Object {
            [ordered]@{ path = $_.Target; size = (Get-Item $_.Source).Length; sha256 = Get-Sha256 $_.Source }
        })
        $hashed = if ($package.changesWith) {
            Get-ChildItem (Join-Path $RepoRoot $package.changesWith) -File | Sort-Object Name |
                ForEach-Object { [ordered]@{ path = $_.Name; sha256 = Get-Sha256 $_.FullName } }
        } else { $listed }
        $contentHash = Get-TextSha256 (($hashed | ForEach-Object { "$($_.path):$($_.sha256)" }) -join "`n")
        $old = $previousByOs[$os.Name][$package.name]
        if ($shared -and -not ($old -and $old.contentHash -eq $contentHash)) {
            foreach ($other in $previousByOs.Values) {
                $candidate = $other[$package.name]
                if ($candidate -and $candidate.contentHash -eq $contentHash) { $old = $candidate }
            }
        }
        $entry = if ($old -and $old.contentHash -eq $contentHash) {
            Write-Host "${label}: unchanged since $($old.release)"
            $old
        } else {
            $zip = New-PackageZip $label $files
            $uploads.Add($zip.FullName)
            Write-Host ('{0}: {1} files, {2:N1} MB zipped' -f $label, $listed.Count, ($zip.Length / 1MB))
            [ordered]@{
                name = $package.name
                release = $tag
                url = "$baseUrl/$($zip.Name)"
                size = $zip.Length
                sha256 = Get-Sha256 $zip.FullName
                contentHash = $contentHash
                files = $listed
            }
        }
        if ($shared) { $sharedEntries[$package.name] = $entry }
        $packages.Add($entry)
    }
    $packagesByOs[$os.Name] = $packages
}

$navGroups = @(Get-NavGroups $previous)

Assert-WorldDumpMatchesServer

$notes = @(Get-ReleaseNotes)
if ($Version -and -not ($notes | Where-Object { $_.version -eq $version })) {
    $testNotes = if ($NotesFile) { ([System.IO.File]::ReadAllText((Resolve-Path $NotesFile))).Trim() } else { '- Test release built with release.ps1 -Version.' }
    $notes = @([ordered]@{ version = $version; notes = $testNotes }) + $notes
}
if ($testChannel) { $notes = @(Add-EarlierTestNotes $notes $previous) }
$currentNotes = $notes | Where-Object { $_.version -eq $version } | Select-Object -First 1
if (-not $currentNotes) { throw "CHANGELOG.md has no section for $version." }
if ($OwnNotesOnly) { $notes = @($currentNotes) }

$published = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$launcherHashes = [System.Collections.Generic.List[string]]::new()
foreach ($os in $operatingSystems) {
    $manifest = [ordered]@{
        product = $releaseConfig.productName
        version = $version
        tag = $tag
        published = $published
        minLauncherVersion = $releaseConfig.minLauncherVersion
        realmName = $releaseConfig.realmName
        clientDlls = $releaseConfig.clientDlls
        releaseNotes = $notes
        navTiles = $navGroups
        thirdParty = @($releaseConfig.thirdParty | Where-Object { -not $_.os -or $_.os -eq $os.Name } | ForEach-Object { Get-ThirdPartyEntry $_ })
        packages = $packagesByOs[$os.Name]
    }
    $manifestPath = Join-Path $assetsDir $os.Manifest
    [System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8) + "`n")
    $releaseUploads.Add($manifestPath)

    $launcherBuild = if ($os.Name -eq 'windows') { Join-Path $buildDir "launcher\$($os.Launcher)" } else { Join-Path $linuxOut "launcher\$($os.Launcher)" }
    if (-not (Test-Path $launcherBuild)) { continue }
    $download = Join-Path $assetsDir $os.Download
    if ($os.Name -eq 'windows') {
        Copy-Item $launcherBuild $download -Force
    } else {
        Invoke-Native 'Linux launcher archive' 'python' @((Join-Path $PSScriptRoot 'linux\pack-launcher.py'), $launcherBuild, $download)
    }
    $releaseUploads.Add($download)
    $launcherHashes.Add("``$($os.Download)`` SHA-256: ``$(Get-Sha256 $download)``")
}
$notesPath = Join-Path $outDir 'notes.md'
$releaseBody = $currentNotes.notes
if ($launcherHashes.Count) {
    $releaseBody += "`n`n---`n`nNew here? On Windows, download ``HoALauncher.exe`` below and put it in your World of Warcraft 1.12.1 folder. On Linux and Steam Deck, unpack ``HoALauncher-linux.tar.gz`` into that folder and run ``HoALauncher``. Already playing? The launcher updates itself.`n`n" + ($launcherHashes -join "`n`n")
}
[System.IO.File]::WriteAllText($notesPath, $releaseBody + "`n")

Write-Host "Release $tag staged in $outDir ($($uploads.Count) changed packages for $packageTag)"
if (-not $Publish) { return }

$title = if ($testChannel) { "$($releaseConfig.productName) $version (test build)" } else { "$($releaseConfig.productName) $version" }
if ($uploads.Count) {
    gh release create $packageTag @uploads --repo $repository --prerelease --title "$title update packages" --notes "Packages the launcher downloads for $tag. Players don't need anything here: get the launcher from the $tag release."
    if ($LASTEXITCODE -ne 0) { throw "gh release create $packageTag failed with exit code $LASTEXITCODE." }
}
if ($Hotfix) {
    gh release upload $tag @releaseUploads --repo $repository --clobber
    if ($LASTEXITCODE -ne 0) { throw "gh release upload $tag failed with exit code $LASTEXITCODE." }
    gh release edit $tag --repo $repository --notes-file $notesPath
    if ($LASTEXITCODE -ne 0) { throw "gh release edit $tag failed with exit code $LASTEXITCODE." }
    if (-not $testChannel) { & (Join-Path $PSScriptRoot 'sync-mirror.ps1') -Repository $repository -LocalDir $assetsDir }
    Write-Host "Published hotfix $Hotfix to $tag on $repository; no Discord post"
    return
}
gh release create $tag @releaseUploads --repo $repository --title $title --notes-file $notesPath --latest
if ($LASTEXITCODE -ne 0) { throw "gh release create failed with exit code $LASTEXITCODE." }
Write-Host "Published $tag to $repository"
if (-not $testChannel) {
    & (Join-Path $PSScriptRoot 'sync-mirror.ps1') -Repository $repository -LocalDir $assetsDir
    Send-DiscordAnnouncement $title $currentNotes.notes "https://github.com/$repository/releases/tag/$tag" $tag
}

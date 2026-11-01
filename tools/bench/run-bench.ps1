param(
    [Parameter(Mandatory)][ValidateSet('warrior', 'paladin', 'hunter', 'rogue', 'priest', 'shaman', 'mage', 'warlock', 'druid')][string]$Class,
    [string[]]$Builds = @(),
    [string]$Account = 'player',
    [string]$Password = '',
    [string]$Hero = '',
    [switch]$Dummies,
    [switch]$DummyCrowd,
    [switch]$Melee,
    [switch]$Crowd,
    [switch]$Waves,
    [switch]$NoAnchor,
    [switch]$Markdown,
    [switch]$Singles,
    [int]$Rank = 0,
    [string[]]$Passives = @(),
    [int[]]$Glyphs = @(),
    [int[]]$Items = @(),
    [int]$Training = 0,
    [string[]]$Cards = @(),
    [string[]]$Talents = @(),
    [switch]$Mortal,
    [int]$Tier = 0,
    [int]$Band = 1,
    [int]$Minute = 5,
    [int]$Level = 20,
    [string]$Tag = '',
    [int]$DummyCount = 10,
    [int]$ProbeTalent = 0,
    [string[]]$AfterPack = @(),
    [string]$Pack = '',
    [switch]$Benilla
)
. "$PSScriptRoot\..\common.ps1"
$Builds = @($Builds | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Passives = @($Passives | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Cards = @($Cards | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Talents = @($Talents | ForEach-Object { $_ -split ',' } | Where-Object { $_ })

$ClassIds = @{ warrior = 1; paladin = 2; hunter = 3; rogue = 4; priest = 5; shaman = 7; mage = 8; warlock = 9; druid = 11 }
$AnchorKey = 'anchor'
$BuildSeconds = if ($Rank -gt 1) { 52 } else { 45 }
$QuitDelaySeconds = 3
$DummyRingYards = 7
$SetupSeconds = if ($Dummies) { 14 } else { 13 }
$EnterWaitSeconds = 10
$QuitMarginSeconds = 90
$WaveSeconds = 3
$VitalsSeconds = 2

$mariadb = Join-Path $MariaDir 'bin\mariadb.exe'
$addonSource = Join-Path $PSScriptRoot 'BenchTest'
$benillaRoot = Join-Path (Split-Path -Parent $RepoRoot) 'WoW Vanilla-benilla'
$benillaClient = Join-Path $benillaRoot 'client'
$addonTarget = if ($Benilla) { Join-Path $benillaClient 'benilla-config\AddOns\BenchTest' } else { Join-Path $RepoRoot 'Interface\AddOns\BenchTest' }
$statsFile = Join-Path $RepoRoot 'Interface\GlueXML\BonkStats.lua'
$chatLog = if ($Benilla) { Join-Path $benillaClient 'benilla-config\Logs\WoWChatLog.txt' } else { Join-Path $RepoRoot 'Logs\WoWChatLog.txt' }
$realmLog = if ($Benilla) { Join-Path (Split-Path -Parent $RepoRoot) 'WoW Vanilla\server\logs\Realmd.log' } else { Join-Path $LogDir 'Realmd.log' }
$manifestFile = Join-Path $env:TEMP "bench-$Class.json"

Add-Type -Namespace Bench -Name Window -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
'@

function Invoke-Sql([string]$Sql, [string]$Database) {
    $rows = & $mariadb @DbRootArgs -N -B -e $Sql $Database
    if ($LASTEXITCODE -ne 0) { throw "SQL failed: $Sql" }
    @($rows)
}

function Get-GameProcess {
    Get-Process HordesOfAzeroth, VanillaBonk, WoW -ErrorAction SilentlyContinue
}

function Read-Builds {
    $all = foreach ($line in Get-Content (Join-Path $PSScriptRoot 'builds.txt')) {
        $fields = @($line.Trim() -split '\s+')
        $idCount = 0
        while ($idCount -lt 4 -and 2 + $idCount -lt $fields.Count -and $fields[2 + $idCount] -match '^\d+$') { $idCount++ }
        if ($idCount -lt 1 -or $fields.Count -lt 3 + $idCount) { continue }
        [pscustomobject]@{ Class = $fields[0]; Key = $fields[1]; Ids = [int[]]$fields[2..(1 + $idCount)]; Label = $fields[(2 + $idCount)..($fields.Count - 1)] -join ' ' }
    }
    if ($Singles) {
        $ids = @($all | Where-Object { $_.Class -eq $Class -and $_.Key -ne $AnchorKey } | ForEach-Object { $_.Ids } | Sort-Object -Unique)
        return @($ids | Where-Object { $Builds.Count -eq 0 -or $Builds -contains "s$_" } | ForEach-Object {
            [pscustomobject]@{ Class = $Class; Key = "s$_"; Ids = [int[]]@($_); Label = "Spell $_ alone" }
        })
    }
    if ($NoAnchor) {
        return @($all | Where-Object { $_.Class -eq $Class -and ($Builds.Count -eq 0 -or $Builds -contains $_.Key) })
    }
    $anchor = $all | Where-Object { $_.Class -eq 'warrior' -and $_.Key -eq $AnchorKey } | Select-Object -First 1
    if (-not $anchor) { throw "builds.txt has no warrior $AnchorKey row." }
    $chosen = @($all | Where-Object { $_.Class -eq $Class -and $_.Key -ne $AnchorKey -and ($Builds.Count -eq 0 -or $Builds -contains $_.Key) })
    @($anchor) + $chosen
}

function Show-Vitals([long]$From) {
    $stream = [System.IO.File]::Open($chatLog, 'Open', 'Read', 'ReadWrite')
    try {
        $stream.Seek($From, 'Begin') | Out-Null
        $text = (New-Object System.IO.StreamReader($stream)).ReadToEnd()
    } finally {
        $stream.Close()
    }
    $build = $null
    $samples = @{}
    foreach ($line in $text -split "`n") {
        if ($line -match 'To \S+: window pack (\S+)') { $build = $Matches[1]; $samples[$build] = @(); continue }
        if ($build -and $line -match 'vitals hp (\d+) shield (\d+) taken (\d+) absorbed (\d+) deaths (\d+)') {
            $samples[$build] += ,[int64[]]@($Matches[1], $Matches[2], $Matches[3], $Matches[4], $Matches[5])
        }
    }
    foreach ($key in $samples.Keys) {
        $rows = @($samples[$key] | Select-Object -Skip 1)
        if ($rows.Count -lt 2) { continue }
        $first = $rows[0]; $last = $rows[-1]
        $hit = ($last[2] - $first[2]) + ($last[3] - $first[3])
        $absorbedPct = if ($hit -gt 0) { [math]::Round(100 * ($last[3] - $first[3]) / $hit) } else { 0 }
        $minHp = ($rows | ForEach-Object { $_[0] } | Measure-Object -Minimum).Minimum
        $avgShield = [math]::Round(($rows | ForEach-Object { $_[1] } | Measure-Object -Average).Average)
        "{0,-8} vitals  min hp {1,3}%  avg shield {2,3}%  hits {3,9}  absorbed {4,3}%  to health {5,8}  deaths {6}" -f $key, $minHp, $avgShield, $hit, $absorbedPct, ($last[2] - $first[2]), ($last[4] - $first[4])
    }
}

function Get-Spells([object[]]$BuildList) {
    $ids = ($BuildList | ForEach-Object { $_.Ids } | Sort-Object -Unique) -join ','
    $spells = @{}
    foreach ($row in Invoke-Sql "SELECT id, evolves_from, name FROM bonk_weapon WHERE id IN ($ids)" 'mangos') {
        $id, $from, $name = $row -split "`t", 3
        $spells[[int]$id] = [pscustomobject]@{ Id = [int]$id; Verb = $(if ([int]$from) { 'evolve' } else { 'spell' }); Name = $name }
    }
    foreach ($id in $ids -split ',') { if (-not $spells.ContainsKey([int]$id)) { throw "Spell $id is not in bonk_weapon." } }
    $spells
}

$DruidForms = @{ balance = 1; feral = 2; bear = 3; resto = 4; ssmoon = 1; sscat = 2; ssbear = 3; sstree = 4;
    balanceA = 1; balanceB = 1; feralA = 2; feralB = 2; bearA = 3; bearB = 3; restoA = 4; restoB = 4; rootsA = 4; rootsB = 4 }
$DruidCycles = @{ ssdance = 3000; ssurge = 3000; sspirit = 3000; hybrid2 = 3000; hybrid3 = 3000 }

function Write-AddonBuilds([object[]]$BuildList, [hashtable]$Spells) {
    $setupSteps = @('bench', "level $Level", 'quiet', "minute $Minute") + @(if ($Tier) { "tier $Tier $Band" }) + @($Passives | ForEach-Object { "passive $($_ -replace ':', ' ')" }) + @($Glyphs | ForEach-Object { "glyph $_" }) + @($Cards | ForEach-Object { "card $($_ -replace ':', ' ')" }) + @($Talents | ForEach-Object { "talent $($_ -replace ':', ' ')" }) + @(if ($Training) { "training $Training" }) + @($Items | ForEach-Object { "item $_" })
    if ($Dummies) { $setupSteps += 'deep' }
    if ($Crowd) { $setupSteps += 'unkillable' }
    $setup = ($setupSteps | ForEach-Object { '"' + $_ + '"' }) -join ', '
    $lines = @("BenchSetup = { $setup }", "BenchBuildSeconds = $BuildSeconds", '')
    if ($Dummies) { $lines += "BenchDummies = `"$DummyCount $DummyRingYards`"" }
    if ($Dummies -and $DummyCrowd) { $lines += 'BenchDummyVerb = "crowddummies"' }
    $packVerb = if ($Pack) { $Pack } elseif ($Melee -or $Crowd) { 'pack 150 1' }
    if ($packVerb) { $lines += "BenchPack = $(ConvertTo-LuaString $packVerb)" }
    if ($Crowd) { $lines += 'BenchCrowdProbeEvery = 2' }
    if ($Waves) { $lines += "BenchWaveEvery = $WaveSeconds" }
    if ($afterPackSteps.Count) {
        $after = ($afterPackSteps | ForEach-Object { "{ $($_.Seconds.ToString([Globalization.CultureInfo]::InvariantCulture)), $(ConvertTo-LuaString $_.Command) }" }) -join ', '
        $lines += "BenchAfterPack = { $after }"
    }
    if ($Mortal) {
        $setup += ', "god"'
        $lines[0] = "BenchSetup = { $setup }"
        $lines += "BenchVitalsEvery = $VitalsSeconds"
    }
    $lines += 'BenchBuilds = {'
    if ($Crowd) {
        $lines += '    { name = "crowd", steps = { } },'
        $BuildList = @()
    }

    foreach ($build in $BuildList) {
        $stepList = @($build.Ids | ForEach-Object { $Spells[$_].Verb + ' ' + $_ })
        if ($Rank -gt 1) { $stepList += @($build.Ids | ForEach-Object { "maxrank $_ $Rank" }) }
        if ($build.PSObject.Properties['Extra']) { $stepList += @($build.Extra) }
        if ($build.Class -eq 'druid' -and $DruidForms.ContainsKey($build.Key)) { $stepList += "form $($DruidForms[$build.Key])" }
        if ($build.Class -eq 'druid' -and $DruidCycles.ContainsKey($build.Key)) { $stepList += "formcycle $($DruidCycles[$build.Key])" }
        $steps = ($stepList | ForEach-Object { '"' + $_ + '"' }) -join ', '
        $lines += "    { name = `"$($build.Key)`", steps = { $steps } },"
    }
    $lines += '}'
    [System.IO.File]::WriteAllLines((Join-Path $addonTarget 'BenchBuilds.lua'), [string[]]$lines)
}

function Write-Manifest([object[]]$BuildList, [hashtable]$Spells, [string]$Hero, [string]$Since) {
    $manifest = [ordered]@{
        since = $Since
        date = (Get-Date).ToString('yyyy-MM-dd')
        class = $Class
        hero = $Hero
        pack = $Pack
        afterPack = @($afterPackSteps | ForEach-Object { [ordered]@{ seconds = $_.Seconds; command = $_.Command } })
        builds = @($BuildList | ForEach-Object {
            [ordered]@{ key = $_.Key; label = $_.Label; spells = @($_.Ids | ForEach-Object { [ordered]@{ id = $_; name = $Spells[$_].Name } }) }
        })
    }
    [System.IO.File]::WriteAllText($manifestFile, ($manifest | ConvertTo-Json -Depth 6))
}

function Find-LastHero([string]$Text) {
    $block = [regex]::Escape("BONK_STATS_ACCOUNTS[""$($Account.ToUpper())""]")
    [regex]::Match($Text, "$block = \{\s*gold = \d+,\s*lastHero = ""([^""]*)""")
}

function Set-LastHero([string]$Name) {
    if (-not (Test-Path $statsFile)) { return $null }
    $text = [System.IO.File]::ReadAllText($statsFile)
    $match = Find-LastHero $text
    if (-not $match.Success) { return $null }
    $group = $match.Groups[1]
    [System.IO.File]::WriteAllText($statsFile, $text.Remove($group.Index, $group.Length).Insert($group.Index, $Name))
    $group.Value
}

function Get-StatsStamp {
    if (Test-Path $statsFile) { (Get-Item $statsFile).LastWriteTimeUtc } else { [datetime]::MinValue }
}

function Wait-LogoutWrite([datetime]$Before) {
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline -and (Get-StatsStamp) -le $Before) { Start-Sleep -Milliseconds 500 }
}


function Send-Enter([System.Diagnostics.Process]$Game) {
    $hwnd = $Game.MainWindowHandle
    for ($try = 0; $try -lt 10 -and [Bench.Window]::GetForegroundWindow() -ne $hwnd; $try++) {
        [Bench.Window]::ShowWindow($hwnd, 9) | Out-Null
        [Bench.Window]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
        [Bench.Window]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
        [Bench.Window]::SetForegroundWindow($hwnd) | Out-Null
        Start-Sleep -Milliseconds 400
    }
    if ([Bench.Window]::GetForegroundWindow() -ne $hwnd) { throw 'The game window did not come to the front (someone is using the PC?). Stopping.' }
    [Bench.Window]::keybd_event(0x0D, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [Bench.Window]::keybd_event(0x0D, 0, 2, [UIntPtr]::Zero)
}

function Test-ChatMarker([string]$Marker, [long]$From) {
    if (-not (Test-Path $chatLog)) { return $false }
    $stream = [System.IO.File]::Open($chatLog, 'Open', 'Read', 'ReadWrite')
    try {
        if ($stream.Length -le $From) { return $false }
        $stream.Seek($From, 'Begin') | Out-Null
        (New-Object System.IO.StreamReader($stream)).ReadToEnd().Contains(": $Marker")
    } finally {
        $stream.Close()
    }
}

function Wait-BenchDone([System.Diagnostics.Process]$Game, [long]$ChatStart, [int]$BuildCount) {
    $scheduleEnd = (Get-Date).AddSeconds($SetupSeconds + $BuildCount * $BuildSeconds + $QuitDelaySeconds + $QuitMarginSeconds)
    while ((Get-Date) -lt $scheduleEnd) {
        if ($Game.HasExited) { return }
        if (Test-ChatMarker 'bench done' $ChatStart) {
            Start-Sleep -Seconds $QuitDelaySeconds
            return
        }
        Start-Sleep -Seconds 1
    }
}

function Enter-BenillaWorld([string]$HeroName) {
    $realmStart = if (Test-Path $realmLog) { (Get-Item $realmLog).Length } else { 0 }
    $env:WOW_USER = $Account.ToUpper()
    $env:WOW_PASS = if ($Password) { $Password } else { $Account.ToUpper() }
    $env:WOW_CHAR = $HeroName
    $env:WOW_UNATTENDED = '1'
    $env:WOW_ALLOW_ACCOUNT = '1'
    $env:WOW_NOSOUND = '1'
    $env:BENILLA_HOME = Join-Path $benillaClient 'benilla-config'
    $exe = Join-Path $benillaClient 'target\release\HordesOfAzeroth.exe'
    $log = Join-Path $benillaClient 'benilla-config\bench.log'
    Start-Process $exe -WorkingDirectory $benillaClient -RedirectStandardOutput $log -RedirectStandardError "$log.err" | Out-Null
    Wait-Until {
        (Test-Path $realmLog) -and (Get-Item $realmLog).Length -gt $realmStart -and
            ((Get-Content $realmLog -Tail 30 | Out-String) -match 'successfully authenticated')
    } 90 'the client to log in'
    Start-Sleep -Seconds ($EnterWaitSeconds + 8)
    $client = Get-GameProcess | Select-Object -First 1
    if (-not $client) { throw 'The benilla client closed before entering the world.' }
    $client
}

function Enter-World([long]$ChatStart) {
    $realmStart = if (Test-Path $realmLog) { (Get-Item $realmLog).Length } else { 0 }
    & (Join-Path $RepoRoot 'tools\launch-client.ps1') -Account $Account -Password $Account | Out-Null
    Wait-Until {
        (Test-Path $realmLog) -and (Get-Item $realmLog).Length -gt $realmStart -and
            ((Get-Content $realmLog -Tail 30 | Out-String) -match 'successfully authenticated')
    } 90 'the client to log in'
    $game = Get-GameProcess | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if (-not $game) { throw 'The game window did not open.' }
    Start-Sleep -Seconds 8
    Send-Enter $game
    Start-Sleep -Seconds $EnterWaitSeconds
    if ($game.HasExited) { throw 'The client closed before entering the world.' }
    $game
}

function ConvertTo-LuaString([string]$Text) {
    '"' + ($Text -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Read-AfterPack([string[]]$Entries) {
    @($Entries | ForEach-Object {
        $seconds, $command = $_ -split '=', 2
        $offset = 0.0
        if (-not $command -or -not [double]::TryParse($seconds, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$offset)) {
            throw "-AfterPack '$_' must be seconds=command, for example 5=.bonk crowd."
        }
        if ($offset -lt 0 -or $offset -ge $BuildSeconds - 1) { throw "-AfterPack '$_' must fire between 0 and $($BuildSeconds - 1) seconds." }
        [pscustomobject]@{ Seconds = $offset; Command = $command }
    })
}

if ($Pack -and $Dummies) { throw '-Pack has no effect with -Dummies.' }
$afterPackSteps = @(Read-AfterPack $AfterPack)

for ($wait = 0; $wait -lt 20 -and (Get-GameProcess); $wait++) { Start-Sleep -Seconds 1 }
if (Get-GameProcess) { throw 'The game client is running. Close it (or wait for the session using it) first.' }
if (-not (Get-Process mangosd -ErrorAction SilentlyContinue)) { throw 'mangosd is not running (tools\start-server.ps1).' }

$buildList = Read-Builds
if ($ProbeTalent) {
    $buildList = @($buildList | ForEach-Object {
        $_
        [pscustomobject]@{ Class = $_.Class; Key = "$($_.Key)+$ProbeTalent"; Ids = $_.Ids; Label = "$($_.Label) + talent $ProbeTalent"; Extra = @("talent $ProbeTalent 1") }
    })
}
$spells = Get-Spells $buildList
$accountId = @(Invoke-Sql "SELECT id FROM account WHERE username = '$($Account.ToUpper())'" 'realmd')[0]
$heroFilter = if ($Hero) { "name = '$Hero'" } else { "class = $($ClassIds[$Class])" }
$hero = @(Invoke-Sql "SELECT name FROM characters WHERE account = $accountId AND $heroFilter" 'characters')[0]
if (-not $hero) { throw "Account $Account has no $(if ($Hero) { "hero named $Hero" } else { "$Class hero" })." }

Write-Host "Bench: $Class on $hero, builds $(($buildList | ForEach-Object { $_.Key }) -join ', ')"
$since = (Get-Date).ToString('MM/dd HH:mm:ss')
$lastHero = $null
$statsBefore = [datetime]::MinValue
$game = $null
try {
    if (Test-Path $addonTarget) { Remove-Item $addonTarget -Recurse -Force }
    Copy-Item $addonSource $addonTarget -Recurse
    Write-AddonBuilds $buildList $spells
    $lastHero = Set-LastHero $hero
    $statsBefore = Get-StatsStamp
    $chatStart = if (Test-Path $chatLog) { (Get-Item $chatLog).Length } else { 0 }
    $game = if ($Benilla) { Enter-BenillaWorld $hero } else { Enter-World $chatStart }
    Wait-BenchDone $game $chatStart $(if ($Crowd) { 1 } else { $buildList.Count })
} finally {
    $wasInWorld = $null -ne $game
    Get-GameProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    if ($null -ne $lastHero) {
        if ($wasInWorld) { Wait-LogoutWrite $statsBefore }
        Set-LastHero $lastHero | Out-Null
    }
    if (Test-Path $addonTarget) { Remove-Item $addonTarget -Recurse -Force }
}

if ($Crowd) {
    $stream = [System.IO.File]::Open($chatLog, 'Open', 'Read', 'ReadWrite')
    try {
        $stream.Seek($chatStart, 'Begin') | Out-Null
        (New-Object System.IO.StreamReader($stream)).ReadToEnd() -split "`n" |
            Where-Object { $_ -match 'whispers: .*enemies walk in the crowd' } | ForEach-Object { $_.Substring(6, 8) + ' ' + $_.Substring($_.IndexOf('whispers: ') + 10).Trim() }
    } finally {
        $stream.Close()
    }
    return
}

Write-Manifest $buildList $spells $hero $since
$parseArgs = @((Join-Path $PSScriptRoot 'parse_bench.py'), $manifestFile)
if ($Markdown) { $parseArgs += '--markdown' }
$mode = if ($Dummies) { 'dummies' } elseif ($Melee) { 'melee' } elseif ($Waves) { 'waves' } else { 'pack' }
if ($Tag) { $mode = "$mode-$Tag" }
$parseArgs += @('--log', $chatLog)
$parseArgs += @('--save', (Join-Path $PSScriptRoot 'results.json'), '--mode', $mode)
$ErrorActionPreference = 'Continue'
& python @parseArgs 2>&1 | ForEach-Object { "$_" }
if ($Mortal) { Show-Vitals $chatStart }

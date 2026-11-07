param(
    [string]$WowPath = "C:\World of Warcraft",
    [string]$Char = "",
    [string]$ClassName = "",
    [int]$Duration = 80
)
$ErrorActionPreference = 'Stop'
$root = "C:\Users\hunau\Desktop\hoa-core\.claude\worktrees\runmaster-coop-fix"
$client = "$root\client"
$exe = "$client\target\debug\HordesOfAzeroth.exe"
if (-not (Test-Path $exe)) { throw "no client build" }

$identity = "$client\.probe-identity"
foreach ($line in Get-Content $identity) {
    if ($line -match '^(WOW_USER|WOW_PASS|WOW_CHAR)=(.*)$') { Set-Item "env:$($Matches[1])" $Matches[2] }
}
if ($Char) { $env:WOW_CHAR = $Char }

$env:BENILLA_HOME = "$client\benilla-config"
$env:WOW_HOST = "127.0.0.1:3724"
$env:WOW_UNATTENDED = "1"
$env:WOW_NOSOUND = "1"
$env:WOW_PROBE_EXIT_AT = "$Duration"
$env:WOW_PROBE_LUA_AT = "10"
$env:WOW_PROBE_CHAT_AT = "25"
$env:WOW_PROBE_CHAT_EVERY = "8"
$env:WOW_PROBE_CHAT = ".bonk hello enUS;.bonk start 1;.bonk god"
$env:WOW_PROBE_LUA = Get-Content "$root\tools\e2e\class-verify.lua" -Raw

Push-Location $client
try {
        $env:WOW_DATA = "$WowPath\Data"
        cmd /c "`"$exe`" > `"$env:BENILLA_HOME\probe.log`" 2>&1"
    } finally { Pop-Location }

Write-Host ""
Write-Host "===== $ClassName ($Char) ====="
Get-Content "$env:BENILLA_HOME\probe.log" | ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' } |
    Where-Object { $_ -match 'probe-log:|error|lua error|script error' } |
    ForEach-Object { Write-Host "  $($_.Substring([Math]::Min(28, $_.Length)))" }
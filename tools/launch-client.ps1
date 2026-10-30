param(
    [string]$Account = 'player',
    [string]$Password = 'player',
    [string[]]$ClientArgs = @()
)
. "$PSScriptRoot\common.ps1"

$client = Join-Path $RepoRoot 'client'
$exe = Join-Path $client 'target\release\HordesOfAzeroth.exe'
if (-not (Test-Path $exe)) { throw 'Build the client first: cargo build --release -p hoa (in client\).' }

$env:BENILLA_HOME = Join-Path $client 'benilla-config'
Get-ChildItem (Join-Path $env:BENILLA_HOME 'cache') -Filter *.bin -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
if (-not (Test-Path (Join-Path $client 'WoW'))) { $env:WOW_DATA = Join-Path $RepoRoot 'Data' }
$env:WOW_USER = $Account
$env:WOW_PASS = $Password
Start-Quoted $exe $ClientArgs $client | Out-Null
Write-Host "Started HordesOfAzeroth.exe; it logs in as $Account"

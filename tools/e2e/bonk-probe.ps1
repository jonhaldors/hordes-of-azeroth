# SPDX-License-Identifier: GPL-3.0-only
<#
.SYNOPSIS
    Drive a live client against the local test server with .bonk chat commands, then read what
    both sides logged.

.DESCRIPTION
    One run is: log the account in client\.probe-identity into the world server, type each line
    of -Commands into the chat box in world, run a probe Lua chunk in the live UI VM, exit, then
    print (a) the client's probe-log and error lines, (b) every line the server logged during the
    run — Chat.log for the chat itself, Server.log and DBErrors.log for what the commands did.

    The chat file is the transcript: World::LogChat writes every message there, so each .bonk
    command and each addon reply the server prints back is in order.

.PARAMETER Commands
    The chat lines to type, in order, one every -ChatEvery seconds.

.PARAMETER LuaFile
    A file whose Lua runs in the live UI VM once in world (WOW_PROBE_LUA): install listeners,
    watch the addon's frames, ProbeLog what happened.

.PARAMETER Server
    The world server's realmlist address, default 127.0.0.1:3724.

.PARAMETER WowPath
    The 1.12 install, default C:\World of Warcraft (its Data folder is what the client reads).

.PARAMETER ServerLogs
    The server's logs folder, default <WowPath>\server\logs.

.PARAMETER ExitAfter, LuaAt, ChatAt, ChatEvery
    Timings in seconds: when to run the Lua, when to start typing, the gap between lines, when
    to quit the client.

.EXAMPLE
    tools\e2e\bonk-probe.ps1 -Commands '.bonk mog open' -LuaFile tools\e2e\mog-listen.lua
#>
param(
    [string[]]$Commands = @(),
    [string]$CommandsFile = '',
    [string]$LuaFile = '',
    [string]$Server = '127.0.0.1:3724',
    [string]$WowPath = 'C:\World of Warcraft',
    [string]$ServerLogs = '',
    [int]$ExitAfter = 90,
    [int]$LuaAt = 15,
    [int]$ChatAt = 30,
    [int]$ChatEvery = 3,
    [string]$Client = ''
)

$ErrorActionPreference = 'Stop'
if ($CommandsFile) {
    if (-not (Test-Path -LiteralPath $CommandsFile)) { throw "no commands file: $CommandsFile" }
    $Commands = @(Get-Content -LiteralPath $CommandsFile |
        Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { $_.Trim() })
}
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$clientDir = Join-Path $root 'client'
if (-not $ServerLogs) { $ServerLogs = Join-Path $WowPath 'server/logs' }
if (-not $Client) {
    $Client = Join-Path $clientDir 'target/debug/HordesOfAzeroth.exe'
    if (-not (Test-Path -LiteralPath $Client)) {
        # The main checkout's build will do: the addon comes from BENILLA_HOME, not the binary.
        $Client = 'C:/Users/hunau/Desktop/hoa-core/client/target/debug/HordesOfAzeroth.exe'
    }
}
if (-not (Test-Path -LiteralPath $Client)) {
    throw 'no client build: cargo build -p hoa (in client/), or pass -Client <HordesOfAzeroth.exe>.'
}

$identity = Join-Path $clientDir '.probe-identity'
if (-not (Test-Path -LiteralPath $identity)) {
    throw "no account: $identity must hold WOW_USER=, WOW_PASS=, WOW_CHAR=."
}
foreach ($line in Get-Content -LiteralPath $identity) {
    if ($line -match '^(WOW_USER|WOW_PASS|WOW_CHAR)=(.*)$') { Set-Item "env:$($Matches[1])" $Matches[2] }
}
if (-not $env:WOW_USER -or -not $env:WOW_PASS) { throw "$identity names no account." }

$env:WOW_DATA = if (Test-Path (Join-Path $WowPath 'Data')) { Join-Path $WowPath 'Data' } else { $WowPath }
$env:BENILLA_HOME = Join-Path $clientDir 'benilla-config'
$env:WOW_HOST = $Server
$env:WOW_UNATTENDED = '1'
$env:WOW_NOSOUND = '1'
if ($Commands.Count) {
    # The client has to live long enough to type them all and let the answers land.
    $needed = $ChatAt + $Commands.Count * [Math]::Max($ChatEvery, 1) + 25
    if ($ExitAfter -lt $needed) { $ExitAfter = $needed }
    $env:WOW_PROBE_CHAT = $Commands -join ';'
}
$env:WOW_PROBE_EXIT_AT = "$ExitAfter"
$env:WOW_PROBE_LUA_AT = "$LuaAt"
$env:WOW_PROBE_CHAT_AT = "$ChatAt"
$env:WOW_PROBE_CHAT_EVERY = "$ChatEvery"
if ($LuaFile) {
    if (-not (Test-Path -LiteralPath $LuaFile)) { throw "no Lua file: $LuaFile" }
    $env:WOW_PROBE_LUA = Get-Content -LiteralPath $LuaFile -Raw
} else {
    Remove-Item Env:WOW_PROBE_LUA -ErrorAction SilentlyContinue
}

# The server logs' sizes before the run, so only what this run adds is printed.
$logFiles = @('Chat.log', 'Server.log', 'DBErrors.log', 'Char.log', 'Loot.log')
$before = @{}
foreach ($name in $logFiles) {
    $path = Join-Path $ServerLogs $name
    $before[$name] = if (Test-Path -LiteralPath $path) { (Get-Item -LiteralPath $path).Length } else { 0 }
}

$log = Join-Path $env:BENILLA_HOME 'probe.log'
Write-Host "client  : $Client"
Write-Host "chat    : $($Commands -join ' | ')"
Push-Location $clientDir
try { & $Client *> $log } finally { Pop-Location }

function Show-New([string]$name) {
    $path = Join-Path $ServerLogs $name
    if (-not (Test-Path -LiteralPath $path)) { return }
    $start = $before[$name]
    $added = (Get-Item -LiteralPath $path).Length - $start
    if ($added -le 0) { return }
    # ReadWrite share: the server holds the log open while it writes.
    $stream = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        [void]$stream.Seek($start, 'Begin')
        $reader = [System.IO.StreamReader]::new($stream)
        $text = $reader.ReadToEnd()
    } finally { $stream.Dispose() }
    Write-Host ""
    Write-Host "===== $name (+$added bytes) ====="
    $lines = $text -split "`r?`n" | Where-Object { $_ -ne '' }
    foreach ($line in ($lines | Select-Object -First 400)) {
        Write-Host "  $line"
    }
    if ($lines.Count -gt 400) { Write-Host "  …$($lines.Count - 400) more lines" }
}

Write-Host ""
Write-Host '===== client (probe-log and errors) ====='
Get-Content -LiteralPath $log | ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' } |
    Where-Object { $_ -match 'probe-log:|error|warning: lua|Script ran too long' } |
    ForEach-Object { Write-Host "  $($_.Substring([Math]::Min(28, $_.Length)))" }

foreach ($name in $logFiles) { Show-New $name }
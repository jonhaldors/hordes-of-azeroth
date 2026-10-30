$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$ConfigDir = Join-Path $RepoRoot 'config'
$ServerDir = Join-Path $RepoRoot 'server'
$RunDir    = Join-Path $ServerDir 'run'
$DataDir   = Join-Path $ServerDir 'data'
$LogDir    = Join-Path $ServerDir 'logs'
$MariaDir  = Join-Path $ServerDir 'mariadb'
$MariaData = Join-Path $ServerDir 'mariadb-data'

$DbHost = '127.0.0.1'
$DbPort = 3306
$DbRootArgs = @('--skip-ssl', '-h', $DbHost, '-P', $DbPort, '-u', 'root', '-proot')

function Test-PortOpen([int]$Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect($DbHost, $Port)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Test-DbUp { Test-PortOpen $DbPort }

function Start-Quoted([string]$Exe, [string[]]$Arguments, [string]$WorkDir, [string]$WindowStyle = 'Normal') {
    $quoted = $Arguments | ForEach-Object { '"' + $_ + '"' }
    $params = @{ FilePath = $Exe; WorkingDirectory = $WorkDir; WindowStyle = $WindowStyle; PassThru = $true }
    if ($quoted) { $params.ArgumentList = $quoted }
    Start-Process @params
}

function Wait-Until([scriptblock]$Condition, [int]$TimeoutSeconds, [string]$What) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while (-not (& $Condition)) {
        if ((Get-Date) -gt $deadline) { throw "Timed out after ${TimeoutSeconds}s waiting for $What." }
        Start-Sleep -Milliseconds 500
    }
}

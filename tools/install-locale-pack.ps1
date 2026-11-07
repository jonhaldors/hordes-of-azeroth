# SPDX-License-Identifier: GPL-3.0-only
param(
    [Parameter(Mandatory = $true)]
    [string]$Client,
    [Parameter(Mandatory = $true)]
    [ValidateSet('enUS', 'zhCN', 'zhTW')]
    [string]$Language,
    [string]$Config,
    [string]$Extractor
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot

$data = if (Test-Path (Join-Path $Client 'Data\dbc.MPQ')) {
    Join-Path $Client 'Data'
} elseif (Test-Path (Join-Path $Client 'dbc.MPQ')) {
    $Client
} else {
    throw "No vanilla Data folder under '$Client': pass the install root or its Data folder."
}

if (-not $Config) {
    $Config = if ($env:BENILLA_HOME) { $env:BENILLA_HOME } else { Join-Path $RepoRoot 'client\benilla-config' }
}
$out = Join-Path $Config "locale\$Language"

if ($Extractor) {
    & $Extractor $data locale-pack $Language $out
} else {
    & cargo run --quiet --manifest-path (Join-Path $RepoRoot 'client\Cargo.toml') `
        -p benilla-formats --bin benilla-extract -- $data locale-pack $Language $out
}
if ($LASTEXITCODE -ne 0) { throw "benilla-extract locale-pack failed with exit code $LASTEXITCODE." }

Write-Host "Installed the $Language stock language pack at $out"
Write-Host "Set the account language to $Language and restart the client to load it."

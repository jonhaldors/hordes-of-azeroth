param(
    [string]$StatsHost = $env:HOA_STATS_HOST,
    [switch]$Reports
)

if (-not $StatsHost) { throw 'Set HOA_STATS_HOST (for example user@host) or pass -StatsHost.' }

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$inbox = Join-Path $root 'data\runs\inbox'
New-Item -ItemType Directory -Force $inbox | Out-Null

& scp -q -r "${StatsHost}:/var/lib/hoa-stats/runs/*" $inbox
if ($LASTEXITCODE -ne 0) { throw "Copying runs from $StatsHost failed with exit code $LASTEXITCODE." }

if ($Reports) {
    $reportDir = Join-Path $root 'data\reports'
    New-Item -ItemType Directory -Force $reportDir | Out-Null
    & scp -q -r "${StatsHost}:/var/lib/hoa-stats/reports/*" $reportDir
    if ($LASTEXITCODE -ne 0) { throw "Copying reports from $StatsHost failed with exit code $LASTEXITCODE." }
}

& python (Join-Path $root 'tools\run-archive.py') ingest
& python (Join-Path $root 'tools\run-archive.py') csv --archive (Join-Path $root 'data\runs\players.jsonl')

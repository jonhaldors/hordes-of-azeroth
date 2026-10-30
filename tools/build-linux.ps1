param(
    [ValidateSet('all', 'server', 'client')][string]$Part = 'all',
    [string]$ClientSource,
    [string]$ServerSource,
    [string]$Out
)

. "$PSScriptRoot\common.ps1"

$distro = 'Ubuntu-22.04'

if (-not $ClientSource) { $ClientSource = Join-Path $RepoRoot 'client' }
if (-not $ServerSource) { $ServerSource = Join-Path $RepoRoot 'server\core' }
if (-not $Out) { $Out = Join-Path $RepoRoot 'release\build\linux' }

function ConvertTo-WslPath([string]$Path) {
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    '/mnt/' + $full.Substring(0, 1).ToLowerInvariant() + ($full.Substring(2) -replace '\\', '/')
}

$installed = (wsl --list --quiet) -replace "`0", '' | ForEach-Object { $_.Trim() }
if ($installed -notcontains $distro) { throw "The Linux build needs WSL ${distro}: wsl --install -d $distro --no-launch" }

New-Item -ItemType Directory -Force $Out | Out-Null

$ErrorActionPreference = 'Continue'
wsl -d $distro -u root -- bash (ConvertTo-WslPath (Join-Path $PSScriptRoot 'linux\build.sh')) $Part `
    (ConvertTo-WslPath $ClientSource) (ConvertTo-WslPath $ServerSource) (ConvertTo-WslPath $Out)
if ($LASTEXITCODE -ne 0) { throw "Linux build failed with exit code $LASTEXITCODE." }

param(
    [string]$Repository,
    [string[]]$LocalDir = @(),
    [int]$KeepReleases = 3,
    [switch]$PruneOnly,
    [switch]$DryRun
)
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Setting([string]$Name) {
    $value = [Environment]::GetEnvironmentVariable($Name)
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($Name, 'User') }
    "$value".Trim()
}

$mirrorUrl = (Get-Setting 'HOA_MIRROR_URL').TrimEnd('/')
$accountId = Get-Setting 'HOA_R2_ACCOUNT_ID'
$accessKey = Get-Setting 'HOA_R2_ACCESS_KEY_ID'
$secretKey = Get-Setting 'HOA_R2_SECRET_ACCESS_KEY'
$bucket = Get-Setting 'HOA_R2_BUCKET'
$missing = @('HOA_MIRROR_URL', 'HOA_R2_ACCOUNT_ID', 'HOA_R2_ACCESS_KEY_ID', 'HOA_R2_SECRET_ACCESS_KEY', 'HOA_R2_BUCKET') | Where-Object { -not (Get-Setting $_) }
if ($missing) {
    Write-Warning "The download mirror is not set up ($($missing -join ', ') missing): players who can't reach GitHub get no mirror for this release."
    return
}

$releaseConfig = Get-Content (Join-Path $ConfigDir 'release.json') -Raw | ConvertFrom-Json
$repository = if ($Repository) { $Repository } else { $releaseConfig.repository }
$releasesUrl = "https://github.com/$repository/releases/"
$cacheDir = Join-Path $RepoRoot 'release\cache\mirror'
$searchDirs = @($LocalDir) + @((Join-Path $RepoRoot 'release\cache'), (Join-Path $RepoRoot 'server\downloads'), $cacheDir) | Where-Object { $_ -and (Test-Path $_) }
$r2Host = "$accountId.r2.cloudflarestorage.com"
$http = New-Object System.Net.Http.HttpClient
$http.Timeout = [TimeSpan]::FromHours(2)
$http.DefaultRequestHeaders.UserAgent.ParseAdd('HordesOfAzerothRelease')

function Get-Sha256([string]$Path) { (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

function Get-Hmac([byte[]]$Key, [string]$Text) {
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 (, $Key)
    $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-TextHash([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)) | ForEach-Object { $_.ToString('x2') })
}

function Get-MirrorKey([string]$Url) {
    if ($Url.StartsWith($releasesUrl + 'latest/download/')) { return 'latest/' + $Url.Substring(($releasesUrl + 'latest/download/').Length) }
    if ($Url.StartsWith($releasesUrl + 'download/')) { return $Url.Substring(($releasesUrl + 'download/').Length) }
    'third-party/' + [System.IO.Path]::GetFileName(([Uri]$Url).AbsolutePath)
}

function Get-ContentType([string]$Name) {
    switch -Regex ($Name) {
        '\.json$' { 'application/json'; break }
        '\.zip$' { 'application/zip'; break }
        '\.(tar\.)?gz$' { 'application/gzip'; break }
        default { 'application/octet-stream' }
    }
}

function New-BucketRequest([string]$Method, [string]$Key, [string]$Query = '') {
    $now = [DateTime]::UtcNow
    $amzDate = $now.ToString('yyyyMMddTHHmmssZ')
    $day = $now.ToString('yyyyMMdd')
    $path = if ($Key) { "/$bucket/" + (($Key -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/') } else { "/$bucket" }
    $canonical = "$Method`n$path`n$Query`nhost:$r2Host`nx-amz-content-sha256:UNSIGNED-PAYLOAD`nx-amz-date:$amzDate`n`nhost;x-amz-content-sha256;x-amz-date`nUNSIGNED-PAYLOAD"
    $scope = "$day/auto/s3/aws4_request"
    $toSign = "AWS4-HMAC-SHA256`n$amzDate`n$scope`n$(Get-TextHash $canonical)"
    $signingKey = Get-Hmac (Get-Hmac (Get-Hmac (Get-Hmac ([Text.Encoding]::UTF8.GetBytes("AWS4$secretKey")) $day) 'auto') 's3') 'aws4_request'
    $signature = -join ((Get-Hmac $signingKey $toSign) | ForEach-Object { $_.ToString('x2') })
    $request = New-Object System.Net.Http.HttpRequestMessage (New-Object System.Net.Http.HttpMethod $Method), ("https://$r2Host$path" + $(if ($Query) { "?$Query" } else { '' }))
    $request.Headers.TryAddWithoutValidation('x-amz-date', $amzDate) | Out-Null
    $request.Headers.TryAddWithoutValidation('x-amz-content-sha256', 'UNSIGNED-PAYLOAD') | Out-Null
    $request.Headers.TryAddWithoutValidation('Authorization', "AWS4-HMAC-SHA256 Credential=$accessKey/$scope, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=$signature") | Out-Null
    $request
}

function Test-Mirrored([string]$Key, [long]$Size) {
    $response = $http.SendAsync((New-BucketRequest 'HEAD' $Key)).GetAwaiter().GetResult()
    try { $response.IsSuccessStatusCode -and $response.Content.Headers.ContentLength -eq $Size } finally { $response.Dispose() }
}

function Send-ToMirror([string]$Path, [string]$Key, [bool]$AlwaysFresh) {
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $request = New-BucketRequest 'PUT' $Key
        $request.Content = New-Object System.Net.Http.StreamContent $stream
        $request.Content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse((Get-ContentType $Key))
        if ($AlwaysFresh) { $request.Content.Headers.TryAddWithoutValidation('Cache-Control', 'no-cache') | Out-Null }
        $response = $http.SendAsync($request).GetAwaiter().GetResult()
        try {
            if (-not $response.IsSuccessStatusCode) {
                $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                throw "Mirror upload of $Key failed with $([int]$response.StatusCode): $body"
            }
        } finally { $response.Dispose() }
    } finally { $stream.Dispose() }
    Write-Host ('mirror: {0} ({1:N1} MB)' -f $Key, ((Get-Item $Path).Length / 1MB))
}

function Get-BucketObjects {
    $token = $null
    do {
        $query = if ($token) { "continuation-token=$([Uri]::EscapeDataString($token))&list-type=2" } else { 'list-type=2' }
        $response = $http.SendAsync((New-BucketRequest 'GET' '' $query)).GetAwaiter().GetResult()
        try {
            $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            if (-not $response.IsSuccessStatusCode) { throw "Listing the mirror failed with $([int]$response.StatusCode): $body" }
        } finally { $response.Dispose() }
        $listing = ([xml]$body).ListBucketResult
        foreach ($item in @($listing.Contents)) { if ($item) { [pscustomobject]@{ Key = $item.Key; Size = [long]$item.Size } } }
        $token = if ($listing.IsTruncated -eq 'true') { $listing.NextContinuationToken } else { $null }
    } while ($token)
}

function Remove-FromMirror([string]$Key) {
    $response = $http.SendAsync((New-BucketRequest 'DELETE' $Key)).GetAwaiter().GetResult()
    try { if (-not $response.IsSuccessStatusCode) { throw "Removing $Key from the mirror failed with $([int]$response.StatusCode)." } } finally { $response.Dispose() }
}

function Get-ManifestDownloads([string]$Path) {
    $manifest = Get-Content $Path -Raw | ConvertFrom-Json
    $downloads = @($manifest.packages) + @($manifest.navTiles | Where-Object { $_.download } | ForEach-Object { $_.download }) + @($manifest.thirdParty)
    $downloads | Where-Object { $_.url }
}

function Get-KeptKeys {
    $releases = gh release list --repo $repository --exclude-pre-releases --limit $KeepReleases --json tagName | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw "gh release list failed with exit code $LASTEXITCODE." }
    $manifestDir = Join-Path $cacheDir 'kept-manifests'
    $kept = @{}
    $prefixes = @('latest/')
    foreach ($keptRelease in $releases) {
        $prefixes += "$($keptRelease.tagName)/"
        $dir = Join-Path $manifestDir $keptRelease.tagName
        New-Item -ItemType Directory -Force $dir | Out-Null
        gh release download $keptRelease.tagName --repo $repository --pattern 'manifest*.json' --dir $dir --clobber 2>$null | Out-Null
        foreach ($file in Get-ChildItem $dir -Filter 'manifest*.json') {
            foreach ($download in Get-ManifestDownloads $file.FullName) { $kept[(Get-MirrorKey $download.url)] = $true }
        }
    }
    [pscustomobject]@{ Keys = $kept; Prefixes = $prefixes; Releases = @($releases.tagName) }
}

function Invoke-MirrorPrune {
    $keep = Get-KeptKeys
    if ($keep.Keys.Count -eq 0) { throw 'No manifest of the kept releases could be read, so nothing is removed from the mirror.' }
    $stale = @(Get-BucketObjects | Where-Object {
        $key = $_.Key
        -not $keep.Keys.ContainsKey($key) -and -not ($keep.Prefixes | Where-Object { $key.StartsWith($_) })
    })
    foreach ($object in $stale) {
        if ($DryRun) { Write-Host "mirror: would remove $($object.Key)" } else { Remove-FromMirror $object.Key; Write-Host "mirror: removed $($object.Key)" }
    }
    $verb = if ($DryRun) { 'would free' } else { 'freed' }
    Write-Host ('Mirror keeps {0}: {1} stale files, {2} {3:N1} MB' -f ($keep.Releases -join ', '), $stale.Count, $verb, (($stale | Measure-Object Size -Sum).Sum / 1MB))
}

function Find-LocalCopy([string]$Name, [long]$Size, [string]$Sha256) {
    foreach ($dir in $searchDirs) {
        foreach ($file in Get-ChildItem $dir -Recurse -File -Filter $Name -ErrorAction SilentlyContinue) {
            if ($file.Length -eq $Size -and (-not $Sha256 -or (Get-Sha256 $file.FullName) -eq $Sha256)) { return $file.FullName }
        }
    }
    $null
}

function Get-Download([string]$Url, [string]$Name, [long]$Size, [string]$Sha256) {
    $local = Find-LocalCopy $Name $Size $Sha256
    if ($local) { return $local }
    New-Item -ItemType Directory -Force $cacheDir | Out-Null
    $target = Join-Path $cacheDir $Name
    Invoke-WebRequest $Url -OutFile $target -UseBasicParsing
    if ($Sha256 -and (Get-Sha256 $target) -ne $Sha256) { Remove-Item $target; throw "$Name from $Url doesn't match its manifest hash." }
    $target
}

if ($PruneOnly) {
    Invoke-MirrorPrune
    return
}

$release = gh release view --repo $repository --json tagName,assets | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw "gh release view failed with exit code $LASTEXITCODE." }
$tag = $release.tagName

$releaseFiles = foreach ($asset in $release.assets) {
    [pscustomobject]@{ Name = $asset.name; Path = (Get-Download $asset.url $asset.name $asset.size $null) }
}

$entries = @{}
foreach ($file in $releaseFiles | Where-Object { $_.Name -like 'manifest*.json' }) {
    foreach ($download in Get-ManifestDownloads $file.Path) { $entries[$download.url] = $download }
}

$uploaded = 0
foreach ($download in $entries.Values) {
    $key = Get-MirrorKey $download.url
    if (Test-Mirrored $key $download.size) { continue }
    $name = [System.IO.Path]::GetFileName(([Uri]$download.url).AbsolutePath)
    Send-ToMirror (Get-Download $download.url $name $download.size $download.sha256) $key $false
    $uploaded++
}

foreach ($file in $releaseFiles | Sort-Object { $_.Name -like 'manifest*.json' }) {
    Send-ToMirror $file.Path "$tag/$($file.Name)" $true
    Send-ToMirror $file.Path "latest/$($file.Name)" $true
}
Write-Host "Mirror holds ${tag}: $uploaded new package files, $($entries.Count) referenced, $($releaseFiles.Count) release files under latest/"
Invoke-MirrorPrune

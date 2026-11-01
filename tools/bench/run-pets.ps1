param(
    [string[]]$Groups = @(),
    [switch]$Waves,
    [int]$Tier = 2,
    [int]$Band = 1,
    [int]$Rank = 3,
    [int]$Training = 3,
    [int[]]$Items = @(902241, 902028, 902031),
    [string]$Tag = 'pets',
    [switch]$Benilla
)
$Groups = @($Groups | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$PetGroups = [ordered]@{
    'hunter-301'  = @(201, 211, 228, 229, 230, 231)
    'priest-503'  = @(511, 534, 535)
    'shaman-702'  = @(707, 726, 727)
    'shaman-703'  = @(708, 709, 728, 729, 730, 731, 733)
    'mage-803'    = @(410, 431, 432)
    'warlock-902' = @(900, 901, 902, 903, 911, 912, 913, 914, 915, 916, 917, 918)
    'druid-1103'  = @(1009, 1030, 1031)
}
$talentsByTree = @{}
foreach ($line in Get-Content (Join-Path $PSScriptRoot 'reference.txt')) {
    $parts = $line -split ' '
    $talentsByTree[$parts[1]] = @($parts[4] -split ',')
}

foreach ($group in $PetGroups.Keys) {
    if ($Groups.Count -and $group -notin $Groups) { continue }
    $class, $tree = $group -split '-'
    $builds = @($PetGroups[$group] | ForEach-Object { "pet$_" })
    $mode = if ($Waves) { 'waves' } else { 'dummies' }
    Write-Host "== $group ($mode)"
    & (Join-Path $PSScriptRoot 'run-bench.ps1') -Class $class -Builds $builds -NoAnchor -Waves:$Waves -Dummies:(-not $Waves) -DummyCrowd:(-not $Waves) -DummyCount 20 `
        -Tier $Tier -Band $Band -Rank $Rank -Talents $talentsByTree[$tree] -Training $Training -Items $Items -Benilla:$Benilla -Tag "$Tag-$tree" 2>&1 |
        Select-String 'k/s|error|Exception|throw'
}

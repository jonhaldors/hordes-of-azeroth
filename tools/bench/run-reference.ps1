param(
    [string[]]$Classes = @(),
    [string[]]$Specs = @(),
    [switch]$NoCapstone,
    [switch]$BaseOnly,
    [switch]$EvolvedOnly,
    [int]$Tier = 2,
    [int]$Band = 1,
    [int]$Rank = 3,
    [int]$Minute = 5,
    [int]$Training = 3,
    [ValidateSet('blue', 'mixed', 'epic')][string]$Gear = 'blue',
    [int]$GearTier = 10,
    [string[]]$Cards = @(),
    [int[]]$Glyphs = @(),
    [string]$Tag = '',
    [switch]$Benilla,
    [switch]$Dummies
)
$Classes = @($Classes | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Specs = @($Specs | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$runTag = if ($Tag) { $Tag } else { "ref-t$Tier-b$Band-$Gear$GearTier" + $(if ($NoCapstone) { '-nocap' } else { '' }) }

$GearFirst = 930000
$GearTiers = 10
$ArmorFirstKind = @{ cloth = 0; leather = 8; mail = 16 }
$ClassArmor = @{ warrior = 'mail'; paladin = 'mail'; hunter = 'leather'; rogue = 'leather'; shaman = 'leather'; druid = 'leather'; priest = 'cloth'; mage = 'cloth'; warlock = 'cloth' }
$ClassWeapons = @{ warrior = @(27); paladin = @(28); hunter = @(30); rogue = @(26); shaman = @(25, 31); priest = @(29); mage = @(29); warlock = @(29); druid = @(29) }
$CloakKind, $NeckKind, $RingKind = 33, 34, 35

function Get-GearSet([string]$Class) {
    $armorFirst = $ArmorFirstKind[$ClassArmor[$Class]]
    $kinds = @($armorFirst..($armorFirst + 7)) + $ClassWeapons[$Class] + @($CloakKind, $NeckKind, $RingKind, $RingKind)
    $index = 0
    foreach ($kind in $kinds) {
        $quality = switch ($Gear) { 'blue' { 3 } 'epic' { 4 } 'mixed' { if ($index % 2) { 4 } else { 3 } } }
        $GearFirst + (($kind * 4 + $quality - 1) * $GearTiers + $GearTier - 1)
        $index++
    }
}

foreach ($line in Get-Content (Join-Path $PSScriptRoot 'reference.txt')) {
    $class, $tree, $base, $evolved, $talentList = $line -split ' '
    if ($Classes.Count -and $class -notin $Classes) { continue }
    if ($Specs.Count -and $base -notin $Specs) { continue }
    $talents = @($talentList -split ',')
    if ($NoCapstone) { $talents = $talents[0..($talents.Count - 2)] }
    $builds = if ($BaseOnly) { @($base) } elseif ($EvolvedOnly) { @($evolved) } else { @($base, $evolved) }
    Write-Host "== $class $base ($tree)"
    & (Join-Path $PSScriptRoot 'run-bench.ps1') -Class $class -Builds $builds -NoAnchor -Waves:(-not $Dummies) -Dummies:$Dummies -DummyCrowd:$Dummies -DummyCount 20 -Tier $Tier -Band $Band -Rank $Rank -Minute $Minute `
        -Talents $talents -Training $Training -Items (Get-GearSet $class) -Cards $Cards -Glyphs $Glyphs -Benilla:$Benilla -Tag "$runTag-$tree" 2>&1 |
        Select-String 'k/s|error|Exception|throw'
}

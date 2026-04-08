param(
  [string]$Session = 'lpcgen_batch',
  [string[]]$Ids = @()
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$enemyOutputDir = Join-Path $projectRoot 'assets\sprites\enemies'
$reportPath = Join-Path $projectRoot 'docs\generated\lpc-generated-enemies.md'
$tempDir = Join-Path $projectRoot 'output\playwright'
$specPath = Join-Path $tempDir 'lpc_enemy_specs.json'
$exportToolDir = Join-Path $projectRoot 'tools\lpc-export'
$exportScriptPath = Join-Path $exportToolDir 'lpc_batch_export.mjs'
$nodeModulesPath = Join-Path $exportToolDir 'node_modules'
$polishScriptPath = Join-Path $projectRoot 'tools\polish_enemy_sprites.py'
$defaultBaseArchivePath = 'standard/walk/down/5.png'
$walkZipExports = @(
  @{
    archivePath = 'standard/walk/down/3.png'
    suffix = 'walk_02'
  },
  @{
    archivePath = 'standard/walk/down/7.png'
    suffix = 'walk_03'
  }
)

# Session is retained for backward compatibility with earlier automation entrypoints.
[void]$Session

$enemySpecs = @(
  @{
    id = 'raider'
    bodyType = 'male'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_leather', 'brown'),
      @('shoulders_leather', 'brown'),
      @('belt_leather', 'brown'),
      @('feet_boots_basic', 'brown'),
      @('hat_hood_cloth', 'hood_brown'),
      @('weapon_sword_dagger', 'dagger'),
      @('cape_tattered', 'red')
    )
  },
  @{
    id = 'scout'
    bodyType = 'teen'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_leather', 'forest'),
      @('shoulders_leather', 'forest'),
      @('belt_double', 'leather'),
      @('feet_boots_basic', 'brown'),
      @('hat_hood_cloth', 'hood_brown'),
      @('weapon_ranged_bow_normal', 'dark'),
      @('cape_tattered', 'forest')
    )
  },
  @{
    id = 'banner_captain'
    bodyType = 'male'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_leather', 'brown'),
      @('shoulders_leather', 'brown'),
      @('belt_double', 'leather'),
      @('feet_boots_basic', 'brown'),
      @('hat_bicorne_athwart_captain', 'brown'),
      @('hat_accessory_plumage_centurion', 'red'),
      @('weapon_polearm_spear', 'steel'),
      @('cape_tattered', 'red')
    )
  },
  @{
    id = 'wolf_scout'
    bodyType = 'teen'
    removeItemIds = @('face_neutral')
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('heads_wolf_male', ''),
      @('head_ears_wolf', 'fur_grey'),
      @('tail_wolf_fluffy', 'fur_grey'),
      @('torso_armour_leather', 'forest'),
      @('shoulders_leather', 'forest'),
      @('belt_double', 'leather'),
      @('feet_boots_basic', 'brown'),
      @('weapon_ranged_bow_normal', 'dark'),
      @('cape_tattered', 'charcoal')
    )
  },
  @{
    id = 'shield_infantry'
    bodyType = 'male'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_plate', 'steel'),
      @('shoulders_legion', ''),
      @('hat_helmet_legion', 'steel'),
      @('shield_kite', 'kite green gray'),
      @('weapon_sword_arming', 'steel')
    )
  },
  @{
    id = 'cult_adept'
    bodyType = 'female'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_clothes_robe', 'red'),
      @('shoulders_mantal', 'maroon'),
      @('hat_hood_cloth', 'hood_black'),
      @('weapon_magic_loop', 'brass'),
      @('belt_mage', 'gold'),
      @('cape_solid', 'charcoal')
    )
  },
  @{
    id = 'skeleton'
    bodyType = 'male'
    removeItemIds = @('face_neutral')
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('body_skeleton', 'skeleton'),
      @('heads_skeleton', 'skeleton'),
      @('belt_leather', 'brown'),
      @('weapon_sword_arming', 'iron')
    )
  },
  @{
    id = 'bone_archer'
    bodyType = 'male'
    removeItemIds = @('face_neutral')
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('body_skeleton', 'skeleton'),
      @('heads_skeleton', 'skeleton'),
      @('belt_leather', 'brown'),
      @('weapon_ranged_bow_normal', 'dark'),
      @('cape_tattered', 'charcoal')
    )
  },
  @{
    id = 'grave_guard'
    bodyType = 'male'
    removeItemIds = @('face_neutral')
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('body_skeleton', 'skeleton'),
      @('heads_skeleton', 'skeleton'),
      @('torso_armour_plate', 'iron'),
      @('shoulders_plate', 'iron'),
      @('hat_helmet_close', 'iron'),
      @('shield_heater_revised_wood', 'umber'),
      @('shield_heater_revised_pattern_cross', 'green'),
      @('weapon_sword_arming', 'iron'),
      @('cape_tattered', 'forest'),
      @('belt_leather', 'brown')
    )
  },
  @{
    id = 'plague_bearer'
    bodyType = 'male'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_clothes_robe', 'forest green'),
      @('shoulders_mantal', 'charcoal'),
      @('hat_hood_cloth', 'hood_black'),
      @('weapon_magic_gnarled', 'dark'),
      @('belt_robe', 'white'),
      @('cape_solid', 'forest')
    )
  },
  @{
    id = 'corrupted_knight'
    bodyType = 'male'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_plate', 'iron'),
      @('shoulders_plate', 'iron'),
      @('hat_helmet_horned', 'iron'),
      @('hat_visor_horned', 'iron'),
      @('weapon_sword_arming', 'iron'),
      @('shield_kite', 'kite red gray'),
      @('cape_tattered', 'maroon')
    )
  },
  @{
    id = 'hex_sniper'
    bodyType = 'female'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_clothes_robe', 'dark gray'),
      @('shoulders_mantal', 'purple'),
      @('hat_hood_cloth', 'hood_black'),
      @('weapon_ranged_crossbow', 'crossbow'),
      @('belt_mage', 'silver'),
      @('cape_solid', 'charcoal')
    )
  },
  @{
    id = 'warlock'
    bodyType = 'female'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_clothes_robe', 'dark gray'),
      @('shoulders_mantal', 'purple'),
      @('hat_magic_wizard', 'base_black'),
      @('hat_magic_wizard_belt', 'maroon'),
      @('hat_magic_wizard_buckle', 'gold'),
      @('weapon_magic_loop', 'gold'),
      @('belt_mage', 'silver'),
      @('cape_solid', 'purple')
    )
  },
  @{
    id = 'bastion_priest'
    bodyType = 'male'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_legion', ''),
      @('shoulders_legion', ''),
      @('hat_helmet_legion', 'gold'),
      @('weapon_blunt_mace', 'mace'),
      @('belt_mage', 'gold'),
      @('cape_solid', 'white')
    )
  },
  @{
    id = 'bastion_overlord'
    bodyType = 'muscular'
    baseArchivePath = $defaultBaseArchivePath
    zipExports = $walkZipExports
    selections = @(
      @('torso_armour_plate', 'gold'),
      @('shoulders_plate', 'gold'),
      @('hat_helmet_horned', 'gold'),
      @('hat_visor_horned', 'gold'),
      @('weapon_sword_arming', 'gold'),
      @('cape_solid', 'red')
    )
  }
)

if ($Ids.Count -gt 0) {
  $requestedIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($id in $Ids) {
    foreach ($token in ($id -split ',')) {
      if (-not [string]::IsNullOrWhiteSpace($token)) {
        [void]$requestedIds.Add($token.Trim())
      }
    }
  }
  if ($requestedIds.Count -gt 0) {
    $enemySpecs = @(
      foreach ($spec in $enemySpecs) {
        if ($requestedIds.Contains([string]$spec.id)) {
          $spec
        }
      }
    )
    if ($enemySpecs.Count -eq 0) {
      throw "No enemy specs matched requested ids: $($Ids -join ', ')"
    }
  }
}

New-Item -ItemType Directory -Force -Path $enemyOutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
[IO.File]::WriteAllText(
  $specPath,
  (ConvertTo-Json -InputObject @($enemySpecs) -Depth 8),
  [Text.UTF8Encoding]::new($false)
)

if (-not (Test-Path $nodeModulesPath)) {
  Push-Location $exportToolDir
  try {
    & npm install 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
      throw 'npm install failed for tools\lpc-export.'
    }
  } finally {
    Pop-Location
  }
}

Push-Location $exportToolDir
try {
  $nodeArgs = @(
    $exportScriptPath,
    '--specs', $specPath,
    '--outdir', 'assets/sprites/enemies'
  )
  if ($Ids.Count -eq 0) {
    $nodeArgs += @('--report', 'docs/generated/lpc-generated-enemies.md')
  }
  $nodeOutput = & node @nodeArgs 2>&1
} finally {
  Pop-Location
}

if ($LASTEXITCODE -ne 0) {
  throw ([string]::Join("`n", $nodeOutput))
}

$parsed = $nodeOutput -join "`n" | ConvertFrom-Json
Add-Type -AssemblyName System.IO.Compression.FileSystem
$baseArchivePathById = @{}
$zipExportsById = @{}
foreach ($spec in $enemySpecs) {
  $baseArchivePathById[[string]$spec.id] = [string]$spec.baseArchivePath
  $zipExportsById[[string]$spec.id] = @($spec.zipExports)
}

foreach ($result in $parsed.results) {
  $animationZipPath = [string]$result.animationZipPath
  if ([string]::IsNullOrWhiteSpace($animationZipPath) -or -not (Test-Path $animationZipPath)) {
    throw "Missing animation zip for $($result.id): $animationZipPath"
  }

  $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($animationZipPath)
  try {
    $baseArchivePath = $baseArchivePathById[[string]$result.id]
    $baseEntry = $zipArchive.GetEntry($baseArchivePath)
    if ($null -eq $baseEntry) {
      throw "Missing base zip entry '$baseArchivePath' for $($result.id)"
    }
    $baseTargetPath = Join-Path $enemyOutputDir "$($result.id).png"
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($baseEntry, $baseTargetPath, $true)

    foreach ($zipExport in $zipExportsById[[string]$result.id]) {
      $archivePath = [string]$zipExport.archivePath
      $suffix = [string]$zipExport.suffix
      $entry = $zipArchive.GetEntry($archivePath)
      if ($null -eq $entry) {
        throw "Missing zip entry '$archivePath' for $($result.id)"
      }
      $targetPath = Join-Path $enemyOutputDir "$($result.id)_$suffix.png"
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
    }
  } finally {
    $zipArchive.Dispose()
  }
}

$polishArgs = @($polishScriptPath)
if ($Ids.Count -gt 0) {
  $polishArgs += @('--ids')
  $polishArgs += $Ids
}
$pythonOutput = & python @polishArgs 2>&1
if ($LASTEXITCODE -ne 0) {
  throw ([string]::Join("`n", $pythonOutput))
}

$parsed.results |
  Select-Object id, baseArchivePath, outputPath |
  Format-Table -AutoSize

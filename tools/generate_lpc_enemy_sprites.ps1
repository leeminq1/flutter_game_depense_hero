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
$legacyBaseArchivePath = 'standard/walk/down/5.png'
$legacyZipExports = @(
  @{
    archivePath = 'standard/walk/down/3.png'
    suffix = 'walk_02'
  },
  @{
    archivePath = 'standard/walk/down/7.png'
    suffix = 'walk_03'
  }
)
$directionalExports = @(
  @{
    direction = 'west'
    baseArchivePath = 'standard/walk/left/5.png'
    zipExports = @(
      @{ archivePath = 'standard/walk/left/3.png'; suffix = 'walk_02' },
      @{ archivePath = 'standard/walk/left/7.png'; suffix = 'walk_03' }
    )
  },
  @{
    direction = 'north'
    baseArchivePath = 'standard/walk/up/5.png'
    zipExports = @(
      @{ archivePath = 'standard/walk/up/3.png'; suffix = 'walk_02' },
      @{ archivePath = 'standard/walk/up/7.png'; suffix = 'walk_03' }
    )
  },
  @{
    direction = 'south'
    baseArchivePath = 'standard/walk/down/5.png'
    zipExports = @(
      @{ archivePath = 'standard/walk/down/3.png'; suffix = 'walk_02' },
      @{ archivePath = 'standard/walk/down/7.png'; suffix = 'walk_03' }
    )
  }
)

# Session is retained for backward compatibility with earlier automation entrypoints.
[void]$Session

$enemySpecs = @(
  @{
    id = 'raider'
    bodyType = 'male'
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
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
$specById = @{}
foreach ($spec in $enemySpecs) {
  $specById[[string]$spec.id] = $spec
}

foreach ($result in $parsed.results) {
  $animationZipPath = [string]$result.animationZipPath
  if ([string]::IsNullOrWhiteSpace($animationZipPath) -or -not (Test-Path $animationZipPath)) {
    throw "Missing animation zip for $($result.id): $animationZipPath"
  }

  $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($animationZipPath)
  try {
    $spec = $specById[[string]$result.id]
    $enemyDir = Join-Path $enemyOutputDir ([string]$result.id)
    New-Item -ItemType Directory -Force -Path $enemyDir | Out-Null

    foreach ($directional in $directionalExports) {
      $direction = [string]$directional.direction
      $directionDir = Join-Path $enemyDir $direction
      New-Item -ItemType Directory -Force -Path $directionDir | Out-Null

      $directionBaseArchivePath = [string]$directional.baseArchivePath
      $directionBaseEntry = $zipArchive.GetEntry($directionBaseArchivePath)
      if ($null -eq $directionBaseEntry) {
        throw "Missing base zip entry '$directionBaseArchivePath' for $($result.id) [$direction]"
      }
      $directionBaseTargetPath = Join-Path $directionDir 'base.png'
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($directionBaseEntry, $directionBaseTargetPath, $true)

      foreach ($zipExport in @($directional.zipExports)) {
        $archivePath = [string]$zipExport.archivePath
        $suffix = [string]$zipExport.suffix
        $entry = $zipArchive.GetEntry($archivePath)
        if ($null -eq $entry) {
          throw "Missing zip entry '$archivePath' for $($result.id) [$direction]"
        }
        $targetPath = Join-Path $directionDir "$suffix.png"
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
      }
    }

    $legacyBaseEntry = $zipArchive.GetEntry($legacyBaseArchivePath)
    if ($null -eq $legacyBaseEntry) {
      throw "Missing legacy base zip entry '$legacyBaseArchivePath' for $($result.id)"
    }
    $baseTargetPath = Join-Path $enemyOutputDir "$($result.id).png"
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($legacyBaseEntry, $baseTargetPath, $true)

    foreach ($zipExport in $legacyZipExports) {
      $archivePath = [string]$zipExport.archivePath
      $suffix = [string]$zipExport.suffix
      $entry = $zipArchive.GetEntry($archivePath)
      if ($null -eq $entry) {
        throw "Missing zip entry '$archivePath' for $($result.id)"
      }
      $targetPath = Join-Path $enemyOutputDir "$($result.id)_$suffix.png"
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
    }

    $metadataPath = Join-Path $enemyDir 'metadata.json'
    $metadata = [ordered]@{
      enemyId = [string]$result.id
      bodyType = [string]$spec.bodyType
      generatedAt = (Get-Date).ToString('o')
      size = '64x64'
      legacyFallback = [ordered]@{
        base = "assets/sprites/enemies/$($result.id).png"
        walk_02 = "assets/sprites/enemies/$($result.id)_walk_02.png"
        walk_03 = "assets/sprites/enemies/$($result.id)_walk_03.png"
      }
      exports = [ordered]@{
        west = [ordered]@{
          base = 'west/base.png'
          walk_02 = 'west/walk_02.png'
          walk_03 = 'west/walk_03.png'
          source = [ordered]@{
            base = 'standard/walk/left/5.png'
            walk_02 = 'standard/walk/left/3.png'
            walk_03 = 'standard/walk/left/7.png'
          }
        }
        north = [ordered]@{
          base = 'north/base.png'
          walk_02 = 'north/walk_02.png'
          walk_03 = 'north/walk_03.png'
          source = [ordered]@{
            base = 'standard/walk/up/5.png'
            walk_02 = 'standard/walk/up/3.png'
            walk_03 = 'standard/walk/up/7.png'
          }
        }
        south = [ordered]@{
          base = 'south/base.png'
          walk_02 = 'south/walk_02.png'
          walk_03 = 'south/walk_03.png'
          source = [ordered]@{
            base = 'standard/walk/down/5.png'
            walk_02 = 'standard/walk/down/3.png'
            walk_03 = 'standard/walk/down/7.png'
          }
        }
        east = [ordered]@{
          status = 'runtime_mirror_mvp'
        }
      }
      selections = @(
        foreach ($selection in @($spec.selections)) {
          [ordered]@{
            id = [string]$selection[0]
            variant = [string]$selection[1]
          }
        }
      )
      removeItemIds = @($spec.removeItemIds)
      attribution = 'LPC-derived assets require credits export before shipping.'
    }
    [IO.File]::WriteAllText(
      $metadataPath,
      (ConvertTo-Json -InputObject $metadata -Depth 8),
      [Text.UTF8Encoding]::new($false)
    )

    $creditsPath = Join-Path $enemyDir 'credits.txt'
    $creditsText = @"
Enemy: $($result.id)
Source: Universal LPC Spritesheet Character Generator
Generator URL: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/
Export: ZIP split by animation and frame
Note: Preserve the generator credits export before shipping LPC-derived assets.
"@
    [IO.File]::WriteAllText(
      $creditsPath,
      $creditsText.Trim(),
      [Text.UTF8Encoding]::new($false)
    )
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

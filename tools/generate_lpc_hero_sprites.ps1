param(
  [string[]]$Ids = @()
)

$ErrorActionPreference = 'Stop'

$projectRoot    = Split-Path -Parent $PSScriptRoot
$heroOutputDir  = Join-Path $projectRoot 'assets\sprites\heroes'
$tempDir        = Join-Path $projectRoot 'output\playwright'
$specPath       = Join-Path $tempDir 'lpc_hero_specs.json'
$exportToolDir  = Join-Path $projectRoot 'tools\lpc-export'
$exportScriptPath = Join-Path $exportToolDir 'lpc_batch_export.mjs'
$nodeModulesPath  = Join-Path $exportToolDir 'node_modules'

$legacyBaseArchivePath = 'standard/walk/down/5.png'
$legacyZipExports = @(
  @{ archivePath = 'standard/walk/down/3.png'; suffix = 'walk_02' },
  @{ archivePath = 'standard/walk/down/7.png'; suffix = 'walk_03' }
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

$heroSpecs = @(
  @{
    id = 'knight'
    bodyType = 'muscular'
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
    selections = @(
      @('torso_armour_plate',  'gold'),
      @('shoulders_plate',     'gold'),
      @('hat_helmet_close',    'gold'),
      @('weapon_sword_arming', 'gold'),
      @('shield_kite',         'kite green gray'),
      @('cape_solid',          'blue')
    )
  },
  @{
    id = 'elf_archer'
    bodyType = 'female'
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
    selections = @(
      @('head_ears_elven',           ''),
      @('torso_armour_leather',      'forest'),
      @('shoulders_leather',         'forest'),
      @('hat_hood_cloth',            'hood_brown'),
      @('weapon_ranged_bow_normal',  'dark'),
      @('belt_double',               'leather'),
      @('cape_solid',                'forest')
    )
  },
  @{
    id = 'flame_mage'
    bodyType = 'male'
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
    selections = @(
      @('torso_clothes_robe',  'red'),
      @('shoulders_mantal',    'maroon'),
      @('hat_hood_cloth',      'hood_black'),
      @('weapon_magic_loop',   'gold'),
      @('belt_mage',           'gold'),
      @('cape_solid',          'red')
    )
  },
  @{
    id = 'cleric'
    bodyType = 'male'
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
    selections = @(
      @('torso_clothes_robe',  'white'),
      @('hat_helmet_legion',   'gold'),
      @('weapon_blunt_mace',   'mace'),
      @('belt_mage',           'gold'),
      @('cape_solid',          'white')
    )
  },
  @{
    id = 'red_assassin'
    bodyType = 'teen'
    baseArchivePath = $legacyBaseArchivePath
    zipExports = $legacyZipExports
    selections = @(
      @('torso_armour_leather', 'brown'),
      @('hat_hood_cloth',       'hood_black'),
      @('belt_double',          'leather'),
      @('weapon_sword_dagger',  'dagger'),
      @('cape_solid',           'red')
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
    $heroSpecs = @(
      foreach ($spec in $heroSpecs) {
        if ($requestedIds.Contains([string]$spec.id)) { $spec }
      }
    )
    if ($heroSpecs.Count -eq 0) {
      throw "No hero specs matched requested ids: $($Ids -join ', ')"
    }
  }
}

New-Item -ItemType Directory -Force -Path $heroOutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
[IO.File]::WriteAllText(
  $specPath,
  (ConvertTo-Json -InputObject @($heroSpecs) -Depth 8),
  [Text.UTF8Encoding]::new($false)
)

if (-not (Test-Path $nodeModulesPath)) {
  Push-Location $exportToolDir
  try {
    & npm install 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'npm install failed for tools\lpc-export.' }
  } finally {
    Pop-Location
  }
}

$nodeArgs = @(
  $exportScriptPath,
  '--specs', $specPath,
  '--outdir', 'assets/sprites/heroes'
)
$stdoutFile = [IO.Path]::GetTempFileName()
$stderrFile  = [IO.Path]::GetTempFileName()
$proc = Start-Process -FilePath 'node' -ArgumentList $nodeArgs `
  -WorkingDirectory $exportToolDir `
  -NoNewWindow -Wait -PassThru `
  -RedirectStandardOutput $stdoutFile `
  -RedirectStandardError  $stderrFile
$nodeExitCode = $proc.ExitCode
$nodeOutput   = Get-Content $stdoutFile -Raw -ErrorAction SilentlyContinue
$stderrOut    = Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue
Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue
if ($stderrOut) { Write-Host $stderrOut }

if ($nodeExitCode -ne 0) {
  throw "node exited $nodeExitCode`n$nodeOutput"
}

$parsed = $nodeOutput -join "`n" | ConvertFrom-Json
Add-Type -AssemblyName System.IO.Compression.FileSystem
$specById = @{}
foreach ($spec in $heroSpecs) {
  $specById[[string]$spec.id] = $spec
}

foreach ($result in $parsed.results) {
  $animationZipPath = [string]$result.animationZipPath
  if ([string]::IsNullOrWhiteSpace($animationZipPath) -or -not (Test-Path $animationZipPath)) {
    throw "Missing animation zip for $($result.id): $animationZipPath"
  }

  $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($animationZipPath)
  try {
    $spec    = $specById[[string]$result.id]
    $heroDir = Join-Path $heroOutputDir ([string]$result.id)
    New-Item -ItemType Directory -Force -Path $heroDir | Out-Null

    foreach ($directional in $directionalExports) {
      $direction    = [string]$directional.direction
      $directionDir = Join-Path $heroDir $direction
      New-Item -ItemType Directory -Force -Path $directionDir | Out-Null

      $baseEntry = $zipArchive.GetEntry([string]$directional.baseArchivePath)
      if ($null -eq $baseEntry) {
        throw "Missing base zip entry '$($directional.baseArchivePath)' for $($result.id) [$direction]"
      }
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($baseEntry, (Join-Path $directionDir 'base.png'), $true)

      foreach ($zipExport in @($directional.zipExports)) {
        $entry = $zipArchive.GetEntry([string]$zipExport.archivePath)
        if ($null -eq $entry) {
          throw "Missing zip entry '$($zipExport.archivePath)' for $($result.id) [$direction]"
        }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $directionDir "$($zipExport.suffix).png"), $true)
      }
    }

    $metadata = [ordered]@{
      heroId      = [string]$result.id
      type        = 'hero'
      bodyType    = [string]$spec.bodyType
      generatedAt = (Get-Date).ToString('o')
      size        = '64x64'
      exports     = [ordered]@{
        west  = [ordered]@{ base = 'west/base.png';  walk_02 = 'west/walk_02.png';  walk_03 = 'west/walk_03.png'  }
        north = [ordered]@{ base = 'north/base.png'; walk_02 = 'north/walk_02.png'; walk_03 = 'north/walk_03.png' }
        south = [ordered]@{ base = 'south/base.png'; walk_02 = 'south/walk_02.png'; walk_03 = 'south/walk_03.png' }
        east  = [ordered]@{ status = 'runtime_mirror_mvp' }
      }
      selections  = @(
        foreach ($selection in @($spec.selections)) {
          [ordered]@{ id = [string]$selection[0]; variant = [string]$selection[1] }
        }
      )
      attribution = 'LPC-derived assets require credits export before shipping.'
    }
    [IO.File]::WriteAllText(
      (Join-Path $heroDir 'metadata.json'),
      (ConvertTo-Json -InputObject $metadata -Depth 8),
      [Text.UTF8Encoding]::new($false)
    )

    [IO.File]::WriteAllText(
      (Join-Path $heroDir 'credits.txt'),
      "Hero: $($result.id)`nSource: Universal LPC Spritesheet Character Generator`nGenerator URL: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/`nLicense: CC-BY-SA 3.0 / GPL 3.0`nNote: Preserve the generator credits export before shipping LPC-derived assets.",
      [Text.UTF8Encoding]::new($false)
    )

    Write-Host "  [DONE] $($result.id)"
  } finally {
    $zipArchive.Dispose()
  }
}

Write-Host ''
Write-Host 'HERO BATCH COMPLETE'
foreach ($name in $heroSpecs | ForEach-Object { $_.id }) {
  $count = @(Get-ChildItem -Recurse -Filter '*.png' -Path (Join-Path $heroOutputDir $name) -ErrorAction SilentlyContinue).Count
  Write-Host "  $($name.PadRight(15)): $count PNGs"
}

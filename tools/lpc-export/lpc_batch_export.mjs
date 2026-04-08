import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { chromium } from 'playwright';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..', '..');

function getArg(flag) {
  const index = process.argv.indexOf(flag);
  if (index === -1) {
    return null;
  }
  return process.argv[index + 1] ?? null;
}

const specsPath = getArg('--specs');
const outDirArg = getArg('--outdir');
const reportPath = getArg('--report');

if (!specsPath || !outDirArg) {
  console.error('Missing required args: --specs <file> --outdir <dir>');
  process.exit(1);
}

const generatorUrl =
  'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/';

const configureEnemy = async (page, config) => {
  return page.evaluate(async (cfg) => {
    const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    await window.setDefaultSelections();
    const stateModule = await import(
      'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/sources/state/state.js'
    );
    const { state, resetAll, selectItem, getSelectionGroup, getStateDeps } =
      stateModule;
    const deps = getStateDeps();

    await resetAll();
    state.bodyType = cfg.bodyType;

    for (const itemId of cfg.removeItemIds || []) {
      delete state.selections[getSelectionGroup(itemId)];
    }

    for (const [itemId, variant] of cfg.selections) {
      selectItem(itemId, variant ?? '');
    }

    deps.syncSelectionsToHash();
    await deps.renderCharacter(state.selections, state.bodyType);
    deps.redraw();
    await sleep(350);

    return {
      hash: window.location.hash,
    };
  }, config);
};

const downloadAnimationZip = async (page, id) => {
  const archiveDir = path.resolve(
    rootDir,
    'output',
    'playwright',
    'lpc-animation-zips',
  );
  await fs.mkdir(archiveDir, { recursive: true });
  const archivePath = path.join(archiveDir, `${id}.zip`);
  const [download] = await Promise.all([
    page.waitForEvent('download', { timeout: 120000 }),
    page.getByText('ZIP: Split by animation and frame').click(),
  ]);
  await download.saveAs(archivePath);
  return archivePath;
};

const formatZipNotes = (result) => {
  const details = [
    `base <= ${result.baseArchivePath || 'unset'}`,
    ...(result.zipExports ?? []).map(
      (extra) => `${extra.suffix} <= ${extra.archivePath}`,
    ),
  ];
  return details.join(', ');
};

const main = async () => {
  const specs = JSON.parse(await fs.readFile(specsPath, 'utf8'));
  const outDir = path.resolve(rootDir, outDirArg);
  await fs.mkdir(outDir, { recursive: true });
  if (reportPath) {
    await fs.mkdir(
      path.dirname(path.resolve(rootDir, reportPath)),
      { recursive: true },
    );
  }

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(generatorUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(
    () => typeof window.setDefaultSelections === 'function',
  );

  const results = [];
  for (const spec of specs) {
    const configured = await configureEnemy(page, spec);
    const animationZipPath = await downloadAnimationZip(page, spec.id);
    results.push({
      id: spec.id,
      outputPath: path.join(outDir, `${spec.id}.png`),
      hash: configured.hash ?? '',
      animationZipPath,
      baseArchivePath: spec.baseArchivePath ?? null,
      zipExports: spec.zipExports ?? [],
    });
  }

  await browser.close();

  if (reportPath) {
    const lines = [
      '# LPC Generated Enemy Sprites',
      '',
      'These enemy sprites were generated from the Universal LPC generator through a Playwright-driven Node export script.',
      'High-level role prompts live in `assets/sprites/enemies/AI_GENERATION_PROMPTS.md`, and exact LPC selections live in `tools/generate_lpc_enemy_sprites.ps1`.',
      '',
      '| Enemy | Files | Notes |',
      '| --- | --- | --- |',
      ...results.map(
        (result) =>
          `| ${result.id} | assets/sprites/enemies/${result.id}.png plus walk companions | ZIP frame mapping: ${formatZipNotes(result)} |`,
      ),
      '',
      '## Source and Format',
      '',
      '- Source generator: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/',
      '- License status: LPC-derived assets require attribution. Preserve the generator credits export before shipping.',
      '- Export format: transparent RGBA PNG, 64x64 centered crop from the split animation ZIP.',
      '- Canonical frame mapping: base `standard/walk/down/5.png`, `walk_02` `standard/walk/down/3.png`, `walk_03` `standard/walk/down/7.png`.',
      '- Local polish is applied only to the extracted base PNGs after export.',
      '',
      'Attribution is still required for LPC-derived assets.',
      `Source generator: ${generatorUrl}`,
      'Regenerate with: `powershell -ExecutionPolicy Bypass -File .\\tools\\generate_lpc_enemy_sprites.ps1`',
      '',
    ];
    await fs.writeFile(
      path.resolve(rootDir, reportPath),
      lines.join('\n'),
      'utf8',
    );
  }

  process.stdout.write(JSON.stringify({ results }, null, 2));
};

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

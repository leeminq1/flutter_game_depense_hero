import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..', '..');

function getArg(flag) {
  const index = process.argv.indexOf(flag);
  if (index === -1) return null;
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

/**
 * Build a v2 JSON config from a spec's selections array.
 * Each selection is [itemId, variant] from the PS1 format.
 * The system maps by itemId so key names are arbitrary.
 */
const buildJsonConfig = (spec) => {
  const headItem = spec.bodyType === 'female' ? 'heads_human_female' : 'heads_human_male';
  const baseSelections = {
    body:       { itemId: 'body',       variant: '', recolor: 'light' },
    head:       { itemId: headItem,     variant: '', recolor: 'light' },
    expression: { itemId: 'face_neutral', variant: '', recolor: 'light' },
  };

  const itemSelections = {};
  for (let i = 0; i < spec.selections.length; i++) {
    const [itemId, variant] = spec.selections[i];
    const key = `item_${i}`;
    // Decide whether to use recolor or variant based on what the LPC site expects.
    // For color-only items (plate armour, helm), use recolor. For style items, use variant.
    const colorItems = [
      'body', 'heads_human_male', 'heads_human_female', 'heads_elf',
      'torso_armour_plate', 'torso_armour_leather', 'torso_armour_legion', 'torso_clothes_robe',
      'shoulders_plate', 'shoulders_leather', 'shoulders_mantal', 'shoulders_legion',
      'hat_helmet_close', 'hat_helmet_legion', 'hat_helmet_horned',
      'cape_solid', 'cape_tattered',
      'belt_mage', 'belt_double', 'belt_leather', 'belt_robe',
      'shield_kite', 'shield_round', 'shield_heater_wood', 'shield_heater_revised_wood',
    ];
    if (colorItems.includes(itemId) && variant) {
      itemSelections[key] = { itemId, variant: '', recolor: variant };
    } else {
      itemSelections[key] = { itemId, variant: variant || '', recolor: '' };
    }
  }

  // Remove default head/body if spec overrides them
  const specItemIds = Object.values(itemSelections).map(s => s.itemId);
  const selections = { ...baseSelections, ...itemSelections };
  if (specItemIds.some(id => id.startsWith('heads_') && id !== 'heads_human_male')) {
    delete selections.head;
  }

  return {
    version: 2,
    bodyType: spec.bodyType || 'male',
    selections,
    selectedAnimation: 'walk',
  };
};

/**
 * Import character config via clipboard JSON and trigger ZIP download.
 */
const configureAndDownload = async (page, spec) => {
  const config = buildJsonConfig(spec);

  // Reset previous state
  await page.evaluate(() => window.setDefaultSelections());
  await page.waitForTimeout(2000);

  // Write config to clipboard and import
  await page.evaluate((cfg) => navigator.clipboard.writeText(JSON.stringify(cfg)), config);
  await page.waitForTimeout(800);
  await page.getByText('Import from Clipboard (JSON)').click();
  await page.waitForTimeout(3500);

  // Download ZIP
  const archiveDir = path.resolve(rootDir, 'output', 'playwright', 'lpc-animation-zips');
  await fs.mkdir(archiveDir, { recursive: true });
  const archivePath = path.join(archiveDir, `${spec.id}.zip`);

  // Click download button and wait
  const downloadPromise = page.waitForEvent('download', { timeout: 60000 });
  await page.getByText('ZIP: Split by animation and frame').click();
  const download = await downloadPromise;
  await download.saveAs(archivePath);

  const hash = await page.evaluate(() => window.location.hash);
  return { animationZipPath: archivePath, hash };
};

const formatZipNotes = (result) => {
  const details = [
    `base <= ${result.baseArchivePath || 'unset'}`,
    ...(result.zipExports ?? []).map(e => `${e.suffix} <= ${e.archivePath}`),
  ];
  return details.join(', ');
};

const main = async () => {
  const specs = JSON.parse(await fs.readFile(specsPath, 'utf8'));
  const outDir = path.resolve(rootDir, outDirArg);
  await fs.mkdir(outDir, { recursive: true });
  if (reportPath) {
    await fs.mkdir(path.dirname(path.resolve(rootDir, reportPath)), { recursive: true });
  }

  const browser = await chromium.launch({ headless: false });

  const results = [];
  for (const spec of specs) {
    console.error(`Configuring: ${spec.id}`);
    // Fresh context per hero to avoid state bleed between downloads
    const context = await browser.newContext({ permissions: ['clipboard-read', 'clipboard-write'] });
    const page = await context.newPage();
    try {
      await page.goto(generatorUrl, { waitUntil: 'networkidle', timeout: 60000 });
      await page.waitForFunction(() => typeof window.setDefaultSelections === 'function', { timeout: 30000 });
      await page.waitForTimeout(3000);

      const { animationZipPath, hash } = await configureAndDownload(page, spec);
      results.push({
        id: spec.id,
        outputPath: path.join(outDir, `${spec.id}.png`),
        hash,
        animationZipPath,
        baseArchivePath: spec.baseArchivePath ?? null,
        zipExports: spec.zipExports ?? [],
      });
      console.error(`  Done: ${spec.id} → ${animationZipPath}`);
    } catch (err) {
      console.error(`  ERROR ${spec.id}: ${err.message}`);
      results.push({
        id: spec.id, outputPath: '', hash: '', animationZipPath: '',
        baseArchivePath: spec.baseArchivePath ?? null, zipExports: spec.zipExports ?? [],
      });
    } finally {
      await context.close();
    }
  }

  await browser.close();

  if (reportPath) {
    const lines = [
      '# LPC Generated Hero Sprites',
      '',
      '| Hero | Files | Notes |',
      '| --- | --- | --- |',
      ...results.map(r =>
        `| ${r.id} | assets/sprites/heroes/${r.id}/ | ZIP frame mapping: ${formatZipNotes(r)} |`
      ),
      '',
    ];
    await fs.writeFile(path.resolve(rootDir, reportPath), lines.join('\n'), 'utf8');
  }

  process.stdout.write(JSON.stringify({ results }, null, 2));
};

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

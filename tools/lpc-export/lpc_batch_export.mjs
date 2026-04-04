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

const generatorUrl = 'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/';

const renderEnemy = async (page, config) => {
  return page.evaluate(async (cfg) => {
    const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    await window.setDefaultSelections();
    const stateModule = await import('https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/sources/state/state.js');
    const { state, resetAll, selectItem, getSelectionGroup, getStateDeps } = stateModule;
    const deps = getStateDeps();

    await resetAll();
    state.bodyType = cfg.bodyType;
    for (const itemId of cfg.removeItemIds || []) {
      delete state.selections[getSelectionGroup(itemId)];
    }
    for (const [itemId, variant] of cfg.selections) {
      selectItem(itemId, variant);
    }
    state.selectedAnimation = 'idle';
    deps.syncSelectionsToHash();
    await deps.renderCharacter(state.selections, state.bodyType);
    deps.redraw();
    await sleep(300);

    const previewCanvas = document.querySelectorAll('canvas')[0];
    const frameWidth = 64;
    const frameCount = Math.max(1, Math.floor(previewCanvas.width / frameWidth));
    const frameHeight = previewCanvas.height;
    const frameCanvas = document.createElement('canvas');
    frameCanvas.width = frameWidth;
    frameCanvas.height = frameHeight;
    const frameContext = frameCanvas.getContext('2d');
    frameContext.imageSmoothingEnabled = false;

    const forcedFrame = Number.isInteger(cfg.preferredFrame) ? cfg.preferredFrame : null;
    let bestFrame = forcedFrame ?? 0;
    let bestOpaque = -1;
    let bestBounds = { minX: 0, minY: 0, maxX: frameWidth - 1, maxY: frameHeight - 1 };

    for (let frameIndex = 0; frameIndex < frameCount; frameIndex += 1) {
      frameContext.clearRect(0, 0, frameWidth, frameHeight);
      frameContext.drawImage(
        previewCanvas,
        frameIndex * frameWidth,
        0,
        frameWidth,
        frameHeight,
        0,
        0,
        frameWidth,
        frameHeight,
      );
      const pixelData = frameContext.getImageData(0, 0, frameWidth, frameHeight).data;
      let opaqueCount = 0;
      let minX = frameWidth;
      let minY = frameHeight;
      let maxX = -1;
      let maxY = -1;
      for (let y = 0; y < frameHeight; y += 1) {
        for (let x = 0; x < frameWidth; x += 1) {
          if (pixelData[(y * frameWidth + x) * 4 + 3] > 0) {
            opaqueCount += 1;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }
      if (forcedFrame === null && opaqueCount > bestOpaque) {
        bestOpaque = opaqueCount;
        bestFrame = frameIndex;
        bestBounds = maxX >= 0
          ? { minX, minY, maxX, maxY }
          : { minX: 0, minY: 0, maxX: frameWidth - 1, maxY: frameHeight - 1 };
      }
    }

    if (bestFrame >= frameCount) {
      bestFrame = 0;
    }

    if (forcedFrame !== null) {
      frameContext.clearRect(0, 0, frameWidth, frameHeight);
      frameContext.drawImage(
        previewCanvas,
        bestFrame * frameWidth,
        0,
        frameWidth,
        frameHeight,
        0,
        0,
        frameWidth,
        frameHeight,
      );
      const pixelData = frameContext.getImageData(0, 0, frameWidth, frameHeight).data;
      let minX = frameWidth;
      let minY = frameHeight;
      let maxX = -1;
      let maxY = -1;
      for (let y = 0; y < frameHeight; y += 1) {
        for (let x = 0; x < frameWidth; x += 1) {
          if (pixelData[(y * frameWidth + x) * 4 + 3] > 0) {
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }
      bestBounds = maxX >= 0
        ? { minX, minY, maxX, maxY }
        : { minX: 0, minY: 0, maxX: frameWidth - 1, maxY: frameHeight - 1 };
    }

    frameContext.clearRect(0, 0, frameWidth, frameHeight);
    frameContext.drawImage(
      previewCanvas,
      bestFrame * frameWidth,
      0,
      frameWidth,
      frameHeight,
      0,
      0,
      frameWidth,
      frameHeight,
    );

    const cropWidth = bestBounds.maxX - bestBounds.minX + 1;
    const cropHeight = bestBounds.maxY - bestBounds.minY + 1;
    const outputCanvas = document.createElement('canvas');
    outputCanvas.width = 64;
    outputCanvas.height = 64;
    const outputContext = outputCanvas.getContext('2d');
    outputContext.imageSmoothingEnabled = false;
    const scale = Math.max(1, Math.floor(Math.min(56 / cropWidth, 60 / cropHeight)));
    const drawWidth = cropWidth * scale;
    const drawHeight = cropHeight * scale;
    const drawX = Math.floor((64 - drawWidth) / 2);
    const drawY = 64 - drawHeight - 2;
    outputContext.clearRect(0, 0, 64, 64);
    outputContext.drawImage(
      frameCanvas,
      bestBounds.minX,
      bestBounds.minY,
      cropWidth,
      cropHeight,
      drawX,
      drawY,
      drawWidth,
      drawHeight,
    );

    return {
      hash: window.location.hash,
      bestFrame,
      dataUrl: outputCanvas.toDataURL('image/png'),
    };
  }, config);
};

const main = async () => {
  const specs = JSON.parse(await fs.readFile(specsPath, 'utf8'));
  const outDir = path.resolve(rootDir, outDirArg);
  await fs.mkdir(outDir, { recursive: true });
  if (reportPath) {
    await fs.mkdir(path.dirname(path.resolve(rootDir, reportPath)), { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(generatorUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => typeof window.setDefaultSelections === 'function');

  const results = [];
  for (const spec of specs) {
    const result = await renderEnemy(page, spec);
    const base64 = result.dataUrl.replace(/^data:image\/png;base64,/, '');
    const outputPath = path.join(outDir, `${spec.id}.png`);
    await fs.writeFile(outputPath, Buffer.from(base64, 'base64'));
    results.push({
      id: spec.id,
      outputPath,
      hash: result.hash ?? '',
      bestFrame: Number.isInteger(result.bestFrame) ? result.bestFrame : 0,
    });
  }

  await browser.close();

  if (reportPath) {
    const lines = [
      '# LPC Generated Enemy Sprites',
      '',
      'These enemy sprites were generated from the Universal LPC generator through a Playwright-driven Node export script.',
      '',
      '| Enemy | File | Notes |',
      '| --- | --- | --- |',
      ...results.map((result) =>
        `| ${result.id} | assets/sprites/enemies/${result.id}.png | idle preview best frame ${result.bestFrame} |`,
      ),
      '',
      'Attribution is still required for LPC-derived assets.',
      `Source generator: ${generatorUrl}`,
      'Regenerate with: `powershell -ExecutionPolicy Bypass -File .\\tools\\generate_lpc_enemy_sprites.ps1`',
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

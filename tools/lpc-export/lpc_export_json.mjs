/**
 * Clicks "Export to Clipboard (JSON)" on the LPC site to discover the JSON config format.
 * Then shows the structure so we can build hero configs.
 */
import { chromium } from 'playwright';

const generatorUrl = 'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/';

const main = async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    permissions: ['clipboard-read', 'clipboard-write'],
  });
  const page = await context.newPage();
  await page.goto(generatorUrl, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForFunction(() => typeof window.setDefaultSelections === 'function', { timeout: 30000 });
  await page.waitForTimeout(4000);

  // Click "Export to Clipboard (JSON)"
  await page.getByText('Export to Clipboard (JSON)').click();
  await page.waitForTimeout(1000);

  // Read clipboard
  const json = await page.evaluate(() => navigator.clipboard.readText());
  console.log('=== DEFAULT CHARACTER JSON ===');
  try {
    const parsed = JSON.parse(json);
    console.log(JSON.stringify(parsed, null, 2));
  } catch {
    console.log(json);
  }

  await browser.close();
};

main().catch(e => { console.error(e); process.exit(1); });

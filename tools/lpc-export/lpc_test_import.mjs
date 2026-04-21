/**
 * Test: import a knight config via clipboard JSON, then export to see which keys worked.
 */
import { chromium } from 'playwright';

const generatorUrl = 'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/';

const knightConfig = {
  version: 2,
  bodyType: 'muscular',
  selections: {
    body:          { itemId: 'body',               variant: '', recolor: 'light' },
    head:          { itemId: 'heads_human_male',    variant: '', recolor: 'light' },
    expression:    { itemId: 'face_neutral',         variant: '', recolor: 'light' },
    torso:         { itemId: 'torso_armour_plate',   variant: '', recolor: 'gold' },
    shoulders:     { itemId: 'shoulders_plate',      variant: '', recolor: 'gold' },
    hat:           { itemId: 'hat_helmet_close',     variant: '', recolor: 'gold' },
    weapon_right:  { itemId: 'weapon_sword_arming',  variant: '', recolor: '' },
    shield_offhand:{ itemId: 'shield_kite',           variant: '', recolor: '' },
    cape:          { itemId: 'cape_solid',            variant: '', recolor: 'blue' },
  },
  selectedAnimation: 'walk',
};

const main = async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ permissions: ['clipboard-read', 'clipboard-write'] });
  const page = await context.newPage();
  await page.goto(generatorUrl, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForFunction(() => typeof window.setDefaultSelections === 'function', { timeout: 30000 });
  await page.waitForTimeout(4000);

  // Import knight config
  await page.evaluate(cfg => navigator.clipboard.writeText(JSON.stringify(cfg)), knightConfig);
  await page.waitForTimeout(500);
  await page.getByText('Import from Clipboard (JSON)').click();
  await page.waitForTimeout(3000);

  // Export and check what was accepted
  await page.getByText('Export to Clipboard (JSON)').click();
  await page.waitForTimeout(500);
  const exported = JSON.parse(await page.evaluate(() => navigator.clipboard.readText()));

  console.log('=== IMPORTED SELECTIONS (what actually got applied) ===');
  console.log(JSON.stringify(exported.selections, null, 2));
  console.log('\n=== HASH ===');
  console.log(exported.url);

  await browser.close();
};

main().catch(e => { console.error(e); process.exit(1); });

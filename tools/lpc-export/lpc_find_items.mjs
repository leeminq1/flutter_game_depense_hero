/**
 * Clicks armor-related items on LPC site and exports JSON to find correct selections keys.
 */
import { chromium } from 'playwright';

const generatorUrl = 'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/';

const exportConfig = async (page) => {
  await page.getByText('Export to Clipboard (JSON)').click();
  await page.waitForTimeout(500);
  const json = await page.evaluate(() => navigator.clipboard.readText());
  const parsed = JSON.parse(json);
  return parsed.selections;
};

const main = async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ permissions: ['clipboard-read', 'clipboard-write'] });
  const page = await context.newPage();
  await page.goto(generatorUrl, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForFunction(() => typeof window.setDefaultSelections === 'function', { timeout: 30000 });
  await page.waitForTimeout(4000);

  // Get all item thumbnail elements in chooser column
  const chooserItems = await page.evaluate(() => {
    const chooser = document.getElementById('chooser-column');
    if (!chooser) return 'NO CHOOSER COLUMN';
    const html = chooser.innerHTML.slice(0, 3000);
    // Find all anchor/button/img elements
    const allEls = Array.from(chooser.querySelectorAll('a, button, img, [class*="item"], [class*="sprite"]'));
    return {
      html: html,
      count: allEls.length,
      sample: allEls.slice(0, 20).map(el => ({
        tag: el.tagName,
        class: el.className?.slice(0, 60),
        href: el.href,
        src: el.src?.split('/').slice(-3).join('/'),
        text: el.textContent?.trim().slice(0, 30),
      }))
    };
  });
  console.log('CHOOSER COLUMN:', JSON.stringify(chooserItems, null, 2));

  // Try to find items by searching for text "Armour" or "plate"
  const armorItems = await page.evaluate(() => {
    const all = Array.from(document.querySelectorAll('*'));
    const armour = all.filter(el =>
      el.children.length === 0 &&
      el.textContent?.toLowerCase().includes('armour') &&
      el.textContent?.trim().length < 50
    ).slice(0, 10).map(el => ({
      tag: el.tagName,
      class: el.className,
      text: el.textContent?.trim(),
      parentClass: el.parentElement?.className,
    }));
    return armour;
  });
  console.log('\nARMOUR TEXT ELEMENTS:', JSON.stringify(armorItems, null, 2));

  await browser.close();
};

main().catch(e => { console.error(e); process.exit(1); });

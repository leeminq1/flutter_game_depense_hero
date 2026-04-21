import { chromium } from 'playwright';

const generatorUrl = 'https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/';

const main = async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(generatorUrl, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForFunction(() => typeof window.setDefaultSelections === 'function', { timeout: 30000 });
  await page.waitForTimeout(3000);

  await page.evaluate(() => window.setDefaultSelections());
  await page.waitForTimeout(2000);

  // Wait longer for item grid to render
  await page.waitForTimeout(5000);

  const result = await page.evaluate(() => {
    const hash = window.location.hash;

    // Find all img elements (item thumbnails)
    const imgs = Array.from(document.querySelectorAll('img')).slice(0, 30).map(el => ({
      src: el.src?.split('/').slice(-3).join('/'),
      alt: el.alt,
      classes: el.className,
      parentTag: el.parentElement?.tagName,
      parentClasses: el.parentElement?.className?.slice(0, 60),
      clickable: el.closest('button, a, [role=button], [onclick]') !== null,
    }));

    // Find buttons
    const buttons = Array.from(document.querySelectorAll('button')).slice(0, 20).map(el => ({
      text: el.textContent?.trim().slice(0, 40),
      classes: el.className?.slice(0, 60),
      data: Object.fromEntries([...el.attributes].filter(a => a.name.startsWith('data-')).map(a => [a.name, a.value])),
    }));

    // Get all section/aside IDs to understand layout
    const sections = Array.from(document.querySelectorAll('section, aside, [id]')).slice(0, 20).map(el => ({
      tag: el.tagName, id: el.id, classes: el.className?.slice(0, 60)
    }));

    // Count total imgs in document
    const totalImgs = document.querySelectorAll('img').length;

    return { hash, imgs, buttons, sections, totalImgs };
  });

  console.log('=== HASH ===');
  console.log(result.hash);
  console.log(`\n=== TOTAL IMGS: ${result.totalImgs} ===`);
  console.log(JSON.stringify(result.imgs, null, 2));
  console.log('\n=== BUTTONS ===');
  console.log(JSON.stringify(result.buttons, null, 2));
  console.log('\n=== SECTIONS/IDs ===');
  console.log(JSON.stringify(result.sections, null, 2));

  await browser.close();
};

main().catch(e => { console.error(e); process.exit(1); });

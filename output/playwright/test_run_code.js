const fs = require('fs');
const code = '(() => document.title)()';
(async () => {
  const result = await page.evaluate(code);
  console.log(JSON.stringify({ result }));
})();

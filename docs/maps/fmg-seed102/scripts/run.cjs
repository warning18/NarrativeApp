// usage: node run.cjs <fmgdir> <seed> <snippet.js> [outdir]
// Loads the generator with a seed, runs the snippet's body as an async page function,
// prints its JSON result; if the result has .files {name: text|dataURL}, writes them to outdir.
const fs = require('fs');
const { chromium } = require(process.argv[2] + '/node_modules/playwright');
(async () => {
  const [, , dir, seed, snip, out] = process.argv;
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args: ['--no-sandbox'] });
  const p = await b.newPage({ viewport: { width: 1600, height: 1000 }, deviceScaleFactor: 2 });
  const errs = [];
  p.on('pageerror', e => errs.push(String(e)));
  await p.goto(`http://127.0.0.1:5173/Fantasy-Map-Generator/?seed=${seed}&width=1600&height=1000`, { waitUntil: 'load', timeout: 120000 });
  await p.waitForFunction(() => window.pack && pack.burgs && pack.burgs.length > 1, null, { timeout: 120000 });
  await p.waitForTimeout(1500);
  const body = fs.readFileSync(snip, 'utf8');
  const res = await p.evaluate(`(async () => { ${body} })()`);
  if (res && res.files && out) {
    fs.mkdirSync(out, { recursive: true });
    for (const [n, v] of Object.entries(res.files)) {
      if (typeof v === 'string' && v.startsWith('data:')) fs.writeFileSync(`${out}/${n}`, Buffer.from(v.split(',')[1], 'base64'));
      else fs.writeFileSync(`${out}/${n}`, typeof v === 'string' ? v : JSON.stringify(v, null, 1));
    }
    if (res.screenshot) await p.screenshot({ path: `${out}/${res.screenshot}` });
    delete res.files;
  }
  console.log(JSON.stringify(res).slice(0, 8000));
  if (errs.length) console.log('page errors:', errs.slice(0, 5));
  await b.close();
})().catch(e => { console.error(e); process.exit(1); });

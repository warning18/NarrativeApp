// node search.cjs <fmgdir> <fromSeed> <count>: score seeds for a 3-landmass world with the game's climates
const { chromium } = require(process.argv[2] + '/node_modules/playwright');
(async () => {
  const [, , dir, from, count] = process.argv;
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args: ['--no-sandbox'] });
  const p = await b.newPage({ viewport: { width: 1600, height: 1000 } });
  for (let s = +from; s < +from + +count; s++) {
    try {
      await p.goto(`http://127.0.0.1:5173/Fantasy-Map-Generator/?seed=${s}&width=1600&height=1000`, { waitUntil: 'load', timeout: 90000 });
      await p.waitForFunction(() => window.pack && pack.burgs && pack.burgs.length > 1, null, { timeout: 90000 });
      const r = await p.evaluate(() => {
        const land = pack.features.filter(f => f && f.land && f.cells >= 150).sort((a, b) => b.cells - a.cells);
        const bio = f => { const c = {}; for (let i = 0; i < pack.cells.i.length; i++) if (pack.cells.f[i] === f.i) c[pack.cells.biome[i]] = (c[pack.cells.biome[i]] || 0) + 1; return c; };
        return { tpl: options.generation.template, land: land.map(f => ({ cells: f.cells, bio: bio(f) })) };
      });
      // desired: >=3 landmasses; one with hot desert(1)+temperate(4/6/8); one with tundra/taiga(9/10)+wetland(12); a small third
      const L = r.land;
      const has = (l, ids, n = 15) => ids.reduce((a, i) => a + (l.bio[i] || 0), 0) >= n;
      let score = Math.min(L.length, 4);
      const old = L.findIndex(l => has(l, [1]) && has(l, [4, 6, 8]));
      const ash = L.findIndex((l, i) => i !== old && has(l, [9, 10, 11]) && has(l, [12], 3));
      if (old >= 0) score += 3; if (ash >= 0) score += 3;
      if (L.length >= 3) score += 2;
      console.log(JSON.stringify({ seed: s, score, tpl: r.tpl, n: L.length, old, ash, sizes: L.map(l => l.cells).slice(0, 6) }));
    } catch (e) { console.log(JSON.stringify({ seed: s, err: String(e).slice(0, 80) })); }
  }
  await b.close();
})();

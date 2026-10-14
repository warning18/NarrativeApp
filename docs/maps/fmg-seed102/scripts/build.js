// expects SPEC (prepended). Places the game's landmarks on the generated world, draws its roads, exports.
const BN = (window.biomesData && biomesData.name) || ['Marine','Hot desert','Cold desert','Savanna','Grassland','Tropical seasonal forest','Temperate deciduous forest','Tropical rainforest','Temperate rainforest','Taiga','Tundra','Glacier','Wetland'];
const C = pack.cells, N = C.i.length, P = C.p, W = window.graphWidth || 1600, H = window.graphHeight || 1000;
const nm = Object.assign({ storm: 'The Storm Crossing', heart: 'The Dead Heart', wreck: 'The White Fleet’s Grave', candlehold: 'Candlehold' }, SPEC.names);
const label = Object.assign({}, nm, { hovel: 'Alster', wharf: 'Saltmouth', reliquary: 'The Black Reliquary' });
const lands = pack.features.filter(f => f && f.land && f.cells >= 150).sort((a, b) => b.cells - a.cells);
const FEAT = { OLD: lands[0].i, ASH: lands[1].i, LANT: lands[2].i };
const ocean = pack.features.find(f => f && f.type === 'ocean').i;
const d2 = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1]);
const bbox = {}; for (const k in FEAT) { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (let i = 0; i < N; i++) if (C.f[i] === FEAT[k]) { x0 = Math.min(x0, P[i][0]); x1 = Math.max(x1, P[i][0]); y0 = Math.min(y0, P[i][1]); y1 = Math.max(y1, P[i][1]); } bbox[k] = { x0, x1, y0, y1 }; }
const burgAt = new Map(); for (const b of pack.burgs) if (b && b.i && !b.removed) burgAt.set(b.cell, b);
const placed = {}, cellOf = {}, why = {};
const countryOf = {}; for (const [c, ids] of Object.entries(SPEC.countries)) for (const id of ids) countryOf[id] = c;
const anchor = {};
const order = ['hovel', 'wharf', 'crash', 'camp', 'reliquary', 'cloister', 'anchorage', 'candlehold', 'sleeper', 'wells', 'quarter', 'emberwick', 'spire', 'akagiri', 'rimewell', 'highhearth', 'kindly', 'court', 'wrack', 'greyhithe', 'shore'];
const region = new Int16Array(N).fill(-1); let regionsBuilt = false;
const cIdx = Object.keys(SPEC.countries);
function buildRegions() { // each land cell belongs to the nearest country anchor on the same land
  const anchors = Object.entries(anchor).map(([c, id]) => ({ ci: cIdx.indexOf(c), p: placed[id], f: C.f[cellOf[id]] }));
  for (let i = 0; i < N; i++) { if (C.h[i] < 20) continue; let bd = 1e9; for (const A of anchors) if (A.f === C.f[i]) { const dd = d2(P[i], A.p); if (dd < bd) { bd = dd; region[i] = A.ci; } } }
}
for (const id of order) {
  const r = SPEC.rules[id], f = FEAT[r.land], bb = bbox[r.land], c = countryOf[id], isAnchor = !anchor[c];
  if (!isAnchor && !regionsBuilt) { buildRegions(); regionsBuilt = true; }
  let best = -1e9, bi = -1;
  for (let i = 0; i < N; i++) {
    if (C.f[i] !== f || C.h[i] < 20) continue;
    if (!isAnchor && region[i] !== cIdx.indexOf(c)) continue;
    const p = P[i]; let s = 0;
    if (r.bio) s += r.bio.includes(C.biome[i]) ? 5 : -3;
    if (r.coast) s += C.t[i] === 1 ? 4 : -4;
    if (r.river) s += C.r[i] > 0 ? 3 : 0;
    if (r.high) s += (C.h[i] - 45) / 8;
    const rx = (p[0] - bb.x0) / (bb.x1 - bb.x0 || 1), ry = (p[1] - bb.y0) / (bb.y1 - bb.y0 || 1);
    if (r.north) s += (1 - ry) * 5; if (r.south) s += ry * 4; if (r.east) s += rx * 5;
    const b = burgAt.get(i); if (b) s += 1 + (r.city ? (b.capital ? 3 : 1) : 0);
    if (!isAnchor) s -= d2(p, placed[anchor[c]]) / 40;
    let tooClose = false;
    for (const [o, q] of Object.entries(placed)) { const dd = d2(p, q); if (dd < 32) tooClose = true; if (isAnchor && SPEC.rules[o] && SPEC.rules[o].land === r.land && anchor[countryOf[o]] === o) s -= Math.max(0, 170 - dd) / 12; }
    if (tooClose) continue;
    s += ((i * 2654435761) % 1000) / 1e5;
    if (s > best) { best = s; bi = i; }
  }
  if (bi < 0) return { error: 'no cell for ' + id };
  placed[id] = [P[bi][0], P[bi][1]]; cellOf[id] = bi; if (isAnchor) anchor[c] = id;
  why[id] = { biome: BN[C.biome[bi]], h: C.h[bi], coast: C.t[bi] === 1, river: C.r[bi] > 0, burg: burgAt.get(bi)?.name || null };
}
// districts cluster round their city
const kids = {}; for (const [id, r] of Object.entries(SPEC.rules)) if (r.cluster) (kids[r.cluster] ??= []).push(id);
for (const [par, ks] of Object.entries(kids)) ks.forEach((k, j) => { const a = (j / ks.length) * 2 * Math.PI + 0.4; placed[k] = [placed[par][0] + 9 * Math.cos(a), placed[par][1] + 9 * Math.sin(a)]; cellOf[k] = cellOf[par]; });
// sea places
const water = []; for (let i = 0; i < N; i++) if (C.f[i] === ocean) water.push(i);
const nearestWater = (pt, want = 0) => water.reduce((bi, i) => Math.abs(d2(P[i], pt) - want) < Math.abs(d2(P[bi], pt) - want) ? i : bi, water[0]);
{ const a = placed.wharf, b = placed.camp; const i = nearestWater([(a[0] + b[0]) / 2, (a[1] + b[1]) / 2]); placed.storm = [...P[i]]; cellOf.storm = i; }
{ const i = nearestWater(placed.anchorage, 28); placed.wreck = [...P[i]]; cellOf.wreck = i; }
// roads: Dijkstra over the cell graph
function path(a, b, sea) {
  const s = cellOf[a], t = cellOf[b]; if (s === t) return null;
  if (sea && C.f[s] === C.f[t] && C.h[s] >= 20 && C.h[t] >= 20) return { pts: [placed[a], placed[b]], straight: true }; // a sky-ship hop over its own land
  const sameLand = C.f[s] === C.f[t] && C.h[s] >= 20 && C.h[t] >= 20 && !sea;
  const ok = i => i === s || i === t || (sameLand ? (C.f[i] === C.f[s] && C.h[i] >= 20) : C.h[i] < 20);
  const dist = new Float64Array(N).fill(Infinity), prev = new Int32Array(N).fill(-1), done = new Uint8Array(N);
  dist[s] = 0; const q = [[0, s]];
  while (q.length) { let m = 0; for (let k = 1; k < q.length; k++) if (q[k][0] < q[m][0]) m = k; const [dd, u] = q.splice(m, 1)[0]; if (done[u]) continue; done[u] = 1; if (u === t) break;
    for (const v of C.c[u]) { if (!ok(v) || done[v]) continue; const w = d2(P[u], P[v]) * (sameLand ? 1 + Math.max(0, C.h[v] - 40) / 25 : 1); if (dd + w < dist[v]) { dist[v] = dd + w; prev[v] = u; q.push([dist[v], v]); } } }
  if (prev[t] < 0) return { pts: [placed[a], placed[b]], straight: true };
  const pts = []; for (let u = t; u >= 0; u = prev[u]) pts.push([...P[u]]); pts.reverse(); pts[0] = placed[a]; pts[pts.length - 1] = placed[b];
  return { pts };
}
const chaikin = pts => { let p = pts; for (let k = 0; k < 2; k++) { const o = [p[0]]; for (let i = 0; i < p.length - 1; i++) { const [a, b] = [p[i], p[i + 1]]; o.push([a[0] * .75 + b[0] * .25, a[1] * .75 + b[1] * .25], [a[0] * .25 + b[0] * .75, a[1] * .25 + b[1] * .75]); } o.push(p[p.length - 1]); p = o; } return p; };
const roads = [];
for (const r of SPEC.roads) { const res = path(r.a, r.b, r.sea); if (!res) continue; roads.push({ id: r.id, sea: r.sea || !!res.straight, pts: res.straight ? res.pts : chaikin(res.pts) }); }
// hide generated political layers, keep the land itself
for (const id of ['burgIcons', 'labels', 'routes', 'markers', 'emblems', 'borders', 'regions', 'provs', 'zones', 'cults', 'relig', 'armies', 'journeys', 'goods', 'markets', 'tradeAnimation', 'ruler', 'coordinates', 'gridOverlay', 'population', 'prec', 'temperature', 'cells', 'debug', 'fogging', 'compass'])
  { const g = document.getElementById(id); if (g) g.style.display = 'none'; }
for (const l of ['biomes', 'rivers', 'relief', 'lakes', 'coastline']) { try { if (!Layers.isOn(l)) Layers.show(l); } catch (e) {} }
{ const g = document.getElementById('biomes'); if (g) g.style.display = ''; }
const NS = 'http://www.w3.org/2000/svg', vb = document.getElementById('viewbox');
const old = document.getElementById('gameLayer'); if (old) old.remove();
const G = document.createElementNS(NS, 'g'); G.id = 'gameLayer'; vb.appendChild(G);
const el = (tag, at, parent = G) => { const e = document.createElementNS(NS, tag); for (const k in at) e.setAttribute(k, at[k]); parent.appendChild(e); return e; };
const dpath = pts => 'M' + pts.map(p => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join('L');
for (const r of roads) el('path', { d: dpath(r.pts), fill: 'none', stroke: r.sea ? '#2c4a6b' : '#6b3d1e', 'stroke-width': r.sea ? 1.2 : 1.6, 'stroke-dasharray': r.sea ? '4 3' : '', 'stroke-linecap': 'round', opacity: .9 });
const text = (x, y, s, size, at = {}) => { const t = el('text', Object.assign({ x, y, 'font-size': size, 'font-family': 'Georgia, serif', 'text-anchor': 'middle', fill: '#2b1d12', stroke: '#f4ead2', 'stroke-width': size / 4, 'paint-order': 'stroke', 'stroke-linejoin': 'round' }, at)); t.textContent = s; return t; };
const cityIds = Object.entries(SPEC.rules).filter(([, r]) => r.city).map(([k]) => k);
for (const [id, p] of Object.entries(placed)) {
  const r = SPEC.rules[id] || {}; if (r.cluster) { el('circle', { cx: p[0], cy: p[1], r: 1.6, fill: '#6b3d1e' }); continue; }
  const sea = r.land === 'SEA', city = cityIds.includes(id);
  el('circle', { cx: p[0], cy: p[1], r: city ? 4.2 : 2.8, fill: sea ? '#e8f0f6' : (city ? '#7a1f1f' : '#f4ead2'), stroke: '#2b1d12', 'stroke-width': city ? 1.2 : 1 });
  text(p[0], p[1] - (city ? 8 : 6), label[id], city ? 11 : 9, sea ? { 'font-style': 'italic', fill: '#1f3b57' } : {});
}
const centroid = ids => { const ps = ids.map(i => placed[i]).filter(Boolean); return [ps.reduce((a, p) => a + p[0], 0) / ps.length, ps.reduce((a, p) => a + p[1], 0) / ps.length]; };
for (const [c, ids] of Object.entries(SPEC.countries)) { const ci = cIdx.indexOf(c); let sx = 0, sy = 0, n = 0; for (let i = 0; i < N; i++) if (region[i] === ci) { sx += P[i][0]; sy += P[i][1]; n++; } let [x, y] = n ? [sx / n, sy / n] : centroid(ids); for (let k = 0; k < 6 && Object.values(placed).some(q => Math.abs(q[0] - x) < 60 && Math.abs(q[1] - y) < 12); k++) y += 12; text(x, y, c.toUpperCase(), 9, { 'letter-spacing': 2, fill: '#5b3420', opacity: .75 }); }
const featLabel = (k, s) => { let sx = 0, n = 0; for (let i = 0; i < N; i++) if (C.f[i] === FEAT[k]) { sx += P[i][0]; n++; } const cx = sx / n; let top = 1e9; for (let i = 0; i < N; i++) if (C.f[i] === FEAT[k] && Math.abs(P[i][0] - cx) < 60) top = Math.min(top, P[i][1]); text(cx, top - 14, s, 17, { 'font-style': 'italic', 'letter-spacing': 1.5 }); };
featLabel('OLD', 'The Old Continent'); featLabel('ASH', 'The Ashen Continent'); featLabel('LANT', 'The Lantern Isles');
{ const [x, y] = placed.storm; text(x, y + 26, 'The Narrow Sea', 14, { 'font-style': 'italic', fill: '#1f3b57', 'letter-spacing': 2 }); }
// export data: places, coastlines of the three lands, main rivers
const ring = f => (f.vertices || []).map(v => pack.vertices.p[v]).filter(Boolean).map(p => [+p[0].toFixed(1), +p[1].toFixed(1)]);
const rivers = (pack.rivers || []).filter(rv => rv && rv.cells && [FEAT.OLD, FEAT.ASH, FEAT.LANT].includes(C.f[rv.mouth || rv.cells[0]])).sort((a, b) => (b.length || 0) - (a.length || 0)).slice(0, 12)
  .map(rv => rv.cells.filter(i => i >= 0 && i < N).map(i => [+P[i][0].toFixed(1), +P[i][1].toFixed(1)]));
const data = { seed: window.seed, template: options.generation.template, size: [W, H], places: Object.fromEntries(Object.entries(placed).map(([k, p]) => [k, [+p[0].toFixed(1), +p[1].toFixed(1)]])), lands: { old_continent: ring(lands[0]), ashen_continent: ring(lands[1]), lantern_isles: ring(lands[2]) }, rivers, roads: roads.map(r => ({ id: r.id, sea: r.sea, pts: r.pts.map(p => [+p[0].toFixed(1), +p[1].toFixed(1)]) })), why };
const svg = document.getElementById('map'); const st = document.createElement('style'); st.textContent = 'body > *:not(#map):not(svg){display:none!important} #map{position:fixed;left:0;top:0}'; document.head.appendChild(st); for (const e of document.querySelectorAll('button, .ui-dialog, #optionsTrigger, #helpButton, #mapLayers, #collapsible, #tooltip')) e.style.display = 'none'; vb.setAttribute('transform', '');
const svgText = new XMLSerializer().serializeToString(svg);
return { files: { 'game-map-data.json': JSON.stringify(data), 'game-map.svg': svgText }, screenshot: 'game-map.png', placedCount: Object.keys(placed).length, roads: roads.length, straight: roads.filter(r => r.sea).map(r => r.id), why, ringSizes: Object.fromEntries(Object.entries(data.lands).map(([k, v]) => [k, v.length])), rivers: rivers.length };

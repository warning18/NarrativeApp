#!/usr/bin/env node
'use strict';
// Firebase Events Live: local server. No dependencies, needs only `adb` and Node 18+.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile, spawn } = require('child_process');
const { parseLine } = require('./parser');

const PORT = process.env.PORT || 4455;
const ADB = process.env.ADB || 'adb';
const clients = new Set();
let logcat = null, session = null, seq = 0;
const history = [];

const adb = (args, opts = {}) => new Promise((res, rej) =>
  execFile(ADB, args, { maxBuffer: 64 * 1024 * 1024, encoding: opts.binary ? 'buffer' : 'utf8', timeout: opts.timeout || 15000 },
    (e, out, err) => e ? rej(new Error((err && err.toString().trim()) || e.message)) : res(out)));

const send = (obj) => { const s = `data: ${JSON.stringify(obj)}\n\n`; for (const c of clients) c.write(s); };
const json = (res, code, obj) => { res.writeHead(code, { 'content-type': 'application/json' }); res.end(JSON.stringify(obj)); };
const body = (req) => new Promise((r) => { let b = ''; req.on('data', d => b += d); req.on('end', () => { try { r(JSON.parse(b || '{}')); } catch { r({}); } }); });

async function stop() {
  if (logcat) { logcat.kill(); logcat = null; }
  if (session) {
    await adb(['-s', session.serial, 'shell', 'setprop', 'debug.firebase.analytics.app', '.none.']).catch(() => {});
    session = null;
  }
  send({ type: 'status', running: false });
}

async function start(serial, pkg) {
  await stop();
  if (!/^[\w.]+$/.test(pkg)) throw new Error('Invalid package name');
  const sh = (...a) => adb(['-s', serial, 'shell', ...a]);
  await sh('setprop', 'debug.firebase.analytics.app', pkg);
  await sh('setprop', 'log.tag.FA', 'VERBOSE');
  await sh('setprop', 'log.tag.FA-SVC', 'VERBOSE');
  session = { serial, pkg };
  history.length = 0;
  logcat = spawn(ADB, ['-s', serial, 'logcat', '-v', 'threadtime', '-T', '1', '-s', 'FA:V', 'FA-SVC:V']);
  let buf = '';
  logcat.stdout.on('data', (d) => {
    buf += d; const lines = buf.split('\n'); buf = lines.pop();
    for (const l of lines) {
      const ev = parseLine(l);
      if (ev) { ev.id = ++seq; ev.ts = Date.now(); history.push(ev); if (history.length > 5000) history.shift(); send({ type: 'event', event: ev }); }
    }
  });
  logcat.on('exit', () => { if (logcat) { logcat = null; session = null; send({ type: 'status', running: false, error: 'logcat stopped (device disconnected?)' }); } });
  send({ type: 'status', running: true, serial, pkg });
}

const routes = {
  'GET /api/devices': async () => {
    const out = await adb(['devices', '-l']);
    return out.split('\n').slice(1).filter(l => l.trim()).map(l => {
      const [serial, state, ...rest] = l.trim().split(/\s+/);
      const model = (rest.find(x => x.startsWith('model:')) || '').slice(6);
      return { serial, state, model };
    });
  },
  'POST /api/pair': async (req) => { const b = await body(req); return { out: await adb(['pair', b.addr, b.code]) }; },
  'POST /api/connect': async (req) => { const b = await body(req); return { out: await adb(['connect', b.addr]) }; },
  'GET /api/packages': async (req, url) => {
    const out = await adb(['-s', url.searchParams.get('serial'), 'shell', 'pm', 'list', 'packages', '-3']);
    return out.split('\n').map(l => l.replace('package:', '').trim()).filter(Boolean).sort();
  },
  'POST /api/start': async (req) => { const b = await body(req); await start(b.serial, b.pkg); return { ok: true }; },
  'POST /api/stop': async () => { await stop(); return { ok: true }; },
  'POST /api/clear': async () => { history.length = 0; return { ok: true }; },
};

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x');
  try {
    if (req.method === 'GET' && url.pathname === '/api/stream') {
      res.writeHead(200, { 'content-type': 'text/event-stream', 'cache-control': 'no-cache', connection: 'keep-alive' });
      clients.add(res);
      res.write(`data: ${JSON.stringify({ type: 'status', running: !!session, ...(session || {}) })}\n\n`);
      for (const e of history) res.write(`data: ${JSON.stringify({ type: 'event', event: e })}\n\n`);
      req.on('close', () => clients.delete(res));
      return;
    }
    if (req.method === 'GET' && url.pathname === '/api/screen') {
      const png = await adb(['-s', url.searchParams.get('serial'), 'exec-out', 'screencap', '-p'], { binary: true, timeout: 8000 });
      res.writeHead(200, { 'content-type': 'image/png', 'cache-control': 'no-store' });
      return res.end(png);
    }
    const h = routes[`${req.method} ${url.pathname}`];
    if (h) return json(res, 200, await h(req, url));
    const file = url.pathname === '/' ? 'index.html' : path.normalize(url.pathname).replace(/^(\.\.[/\\])+/, '');
    const full = path.join(__dirname, 'public', file);
    if (!full.startsWith(path.join(__dirname, 'public')) || !fs.existsSync(full)) { res.writeHead(404); return res.end('Not found'); }
    res.writeHead(200, { 'content-type': full.endsWith('.html') ? 'text/html' : 'text/plain' });
    fs.createReadStream(full).pipe(res);
  } catch (e) {
    json(res, 500, { error: e.message });
  }
});

process.on('SIGINT', async () => { await stop(); process.exit(0); });
server.listen(PORT, '127.0.0.1', () => console.log(`Firebase Events Live: http://localhost:${PORT}`));

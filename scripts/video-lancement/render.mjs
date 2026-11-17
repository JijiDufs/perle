// Photographie la page de montage (index.html) image par image dans Google Chrome sans fenêtre.
// usage : node render.mjs <dossier des images> <sortie> <fr|en> [première image] [dernière image] [pas] [vertical|carre]
// La page expose window.DURATION (s), window.FPS et window.renderAt(t) (promesse : tout est prêt à photographier).
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const [assets, out, lang = 'fr', from = '0', to = '', step = '1', format = 'vertical'] = process.argv.slice(2);
const H = format === 'carre' ? 1080 : 1920;
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const port = 9300 + Math.floor(Math.random() * 500);
mkdirSync(out, { recursive: true });
const chrome = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${port}`, '--allow-file-access-from-files', '--hide-scrollbars',
  '--force-device-scale-factor=1', '--autoplay-policy=no-user-gesture-required', '--ignore-gpu-blocklist', '--enable-webgl',
  `--user-data-dir=${resolve(out, '..', '.chrome-' + port)}`, 'about:blank'], { stdio: 'ignore' });

const sleep = ms => new Promise(r => setTimeout(r, ms));
let target;
for (let i = 0; i < 60 && !target; i++) {
  await sleep(250);
  try { target = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find(t => t.type === 'page'); } catch {}
}
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r, { once: true }));
let id = 0; const pending = new Map();
ws.addEventListener('message', e => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  if (m.method === 'Runtime.consoleAPICalled') console.log('[page]', ...m.params.args.map(a => a.value));
  if (m.method === 'Runtime.exceptionThrown') console.log('[page error]', JSON.stringify(m.params.exceptionDetails).slice(0, 400)); });
const send = (method, params = {}) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const evaluate = async expr => { const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true });
  if (r.result?.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails).slice(0, 600)); return r.result?.result?.value; };

await send('Runtime.enable');
await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1080, height: H, deviceScaleFactor: 1, mobile: false });
const url = 'file://' + resolve(new URL('.', import.meta.url).pathname, 'index.html') + `?lang=${lang}&format=${format}&a=${encodeURIComponent('file://' + resolve(assets))}`;
await send('Page.navigate', { url });
for (let i = 0; i < 200; i++) { await sleep(150); if (await evaluate('window.ready === true').catch(() => false)) break; }
const fps = await evaluate('window.FPS'), duration = await evaluate('window.DURATION');
const last = to ? Number(to) : Math.round(duration * fps) - 1;
const t0 = Date.now();
for (let f = Number(from); f <= last; f += Number(step)) {
  await evaluate(`window.renderAt(${f / fps})`);
  // JPEG de qualité 95 : 3 fois plus léger que le PNG (2 100 images par langue à 60 i/s).
  const shot = await send('Page.captureScreenshot', { format: 'jpeg', quality: 95, clip: { x: 0, y: 0, width: 1080, height: H, scale: 1 }, captureBeyondViewport: false });
  writeFileSync(`${out}/${String(f).padStart(5, '0')}.jpg`, Buffer.from(shot.result.data, 'base64'));
  if (f % 60 === 0) console.log(`${f}/${last}  ${((Date.now() - t0) / 1000).toFixed(0)} s`);
}
ws.close(); chrome.kill();
console.log(`images ${from}…${last} → ${out}`);

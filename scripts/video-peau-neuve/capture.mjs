// Photographie une page image par image dans Google Chrome sans fenêtre (montage de la vidéo, ou pearl-inc.app filmé).
// usage : node capture.mjs <url> <sortie> <largeur> <hauteur> [échelle] [script injecté] [première] [dernière] [pas]
// La page, ou le script injecté avant ses propres scripts, expose window.FPS, window.DURATION, window.ready
// et window.renderAt(t) (promesse : l'image de l'instant t est prête à photographier).
import { spawn } from 'node:child_process';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const [url, out, w, h, scale = '1', inject = '', from = '0', to = '', step = '1'] = process.argv.slice(2);
const W = Number(w), H = Number(h), S = Number(scale);
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const port = 9300 + Math.floor(Math.random() * 500), profile = resolve(out, '..', '.chrome-' + port);
mkdirSync(out, { recursive: true });
const chrome = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${port}`, '--allow-file-access-from-files', '--hide-scrollbars',
  '--autoplay-policy=no-user-gesture-required', '--ignore-gpu-blocklist', '--enable-webgl',
  `--user-data-dir=${profile}`, 'about:blank'], { stdio: 'ignore' });

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
// Moins de 600 px de large : un iPhone (écran tactile, pas de survol).
const mobile = W < 600;
await send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: S, mobile });
if (mobile) await send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
if (inject) await send('Page.addScriptToEvaluateOnNewDocument', { source: readFileSync(inject, 'utf8') });
await send('Page.navigate', { url });
for (let i = 0; i < 300; i++) { await sleep(150); if (await evaluate('window.ready === true').catch(() => false)) break; }
const fps = await evaluate('window.FPS'), duration = await evaluate('window.DURATION');
const last = to ? Number(to) : Math.round(duration * fps) - 1;
const t0 = Date.now();
for (let f = Number(from); f <= last; f += Number(step)) {
  await evaluate(`window.renderAt(${f / fps})`);
  // Sans « clip » : ses coordonnées sont celles du document, pas de l'écran (une page défilée sortirait vide).
  const shot = await send('Page.captureScreenshot', { format: 'jpeg', quality: 95, captureBeyondViewport: false });
  writeFileSync(`${out}/${String(f).padStart(5, '0')}.jpg`, Buffer.from(shot.result.data, 'base64'));
  if (f % 60 === 0) console.log(`${f}/${last}  ${((Date.now() - t0) / 1000).toFixed(0)} s`);
}
ws.close(); chrome.kill();
// Le profil Chrome jetable : effacé une fois Chrome fermé (≈ 150 Mo par prise). Ses processus annexes écrivent parfois
// encore dedans : on réessaie, et un échec ne fait jamais échouer la prise (make.sh s'arrêterait).
if (chrome.exitCode === null) await new Promise(r => chrome.once('exit', r));
try { rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 }); } catch {}
console.log(`images ${from}…${last} → ${out}`);

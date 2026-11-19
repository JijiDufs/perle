// Injecté dans pearl-inc.app avant ses scripts (capture.mjs) : une horloge virtuelle, pour filmer le site image par image.
// performance.now, Date.now, l'heure des événements, requestAnimationFrame, setTimeout et les animations CSS avancent
// de 1/60 s par image, quel que soit le temps que prend la capture : l'eau, l'huître et les étincelles restent fluides.
// Le défilement (et, sur le téléphone, le pouce qui ouvre l'huître de « À toi d'ouvrir ») suit un plan : ?plan=…
(() => {
  if (window !== top) return;
  const FPS = 60, STEP = 1000 / FPS;
  const realTimeout = setTimeout.bind(window);
  let vt = 0, rid = 0, last = null;
  const raf = new Map(), timers = new Map(), d0 = Date.now();
  performance.now = () => vt;
  Date.now = () => d0 + vt;
  Object.defineProperty(Event.prototype, 'timeStamp', { configurable: true, get: () => vt });
  window.requestAnimationFrame = cb => (raf.set(++rid, cb), rid);
  window.cancelAnimationFrame = i => raf.delete(i);
  window.setTimeout = (fn, ms = 0, ...a) => (timers.set(++rid, { at: vt + Number(ms || 0), fn, a }), rid);
  window.clearTimeout = i => timers.delete(i);
  function tick() {
    vt += STEP;
    for (const [i, x] of [...timers]) if (x.at <= vt) { timers.delete(i); try { x.fn(...x.a); } catch (e) { console.log('timer', String(e)); } }
    const cbs = [...raf.values()]; raf.clear();
    for (const cb of cbs) try { cb(vt); } catch (e) { console.log('rAF', String(e)); }
    for (const a of document.getAnimations()) {
      if (a.__vt === undefined) { a.__vt = Number(a.currentTime) || 0; a.pause(); }
      a.__vt += STEP; a.currentTime = a.__vt;
    }
  }
  const smooth = x => (x = Math.min(1, Math.max(0, x)), x * x * (3 - 2 * x));
  // Plans : [instant (s), position]. Une position est en pixels, ou [sélecteur, part, décalage] : le haut de l'élément en haut
  // de l'écran, plus une part de (sa hauteur − celle de l'écran) (0 = début, 1 = fin d'une section collante), ou 'center'.
  // drag : le pouce sur #pool, de t0 à t1 (s) ; il pousse de `res` px en `tRes` s (la résistance), puis va jusqu'à `dist` px
  // à vitesse constante (lustre S, sous les 380 °/s de la zone fragile) ; posé à `dy` px au-dessus du bas de #pool.
  const PLANS = {
    survey: { dur: 16, keys: [[0, 0], [16, 'end']] },
    desktop: { dur: 6.6, keys: [[0, 0], [0.5, 0], [3.5, ['#ouverture', 0.95]], [4.3, ['#ouverture', 0.95]], [5.5, ['#strand', 0, -70]], [6.6, ['#strand', 0, -70]]] },
    mobile: { dur: 6.6, keys: [[0, 0], [0.4, 0], [1.5, ['#pool', 'center']], [6.6, ['#pool', 'center']]],
      drag: { t0: 1.8, tRes: 0.45, t1: 3.3, res: 70, dist: 267, dy: 140 } },
  };
  const plan = PLANS[new URLSearchParams(location.search).get('plan') || 'survey'];
  window.FPS = FPS;
  window.DURATION = plan.dur;
  const yOf = p => {
    if (p === 'end') return document.documentElement.scrollHeight - innerHeight;
    if (typeof p === 'number') return p;
    const el = document.querySelector(p[0]), r = el.getBoundingClientRect(), top = r.top + scrollY;
    return (p[1] === 'center' ? top + r.height / 2 - innerHeight / 2 : top + p[1] * Math.max(0, r.height - innerHeight)) + (p[2] || 0);
  };
  const scrollAt = t => {
    const k = plan.keys;
    let i = 1; while (i < k.length - 1 && t > k[i][0]) i++;
    const [t0, a] = k[i - 1], [t1, b] = k[i];
    return yOf(a) + (yOf(b) - yOf(a)) * smooth((t - t0) / Math.max(0.001, t1 - t0));
  };
  let finger = null;  // { x, y } du pouce posé (px dans l'écran)
  function drag(t) {
    const d = plan.drag; if (!d) return;
    const pool = document.getElementById('pool');
    const fire = (type, y) => pool.dispatchEvent(new PointerEvent(type, { pointerId: 7, pointerType: 'touch', isPrimary: true, bubbles: true, cancelable: true, clientX: finger.x, clientY: y }));
    if (!finger && t >= d.t0) {
      const r = pool.getBoundingClientRect();
      finger = { x: r.left + r.width / 2, y: r.bottom - d.dy, up: false };
      console.log('pouce', JSON.stringify({ x: finger.x, y: finger.y, dist: d.dist, vw: innerWidth, vh: innerHeight }));
      fire('pointerdown', finger.y);
    }
    if (!finger || finger.up) return;
    const a = t - d.t0, pushed = a <= d.tRes ? d.res * a / d.tRes : d.res + (d.dist - d.res) * Math.min(1, (a - d.tRes) / (d.t1 - d.t0 - d.tRes));
    fire('pointermove', finger.y - pushed);
    if (t >= d.t1) { finger.up = true; fire('pointerup', finger.y - d.dist); }
  }
  // Les images à l'écran pas encore chargées (une image paresseuse hors de l'écran ne se charge jamais : on ne l'attend pas).
  // 1,5 s au plus : sur le téléphone, une fois le résultat de « À toi d'ouvrir » affiché, une image ne finit jamais.
  const images = () => Promise.race([new Promise(r => realTimeout(r, 1500)), Promise.all([...document.images].filter(i => {
    if (i.complete) return false;
    const r = i.getBoundingClientRect(); return r.bottom > 0 && r.top < innerHeight;
  }).map(i => i.decode().catch(() => {})))]);
  window.renderAt = async t => {
    // Une image saute-t-elle des instants (aperçu à grand pas) ? On fait tourner le site entre les deux.
    const n = last === null ? 1 : Math.max(1, Math.min(240, Math.round((t - last) * FPS)));
    for (let i = 0; i < n; i++) {
      const ti = last === null ? t : last + (t - last) * (i + 1) / n;
      window.scrollTo({ top: Math.round(scrollAt(ti)), behavior: 'instant' });
      drag(ti);
      tick();
    }
    last = t;
    await images();
  };
  // Prêt : page chargée, polices prêtes ; on descend une fois toute la page (images chargées à la demande), puis on remonte.
  addEventListener('load', async () => {
    await document.fonts.ready;
    const end = document.documentElement.scrollHeight;
    // Pas d'au moins 200 px : une fenêtre encore à 0 px de haut au chargement ne doit pas figer la boucle.
    for (let y = 0; y < end; y += Math.max(200, innerHeight / 2)) { window.scrollTo({ top: y, behavior: 'instant' }); tick(); await new Promise(r => realTimeout(r, 30)); }
    await new Promise(r => realTimeout(r, 1500));
    await images();
    window.scrollTo({ top: 0, behavior: 'instant' });
    for (let i = 0; i < 90; i++) tick();
    window.ready = true;
  });
})();

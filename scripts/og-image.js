/* Image d'aperçu des liens (Open Graph, 1200×630) de la page site/index.html.
   Dessinée avec le code de la page (window.PerleArt) : lagon, huître ouverte, perle dorée.
   Lancé par scripts/make-og.sh, ne pas ouvrir à la main. */
(async () => {
  await document.fonts.load('700 100px "Inter"');
  await document.fonts.load('500 36px "Inter"');
  await document.fonts.load('600 26px "Inter"');
  const A = window.PerleArt, W = 1200, H = 630, T = 2.3;
  const canvas = document.getElementById('og');
  const c = canvas.getContext('2d');
  const phases = A.randomPhases(() => 0.37);
  const lagoon = new A.Lagoon();
  const hx = 870, hy = H / 2 + 28, L = 228;

  lagoon.draw(c, W, H, T, { x: hx, y: hy, size: L * 0.75 });
  A.drawShellExterior(c, hx, hy, Math.PI, L * 0.98, phases);
  A.drawNacre(c, hx, hy, Math.PI, L * 0.98 * 0.88, phases, T);
  A.drawShellExterior(c, hx, hy, 0, L, phases);
  A.drawNacre(c, hx, hy, 0, L * 0.88, phases, T);
  A.drawFlesh(c, hx, hy, 0, L, phases);

  const pearl = A.pearlById('golden');
  const px = hx + L * 0.5, py = hy, pr = L * 0.16;
  const radial = (x, y, r0, r1, stops) => {
    const g = c.createRadialGradient(x, y, r0, x, y, r1);
    stops.forEach(([at, color]) => g.addColorStop(at, color));
    return g;
  };

  // Halo chaud sous la perle
  c.save();
  c.globalCompositeOperation = 'screen';
  c.fillStyle = radial(px, py, pr * 0.8, pr * 4.2, [[0, 'rgba(255,205,90,.85)'], [0.45, 'rgba(255,190,70,.28)'], [1, 'rgba(255,190,70,0)']]);
  c.beginPath(); c.arc(px, py, pr * 4.2, 0, Math.PI * 2); c.fill();
  c.restore();
  A.drawPearl(c, px, py, pr, pearl, false);
  lagoon.drawOverlay(c, W, H);

  // Lumière qui baigne la scène, et éclats autour de la perle
  c.save();
  c.globalCompositeOperation = 'screen';
  c.fillStyle = radial(px, py, 0, L * 1.7, [[0, 'rgba(255,214,120,.38)'], [0.5, 'rgba(255,200,90,.12)'], [1, 'rgba(255,200,90,0)']]);
  c.fillRect(0, 0, W, H);
  [[-1.1, 1.5, 9], [0.5, 1.75, 6], [2.4, 1.45, 7], [3.7, 1.9, 5]].forEach(([angle, distance, size]) => {
    const x = px + Math.cos(angle) * pr * distance, y = py + Math.sin(angle) * pr * distance;
    c.fillStyle = radial(x, y, 0, size * 2.2, [[0, 'rgba(255,250,225,.95)'], [1, 'rgba(255,240,200,0)']]);
    c.beginPath(); c.arc(x, y, size * 2.2, 0, Math.PI * 2); c.fill();
    c.strokeStyle = 'rgba(255,250,230,.8)'; c.lineWidth = 1.4;
    c.beginPath();
    c.moveTo(x - size * 2.4, y); c.lineTo(x + size * 2.4, y);
    c.moveTo(x, y - size * 2.4); c.lineTo(x, y + size * 2.4);
    c.stroke();
  });
  c.restore();

  // Voile à gauche pour lire le texte ; textes sans langue (même image en FR et en EN)
  const veil = c.createLinearGradient(0, 0, 640, 0);
  veil.addColorStop(0, 'rgba(2,24,34,.66)'); veil.addColorStop(0.75, 'rgba(2,24,34,.15)'); veil.addColorStop(1, 'rgba(2,24,34,0)');
  c.fillStyle = veil; c.fillRect(0, 0, 640, H);
  c.fillStyle = '#fff'; c.shadowColor = 'rgba(0,20,30,.45)'; c.shadowBlur = 18;
  c.font = '700 100px Inter'; c.fillText('Pearl Inc.', 72, 292);
  c.shadowBlur = 10;
  c.font = '500 36px Inter'; c.fillStyle = 'rgba(255,255,255,.92)'; c.fillText('iPhone Duo', 76, 352);
  c.font = '600 26px Inter'; c.fillStyle = 'rgba(255,255,255,.78)'; c.fillText('pearl-inc.app', 76, 560);
  document.title = 'ready';
})();

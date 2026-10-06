// Carte bathymétrique de la suite du voyage, dessinée en Canvas 2D.

type Ctx = CanvasRenderingContext2D;

function island(c: Ctx, x: number, y: number, rx: number, ry: number, hue: 'sand' | 'reef' | 'deep'): void {
  const shore = hue === 'sand' ? '#c1ad7d' : hue === 'reef' ? '#4d978a' : '#344d66';
  const land = hue === 'sand' ? '#597d6c' : hue === 'reef' ? '#2b716a' : '#192b47';
  c.save();
  c.translate(x, y);
  c.rotate(-0.28);
  c.beginPath();
  c.moveTo(-rx * 0.92, -ry * 0.05);
  c.bezierCurveTo(-rx * 0.68, -ry * 0.88, rx * 0.06, -ry * 1.02, rx * 0.57, -ry * 0.62);
  c.bezierCurveTo(rx * 1.15, -ry * 0.17, rx * 0.86, ry * 0.72, rx * 0.24, ry * 0.78);
  c.bezierCurveTo(-rx * 0.42, ry * 1.08, -rx * 1.05, ry * 0.54, -rx * 0.92, -ry * 0.05);
  c.closePath();
  c.fillStyle = shore;
  c.fill();
  c.beginPath();
  c.moveTo(-rx * 0.72, -ry * 0.08);
  c.bezierCurveTo(-rx * 0.5, -ry * 0.72, rx * 0.08, -ry * 0.81, rx * 0.42, -ry * 0.5);
  c.bezierCurveTo(rx * 0.86, -ry * 0.14, rx * 0.64, ry * 0.56, rx * 0.16, ry * 0.59);
  c.bezierCurveTo(-rx * 0.36, ry * 0.8, -rx * 0.82, ry * 0.4, -rx * 0.72, -ry * 0.08);
  c.closePath();
  c.fillStyle = land;
  c.fill();
  c.globalAlpha = 0.4;
  c.strokeStyle = '#d9d8ad';
  c.lineWidth = 1;
  for (let i = 0; i < 3; i++) {
    c.beginPath();
    c.ellipse(-rx * 0.04, ry * 0.02, rx * (0.25 + i * 0.13), ry * (0.22 + i * 0.13), 0.2, 0.1, Math.PI * 1.75);
    c.stroke();
  }
  c.restore();
}

function wreck(c: Ctx, x: number, y: number, size: number): void {
  c.save();
  c.translate(x, y);
  c.rotate(-0.22);
  c.fillStyle = '#725c4b';
  c.beginPath();
  c.moveTo(-size, -size * 0.2);
  c.lineTo(size * 0.72, -size * 0.18);
  c.lineTo(size * 0.9, size * 0.1);
  c.lineTo(size * 0.4, size * 0.42);
  c.lineTo(-size * 0.62, size * 0.34);
  c.closePath();
  c.fill();
  c.strokeStyle = '#ddc18b';
  c.lineWidth = 1.4;
  c.beginPath();
  c.moveTo(-size * 0.78, -size * 0.03);
  c.lineTo(size * 0.55, 0);
  c.moveTo(-size * 0.35, -size * 0.08);
  c.lineTo(-size * 0.1, -size * 0.7);
  c.lineTo(size * 0.02, -size * 0.08);
  c.moveTo(size * 0.38, -size * 0.12);
  c.lineTo(size * 0.56, -size * 0.52);
  c.stroke();
  c.restore();
}

/** La carte raconte la suite, sans ouvrir de zone ni modifier les tirages de la V1. */
export function drawWorldMap(c: Ctx, w: number, h: number): void {
  const sea = c.createLinearGradient(0, 0, w, h);
  sea.addColorStop(0, '#123e4a');
  sea.addColorStop(0.53, '#0b2938');
  sea.addColorStop(1, '#101e34');
  c.fillStyle = sea;
  c.fillRect(0, 0, w, h);

  c.save();
  c.globalAlpha = 0.22;
  c.strokeStyle = '#9ccbb9';
  c.lineWidth = 1;
  const contours = [
    [0.22, 0.72, 0.25, 0.15], [0.22, 0.72, 0.34, 0.2], [0.22, 0.72, 0.43, 0.27],
    [0.55, 0.42, 0.13, 0.1], [0.55, 0.42, 0.22, 0.15], [0.55, 0.42, 0.31, 0.21],
    [0.77, 0.72, 0.16, 0.1], [0.77, 0.72, 0.25, 0.17], [0.77, 0.72, 0.34, 0.23],
  ];
  for (const [cx, cy, rx, ry] of contours) {
    c.beginPath();
    c.ellipse(w * cx, h * cy, w * rx, h * ry, -0.3, 0, Math.PI * 2);
    c.stroke();
  }
  c.restore();

  island(c, w * 0.22, h * 0.72, w * 0.12, h * 0.075, 'sand');
  island(c, w * 0.55, h * 0.42, w * 0.105, h * 0.073, 'reef');
  wreck(c, w * 0.78, h * 0.28, Math.min(w, h) * 0.075);
  island(c, w * 0.77, h * 0.72, w * 0.1, h * 0.065, 'deep');

  c.save();
  c.strokeStyle = 'rgba(244, 215, 155, 0.85)';
  c.lineWidth = 2;
  c.setLineDash([3, 7]);
  c.beginPath();
  c.moveTo(w * 0.22, h * 0.72);
  c.bezierCurveTo(w * 0.34, h * 0.83, w * 0.4, h * 0.35, w * 0.55, h * 0.42);
  c.bezierCurveTo(w * 0.67, h * 0.5, w * 0.68, h * 0.18, w * 0.78, h * 0.28);
  c.stroke();
  c.restore();

  // Rose des vents gravée dans le fond de la carte.
  const x = w * 0.88;
  const y = h * 0.88;
  c.strokeStyle = 'rgba(245, 226, 183, 0.62)';
  c.lineWidth = 1;
  c.beginPath();
  c.moveTo(x, y - 14); c.lineTo(x + 4, y); c.lineTo(x, y + 14); c.lineTo(x - 4, y); c.closePath();
  c.moveTo(x - 12, y); c.lineTo(x, y - 3); c.lineTo(x + 12, y); c.lineTo(x, y + 3); c.closePath();
  c.stroke();
}

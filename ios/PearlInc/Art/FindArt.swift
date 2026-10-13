import SwiftUI

/// Les trouvailles en relief, portées presque ligne à ligne de src/art/finds.ts (même rendu que la webapp).
/// Chaque objet est dessiné dans un repère unité (il tient dans [-1, 1]) avec la même lumière, en haut à gauche :
/// dégradé de matière, liseré clair, reflet net et ombre de contact, pour qu'ils aient du volume.
/// `t` (secondes) anime quelques détails. Aucune règle de jeu ici.
enum FindArt {
    private static let TAU = Double.pi * 2

    /// Dessine une trouvaille centrée en (x, y) ; `size` = demi-largeur de l'objet.
    static func draw(_ context: GraphicsContext, _ x: Double, _ y: Double, _ size: Double, id: String, t: Double = 0) {
        let c = Canvas2D(context)
        c.save()
        c.translate(x, y)
        c.scale(size, size)
        switch id {
        case "tong": tong(c, t)
        case "ticket": ticket(c, t)
        case "cadenas": cadenas(c, t)
        case "canard": canard(c, t)
        case "lunettes": lunettes(c, t)
        case "clapet": clapet(c, t)
        case "dentier": dentier(c, t)
        case "usb": usb(c, t)
        case "nain": nain(c, t)
        case "poisson-clown": poissonClown(c, t)
        case "fourchette": fourchette(c, t)
        case "cube": cube(c, t)
        case "jeton": jeton(c, t)
        case "champignon": champignon(c, t)
        case "ballon": ballon(c, t)
        case "chapeau": chapeau(c, t)
        case "aileron": aileron(c, t)
        case "cartouche": cartouche(c, t)
        case "boussole": boussole(c, t)
        case "anneau": anneau(c, t)
        case "coeur-ocean": coeurOcean(c, t)
        case "piece-or": pieceOr(c, t)
        case "bouteille": bouteille(c, t)
        case "pierre-brute": pierreBrute(c, t)
        case "cle-epave": cleEpave(c, t)
        default: unknown(c, t)
        }
        c.restore()
    }

    // MARK: - Outils de matière

    /// Dégradé de matière le long de la lumière : clair en haut à gauche, sombre en bas à droite.
    private static func lit(_ c: Canvas2D, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ base: String, _ k: Double = 0.35) -> Gradient2D {
        let g = c.createLinearGradient(x0, y0, x1, y1)
        g.addColorStop(0, tintColor(base, k))
        g.addColorStop(0.45, base)
        g.addColorStop(1, shadeColor(base, k))
        return g
    }

    /// Volume arrondi, éclairé en haut à gauche.
    private static func ball(_ c: Canvas2D, _ x: Double, _ y: Double, _ r: Double, _ base: String, _ k: Double = 0.45) -> Gradient2D {
        let g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.05, x, y, r * 1.05)
        g.addColorStop(0, tintColor(base, min(0.9, k + 0.2)))
        g.addColorStop(0.45, base)
        g.addColorStop(1, shadeColor(base, k))
        return g
    }

    /// Reflet blanc, doux sur les bords.
    private static func gloss(_ c: Canvas2D, _ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ rot: Double = -0.6, _ alpha: Double = 0.75) {
        c.save()
        c.translate(x, y)
        c.rotate(rot)
        c.scale(rx, ry)
        let g = c.createRadialGradient(0, 0, 0, 0, 0, 1)
        g.addColorStop(0, "rgba(255,255,255,\(alpha))")
        g.addColorStop(0.55, "rgba(255,255,255,\(alpha * 0.35))")
        g.addColorStop(1, "rgba(255,255,255,0)")
        c.fillStyle = g
        c.beginPath()
        c.arc(0, 0, 1, 0, TAU)
        c.fill()
        c.restore()
    }

    /// Ombre de contact, sous l'objet.
    private static func contact(_ c: Canvas2D, _ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ alpha: Double = 0.4) {
        c.save()
        c.translate(x, y)
        c.scale(rx, ry)
        let g = c.createRadialGradient(0, 0, 0, 0, 0, 1)
        g.addColorStop(0, "rgba(8,6,4,\(alpha))")
        g.addColorStop(0.6, "rgba(8,6,4,\(alpha * 0.45))")
        g.addColorStop(1, "rgba(8,6,4,0)")
        c.fillStyle = g
        c.beginPath()
        c.arc(0, 0, 1, 0, TAU)
        c.fill()
        c.restore()
    }

    /// Contour sombre et fin : détache l'objet du décor.
    private static func ink(_ c: Canvas2D, _ width: Double = 0.022, _ color: String = "rgba(28,18,10,.6)") {
        c.lineWidth = width
        c.strokeStyle = color
        c.lineJoin = "round"
        c.lineCap = "round"
        c.stroke()
    }

    /// Liseré de lumière sur le chemin en cours : clair côté lumière, effacé côté ombre.
    private static func rim(_ c: Canvas2D, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ width: Double = 0.03, _ alpha: Double = 0.7) {
        let g = c.createLinearGradient(x0, y0, x1, y1)
        g.addColorStop(0, "rgba(255,255,255,\(alpha))")
        g.addColorStop(0.5, "rgba(255,255,255,0)")
        c.lineWidth = width
        c.strokeStyle = g
        c.stroke()
    }

    private static func rr(_ c: Canvas2D, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) {
        c.beginPath()
        c.moveTo(x + r, y)
        c.arcTo(x + w, y, x + w, y + h, r)
        c.arcTo(x + w, y + h, x, y + h, r)
        c.arcTo(x, y + h, x, y, r)
        c.arcTo(x, y, x + w, y, r)
        c.closePath()
    }

    private static func heart(_ c: Canvas2D, _ x: Double, _ y: Double, _ s: Double) {
        c.beginPath()
        c.moveTo(x, y + s * 0.9)
        c.bezierCurveTo(x - s * 1.25, y + s * 0.1, x - s * 1.0, y - s * 1.0, x, y - s * 0.38)
        c.bezierCurveTo(x + s * 1.0, y - s * 1.0, x + s * 1.25, y + s * 0.1, x, y + s * 0.9)
        c.closePath()
    }

    /// Texte dans le repère unité : on dessine à l'échelle 100, comme la webapp.
    private static func label(_ c: Canvas2D, _ text: String, _ x: Double, _ y: Double, _ size: Double, _ color: String, _ weight: Int = 700, serif: Bool = false) {
        c.save()
        c.scale(0.01, 0.01)
        c.setFont(size: (size * 100).rounded(), weight: weight, serif: serif)
        c.fillStyle = color
        c.fillText(text, x * 100, y * 100)
        c.restore()
    }

    /// Texte en relief (frappé dans le métal) : un liseré clair décalé sous la lettre.
    private static func embossed(_ c: Canvas2D, _ text: String, _ x: Double, _ y: Double, _ size: Double, _ color: String, _ light: String, _ weight: Int = 800, serif: Bool = false) {
        label(c, text, x + 0.012, y + 0.014, size, light, weight, serif: serif)
        label(c, text, x, y, size, color, weight, serif: serif)
    }

    /// Petit éclat en étoile à quatre branches.
    private static func sparkle(_ c: Canvas2D, _ x: Double, _ y: Double, _ r: Double, _ alpha: Double) {
        if alpha <= 0.01 { return }
        c.save()
        c.globalCompositeOperation = "lighter"
        c.fillStyle = "rgba(255,255,255,\(alpha))"
        c.beginPath()
        c.moveTo(x, y - r)
        c.quadraticCurveTo(x, y, x + r, y)
        c.quadraticCurveTo(x, y, x, y + r)
        c.quadraticCurveTo(x, y, x - r, y)
        c.quadraticCurveTo(x, y, x, y - r)
        c.fill()
        c.restore()
    }

    // MARK: - Les objets (mêmes noms et même ordre que src/art/finds.ts)

    private static func tong(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.08, 0.12, 0.5, 0.92, 0.32);
      c.save();
      c.rotate(-0.35);
      let sole = { (dx: Double, dy: Double) in
        c.beginPath();
        c.moveTo(dx, -0.84 + dy);
        c.bezierCurveTo(0.36 + dx, -0.86 + dy, 0.44 + dx, -0.4 + dy, 0.3 + dx, -0.02 + dy);
        c.bezierCurveTo(0.22 + dx, 0.3 + dy, 0.34 + dx, 0.62 + dy, 0.2 + dx, 0.82 + dy);
        c.bezierCurveTo(0.08 + dx, 0.95 + dy, -0.18 + dx, 0.95 + dy, -0.26 + dx, 0.76 + dy);
        c.bezierCurveTo(-0.34 + dx, 0.55 + dy, -0.2 + dx, 0.3 + dy, -0.28 + dx, -0.02 + dy);
        c.bezierCurveTo(-0.38 + dx, -0.42 + dy, -0.34 + dx, -0.82 + dy, dx, -0.84 + dy);
        c.closePath();
      };
      // Épaisseur de la semelle, puis le dessus.
      sole(0.03, 0.07);
      c.fillStyle = "#185a7a";
      c.fill();
      sole(0, 0);
      c.fillStyle = lit(c, -0.4, -0.8, 0.4, 0.9, "#3fb6e8", 0.3);
      c.fill();
      ink(c, 0.018);
      // Creux laissés par le pied.
      c.fillStyle = "rgba(10,40,60,.13)";
      c.beginPath();
      c.ellipse(-0.02, -0.48, 0.17, 0.23, 0, 0, TAU);
      c.ellipse(-0.03, 0.6, 0.15, 0.18, 0, 0, TAU);
      c.fill();
      // Lanière en Y : ombre portée, matière, reflet.
      let strap = { (dx: Double, dy: Double) in
        c.beginPath();
        c.moveTo(-0.29 + dx, 0.02 + dy);
        c.quadraticCurveTo(-0.2 + dx, -0.42 + dy, dx, -0.56 + dy);
        c.quadraticCurveTo(0.2 + dx, -0.42 + dy, 0.3 + dx, 0.02 + dy);
      };
      c.lineCap = "round";
      strap(0.035, 0.05);
      c.lineWidth = 0.14;
      c.strokeStyle = "rgba(0,30,50,.3)";
      c.stroke();
      strap(0, 0);
      c.strokeStyle = lit(c, -0.3, -0.55, 0.3, 0.05, "#ff6f9f", 0.3);
      c.stroke();
      strap(-0.015, -0.03);
      c.lineWidth = 0.03;
      c.strokeStyle = "rgba(255,255,255,.45)";
      c.stroke();
      c.beginPath();
      c.arc(0, -0.56, 0.075, 0, TAU);
      c.fillStyle = ball(c, 0, -0.56, 0.075, "#ff6f9f");
      c.fill();
      c.restore();
    }

    private static func ticket(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.06, 0.14, 0.9, 0.55, 0.3);
      c.save();
      c.rotate(-0.18);
      let w = 0.85;
      let h = 0.46;
      let notch = 0.12;
      let shape = { (dx: Double, dy: Double) in
        c.beginPath();
        c.moveTo(-w + dx, -h + dy);
        c.lineTo(w + dx, -h + dy);
        c.arc(w + dx, dy, notch, -Double.pi / 2, Double.pi / 2, true);
        c.lineTo(w + dx, h + dy);
        c.lineTo(-w + dx, h + dy);
        c.arc(-w + dx, dy, notch, Double.pi / 2, -Double.pi / 2, true);
        c.closePath();
      };
      shape(0.025, 0.04);
      c.fillStyle = "rgba(90,35,0,.35)";
      c.fill();
      shape(0, 0);
      c.fillStyle = lit(c, -w, -h, w, h, "#ffb070", 0.25);
      c.fill();
      ink(c, 0.015, "rgba(120,50,10,.6)");
      // Cadre intérieur et pointillés de découpe.
      rr(c, -0.7, -0.36, 1.05, 0.72, 0.04);
      c.lineWidth = 0.012;
      c.strokeStyle = "rgba(140,60,20,.55)";
      c.stroke();
      c.setLineDash([0.04, 0.035]);
      c.beginPath();
      c.moveTo(0.46, -0.42);
      c.lineTo(0.46, 0.42);
      c.stroke();
      c.setLineDash([]);
      label(c, "MANÈGE", -0.17, -0.15, 0.17, "#8a3b12", 400, serif: true);
      label(c, "1 TOUR", -0.17, 0.14, 0.19, "#b2461a", 900);
      c.save();
      c.translate(0.64, 0);
      c.rotate(-Double.pi / 2);
      label(c, "N° 0042", 0, 0, 0.085, "#8a3b12", 800);
      c.restore();
      // Papier un peu froissé : un pli clair.
      c.beginPath();
      c.moveTo(-0.3, -0.46);
      c.lineTo(-0.1, 0.46);
      c.lineWidth = 0.02;
      c.strokeStyle = "rgba(255,240,220,.35)";
      c.stroke();
      c.restore();
    }

    private static func cadenas(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.78, 0.55, 0.13, 0.42);
      // Anse en acier.
      let shackle = {
        c.beginPath();
        c.moveTo(-0.3, 0.02);
        c.lineTo(-0.3, -0.4);
        c.arc(0, -0.4, 0.3, Double.pi, 0);
        c.lineTo(0.3, 0.02);
      };
      shackle();
      c.lineCap = "butt";
      c.lineWidth = 0.13;
      c.strokeStyle = "#4c545b";
      c.stroke();
      shackle();
      c.lineWidth = 0.09;
      c.strokeStyle = lit(c, -0.3, -0.75, 0.3, 0, "#c9d1d8", 0.4);
      c.stroke();
      c.beginPath();
      c.arc(-0.012, -0.41, 0.29, Double.pi * 1.08, Double.pi * 1.55);
      c.lineWidth = 0.022;
      c.strokeStyle = "rgba(255,255,255,.7)";
      c.stroke();
      // Corps en cœur, en laiton.
      heart(c, 0.03, 0.27, 0.5);
      c.fillStyle = "rgba(70,40,5,.6)";
      c.fill();
      heart(c, 0, 0.22, 0.5);
      c.fillStyle = ball(c, -0.05, 0.15, 0.62, "#d9a441", 0.45);
      c.fill();
      ink(c, 0.022, "rgba(70,40,5,.7)");
      heart(c, 0, 0.22, 0.5);
      rim(c, -0.5, -0.2, 0.3, 0.5, 0.03, 0.75);
      embossed(c, "J + M", 0, 0.12, 0.17, "rgba(105,62,8,.9)", "rgba(255,230,160,.55)", 400, serif: true);
      // Trou de serrure.
      c.beginPath();
      c.arc(0, 0.34, 0.045, 0, TAU);
      c.moveTo(-0.022, 0.36);
      c.lineTo(0.022, 0.36);
      c.lineTo(0.036, 0.47);
      c.lineTo(-0.036, 0.47);
      c.closePath();
      c.fillStyle = "#2a1a06";
      c.fill();
      gloss(c, -0.24, 0.0, 0.13, 0.06, -0.7, 0.85);
    }

    private static func canard(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.72, 0.72, 0.13, 0.42);
      let body = {
        c.beginPath();
        c.moveTo(-0.78, 0.02);
        c.bezierCurveTo(-0.86, -0.28, -0.62, -0.24, -0.5, -0.06);
        c.bezierCurveTo(-0.2, -0.05, 0.1, 0.0, 0.35, -0.08);
        c.bezierCurveTo(0.7, -0.15, 0.8, 0.25, 0.62, 0.46);
        c.bezierCurveTo(0.4, 0.7, -0.35, 0.72, -0.56, 0.5);
        c.bezierCurveTo(-0.76, 0.34, -0.74, 0.2, -0.78, 0.02);
        c.closePath();
      };
      body();
      c.fillStyle = ball(c, -0.1, 0.12, 0.9, "#ffd23a", 0.42);
      c.fill();
      ink(c, 0.02, "rgba(120,70,0,.6)");
      // Aile.
      c.beginPath();
      c.moveTo(-0.36, 0.2);
      c.bezierCurveTo(-0.1, 0.04, 0.2, 0.14, 0.22, 0.32);
      c.bezierCurveTo(0.05, 0.48, -0.25, 0.45, -0.36, 0.2);
      c.fillStyle = lit(c, -0.3, 0.1, 0.2, 0.5, "#f4bb1c", 0.25);
      c.fill();
      ink(c, 0.014, "rgba(150,90,0,.5)");
      // Tête.
      c.beginPath();
      c.arc(0.3, -0.38, 0.34, 0, TAU);
      c.fillStyle = ball(c, 0.3, -0.38, 0.34, "#ffd23a", 0.42);
      c.fill();
      ink(c, 0.02, "rgba(120,70,0,.6)");
      // Bec.
      c.beginPath();
      c.moveTo(0.58, -0.37);
      c.quadraticCurveTo(0.86, -0.43, 0.92, -0.3);
      c.quadraticCurveTo(0.82, -0.17, 0.58, -0.23);
      c.closePath();
      c.fillStyle = lit(c, 0.58, -0.43, 0.92, -0.17, "#ff8a1f", 0.3);
      c.fill();
      ink(c, 0.016, "rgba(150,60,0,.6)");
      c.beginPath();
      c.moveTo(0.6, -0.3);
      c.lineTo(0.88, -0.31);
      c.lineWidth = 0.012;
      c.strokeStyle = "rgba(150,60,0,.6)";
      c.stroke();
      // Œil.
      c.beginPath();
      c.arc(0.38, -0.46, 0.066, 0, TAU);
      c.fillStyle = "#1b1b24";
      c.fill();
      c.beginPath();
      c.arc(0.36, -0.48, 0.022, 0, TAU);
      c.fillStyle = "#fff";
      c.fill();
      gloss(c, 0.18, -0.56, 0.12, 0.06, -0.6, 0.85);
      gloss(c, -0.3, -0.02, 0.22, 0.06, -0.12, 0.55);
    }

    private static func lunettes(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.55, 0.85, 0.12, 0.3);
      c.save();
      c.rotate(-0.08);
      // Branches, en arrière.
      c.beginPath();
      c.moveTo(-0.84, -0.12);
      c.lineTo(-0.97, 0.3);
      c.moveTo(0.84, -0.12);
      c.lineTo(0.97, 0.3);
      c.lineWidth = 0.05;
      c.strokeStyle = "#a82c60";
      c.lineCap = "round";
      c.stroke();
      // Le seul verre qui reste, teinté rose, avec son reflet.
      heart(c, -0.45, 0.02, 0.36);
      c.fillStyle = "rgba(255,80,140,.5)";
      c.fill();
      c.save();
      heart(c, -0.45, 0.02, 0.36);
      c.clip();
      let sheen = c.createLinearGradient(-0.8, -0.3, -0.1, 0.35);
      sheen.addColorStop(0.3, "rgba(255,255,255,0)");
      sheen.addColorStop(0.42, "rgba(255,255,255,.55)");
      sheen.addColorStop(0.55, "rgba(255,255,255,0)");
      c.fillStyle = sheen;
      c.fillRect(-0.9, -0.5, 0.9, 1);
      c.restore();
      // Monture : deux cœurs.
      for x in [-0.45, 0.45] {
        heart(c, x + 0.02, 0.05, 0.36);
        c.lineWidth = 0.1;
        c.strokeStyle = "rgba(90,10,40,.35)";
        c.stroke();
        heart(c, x, 0.02, 0.36);
        c.lineWidth = 0.09;
        c.strokeStyle = lit(c, x - 0.4, -0.35, x + 0.4, 0.4, "#ff5c9a", 0.3);
        c.stroke();
      }
      c.beginPath();
      c.moveTo(-0.12, -0.12);
      c.quadraticCurveTo(0, -0.2, 0.12, -0.12);
      c.lineWidth = 0.06;
      c.strokeStyle = "#e04585";
      c.stroke();
      gloss(c, -0.64, -0.17, 0.08, 0.03, -0.7, 0.9);
      gloss(c, 0.26, -0.17, 0.08, 0.03, -0.7, 0.9);
      c.restore();
    }

    private static func clapet(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.05, 0.84, 0.45, 0.1, 0.42);
      c.save();
      c.rotate(0.12);
      // Moitié du bas : le clavier.
      rr(c, -0.28, 0.08, 0.6, 0.76, 0.1);
      c.fillStyle = "rgba(20,25,30,.4)";
      c.fill();
      rr(c, -0.3, 0.05, 0.6, 0.76, 0.1);
      c.fillStyle = lit(c, -0.3, 0.05, 0.3, 0.8, "#a9b4bf", 0.35);
      c.fill();
      ink(c, 0.016);
      c.beginPath();
      c.ellipse(0, 0.17, 0.1, 0.045, 0, 0, TAU);
      c.fillStyle = ball(c, 0, 0.17, 0.1, "#5d6a75");
      c.fill();
      for row in stride(from: Double(0), to: Double(4), by: 1) {
        for col in stride(from: Double(0), to: Double(3), by: 1) {
          rr(c, -0.21 + col * 0.15, 0.27 + row * 0.12, 0.12, 0.08, 0.03);
          c.fillStyle = lit(c, -0.2, 0.27, 0.2, 0.75, "#e8edf1", 0.2);
          c.fill();
          ink(c, 0.008, "rgba(40,50,60,.45)");
        }
      }
      // Charnière.
      rr(c, -0.32, -0.03, 0.64, 0.11, 0.05);
      c.fillStyle = lit(c, -0.32, -0.03, 0.32, 0.08, "#7f8a95", 0.35);
      c.fill();
      ink(c, 0.014);
      // Moitié du haut : l'écran, allumé.
      rr(c, -0.3, -0.84, 0.6, 0.8, 0.1);
      c.fillStyle = lit(c, -0.3, -0.84, 0.3, -0.04, "#b9c4ce", 0.35);
      c.fill();
      ink(c, 0.016);
      rr(c, -0.22, -0.72, 0.44, 0.52, 0.04);
      let screen = c.createLinearGradient(0, -0.72, 0, -0.2);
      screen.addColorStop(0, "#2f6f7f");
      screen.addColorStop(1, "#15303c");
      c.fillStyle = screen;
      c.fill();
      let blink = 0.75 + 0.25 * sin(t * 3);
      label(c, "12:07", 0, -0.6, 0.1, "rgba(220,255,245,\(blink))", 800);
      label(c, "1 message", 0, -0.44, 0.06, "#9ff0d0", 700);
      label(c, "non lu", 0, -0.35, 0.05, "#9ff0d0", 600);
      rr(c, -0.08, -0.8, 0.16, 0.025, 0.012);
      c.fillStyle = "#4b5560";
      c.fill();
      gloss(c, -0.12, -0.7, 0.16, 0.05, -0.5, 0.45);
      c.restore();
    }

    private static func dentier(_ c: Canvas2D, _ t: Double) {
        contact(c, 0.03, 0.7, 0.75, 0.13, 0.38)
        let curve = { (x: Double) -> Double in 0.32 * x * x }
        let teeth = 8.0
        let tooth = { (i: Double, upper: Bool) in
            let x = (i - (teeth - 1) / 2) * 0.165
            let front = 1 - abs(i - (teeth - 1) / 2) / teeth
            let h = 0.17 + front * 0.08
            let w = 0.14
            let y = upper ? -0.2 - curve(x) : 0.3 - curve(x) - h
            rr(c, x - w / 2, y, w, h, 0.05)
            c.fillStyle = lit(c, x - w / 2, y, x + w / 2, y + h, "#f3eee0", 0.22)
            c.fill()
            ink(c, 0.012, "rgba(120,100,70,.55)")
        }
        let gum = { (top: (Double) -> Double, bottom: (Double) -> Double) in
            c.beginPath()
            for k in 0...24 {
                let x = -0.72 + (Double(k) / 24) * 1.44
                if k == 0 { c.moveTo(x, top(x)) } else { c.lineTo(x, top(x)) }
            }
            for k in stride(from: 24, through: 0, by: -1) {
                let x = -0.72 + (Double(k) / 24) * 1.44
                c.lineTo(x, bottom(x) + 0.018 * cos(((x + 0.66) / 0.165) * TAU))
            }
            c.closePath()
        }
        // Mâchoire du haut : dents, puis gencive par-dessus leur racine.
        for i in 0..<Int(teeth) { tooth(Double(i), true) }
        gum({ -0.56 - curve($0) * 0.9 }, { -0.18 - curve($0) })
        c.fillStyle = lit(c, -0.6, -0.7, 0.6, -0.1, "#e8798a", 0.3)
        c.fill()
        ink(c, 0.016, "rgba(110,30,40,.6)")
        // Mâchoire du bas, entrouverte.
        for i in 0..<Int(teeth) { tooth(Double(i), false) }
        gum({ 0.28 - curve($0) }, { 0.56 - curve($0) * 0.8 })
        c.fillStyle = lit(c, -0.6, 0.25, 0.6, 0.6, "#e2707f", 0.3)
        c.fill()
        ink(c, 0.016, "rgba(110,30,40,.6)")
        gloss(c, -0.3, -0.42, 0.22, 0.05, -0.15, 0.55)
        gloss(c, -0.1, 0.0, 0.26, 0.035, 0, 0.6)
    }

    private static func usb(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.06, 0.2, 0.9, 0.38, 0.3);
      c.save();
      c.rotate(-0.42);
      // Connecteur métallique.
      rr(c, 0.48, -0.17, 0.42, 0.34, 0.03);
      c.fillStyle = lit(c, 0.48, -0.17, 0.9, 0.17, "#cfd6dc", 0.4);
      c.fill();
      ink(c, 0.014);
      for y in [-0.09, 0.03] {
        rr(c, 0.64, y, 0.09, 0.06, 0.01);
        c.fillStyle = "#2b3138";
        c.fill();
      }
      // Corps.
      rr(c, -0.83, -0.22, 1.38, 0.52, 0.14);
      c.fillStyle = "rgba(0,0,0,.4)";
      c.fill();
      rr(c, -0.85, -0.26, 1.38, 0.52, 0.14);
      c.fillStyle = lit(c, -0.85, -0.26, 0.5, 0.26, "#30333f", 0.4);
      c.fill();
      ink(c, 0.016, "rgba(0,0,0,.7)");
      // Étiquette.
      rr(c, -0.64, -0.17, 0.98, 0.34, 0.04);
      c.fillStyle = lit(c, -0.64, -0.17, 0.34, 0.17, "#f4efe2", 0.12);
      c.fill();
      label(c, "NE PAS", -0.15, -0.065, 0.11, "#c0262d", 900);
      label(c, "OUVRIR", -0.15, 0.08, 0.13, "#c0262d", 900);
      // Diode qui clignote.
      let on = 0.5 + 0.5 * sin(t * 4);
      drawGlow(c, -0.75, 0, 0.12, "#50ff96", 0.5 * on);
      c.beginPath();
      c.arc(-0.75, 0, 0.032, 0, TAU);
      c.fillStyle = "rgba(80,255,150,\(0.45 + 0.55 * on))";
      c.fill();
      gloss(c, -0.3, -0.21, 0.42, 0.025, 0, 0.55);
      c.restore();
    }

    private static func nain(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.02, 0.86, 0.45, 0.1, 0.45);
      for x in [-0.14, 0.14] {
        c.beginPath();
        c.ellipse(x, 0.8, 0.13, 0.07, 0, 0, TAU);
        c.fillStyle = ball(c, x, 0.8, 0.13, "#4a2e1c");
        c.fill();
      }
      // Tunique.
      c.beginPath();
      c.moveTo(-0.34, 0.78);
      c.quadraticCurveTo(-0.4, 0.2, -0.18, 0.04);
      c.lineTo(0.18, 0.04);
      c.quadraticCurveTo(0.4, 0.2, 0.34, 0.78);
      c.closePath();
      c.fillStyle = lit(c, -0.35, 0.05, 0.35, 0.8, "#2f6fc4", 0.35);
      c.fill();
      ink(c);
      rr(c, -0.355, 0.48, 0.71, 0.09, 0.03);
      c.fillStyle = "#3a2416";
      c.fill();
      rr(c, -0.065, 0.465, 0.13, 0.12, 0.02);
      c.lineWidth = 0.025;
      c.strokeStyle = "#e8c050";
      c.stroke();
      // Barbe.
      c.beginPath();
      c.moveTo(-0.27, -0.14);
      c.bezierCurveTo(-0.36, 0.2, -0.12, 0.42, 0, 0.5);
      c.bezierCurveTo(0.12, 0.42, 0.36, 0.2, 0.27, -0.14);
      c.closePath();
      c.fillStyle = ball(c, -0.05, 0.05, 0.5, "#f2efe9", 0.28);
      c.fill();
      ink(c, 0.018, "rgba(90,80,70,.5)");
      // Visage, nez, yeux, joues.
      c.beginPath();
      c.arc(0, -0.2, 0.2, 0, TAU);
      c.fillStyle = ball(c, 0, -0.2, 0.2, "#f1b48f", 0.35);
      c.fill();
      ink(c, 0.016);
      for x in [-0.08, 0.08] {
        c.beginPath();
        c.arc(x, -0.25, 0.022, 0, TAU);
        c.fillStyle = "#20140e";
        c.fill();
        c.beginPath();
        c.arc(x * 1.4, -0.15, 0.045, 0, TAU);
        c.fillStyle = "rgba(230,90,80,.35)";
        c.fill();
      }
      c.beginPath();
      c.arc(0, -0.15, 0.065, 0, TAU);
      c.fillStyle = ball(c, 0, -0.15, 0.065, "#e8866a", 0.35);
      c.fill();
      // Moustache.
      c.beginPath();
      c.ellipse(-0.08, -0.07, 0.09, 0.04, 0.25, 0, TAU);
      c.ellipse(0.08, -0.07, 0.09, 0.04, -0.25, 0, TAU);
      c.fillStyle = "#ece7df";
      c.fill();
      // Bonnet pointu.
      c.beginPath();
      c.moveTo(-0.29, -0.3);
      c.quadraticCurveTo(-0.16, -0.76, 0.1, -0.95);
      c.quadraticCurveTo(0.1, -0.6, 0.3, -0.3);
      c.quadraticCurveTo(0, -0.38, -0.29, -0.3);
      c.closePath();
      c.fillStyle = lit(c, -0.3, -0.9, 0.3, -0.3, "#d8342b", 0.35);
      c.fill();
      ink(c);
      gloss(c, -0.1, -0.6, 0.06, 0.16, 0.45, 0.6);
    }

    // ---------- Clins d'œil ----------

    private static func poissonClown(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.03, 0.64, 0.75, 0.12, 0.32);
      let body = {
        c.beginPath();
        c.moveTo(0.78, 0);
        c.bezierCurveTo(0.72, -0.44, 0.05, -0.52, -0.45, -0.12);
        c.lineTo(-0.84, -0.4);
        c.quadraticCurveTo(-0.72, 0, -0.84, 0.4);
        c.lineTo(-0.45, 0.12);
        c.bezierCurveTo(0.05, 0.52, 0.72, 0.44, 0.78, 0);
        c.closePath();
      };
      // Nageoire dorsale, derrière.
      c.beginPath();
      c.moveTo(-0.15, -0.3);
      c.quadraticCurveTo(0.12, -0.66, 0.44, -0.33);
      c.closePath();
      c.fillStyle = lit(c, -0.1, -0.6, 0.4, -0.3, "#ff8a2a", 0.3);
      c.fill();
      ink(c, 0.03, "#1b1414");
      body();
      c.fillStyle = ball(c, 0.25, -0.1, 0.85, "#ff7a1a", 0.4);
      c.fill();
      c.save();
      body();
      c.clip();
      for (x, w) in [(0.42, 0.12), (0.0, 0.15), (-0.45, 0.1)] {
        c.beginPath();
        c.ellipse(x, 0, w, 0.62, 0, 0, TAU);
        c.fillStyle = "#fbfbf7";
        c.fill();
        c.lineWidth = 0.035;
        c.strokeStyle = "#1b1414";
        c.stroke();
      }
      let belly = c.createLinearGradient(0, -0.4, 0, 0.45);
      belly.addColorStop(0.45, "rgba(120,40,0,0)");
      belly.addColorStop(1, "rgba(120,40,0,.3)");
      c.fillStyle = belly;
      c.fillRect(-1, -0.5, 2, 1);
      c.restore();
      body();
      ink(c, 0.025, "#1b1414");
      // Nageoire pectorale et œil.
      c.beginPath();
      c.ellipse(0.2, 0.17, 0.14, 0.07, 0.5, 0, TAU);
      c.fillStyle = "#ff9a3c";
      c.fill();
      ink(c, 0.02, "#1b1414");
      c.beginPath();
      c.arc(0.56, -0.08, 0.075, 0, TAU);
      c.fillStyle = "#111";
      c.fill();
      c.beginPath();
      c.arc(0.54, -0.1, 0.025, 0, TAU);
      c.fillStyle = "#fff";
      c.fill();
      gloss(c, 0.3, -0.26, 0.25, 0.06, -0.15, 0.55);
    }

    private static func fourchette(_ c: Canvas2D, _ t: Double) {
        contact(c, 0.05, 0.08, 0.32, 0.88, 0.3)
        c.save()
        c.rotate(0.55)
        let steel = { lit(c, -0.25, -0.9, 0.25, 0.9, "#bcc6cf", 0.45) }
        for i in 0..<4 {
            rr(c, -0.215 + Double(i) * 0.12, -0.92, 0.07, 0.45, 0.035)
            c.fillStyle = steel()
            c.fill()
            ink(c, 0.012, "rgba(40,50,60,.6)")
        }
        let handle = { (close: Bool) in
            c.beginPath()
            c.moveTo(-0.215, -0.55)
            c.quadraticCurveTo(-0.22, -0.28, -0.045, -0.16)
            c.lineTo(-0.05, 0.2)
            c.quadraticCurveTo(-0.11, 0.6, -0.09, 0.84)
            c.quadraticCurveTo(0, 0.95, 0.09, 0.84)
            c.quadraticCurveTo(0.11, 0.6, 0.05, 0.2)
            c.lineTo(0.045, -0.16)
            c.quadraticCurveTo(0.22, -0.28, 0.215, -0.55)
            if close { c.closePath() }
        }
        handle(true)
        c.fillStyle = steel()
        c.fill()
        handle(false)
        ink(c, 0.012, "rgba(40,50,60,.6)")
        // Reflet le long du manche, motif gravé au bout.
        c.beginPath()
        c.moveTo(-0.015, -0.14)
        c.lineTo(-0.035, 0.78)
        c.lineWidth = 0.022
        c.strokeStyle = "rgba(255,255,255,.6)"
        c.stroke()
        c.beginPath()
        c.ellipse(0, 0.74, 0.035, 0.07, 0, 0, TAU)
        c.lineWidth = 0.012
        c.strokeStyle = "rgba(60,70,80,.5)"
        c.stroke()
        gloss(c, -0.1, -0.42, 0.1, 0.04, 0, 0.7)
        c.restore()
    }

    private static func cube(_ c: Canvas2D, _ t: Double) {
        contact(c, 0.03, 0.62, 0.72, 0.13, 0.45)
        typealias V = (Double, Double)
        let a = 0.56
        let e1: V = (0.866 * a, 0.5 * a)
        let e2: V = (-0.866 * a, 0.5 * a)
        let e3: V = (0, a)
        let top: V = (0, -0.56)
        func at(_ o: V, _ u: V, _ v: V, _ i: Double, _ j: Double) -> V { (o.0 + u.0 * i + v.0 * j, o.1 + u.1 * i + v.1 * j) }
        let colors = ["W": "#f4f4f0", "Y": "#ffd23f", "R": "#e03a3a", "O": "#ff8c1a", "B": "#2f6fd8", "G": "#2fb35a"]
        // Dessus : presque fini.
        let faces: [(o: V, u: V, v: V, light: Double, stickers: [String])] = [
            (top, e1, e2, 0.25, ["Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "R"]),
            (at(top, e1, e2, 0, 1), e1, e3, 0, ["B", "R", "G", "O", "B", "W", "G", "G", "O"]),
            (at(top, e1, e2, 1, 1), (-e2.0, -e2.1), e3, -0.3, ["R", "W", "O", "B", "G", "R", "W", "O", "B"]),
        ]
        for face in faces {
            let quad = { (i0: Double, j0: Double, i1: Double, j1: Double) in
                let p = [at(face.o, face.u, face.v, i0, j0), at(face.o, face.u, face.v, i1, j0),
                         at(face.o, face.u, face.v, i1, j1), at(face.o, face.u, face.v, i0, j1)]
                c.beginPath()
                c.moveTo(p[0].0, p[0].1)
                for q in p.dropFirst() { c.lineTo(q.0, q.1) }
                c.closePath()
            }
            quad(0, 0, 1, 1)
            c.fillStyle = "#16161c"
            c.fill()
            ink(c, 0.02, "#0a0a0e")
            for (n, sticker) in face.stickers.enumerated() {
                let i = Double(n % 3)
                let j = Double(n / 3)
                let g = 0.07
                quad((i + g) / 3, (j + g) / 3, (i + 1 - g) / 3, (j + 1 - g) / 3)
                let base = colors[sticker] ?? "#ffffff"
                c.fillStyle = face.light >= 0 ? tintColor(base, face.light) : shadeColor(base, -face.light)
                c.fill()
            }
        }
        gloss(c, -0.12, -0.5, 0.2, 0.06, 0.5, 0.55)
    }

    private static func jeton(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.82, 0.7, 0.12, 0.42);
      c.beginPath();
      c.ellipse(0.035, 0.06, 0.78, 0.8, 0, 0, TAU);
      c.fillStyle = "#8f600f";
      c.fill();
      c.beginPath();
      c.ellipse(0, 0, 0.78, 0.8, 0, 0, TAU);
      c.fillStyle = ball(c, 0, 0, 0.85, "#f2c14e", 0.42);
      c.fill();
      ink(c, 0.02, "rgba(90,55,5,.7)");
      // Couronne en relief et perles du bord.
      c.beginPath();
      c.ellipse(0, 0, 0.62, 0.64, 0, 0, TAU);
      c.lineWidth = 0.05;
      c.strokeStyle = "rgba(120,75,5,.55)";
      c.stroke();
      c.beginPath();
      c.ellipse(-0.012, -0.014, 0.62, 0.64, 0, 0, TAU);
      c.lineWidth = 0.02;
      c.strokeStyle = "rgba(255,240,180,.6)";
      c.stroke();
      for k in stride(from: Double(0), to: Double(28), by: 1) {
        let a = (k / 28) * TAU;
        c.beginPath();
        c.arc(cos(a) * 0.71, sin(a) * 0.73, 0.022, 0, TAU);
        c.fillStyle = "rgba(255,235,170,.75)";
        c.fill();
      }
      embossed(c, "CONTINUE", 0, -0.2, 0.16, "#7a4d07", "rgba(255,240,190,.7)", 900);
      embossed(c, "?", 0, 0.06, 0.3, "#7a4d07", "rgba(255,240,190,.7)", 900);
      // Le compte à rebours ne s'arrête jamais.
      embossed(c, String(9 - Int(floor(t)) % 10), 0, 0.38, 0.13, "#9b2d0c", "rgba(255,240,190,.6)", 900);
      gloss(c, -0.32, -0.44, 0.26, 0.1, -0.6, 0.7);
    }

    private static func champignon(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.03, 0.84, 0.55, 0.11, 0.42);
      c.beginPath();
      c.moveTo(-0.34, 0.1);
      c.quadraticCurveTo(-0.42, 0.8, 0, 0.82);
      c.quadraticCurveTo(0.42, 0.8, 0.34, 0.1);
      c.closePath();
      c.fillStyle = lit(c, -0.4, 0.1, 0.4, 0.82, "#f3e2c4", 0.28);
      c.fill();
      ink(c);
      for x in [-0.14, 0.07] {
        rr(c, x, 0.26, 0.07, 0.22, 0.035);
        c.fillStyle = "#1d1410";
        c.fill();
        c.beginPath();
        c.arc(x + 0.025, 0.31, 0.014, 0, TAU);
        c.fillStyle = "#fff";
        c.fill();
      }
      let cap = {
        c.beginPath();
        c.moveTo(-0.84, 0.18);
        c.bezierCurveTo(-0.92, -0.56, -0.4, -0.86, 0, -0.86);
        c.bezierCurveTo(0.4, -0.86, 0.92, -0.56, 0.84, 0.18);
        c.quadraticCurveTo(0, 0.34, -0.84, 0.18);
        c.closePath();
      };
      cap();
      c.fillStyle = ball(c, -0.1, -0.35, 0.95, "#e8322e", 0.45);
      c.fill();
      c.save();
      cap();
      c.clip();
      for (x, y, r) in [(0, -0.48, 0.22), (-0.6, -0.12, 0.18), (0.6, -0.12, 0.18), (-0.32, 0.12, 0.09), (0.34, 0.14, 0.08)] {
        c.beginPath();
        c.ellipse(x, y, r, r * 0.88, 0, 0, TAU);
        c.fillStyle = ball(c, x, y, r, "#fbf8f2", 0.22);
        c.fill();
      }
      c.restore();
      cap();
      ink(c, 0.025);
      gloss(c, -0.42, -0.55, 0.22, 0.09, -0.6, 0.7);
    }

    private static func ballon(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.86, 0.62, 0.12, 0.45);
      c.beginPath();
      c.arc(0, 0, 0.78, 0, TAU);
      c.fillStyle = ball(c, 0, 0, 0.8, "#efe8da", 0.42);
      c.fill();
      c.save();
      c.beginPath();
      c.arc(0, 0, 0.78, 0, TAU);
      c.clip();
      // Coutures des panneaux.
      c.lineWidth = 0.018;
      c.strokeStyle = "rgba(120,100,70,.55)";
      for off in [-0.18, 0.12] {
        c.beginPath();
        c.moveTo(-0.85, -0.2 + off);
        c.bezierCurveTo(-0.3, -0.62 + off, 0.4, -0.6 + off, 0.85, -0.25 + off);
        c.stroke();
      }
      c.beginPath();
      c.moveTo(0.35, -0.85);
      c.bezierCurveTo(0.7, -0.3, 0.72, 0.3, 0.42, 0.85);
      c.stroke();
      // Le visage, peint à la main.
      let paint = "rgba(160,42,30,.68)";
      c.lineCap = "round";
      c.strokeStyle = paint;
      c.lineWidth = 0.09;
      for (x0, y0, x1, y1) in [(-0.3, -0.12, -0.38, -0.5), (-0.12, -0.18, -0.14, -0.6), (0.06, -0.18, 0.1, -0.6), (0.24, -0.12, 0.32, -0.48)] {
        c.beginPath();
        c.moveTo(x0, y0);
        c.lineTo(x1, y1);
        c.stroke();
      }
      c.beginPath();
      c.ellipse(-0.02, 0.12, 0.36, 0.3, 0.1, 0, TAU);
      c.fillStyle = "rgba(160,42,30,.22)";
      c.fill();
      c.fillStyle = paint;
      for x in [-0.14, 0.1] {
        c.beginPath();
        c.ellipse(x, 0.02, 0.05, 0.065, 0, 0, TAU);
        c.fill();
      }
      c.beginPath();
      c.arc(-0.02, 0.12, 0.2, 0.25, Double.pi - 0.25);
      c.lineWidth = 0.05;
      c.stroke();
      c.restore();
      c.beginPath();
      c.arc(0, 0, 0.78, 0, TAU);
      ink(c, 0.02);
      gloss(c, -0.3, -0.4, 0.22, 0.11, -0.6, 0.8);
    }

    private static func chapeau(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.44, 0.92, 0.22, 0.35);
      // Le bord.
      c.beginPath();
      c.ellipse(0, 0.2, 0.92, 0.42, 0, 0, TAU);
      c.fillStyle = lit(c, -0.9, -0.2, 0.9, 0.6, "#e9c46a", 0.3);
      c.fill();
      ink(c, 0.018, "rgba(110,70,10,.6)");
      c.lineWidth = 0.01;
      c.strokeStyle = "rgba(150,100,30,.4)";
      for k in [0.92, 0.84, 0.76, 0.68] {
        c.beginPath();
        c.ellipse(0, 0.2, 0.92 * k, 0.42 * k, 0, 0, TAU);
        c.stroke();
      }
      // La calotte.
      let dome = {
        c.beginPath();
        c.moveTo(-0.46, 0.12);
        c.bezierCurveTo(-0.5, -0.56, 0.5, -0.56, 0.46, 0.12);
        c.ellipse(0, 0.12, 0.46, 0.18, 0, 0, Double.pi);
        c.closePath();
      };
      dome();
      c.fillStyle = ball(c, -0.12, -0.22, 0.6, "#efcd78", 0.35);
      c.fill();
      c.save();
      dome();
      c.clip();
      c.lineWidth = 0.01;
      c.strokeStyle = "rgba(150,100,30,.35)";
      for k in stride(from: Double(1), to: Double(7), by: 1) {
        c.beginPath();
        c.ellipse(0, 0.12 - k * 0.07, 0.46, 0.18, 0, 0, Double.pi);
        c.stroke();
      }
      // Le ruban rouge.
      c.beginPath();
      c.ellipse(0, 0.04, 0.47, 0.18, 0, 0, Double.pi);
      c.lineWidth = 0.13;
      c.strokeStyle = lit(c, -0.45, 0, 0.45, 0.25, "#d0302b", 0.3);
      c.stroke();
      c.restore();
      dome();
      ink(c, 0.018, "rgba(110,70,10,.6)");
      gloss(c, -0.2, -0.24, 0.16, 0.08, -0.6, 0.55);
    }

    private static func aileron(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.03, 0.74, 0.85, 0.14, 0.42);
      // Sangle de fixation.
      rr(c, -0.8, 0.5, 1.6, 0.17, 0.085);
      c.fillStyle = lit(c, -0.8, 0.5, 0.8, 0.67, "#30343a", 0.35);
      c.fill();
      ink(c, 0.014);
      let fin = {
        c.beginPath();
        c.moveTo(-0.62, 0.56);
        c.bezierCurveTo(-0.3, 0.2, -0.05, -0.55, 0.25, -0.86);
        c.bezierCurveTo(0.22, -0.4, 0.3, 0.1, 0.62, 0.56);
        c.closePath();
      };
      fin();
      c.fillStyle = lit(c, -0.5, -0.8, 0.6, 0.56, "#7d8fa0", 0.42);
      c.fill();
      ink(c, 0.02);
      c.beginPath();
      c.moveTo(-0.58, 0.52);
      c.bezierCurveTo(-0.28, 0.2, -0.04, -0.52, 0.22, -0.8);
      c.lineWidth = 0.028;
      c.strokeStyle = "rgba(255,255,255,.5)";
      c.stroke();
      // Couture de moulage.
      c.beginPath();
      c.moveTo(0.22, -0.78);
      c.bezierCurveTo(0.12, -0.3, 0.05, 0.2, 0.0, 0.54);
      c.setLineDash([0.03, 0.03]);
      c.lineWidth = 0.012;
      c.strokeStyle = "rgba(30,40,50,.45)";
      c.stroke();
      c.setLineDash([]);
      // Étiquette de prix encore accrochée.
      c.beginPath();
      c.moveTo(0.36, 0.3);
      c.lineTo(0.5, 0.18);
      c.lineWidth = 0.01;
      c.strokeStyle = "#ddd";
      c.stroke();
      c.save();
      c.translate(0.58, 0.14);
      c.rotate(0.35);
      rr(c, -0.12, -0.07, 0.26, 0.14, 0.025);
      c.fillStyle = "#f4e9cf";
      c.fill();
      ink(c, 0.008);
      label(c, "2,99 €", 0.01, 0, 0.065, "#a3271f", 900);
      c.restore();
    }

    private static func cartouche(_ c: Canvas2D, _ t: Double) {
        contact(c, 0.05, 0.86, 0.7, 0.11, 0.42)
        c.save()
        c.rotate(-0.06)
        rr(c, -0.63, -0.79, 1.32, 1.6, 0.08)
        c.fillStyle = "rgba(0,0,0,.35)"
        c.fill()
        rr(c, -0.66, -0.82, 1.32, 1.6, 0.08)
        c.fillStyle = lit(c, -0.66, -0.82, 0.66, 0.78, "#8d8f96", 0.32)
        c.fill()
        ink(c, 0.016)
        // Stries de prise.
        for i in 0..<7 {
            rr(c, -0.5, -0.74 + Double(i) * 0.045, 1.0, 0.02, 0.01)
            c.fillStyle = "rgba(40,40,48,.4)"
            c.fill()
        }
        // L'étiquette : un coucher de soleil en gros pixels.
        rr(c, -0.5, -0.38, 1.0, 0.86, 0.03)
        let sky = c.createLinearGradient(0, -0.2, 0, 0.48)
        sky.addColorStop(0, "#24307a")
        sky.addColorStop(0.6, "#d0457e")
        sky.addColorStop(1, "#ff9a4a")
        c.fillStyle = sky
        c.fill()
        let px = 0.06
        c.fillStyle = "#ffd23f"
        let sun = ["..##..", ".####.", "######", "######", ".####.", "..##.."]
        for (j, row) in sun.enumerated() {
            for (i, cell) in row.enumerated() where cell == "#" {
                c.fillRect(0.06 + Double(i) * px * 0.75, -0.16 + Double(j) * px * 0.75, px * 0.75, px * 0.75)
            }
        }
        c.fillStyle = "#2a1640"
        let hills: [Double] = [5, 4, 3, 3, 4, 5, 6, 5, 4, 4, 5, 6, 6, 5, 5, 6]
        for (i, hgt) in hills.enumerated() { c.fillRect(-0.5 + Double(i) * 0.0625, 0.48 - hgt * 0.04, 0.0626, hgt * 0.04) }
        rr(c, -0.5, -0.38, 1.0, 0.17, 0.03)
        c.fillStyle = "#111"
        c.fill()
        label(c, "AVENTURE 8 BITS", 0, -0.295, 0.075, "#ffd23f", 900)
        // Contacts dorés.
        rr(c, -0.42, 0.6, 0.84, 0.14, 0.02)
        c.fillStyle = "#2a2b30"
        c.fill()
        for i in 0..<10 {
            rr(c, -0.38 + Double(i) * 0.08, 0.63, 0.04, 0.09, 0.005)
            c.fillStyle = "#d6a63b"
            c.fill()
        }
        gloss(c, -0.4, -0.58, 0.3, 0.05, -0.3, 0.45)
        c.restore()
    }

    private static func boussole(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.04, 0.82, 0.72, 0.12, 0.45);
      // Bélière.
      c.beginPath();
      c.arc(0, -0.88, 0.11, Double.pi * 0.9, Double.pi * 2.1);
      c.lineWidth = 0.055;
      c.strokeStyle = lit(c, -0.1, -1, 0.1, -0.8, "#c99a3a", 0.4);
      c.stroke();
      rr(c, -0.07, -0.82, 0.14, 0.1, 0.03);
      c.fillStyle = lit(c, -0.07, -0.82, 0.07, -0.72, "#c99a3a", 0.4);
      c.fill();
      // Boîtier en laiton.
      c.beginPath();
      c.arc(0.03, 0.06, 0.74, 0, TAU);
      c.fillStyle = "#5e400d";
      c.fill();
      c.beginPath();
      c.arc(0, 0, 0.74, 0, TAU);
      c.fillStyle = ball(c, 0, 0, 0.8, "#d4a443", 0.45);
      c.fill();
      ink(c, 0.02, "rgba(70,45,5,.7)");
      // Cadran.
      c.beginPath();
      c.arc(0, 0, 0.58, 0, TAU);
      let dial = c.createRadialGradient(-0.15, -0.2, 0.05, 0, 0, 0.6);
      dial.addColorStop(0, "#fbf3dc");
      dial.addColorStop(1, "#d6c49a");
      c.fillStyle = dial;
      c.fill();
      c.lineWidth = 0.04;
      c.strokeStyle = "rgba(80,50,10,.45)";
      c.stroke();
      for k in stride(from: Double(0), to: Double(32), by: 1) {
        let a = (k / 32) * TAU;
        let long = k % 8 == 0 ? 0.08 : 0.04;
        c.beginPath();
        c.moveTo(cos(a) * 0.54, sin(a) * 0.54);
        c.lineTo(cos(a) * (0.54 - long), sin(a) * (0.54 - long));
        c.lineWidth = 0.01;
        c.strokeStyle = "rgba(90,60,20,.7)";
        c.stroke();
      }
      for k in stride(from: Double(0), to: Double(8), by: 1) {
        let a = (k / 8) * TAU - Double.pi / 2;
        let r = k % 2 == 0 ? 0.36 : 0.22;
        c.beginPath();
        c.moveTo(0, 0);
        c.lineTo(cos(a - 0.2) * 0.08, sin(a - 0.2) * 0.08);
        c.lineTo(cos(a) * r, sin(a) * r);
        c.closePath();
        c.fillStyle = k % 2 == 0 ? "#8a6a3a" : "#c8a86a";
        c.fill();
      }
      label(c, "N", 0, -0.44, 0.1, "#8b1e1e", 400, serif: true);
      label(c, "E", 0.44, 0, 0.09, "#5a4120", 400, serif: true);
      label(c, "S", 0, 0.44, 0.09, "#5a4120", 400, serif: true);
      label(c, "O", -0.44, 0, 0.09, "#5a4120", 400, serif: true);
      // L'aiguille cherche autre chose que le nord.
      c.save();
      c.rotate(2.1 + 0.25 * sin(t * 1.7) + 0.08 * sin(t * 5.3));
      c.beginPath();
      c.moveTo(0, -0.44);
      c.lineTo(0.055, 0);
      c.lineTo(-0.055, 0);
      c.closePath();
      c.fillStyle = lit(c, -0.05, -0.44, 0.05, 0, "#d0302b", 0.3);
      c.fill();
      c.beginPath();
      c.moveTo(0, 0.44);
      c.lineTo(0.055, 0);
      c.lineTo(-0.055, 0);
      c.closePath();
      c.fillStyle = "#2b3138";
      c.fill();
      c.restore();
      c.beginPath();
      c.arc(0, 0, 0.05, 0, TAU);
      c.fillStyle = ball(c, 0, 0, 0.05, "#e3b54d");
      c.fill();
      // Verre bombé.
      gloss(c, -0.22, -0.28, 0.3, 0.13, -0.7, 0.5);
      c.beginPath();
      c.arc(0, 0, 0.58, Double.pi * 1.05, Double.pi * 1.45);
      c.lineWidth = 0.025;
      c.strokeStyle = "rgba(255,255,255,.6)";
      c.stroke();
    }

    private static func anneau(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.02, 0.55, 0.78, 0.14, 0.45);
      let h = 0.16;
      let gold = "#e3b54d";
      // Paroi extérieure, à l'avant.
      c.beginPath();
      c.ellipse(0, 0, 0.72, 0.42, 0, 0, Double.pi);
      c.ellipse(0, h, 0.72, 0.42, 0, Double.pi, 0, true);
      c.closePath();
      let wall = c.createLinearGradient(-0.72, 0, 0.72, 0);
      wall.addColorStop(0, shadeColor(gold, 0.45));
      wall.addColorStop(0.3, tintColor(gold, 0.45));
      wall.addColorStop(0.55, gold);
      wall.addColorStop(1, shadeColor(gold, 0.5));
      c.fillStyle = wall;
      c.fill();
      ink(c, 0.016, "rgba(90,55,5,.7)");
      // Paroi intérieure, au fond du trou.
      c.save();
      c.beginPath();
      c.ellipse(0, 0.03, 0.54, 0.29, 0, 0, TAU);
      c.clip();
      c.beginPath();
      c.ellipse(0, 0.03, 0.54, 0.29, 0, 0, TAU);
      c.ellipse(0, 0.03 + h, 0.54, 0.29, 0, 0, TAU);
      c.fillStyle = lit(c, 0, -0.3, 0, 0.2, "#c3973e", 0.35);
      c.fill("evenodd");
      c.restore();
      // Le dessus de l'anneau.
      c.beginPath();
      c.ellipse(0, 0, 0.72, 0.42, 0, 0, TAU);
      c.ellipse(0, 0.03, 0.54, 0.29, 0, 0, TAU);
      c.fillStyle = lit(c, -0.6, -0.4, 0.6, 0.4, gold, 0.4);
      c.fill("evenodd");
      c.beginPath();
      c.ellipse(0, 0, 0.72, 0.42, 0, 0, TAU);
      ink(c, 0.016, "rgba(90,55,5,.7)");
      // L'inscription qui apparaît et s'efface.
      let glow = 0.25 + 0.25 * sin(t * 1.6);
      c.save();
      c.globalCompositeOperation = "lighter";
      c.strokeStyle = "rgba(255,140,40,\(glow))";
      c.lineWidth = 0.012;
      for k in stride(from: Double(0), to: Double(22), by: 1) {
        let a = (k / 22) * TAU;
        let x = cos(a) * 0.63;
        let y = sin(a) * 0.355 + 0.015;
        c.beginPath();
        c.moveTo(x - 0.03, y + 0.01);
        c.quadraticCurveTo(x, y - 0.035 + (k % 3) * 0.02, x + 0.03, y);
        c.stroke();
      }
      c.restore();
      gloss(c, -0.38, -0.25, 0.2, 0.05, -0.35, 0.85);
      gloss(c, 0.2, 0.47, 0.22, 0.03, 0.1, 0.6);
    }

    private static func coeurOcean(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.02, 0.86, 0.55, 0.1, 0.35);
      // Chaîne qui remonte hors du cadre.
      for side in [-1.0, 1.0] {
        for k in stride(from: Double(0), to: Double(9), by: 1) {
          let p = k / 8;
          let x = side * (0.12 + p * 0.55);
          let y = -0.5 - sin(p * Double.pi * 0.5) * 0.45;
          c.beginPath();
          c.ellipse(x, y, 0.035, 0.022, side * 0.6, 0, TAU);
          c.lineWidth = 0.014;
          c.strokeStyle = "#e1e5ea";
          c.stroke();
        }
      }
      // Entourage de petits diamants, le long d'un cœur un peu plus grand.
      for k in stride(from: Double(0), to: Double(26), by: 1) {
        let a = (k / 26) * TAU;
        let x = 0.036 * 16 * pow(sin(a), 3);
        let y = 0.08 - 0.036 * (13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a));
        c.beginPath();
        c.arc(x, y, 0.042, 0, TAU);
        c.fillStyle = ball(c, x, y, 0.042, "#eef6ff", 0.35);
        c.fill();
      }
      // Le grand cœur bleu, taillé en facettes.
      heart(c, 0, 0.12, 0.5);
      c.fillStyle = ball(c, -0.1, 0, 0.75, "#1f5fd6", 0.55);
      c.fill();
      c.save();
      heart(c, 0, 0.12, 0.5);
      c.clip();
      for k in stride(from: Double(0), to: Double(16), by: 1) {
        let a0 = (k / 16) * TAU;
        let a1 = ((k + 1) / 16) * TAU;
        c.beginPath();
        c.moveTo(0, 0.1);
        c.lineTo(cos(a0) * 0.9, 0.1 + sin(a0) * 0.9);
        c.lineTo(cos(a1) * 0.9, 0.1 + sin(a1) * 0.9);
        c.closePath();
        c.fillStyle = k % 2 != 0 ? "rgba(255,255,255,.14)" : "rgba(0,10,60,.14)";
        c.fill();
      }
      heart(c, 0, 0.08, 0.25);
      c.fillStyle = "rgba(140,200,255,.35)";
      c.fill();
      c.lineWidth = 0.012;
      c.strokeStyle = "rgba(255,255,255,.5)";
      c.stroke();
      c.restore();
      heart(c, 0, 0.12, 0.5);
      ink(c, 0.02, "rgba(10,30,80,.75)");
      // Bélière.
      c.beginPath();
      c.ellipse(0, -0.34, 0.06, 0.09, 0, 0, TAU);
      c.lineWidth = 0.03;
      c.strokeStyle = "#e1e5ea";
      c.stroke();
      gloss(c, -0.2, -0.08, 0.14, 0.07, -0.7, 0.8);
      sparkle(c, -0.25, -0.12, 0.16 * (0.6 + 0.4 * sin(t * 3)), 0.9);
      sparkle(c, 0.32, 0.25, 0.1 * (0.6 + 0.4 * sin(t * 2.3 + 1)), 0.8);
      sparkle(c, 0.52, -0.3, 0.08 * (0.6 + 0.4 * sin(t * 2.7 + 2)), 0.8);
    }

    // ---------- Trésors engloutis ----------

    private static func pieceOr(_ c: Canvas2D, _ t: Double) {
        contact(c, 0.04, 0.82, 0.7, 0.12, 0.42)
        c.beginPath()
        c.ellipse(0.035, 0.06, 0.78, 0.8, 0, 0, TAU)
        c.fillStyle = "#8a5c12"
        c.fill()
        c.beginPath()
        c.ellipse(0, 0, 0.78, 0.8, 0, 0, TAU)
        c.fillStyle = ball(c, 0, 0, 0.85, "#e8b84a", 0.45)
        c.fill()
        ink(c, 0.02, "rgba(90,55,5,.7)")
        for k in 0..<36 {
            let a = (Double(k) / 36) * TAU
            c.beginPath()
            c.arc(cos(a) * 0.7, sin(a) * 0.72, 0.018, 0, TAU)
            c.fillStyle = "rgba(255,235,170,.7)"
            c.fill()
        }
        // Profil d'un roi oublié, tourné vers la gauche, frappé en relief.
        let points: [(Double, Double)] = [
            (0.24, 0.44), (0.2, 0.2), (0.29, 0.02), (0.27, -0.16), (0.2, -0.27),
            (0.23, -0.48), (0.14, -0.36), (0.07, -0.52), (0.0, -0.36), (-0.07, -0.48), (-0.1, -0.27),
            (-0.12, -0.18), (-0.14, -0.08), (-0.24, 0.02), (-0.15, 0.05), (-0.17, 0.09), (-0.14, 0.11),
            (-0.16, 0.14), (-0.13, 0.21), (-0.04, 0.23), (-0.02, 0.32), (-0.08, 0.44),
        ]
        let profile = { (dx: Double, dy: Double) in
            c.beginPath()
            for (i, (x, y)) in points.enumerated() {
                if i > 0 { c.lineTo(x + dx, y + dy) } else { c.moveTo(x + dx, y + dy) }
            }
            c.closePath()
        }
        profile(0.015, 0.02)
        c.fillStyle = "rgba(255,236,170,.6)"
        c.fill()
        profile(0, 0)
        c.fillStyle = lit(c, -0.3, -0.5, 0.4, 0.45, "#c8932c", 0.35)
        c.fill()
        c.lineWidth = 0.014
        c.strokeStyle = "rgba(110,70,10,.6)"
        c.beginPath()
        c.moveTo(-0.11, -0.07)
        c.lineTo(-0.06, -0.06)
        for (x, y) in [(0.14, -0.12), (0.2, -0.02), (0.14, 0.08)] {
            c.moveTo(x + 0.04, y)
            c.arc(x, y, 0.04, 0, Double.pi * 1.5)
        }
        c.moveTo(-0.07, 0.42)
        c.quadraticCurveTo(0.1, 0.36, 0.22, 0.42)
        c.stroke()
        // Légende autour du bord.
        let text = Array("REX · MARIS · ANNO ·")
        for (k, letter) in text.enumerated() {
            let a = -Double.pi * 0.95 + (Double(k) / Double(text.count)) * Double.pi * 1.25
            c.save()
            c.translate(cos(a) * 0.56, sin(a) * 0.58)
            c.rotate(a + Double.pi / 2)
            label(c, String(letter), 0, 0, 0.09, "rgba(110,70,10,.85)", 800, serif: true)
            c.restore()
        }
        // Patine de la mer.
        c.fillStyle = "rgba(60,140,110,.35)"
        for (x, y, r) in [(0.45, 0.35, 0.08), (0.52, 0.2, 0.04), (-0.5, 0.42, 0.05)] {
            c.beginPath()
            c.arc(x, y, r, 0, TAU)
            c.fill()
        }
        gloss(c, -0.32, -0.44, 0.26, 0.1, -0.6, 0.7)
    }

    private static func bouteille(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.05, 0.44, 0.95, 0.2, 0.35);
      c.save();
      c.rotate(-0.5);
      let glass = {
        c.beginPath();
        c.moveTo(-0.75, -0.3);
        c.lineTo(0.25, -0.3);
        c.bezierCurveTo(0.45, -0.3, 0.45, -0.11, 0.6, -0.11);
        c.lineTo(0.8, -0.11);
        c.lineTo(0.8, 0.11);
        c.lineTo(0.6, 0.11);
        c.bezierCurveTo(0.45, 0.11, 0.45, 0.3, 0.25, 0.3);
        c.lineTo(-0.75, 0.3);
        c.quadraticCurveTo(-0.88, 0.3, -0.88, 0.17);
        c.lineTo(-0.88, -0.17);
        c.quadraticCurveTo(-0.88, -0.3, -0.75, -0.3);
        c.closePath();
      };
      // Fond du verre.
      glass();
      c.fillStyle = "rgba(20,90,60,.55)";
      c.fill();
      // Le message roulé, à travers le verre.
      rr(c, -0.62, -0.13, 0.74, 0.22, 0.1);
      c.fillStyle = lit(c, -0.6, -0.13, 0.1, 0.09, "#f1e3c0", 0.2);
      c.fill();
      c.fillStyle = "#b8352b";
      c.fillRect(-0.3, -0.13, 0.05, 0.22);
      // Le verre par-dessus : bord plus soutenu, centre plus clair.
      glass();
      let g = c.createLinearGradient(0, -0.3, 0, 0.3);
      g.addColorStop(0, "rgba(110,200,150,.55)");
      g.addColorStop(0.35, "rgba(110,210,160,.18)");
      g.addColorStop(0.75, "rgba(30,110,70,.3)");
      g.addColorStop(1, "rgba(10,60,40,.6)");
      c.fillStyle = g;
      c.fill();
      ink(c, 0.016, "rgba(10,50,30,.75)");
      // Bouchon de liège et goulot.
      rr(c, 0.74, -0.13, 0.06, 0.26, 0.02);
      c.fillStyle = "#2f7a55";
      c.fill();
      rr(c, 0.79, -0.095, 0.16, 0.19, 0.03);
      c.fillStyle = lit(c, 0.79, -0.1, 0.95, 0.1, "#b9854f", 0.3);
      c.fill();
      ink(c, 0.01);
      c.beginPath();
      c.moveTo(-0.72, -0.21);
      c.lineTo(0.2, -0.21);
      c.lineWidth = 0.035;
      c.strokeStyle = "rgba(255,255,255,.55)";
      c.stroke();
      c.beginPath();
      c.moveTo(0.55, -0.07);
      c.lineTo(0.75, -0.07);
      c.lineWidth = 0.018;
      c.stroke();
      c.restore();
    }

    private static func pierreBrute(_ c: Canvas2D, _ t: Double) {
        contact(c, 0.03, 0.72, 0.75, 0.13, 0.45)
        let rock: [(Double, Double)] = [(-0.7, 0.1), (-0.55, -0.45), (-0.1, -0.7), (0.4, -0.58), (0.72, -0.15), (0.64, 0.38), (0.2, 0.66), (-0.42, 0.58)]
        let center = (-0.05, -0.02)
        // Facettes de la croûte, éclairées une par une.
        for (i, p) in rock.enumerated() {
            let q = rock[(i + 1) % rock.count]
            c.beginPath()
            c.moveTo(center.0, center.1)
            c.lineTo(p.0, p.1)
            c.lineTo(q.0, q.1)
            c.closePath()
            let mx = (p.0 + q.0) / 2
            let my = (p.1 + q.1) / 2
            let light = -(mx * 0.6 + my * 0.8)
            c.fillStyle = light > 0 ? tintColor("#857464", min(0.35, light * 0.4)) : shadeColor("#857464", min(0.45, -light * 0.5))
            c.fill()
        }
        let trace = { (points: [(Double, Double)]) in
            c.beginPath()
            for (i, (x, y)) in points.enumerated() {
                if i > 0 { c.lineTo(x, y) } else { c.moveTo(x, y) }
            }
            c.closePath()
        }
        trace(rock)
        ink(c, 0.02)
        // Grains de la croûte.
        c.fillStyle = "rgba(40,30,20,.3)"
        for (x, y) in [(-0.4, -0.2), (-0.25, 0.3), (0.1, -0.45), (-0.5, 0.2), (0.5, -0.3), (-0.2, -0.5)] {
            c.beginPath()
            c.arc(x, y, 0.018, 0, TAU)
            c.fill()
        }
        // La fenêtre sur la gemme.
        let hole: [(Double, Double)] = [(0.0, -0.25), (0.35, -0.3), (0.5, 0.05), (0.32, 0.36), (-0.05, 0.3), (-0.16, 0.0)]
        trace(hole)
        c.fillStyle = "#250d38"
        c.fill()
        c.save()
        c.clip()
        for (i, p) in hole.enumerated() {
            let q = hole[(i + 1) % hole.count]
            c.beginPath()
            c.moveTo(0.17, 0.02)
            c.lineTo(p.0, p.1)
            c.lineTo(q.0, q.1)
            c.closePath()
            c.fillStyle = i % 2 == 1 ? "#b77bff" : "#7a3ad1"
            c.fill()
            c.lineWidth = 0.01
            c.strokeStyle = "rgba(255,255,255,.4)"
            c.stroke()
        }
        c.restore()
        trace(hole)
        c.lineWidth = 0.03
        c.strokeStyle = "#d9cbbd"
        c.stroke()
        sparkle(c, 0.12, -0.08, 0.12 * (0.5 + 0.5 * sin(t * 2.5)), 0.9)
    }

    private static func cleEpave(_ c: Canvas2D, _ t: Double) {
      contact(c, 0.05, 0.22, 0.9, 0.34, 0.35);
      c.save();
      c.rotate(-0.55);
      let bronze = "#a8733a";
      // Anneau ajouré.
      c.beginPath();
      c.arc(-0.56, 0, 0.3, 0, TAU);
      c.arc(-0.56, 0, 0.17, 0, TAU, true);
      c.fillStyle = "rgba(0,0,0,.35)";
      c.save();
      c.translate(0.03, 0.04);
      c.fill();
      c.restore();
      c.beginPath();
      c.arc(-0.56, 0, 0.3, 0, TAU);
      c.arc(-0.56, 0, 0.17, 0, TAU, true);
      c.fillStyle = lit(c, -0.86, -0.3, -0.26, 0.3, bronze, 0.4);
      c.fill();
      ink(c, 0.016);
      for k in stride(from: Double(0), to: Double(4), by: 1) {
        let a = (k / 4) * TAU + Double.pi / 4;
        c.beginPath();
        c.arc(-0.56 + cos(a) * 0.235, sin(a) * 0.235, 0.035, 0, TAU);
        c.fillStyle = ball(c, -0.56 + cos(a) * 0.235, sin(a) * 0.235, 0.035, bronze);
        c.fill();
      }
      // Tige et bagues.
      rr(c, -0.3, -0.055, 0.95, 0.11, 0.05);
      c.fillStyle = lit(c, 0, -0.06, 0, 0.06, bronze, 0.45);
      c.fill();
      ink(c, 0.014);
      for x in [-0.29, -0.17] {
        rr(c, x, -0.09, 0.06, 0.18, 0.025);
        c.fillStyle = lit(c, x, -0.09, x + 0.06, 0.09, bronze, 0.4);
        c.fill();
        ink(c, 0.012);
      }
      // Panneton.
      c.beginPath();
      c.moveTo(0.42, 0.05);
      c.lineTo(0.66, 0.05);
      c.lineTo(0.66, 0.36);
      c.lineTo(0.6, 0.36);
      c.lineTo(0.6, 0.26);
      c.lineTo(0.54, 0.26);
      c.lineTo(0.54, 0.36);
      c.lineTo(0.42, 0.36);
      c.lineTo(0.42, 0.2);
      c.lineTo(0.48, 0.2);
      c.lineTo(0.48, 0.12);
      c.lineTo(0.42, 0.12);
      c.closePath();
      c.fillStyle = lit(c, 0.42, 0.05, 0.66, 0.36, bronze, 0.4);
      c.fill();
      ink(c, 0.014);
      // Vert-de-gris et une petite balane.
      c.fillStyle = "rgba(70,160,125,.5)";
      for (x, y, r) in [(-0.7, 0.18, 0.05), (0.1, 0.02, 0.03), (0.6, 0.3, 0.035), (-0.42, -0.2, 0.03)] {
        c.beginPath();
        c.arc(x, y, r, 0, TAU);
        c.fill();
      }
      c.beginPath();
      c.arc(-0.38, -0.25, 0.055, 0, TAU);
      c.fillStyle = ball(c, -0.38, -0.25, 0.055, "#d9d4c7", 0.35);
      c.fill();
      c.beginPath();
      c.arc(-0.38, -0.25, 0.018, 0, TAU);
      c.fillStyle = "#4a4438";
      c.fill();
      gloss(c, 0.1, -0.035, 0.3, 0.016, 0, 0.6);
      c.restore();
    }

    /** Objet inconnu (ne devrait pas arriver) : un point d'interrogation dans une bulle. */
    private static func unknown(_ c: Canvas2D, _ t: Double) {
      c.beginPath();
      c.arc(0, 0, 0.6, 0, TAU);
      c.fillStyle = ball(c, 0, 0, 0.6, "#5b6b6b");
      c.fill();
      label(c, "?", 0, 0.02, 0.6, "#e8f1f0", 800);
    }

}

/// Reste comme en JavaScript (`a % b` sur des nombres à virgule).
private func % (a: Double, b: Double) -> Double { a.truncatingRemainder(dividingBy: b) }

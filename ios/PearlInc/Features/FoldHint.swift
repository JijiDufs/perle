import SwiftUI

/// iPhone Duo : un petit téléphone qui se referme puis se rouvre, au-dessus de « Referme le téléphone, puis ouvre-le ».
/// Le texte seul ne suffisait pas : un testeur naviguait téléphone ouvert sans penser à le refermer (2026-11-06).
struct FoldHint: View {
    /// Pli horizontal (écran intérieur tenu en paysage) : la moitié du haut se rabat sur celle du bas.
    var horizontal = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let closed = reduceMotion ? 0.5 : Self.closed(at: timeline.date.timeIntervalSinceReferenceDate)
            let layout = horizontal ? AnyLayout(VStackLayout(spacing: 2)) : AnyLayout(HStackLayout(spacing: 2))
            layout {
                if horizontal { half(width: 40, height: 26).rotation3DEffect(.degrees(170 * closed), axis: (1, 0, 0), anchor: .bottom, perspective: 0.6) }
                half(width: horizontal ? 40 : 26, height: horizontal ? 26 : 40)
                    .overlay { RoundedRectangle(cornerRadius: 5).stroke(Palette.gold, lineWidth: 1.5) }
                if !horizontal { half(width: 26, height: 40).rotation3DEffect(.degrees(-170 * closed), axis: (0, 1, 0), anchor: .leading, perspective: 0.6) }
            }
            .padding(10)
            .glass(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityHidden(true)
    }

    private func half(width: Double, height: Double) -> some View {
        RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.85)).frame(width: width, height: height)
    }

    /// 0 = ouvert, 1 = fermé. Cycle de 2,4 s : se referme, reste fermé, se rouvre, reste ouvert.
    static func closed(at seconds: Double) -> Double {
        let phase = seconds.truncatingRemainder(dividingBy: 2.4) / 2.4
        func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }
        if phase < 0.35 { return ease(phase / 0.35) }
        if phase < 0.5 { return 1 }
        if phase < 0.85 { return 1 - ease((phase - 0.5) / 0.35) }
        return 0
    }
}

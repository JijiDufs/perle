import SwiftUI
import PearlCore

/// L'anneau de niveau de la barre du haut : le niveau au centre, la réputation du niveau en cours autour,
/// un « +N » à chaque gain. Le toucher ouvre « Ma progression ».
struct LevelRing: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .headline) private var size: CGFloat = 38
    let open: () -> Void

    private enum GainPhase: CaseIterable { case hidden, shown, gone }

    var body: some View {
        let progress = game.levelProgress
        let fraction = progress.needed > 0 ? Double(progress.into) / Double(progress.needed) : 1
        Button(action: open) {
            ZStack {
                Circle().stroke(.white.opacity(0.22), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Palette.gold, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: fraction)
                Text("\(progress.level)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(5)
            }
            .frame(width: size, height: size)
            .padding(3)
            .glass(Circle())
        }
        // « +N » sous l'anneau : il apparaît puis s'efface (sans glisser si « Réduire les animations »).
        .overlay(alignment: .bottom) {
            Text(verbatim: "+\(game.reputationGain)")
                .font(.caption.weight(.heavy).monospacedDigit())
                .foregroundStyle(Palette.gold)
                .shadow(color: .black.opacity(0.4), radius: 2)
                .fixedSize()
                .phaseAnimator(GainPhase.allCases, trigger: game.reputationBump) { content, phase in
                    content
                        .opacity(phase == .shown ? 1 : 0)
                        .offset(y: phase == .gone && !reduceMotion ? 30 : 18)
                } animation: { phase in
                    switch phase {
                    case .hidden: nil
                    case .shown: .spring(duration: 0.3)
                    case .gone: .easeIn(duration: 1.1).delay(0.5)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(Text("Niveau \(progress.level), \(rankAndTitle(progress.level))"))
        .accessibilityValue(progress.needed > 0
            ? Text("\(progress.into) sur \(progress.needed) de réputation pour le niveau suivant")
            : Text("Niveau maximum"))
        .accessibilityHint(Text("Ouvre « Ma progression »"))
    }

    /// « Perlier » ou « Perlier, Virtuose » quand un titre est porté.
    private func rankAndTitle(_ level: Int) -> String {
        let rank = game.catalog.rank(forLevel: level).title
        return game.player.wornTitle(catalog: game.catalog).map { "\(rank), \($0)" } ?? rank
    }
}

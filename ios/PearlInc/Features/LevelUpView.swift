import SwiftUI
import PearlCore

/// Célébration de montée de niveau (une seule fenêtre, même si plusieurs niveaux ont été franchis) :
/// le niveau, le rang atteint, les récompenses déjà données, le prochain rang. Pour une partie de la 1.0 :
/// « Tu es niveau N », réputation calculée d'après la collection.
struct LevelUpView: View {
    @Environment(GameModel.self) private var game
    let levelUp: LevelUp

    /// Moitié d'écran du Duo à moitié ouvert : plus compact, pour tenir sous la barre du haut.
    private var compact: Bool { game.foldX != nil }

    var body: some View {
        let catalog = game.catalog
        let newRank = catalog.ranks.last { $0.level > levelUp.from && $0.level <= levelUp.to }
        VStack(spacing: compact ? 10 : 14) {
            FitOrScroll {
                VStack(spacing: compact ? 10 : 14) {
                    Text(catalog.rank(forLevel: levelUp.to).title.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Palette.gold)

                    ZStack {
                        Circle().stroke(Palette.gold.opacity(0.35), lineWidth: 5)
                        Circle().stroke(AngularGradient(colors: [Palette.gold, .white, Palette.gold], center: .center), lineWidth: 5)
                        Text("\(levelUp.to)")
                            .font(.system(size: compact ? 30 : 44, weight: .bold, design: .rounded).monospacedDigit())
                            .minimumScaleFactor(0.5)
                    }
                    .frame(width: compact ? 64 : 96, height: compact ? 64 : 96)
                    .accessibilityHidden(true)

                    Group {
                        if levelUp.retroactive {
                            Text("Tu es niveau \(levelUp.to) !")
                        } else {
                            Text("Niveau \(levelUp.to) !")
                        }
                    }
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                    if levelUp.retroactive {
                        Text("Ta réputation a été calculée d’après ta collection.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(0.85)
                    }

                    if let newRank {
                        Label {
                            Text("Nouveau rang : \(newRank.title)")
                        } icon: {
                            Image(systemName: "crown.fill").foregroundStyle(Palette.gold)
                        }
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    }

                    rewards

                    if let next = catalog.nextRank(after: levelUp.to) {
                        Text("Prochain rang : \(next.title), au niveau \(next.level)")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(0.75)
                    }
                }
            }

            // Un écrin gagné : on peut aller l'ouvrir tout de suite (l'onglet apparaît avec le premier).
            if (levelUp.ecrins ?? 0) > 0 {
                Button {
                    withAnimation { game.acknowledgeLevelUp(); game.tab = .ecrins }
                } label: {
                    Text("Ouvrir mes écrins")
                }
                .buttonStyle(PearlButtonStyle())
                .padding(.top, 4)
            }
            Button {
                withAnimation { game.acknowledgeLevelUp() }
            } label: {
                Text("Continuer")
            }
            .buttonStyle(levelUp.ecrins ?? 0 > 0 ? AnyButtonStyle(GlassButtonStyle()) : AnyButtonStyle(PearlButtonStyle()))
            .padding(.top, (levelUp.ecrins ?? 0) > 0 ? 0 : 4)
        }
        .foregroundStyle(.white)
        .padding(compact ? 16 : 24)
        .frame(maxWidth: 340)
        .glassPanel(cornerRadius: 28, rim: Palette.gold, shade: 0.35)
        // Gerbe d'étincelles dorées derrière la fenêtre (pas sur la moitié d'écran du Duo : elle passerait sur le pli).
        .background {
            if game.foldX == nil {
                RevealBurst(glow: "#E2B04A", tier: newRank == nil ? 1 : 2).frame(width: 520, height: 520)
            }
        }
        .padding(.horizontal, compact ? 10 : 20)
        .padding(.top, compact ? 64 : 0)
        .environment(\.buttonLabelWraps, game.foldX != nil)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { game.acknowledgeLevelUp() }
        .onAppear { game.celebrateLevelUp() }
    }

    /// Sur une ligne, ou l'une sous l'autre si la place manque.
    private var rewards: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { rewardItems }.fixedSize()
            VStack(spacing: 4) { rewardItems }
        }
        .font(.headline.monospacedDigit())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glass(RoundedRectangle(cornerRadius: 22, style: .continuous), shade: 0.2)
    }

    @ViewBuilder
    private var rewardItems: some View {
        if levelUp.oysters > 0 {
            Label("+ \(levelUp.oysters)", systemImage: "drop.fill")
                .accessibilityLabel(Text("\(levelUp.oysters) huîtres"))
        }
        if levelUp.dust > 0 {
            Text("+ \(levelUp.dust) ✦")
                .foregroundStyle(Palette.gold)
                .accessibilityLabel(Text("\(levelUp.dust) poussière d’or"))
        }
        if let ecrins = levelUp.ecrins, ecrins > 0 {
            Label("+ \(ecrins)", systemImage: "gift.fill")
                .accessibilityLabel(Text("\(ecrins) écrins"))
        }
    }
}

/// Un style de bouton choisi à l'exécution.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }

    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

/// Partie d'avant les écrins (1.1 à 1.3) : les écrins des niveaux déjà franchis, en une seule fenêtre.
struct EcrinCatchUpView: View {
    @Environment(GameModel.self) private var game
    let count: Int

    var body: some View {
        VStack(spacing: game.foldX != nil ? 10 : 14) {
            Image(systemName: "gift.fill").font(.system(size: 40)).foregroundStyle(Palette.gold).accessibilityHidden(true)
            Text("Des écrins t’attendent !").font(.title2.weight(.bold)).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
            Text("Tes huîtres et tes rangs t’ont rapporté \(count) écrins. Ouvre-les doucement : quelque part, le bijou scintille.")
                .font(.subheadline).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).opacity(0.85)
            Button {
                withAnimation { game.acknowledgeEcrinCatchUp(); game.tab = .ecrins }
            } label: {
                Text("Ouvrir mes écrins")
            }
            .buttonStyle(PearlButtonStyle())
            Button("Plus tard") { withAnimation { game.acknowledgeEcrinCatchUp() } }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .foregroundStyle(.white)
        .padding(game.foldX != nil ? 16 : 24)
        .frame(maxWidth: 340)
        .glassPanel(cornerRadius: 28, rim: Palette.gold, shade: 0.35)
        .padding(.horizontal, game.foldX != nil ? 10 : 20)
        .environment(\.buttonLabelWraps, game.foldX != nil)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { game.acknowledgeEcrinCatchUp() }
        .onAppear { game.celebrateAchievement() }
    }
}

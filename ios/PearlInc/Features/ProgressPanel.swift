import SwiftUI
import PearlCore

/// « Ma progression » (toucher l'anneau de niveau) : niveau et rang, statistiques, chemin des rangs,
/// barème de réputation. Seulement ce qui existe dans l'app (règle Apple 2.1 : rien « à venir »).
/// Panneau qui monte depuis le bas, sur une moitié d'écran quand le Duo est à moitié ouvert.
struct ProgressPanel: View {
    @Environment(GameModel.self) private var game
    let close: () -> Void

    /// Moitié d'écran du Duo à moitié ouvert : marges réduites.
    private var compact: Bool { game.foldX != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ma progression").font(.headline)
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark").font(.headline).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Fermer")
            }
            .padding(.leading, compact ? 14 : 20)
            .padding(.trailing, compact ? 2 : 8)
            .padding(.top, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    stats
                    ranks
                    scale
                }
                .padding(.horizontal, compact ? 14 : 20)
                .padding(.bottom, 24)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: 520)
        .glassPanel(cornerRadius: 28, shade: 0.45)
        .padding(.horizontal, compact ? 6 : 12)
        .padding(.top, 60)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, close)
    }

    private var header: some View {
        let progress = game.levelProgress
        return VStack(alignment: .leading, spacing: 8) {
            Text(game.catalog.rank(forLevel: progress.level).title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(Palette.gold)
            Text("Niveau \(progress.level)").font((compact ? Font.title : .largeTitle).weight(.bold))
                .accessibilityAddTraits(.isHeader)
            if progress.needed > 0 {
                ProgressView(value: Double(progress.into), total: Double(progress.needed)).tint(Palette.gold)
                Text("\(progress.into) / \(progress.needed) de réputation pour le niveau \(progress.level + 1)")
                    .font(.footnote.monospacedDigit())
                    .opacity(0.8)
            } else {
                Text("Niveau maximum").font(.footnote).opacity(0.8)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Deux colonnes (nombre pair : rien ne se coupe au pli du Duo).
    private var stats: some View {
        let player = game.player
        let catalog = game.catalog
        let pearlKinds = catalog.pearls.filter { $0.id != "empty" }.count
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            Stat(value: "\(player.oystersOpened)", label: String(localized: "huîtres ouvertes"))
            Stat(value: "\(Set(player.pearlCards.map(\.pearlId)).count)/\(pearlKinds)", label: String(localized: "perles découvertes"))
            Stat(value: "\(Set(player.findCards.map(\.findId)).count)/\(catalog.finds.count)", label: String(localized: "trouvailles"))
            Stat(value: "\(game.shownReputation)", label: String(localized: "de réputation"))
        }
    }

    private var ranks: some View {
        let level = game.levelProgress.level
        let current = game.catalog.rank(forLevel: level)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Les rangs").font(.title3.weight(.bold)).accessibilityAddTraits(.isHeader)
            ForEach(game.catalog.ranks) { rank in
                let reached = level >= rank.level
                HStack(spacing: compact ? 8 : 12) {
                    Text("\(rank.level)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .frame(minWidth: 34, minHeight: 34)
                        .background(Circle().fill(reached ? Palette.gold : .white.opacity(0.12)))
                        .foregroundStyle(reached ? Lagoon.abyss : .white)
                    Text(rank.title).font(.body.weight(rank.id == current.id ? .bold : .regular))
                    Spacer(minLength: 0)
                    if rank.id == current.id {
                        Image(systemName: "star.fill").foregroundStyle(Palette.gold)
                    } else if reached {
                        Image(systemName: "checkmark").foregroundStyle(Palette.gold)
                    }
                }
                .opacity(reached ? 1 : 0.6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(rank.title), niveau \(rank.level)"))
                .accessibilityValue(rank.id == current.id ? Text("Ton rang") : reached ? Text("Atteint") : Text(""))
            }
        }
    }

    private var scale: some View {
        let tuning = game.tuning
        let levels = game.economy.levels
        return VStack(alignment: .leading, spacing: 8) {
            Text("Gagner de la réputation").font(.title3.weight(.bold)).accessibilityAddTraits(.isHeader)
            ScaleRow(label: String(localized: "Ouvrir une huître"), value: "+\(tuning.repOyster)")
            ScaleRow(label: String(localized: "Par ◆ de rareté de la perle ou de la trouvaille"), value: "+\(tuning.repPerTier)")
            ScaleRow(label: String(localized: "Lustre S / A (sans fêlure)"), value: "+\(tuning.repLustreS) / +\(tuning.repLustreA)")
            ScaleRow(label: String(localized: "Nouvelle perle ou nouvelle trouvaille"), value: "+\(tuning.repDiscovery)")
            ScaleRow(label: String(localized: "Mission du jour"), value: "+\(levels.missionReputation)")
            ScaleRow(label: String(localized: "Rendez-vous du jour"), value: "+\(levels.calendarReputation)")
            Text("Chaque niveau : \(levels.rewardOysters) huîtres et \(levels.rewardDust) ✦ ; nouveau rang : \(levels.rankRewardOysters) huîtres et \(levels.rankRewardDust) ✦ de plus.")
                .font(.footnote)
                .opacity(0.8)
                .padding(.top, 4)
        }
    }
}

private struct Stat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold).monospacedDigit()).minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.caption).multilineTextAlignment(.center).minimumScaleFactor(0.8).opacity(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.vertical, 8)
        .glassPanel(cornerRadius: 16, shade: 0.2)
        .accessibilityElement(children: .combine)
    }
}

private struct ScaleRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
            Spacer(minLength: 8)
            Text(value).font(.body.weight(.bold).monospacedDigit()).foregroundStyle(Palette.gold)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

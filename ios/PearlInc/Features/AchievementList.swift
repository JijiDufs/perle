import SwiftUI
import PearlCore

/// Volet « Succès » de « Ma progression » : le titre porté (choisi parmi ceux gagnés), puis chaque succès avec son
/// avancement et sa récompense. Les succès secrets restent cachés tant qu'ils ne sont pas obtenus.
struct AchievementList: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        let player = game.player
        let all = game.catalog.economy.achievements
        VStack(alignment: .leading, spacing: 18) {
            Text("\(player.achievements.count) succès sur \(all.count)")
                .font(.title3.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            titlePicker
            VStack(spacing: 10) {
                ForEach(all) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
    }

    @ViewBuilder
    private var titlePicker: some View {
        let titles = game.player.earnedTitles(catalog: game.catalog)
        if titles.isEmpty {
            Text("Certains succès donnent un titre, à porter sous ton rang.")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0.8)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Titre porté").font(.subheadline.weight(.semibold))
                Picker("Titre porté", selection: Binding(get: { game.player.title }, set: { game.wearTitle($0) })) {
                    Text("Aucun").tag(String?.none)
                    ForEach(titles) { achievement in
                        Text(achievement.title ?? "").tag(String?.some(achievement.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(Palette.gold)
            }
        }
    }
}

private struct AchievementRow: View {
    @Environment(GameModel.self) private var game
    @Environment(\.dynamicTypeSize) private var typeSize
    let achievement: Achievement

    /// Moitié d'écran du Duo, ou très grand texte : la médaille et la coche passent au-dessus du texte.
    private var stacked: Bool { game.foldX != nil || typeSize.isAccessibilitySize }

    var body: some View {
        let earned = game.player.hasAchievement(achievement.id)
        let hidden = achievement.secret == true && !earned
        let (done, goal) = game.player.progress(of: achievement, catalog: game.catalog)
        let check = Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.gold).font(.title3)
        VStack(alignment: .leading, spacing: 6) {
            if stacked {
                HStack {
                    AchievementMedal(tier: achievement.tier, earned: earned)
                    Spacer(minLength: 0)
                    if earned { check }
                }
            }
            HStack(alignment: .top, spacing: 12) {
                if !stacked { AchievementMedal(tier: achievement.tier, earned: earned) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(hidden ? String(localized: "Succès secret") : achievement.name)
                        .font(.body.weight(.semibold))
                    Text(hidden ? String(localized: "Continue de pêcher…") : achievement.description)
                        .font(.subheadline)
                        .opacity(0.8)
                    if !earned && !hidden && goal > 1 {
                        ProgressView(value: Double(done), total: Double(goal)).tint(achievement.tier.color)
                        Text("\(done) / \(goal)").font(.caption.monospacedDigit()).opacity(0.7)
                    }
                    if !hidden {
                        Text(AchievementText.reward(game.catalog.reward(of: achievement)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.gold)
                        if let title = achievement.title {
                            Text("Titre : \(title)").font(.caption).opacity(0.8)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if earned && !stacked { check }
            }
        }
        .padding(stacked ? 10 : 12)
        .glassPanel(cornerRadius: 16, shade: earned ? 0.15 : 0.3)
        .opacity(earned ? 1 : 0.85)
        .accessibilityElement(children: .combine)
        .accessibilityValue(earned ? Text("\(achievement.tier.label), obtenu") : Text("\(achievement.tier.label), \(done) sur \(goal)"))
    }
}

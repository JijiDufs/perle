import SwiftUI
import PearlCore

/// Bannière d'un succès obtenu, en haut de la Pêche, au moment calme suivant (jamais pendant la révélation, la carte,
/// la fête de niveau ni le tutoriel). Elle s'efface seule ; la toucher la referme plus tôt.
struct AchievementBanner: View {
    @Environment(GameModel.self) private var game
    let achievement: Achievement

    /// Moitié d'écran du Duo à moitié ouvert : marges réduites.
    private var compact: Bool { game.foldX != nil }

    var body: some View {
        let reward = game.catalog.reward(of: achievement)
        HStack(spacing: compact ? 8 : 12) {
            AchievementMedal(tier: achievement.tier, earned: true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Succès obtenu · \(achievement.tier.label)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(achievement.tier.color)
                Text(achievement.name).font(.headline)
                Text(AchievementText.reward(reward)).font(.subheadline.monospacedDigit()).opacity(0.85)
                if let title = achievement.title {
                    Text("Nouveau titre : \(title)").font(.footnote).foregroundStyle(Palette.gold)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 10 : 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 420)
        .glassPanel(cornerRadius: 22, rim: achievement.tier.color, shade: 0.35)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { game.acknowledgeAchievement(achievement.id) } }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("Ferme la bannière"))
        .onAppear {
            game.celebrateAchievement()
            AccessibilityNotification.Announcement(String(localized: "Succès obtenu : \(achievement.name)")).post()
        }
        .task(id: achievement.id) {
            try? await Task.sleep(for: .milliseconds(Int(game.tuning.achievementBannerMs)))
            withAnimation { game.acknowledgeAchievement(achievement.id) }
        }
    }
}

/// Partie d'avant les succès : ceux déjà remplis, en une seule fenêtre (récompenses déjà données).
struct AchievementCatchUpView: View {
    @Environment(GameModel.self) private var game
    let catchUp: AchievementCatchUp

    private var compact: Bool { game.foldX != nil }

    var body: some View {
        VStack(spacing: compact ? 10 : 14) {
            AchievementMedal(tier: .or, earned: true)
                .scaleEffect(compact ? 1.2 : 1.6)
                .padding(compact ? 6 : 12)
            Text("Les succès arrivent !")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("Tu en as déjà \(catchUp.count), d’après ta partie.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0.85)
            Text(AchievementText.reward(AchievementReward(oysters: catchUp.oysters, dust: catchUp.dust, reputation: 0)))
                .font(.headline.monospacedDigit())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glass(RoundedRectangle(cornerRadius: 22, style: .continuous), shade: 0.2)
            Text("Retrouve-les dans « Ma progression », en touchant ton niveau.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0.75)
            Button {
                withAnimation { game.acknowledgeAchievementCatchUp() }
            } label: {
                Text("Continuer")
            }
            .buttonStyle(PearlButtonStyle())
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .padding(compact ? 16 : 24)
        .frame(maxWidth: 340)
        .glassPanel(cornerRadius: 28, rim: Palette.gold, shade: 0.35)
        .padding(.horizontal, compact ? 10 : 20)
        .padding(.top, compact ? 64 : 0)
        .environment(\.buttonLabelWraps, compact)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { game.acknowledgeAchievementCatchUp() }
        .onAppear { game.celebrateAchievement() }
    }
}

/// Médaille d'un succès, à la couleur de son palier ; grise tant qu'il n'est pas obtenu.
struct AchievementMedal: View {
    let tier: AchievementTier
    let earned: Bool

    var body: some View {
        Image(systemName: earned ? "medal.fill" : "medal")
            .font(.title2)
            .foregroundStyle(earned ? tier.color : .white.opacity(0.45))
            .frame(width: 34)
            .accessibilityHidden(true)
    }
}

extension AchievementTier {
    var label: String {
        switch self {
        case .bronze: String(localized: "Bronze", comment: "Palier de succès")
        case .argent: String(localized: "Argent", comment: "Palier de succès")
        case .or: String(localized: "Or", comment: "Palier de succès")
        }
    }

    var color: Color {
        switch self {
        case .bronze: Color(hex: "#D9925B")
        case .argent: Color(hex: "#D7DEE6")
        case .or: Palette.gold
        }
    }
}

enum AchievementText {
    /// « + 3 huîtres · + 5 ✦ ».
    static func reward(_ reward: AchievementReward) -> String {
        var parts: [String] = []
        if reward.oysters > 0 { parts.append(String(localized: "+ \(reward.oysters) huîtres")) }
        if reward.dust > 0 { parts.append("+ \(reward.dust) ✦") }
        // Chaque récompense reste sur une ligne (« + 5 huîtres »), même sur la moitié d'écran du Duo.
        return parts.map { $0.replacingOccurrences(of: " ", with: "\u{00A0}") }.joined(separator: " · ")
    }
}

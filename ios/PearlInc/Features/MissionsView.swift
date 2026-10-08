import SwiftUI
import PearlCore

/// Les trois missions du jour, renouvelées à minuit.
struct MissionsView: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        NavigationStack {
            List {
                if let daily = game.player.missions {
                    Section {
                        ForEach(Array(daily.missions.enumerated()), id: \.offset) { index, mission in
                            MissionRow(mission: mission, reward: game.economy.missionRewardDust) {
                                game.claimMission(at: index)
                            }
                        }
                    } footer: {
                        Text(daily.bonusClaimed
                             ? "Bonus des trois missions récupéré. À demain !"
                             : "Les trois récupérées : + \(game.economy.missionBonusDust) ✦ de bonus.")
                    }
                }
                Section {
                    TimelineView(.periodic(from: .now, by: 60)) { timeline in
                        Label("Nouvelles missions dans \(Clock.countdown(Clock.secondsUntilMidnight(timeline.date)))", systemImage: "moon.stars")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Missions du jour")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

private struct MissionRow: View {
    let mission: Mission
    let reward: Int
    let claim: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(mission.text).font(.body.weight(.medium))
                ProgressView(value: Double(mission.progress), total: Double(mission.goal))
                    .tint(Palette.gold)
                Text("\(mission.progress) / \(mission.goal)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Spacer()
            if mission.claimed {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.gold).font(.title2)
                    .accessibilityLabel("Récupérée")
            } else {
                Button("+ \(reward) ✦", action: claim)
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.gold)
                    .disabled(!mission.isDone)
            }
        }
        .padding(.vertical, 4)
    }
}

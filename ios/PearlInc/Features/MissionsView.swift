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
                        .listRowBackground(Color.white.opacity(0.08))
                    } footer: {
                        if daily.bonusClaimed {
                            Text("Bonus des trois missions récupéré. À demain !")
                        } else {
                            Text("Les trois récupérées : + \(game.economy.missionBonusDust) ✦ de bonus.")
                        }
                    }
                }
                Section {
                    TimelineView(.periodic(from: .now, by: 60)) { timeline in
                        Label("Nouvelles missions dans \(GameText.countdown(Clock.secondsUntilMidnight(timeline.date)))", systemImage: "moon.stars")
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Missions du jour")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }
}

private struct MissionRow: View {
    let mission: Mission
    let reward: Int
    let claim: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(GameText.mission(mission)).font(.body.weight(.medium))
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
                    .buttonStyle(PearlButtonStyle(compact: true))
                    .disabled(!mission.isDone)
            }
        }
        .padding(.vertical, 4)
    }
}

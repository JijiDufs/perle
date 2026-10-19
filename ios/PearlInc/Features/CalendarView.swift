import SwiftUI
import PearlCore

/// Rendez-vous du jour (cahier §15) : le calendrier de connexion sur 7 jours et la série.
/// S'ouvre tout seul une fois par jour ; aussi depuis les missions du jour.
struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    /// Hauteur du contenu : la fenêtre s'y ajuste, pour que « Récupérer » soit toujours visible
    /// (l'écran extérieur du Duo est moins haut qu'un iPhone : à mi-hauteur, le bouton était coupé).
    @State private var contentHeight: CGFloat = 480

    var body: some View {
        NavigationStack {
            ScrollView {
                CalendarContent(onClaimed: { dismiss() })
                    .padding(20)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            // Écran extérieur du Duo : la barre d'état est verticale, à droite ; sous elle, la fenêtre
            // n'a rien à éviter. Sans ça, le contenu serait décalé vers la gauche.
            .ignoresSafeArea(.container, edges: .horizontal)
                .navigationTitle("Rendez-vous du jour")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
                }
        }
        // Contenu + barre de titre ; plafonné par iOS à la hauteur de l'écran (on fait alors défiler).
        .presentationDetents([.height(contentHeight + 72)])
        .presentationBackground(.ultraThinMaterial)
    }
}

struct CalendarContent: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Après la récupération (la fenêtre se ferme toute seule, un peu après).
    var onClaimed: (() -> Void)?
    @State private var claimedNow = false

    var body: some View {
        let economy = game.economy
        let login = game.player.login
        let today = Clock.dayKey()
        let canClaim = game.canClaimDaily
        VStack(spacing: 18) {
            streak(login: login, today: today, canClaim: canClaim)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(economy.calendar.indices, id: \.self) { index in
                    DayCell(index: index, reward: economy.calendar[index], state: state(of: index, login: login, today: today, canClaim: canClaim))
                }
            }

            if canClaim {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.4)) { game.claimDaily() }
                    claimedNow = true
                    if let onClaimed {
                        Task { try? await Task.sleep(for: .seconds(1.2)); onClaimed() }
                    }
                } label: {
                    Text("Récupérer")
                }
                .buttonStyle(PearlButtonStyle())
            } else {
                Text(claimedNow ? "Récupéré ! Reviens demain pour la case suivante." : "Reviens demain pour la case suivante.")
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private func streak(login: LoginState, today: String, canClaim: Bool) -> some View {
        let jokerDays = game.economy.calendarJokerDays
        // Série affichée : celle qu'on aura en récupérant aujourd'hui.
        let streak = canClaim ? login.streakIfClaimed(day: today, jokerDays: jokerDays).streak : login.streak
        VStack(spacing: 6) {
            Label {
                Text("\(streak) jours d’affilée")
            } icon: {
                Image(systemName: "flame.fill").foregroundStyle(Palette.gold)
            }
            .font(.title3.weight(.bold))
            let back = login.jokerBackIn(day: today, jokerDays: jokerDays)
            Group {
                if back == 0 {
                    Text("Joker prêt : un jour manqué ne casse pas ta série.")
                } else {
                    Text("Joker utilisé : de retour dans \(back) jours.")
                }
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
    }

    private func state(of index: Int, login: LoginState, today: String, canClaim: Bool) -> DayCell.State {
        // 7e case récupérée aujourd'hui : le calendrier est complet jusqu'à demain.
        if !canClaim && login.lastClaimDay == today && login.calendarIndex == 0 { return .done }
        if index < login.calendarIndex { return .done }
        if index == login.calendarIndex && canClaim { return .today }
        return .later
    }
}

private struct DayCell: View {
    enum State { case done, today, later }

    let index: Int
    let reward: CalendarReward
    let state: State

    var body: some View {
        VStack(spacing: 6) {
            Text("Jour \(index + 1)").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
            ZStack {
                VStack(spacing: 2) {
                    if reward.oysters > 0 {
                        Label("\(reward.oysters)", systemImage: "drop.fill").labelStyle(.titleAndIcon)
                    }
                    if reward.dust > 0 {
                        Text("✦ \(reward.dust)").foregroundStyle(Palette.gold)
                    }
                }
                .font(.subheadline.weight(.bold).monospacedDigit())
                .opacity(state == .done ? 0.35 : 1)
                if state == .done {
                    Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Palette.gold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .glassPanel(cornerRadius: 16, rim: state == .today ? Palette.gold : nil, shade: state == .today ? 0 : 0.2)
        .scaleEffect(state == .today ? 1.04 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        var parts = [String(localized: "Jour \(index + 1)")]
        if reward.oysters > 0 { parts.append(String(localized: "\(reward.oysters) huîtres")) }
        if reward.dust > 0 { parts.append(String(localized: "\(reward.dust) poussière d’or")) }
        switch state {
        case .done: parts.append(String(localized: "Récupéré"))
        case .today: parts.append(String(localized: "À récupérer aujourd’hui"))
        case .later: break
        }
        return parts.joined(separator: ", ")
    }
}

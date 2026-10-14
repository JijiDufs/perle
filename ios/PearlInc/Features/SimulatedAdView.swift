import SwiftUI

/// La pub simulée (Debug, quand AdMob n'a pas de pub prête, voir Platform/RewardedAds.swift) : un écran plein, un compte à rebours,
/// puis la récompense. La fermer avant la fin ne rapporte rien, comme une vraie pub récompensée.
struct SimulatedAdView: View {
    let ads: RewardedAds
    @State private var remaining = RewardedAds.simulatedSeconds

    var body: some View {
        ZStack {
            LagoonBackground(dim: 0.6)
            VStack(spacing: 18) {
                Text("PUBLICITÉ (SIMULÉE)").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(.white.opacity(0.7))
                PearlAppIcon(size: 96)
                Text("Ici, une vraie pub").font(.title2.weight(.bold))
                Text("Pas de pub AdMob prête (version de développement).").font(.subheadline).foregroundStyle(.white.opacity(0.8))
                Text(remaining > 0 ? "Récompense dans \(remaining) s" : "Récompense gagnée !")
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 18).frame(minHeight: 40)
                    .glass(Capsule())
                if remaining == 0 {
                    Button("Récupérer") { ads.finish(rewarded: true) }
                        .buttonStyle(PearlButtonStyle())
                        .frame(maxWidth: 260)
                }
            }
            .foregroundStyle(.white)
            .padding(24)
        }
        .overlay(alignment: .topTrailing) {
            Button { ads.finish(rewarded: false) } label: {
                Image(systemName: "xmark").font(.headline).frame(width: 40, height: 40)
            }
            .buttonStyle(GlassButtonStyle(compact: true))
            .accessibilityLabel("Fermer la pub sans récompense")
            .padding()
        }
        .task {
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
            }
        }
    }
}

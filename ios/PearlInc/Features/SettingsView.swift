import SwiftUI
import PearlCore

/// Réglages : le compte (déconnexion, suppression), les vibrations, les probabilités, les achats,
/// l'aide et les informations légales. Exigences d'Apple : suppression du compte dans l'app (5.1.1 (v)),
/// politique de confidentialité accessible depuis l'app, « Restaurer les achats ».
struct SettingsView: View {
    @Environment(GameModel.self) private var game
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Haptics.settingKey) private var haptics = true
    @State private var confirmSignOut = false
    @State private var confirmDelete = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                account
                Section("Jeu") {
                    Toggle(isOn: $haptics) { Label("Vibrations", systemImage: "iphone.radiowaves.left.and.right") }
                        .tint(Palette.gold)
                    NavigationLink {
                        ScrollView { OddsList().padding(20) }
                            .scrollContentBackground(.hidden)
                            .navigationTitle("Probabilités")
                    } label: {
                        Label("Probabilités des perles", systemImage: "percent")
                    }
                    if game.ads.privacyOptionsRequired {
                        Button { Task { await game.ads.showPrivacyOptions() } } label: {
                            Label("Confidentialité des pubs", systemImage: "hand.raised.square")
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.08))

                Section("Achats") {
                    Button { game.restorePurchases() } label: {
                        Label("Restaurer les achats", systemImage: "arrow.clockwise")
                    }
                }
                .listRowBackground(Color.white.opacity(0.08))

                Section("Aide") {
                    Link(destination: SiteLinks.support) { Label("Aide et contact", systemImage: "questionmark.circle") }
                    Link(destination: SiteLinks.mail(accountId: auth.shortAccountId)) { Label("Écrire au support", systemImage: "envelope") }
                }
                .listRowBackground(Color.white.opacity(0.08))

                Section {
                    Link(destination: SiteLinks.privacy) { Label("Politique de confidentialité", systemImage: "hand.raised") }
                    Link(destination: SiteLinks.terms) { Label("Conditions d’utilisation", systemImage: "doc.text") }
                    Link(destination: SiteLinks.legal) { Label("Mentions légales", systemImage: "building.columns") }
                } header: {
                    Text("Informations légales")
                } footer: {
                    Text("Pearl Inc. \(SiteLinks.version) · iPhone et iPhone Duo sont des marques d’Apple Inc. Pearl Inc. n’est pas affilié à Apple.")
                        .padding(.top, 8)
                }
                .listRowBackground(Color.white.opacity(0.08))
            }
            .scrollContentBackground(.hidden)
            .tint(.white)
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
            .disabled(auth.isLoading)
            .overlay { if auth.isLoading { ProgressView().tint(.white) } }
        }
        .presentationBackground(.ultraThinMaterial)
        .confirmationDialog("Se déconnecter ?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Se déconnecter", role: .destructive) { auth.signOut() }
        } message: {
            Text(auth.accountKind == .anonymous
                 ? "Sans compte, tu ne pourras plus revenir sur ce compte. Ta partie reste sur cet iPhone."
                 : "Ta partie reste sur cet iPhone. Tu pourras te reconnecter avec le même compte.")
        }
        .confirmationDialog("Supprimer ton compte ?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Supprimer définitivement", role: .destructive) {
                auth.deleteAccount { game.eraseLocalGame() }
            }
        } message: {
            Text("Ton compte et les données liées sont effacés pour de bon. La partie sur cet iPhone (collection, huîtres, poussière d’or) repart de zéro. Les coquilles achetées reviennent avec « Restaurer les achats ». Les achats ne sont pas remboursés : pour cela, passe par Apple.")
        }
    }

    // MARK: - Compte

    private var account: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: accountIcon).font(.title2).frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(accountTitle).font(.body.weight(.semibold))
                    if let email = auth.accountEmail, !email.isEmpty {
                        Text(email).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            if let id = auth.shortAccountId {
                Button {
                    UIPasteboard.general.string = id
                    copied = true
                } label: {
                    LabeledContent("Identifiant (pour le support)") {
                        Text(copied ? "Copié" : id).font(.body.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .accessibilityHint("Copie l’identifiant")
            }
            Button { confirmSignOut = true } label: {
                Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
            }
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Supprimer mon compte", systemImage: "trash")
            }
        } header: {
            Text("Compte")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                if auth.accountKind == .anonymous {
                    Text("Sans compte, ta partie reste sur cet iPhone.")
                }
                if let error = auth.errorMessage {
                    Text(error).foregroundStyle(Color(hex: 0xFFB4A8))
                }
            }
        }
        .listRowBackground(Color.white.opacity(0.08))
    }

    private var accountTitle: String {
        switch auth.accountKind {
        case .apple: "Connecté avec Apple"
        case .email: "Connecté par e-mail"
        case .anonymous, nil: "Sans compte"
        }
    }

    private var accountIcon: String {
        switch auth.accountKind {
        case .apple: "apple.logo"
        case .email: "envelope.fill"
        case .anonymous, nil: "person.crop.circle.badge.questionmark"
        }
    }
}

/// Les pages du site (support, légal) et le contact.
enum SiteLinks {
    static let support = URL(string: "https://pearl-inc.app/support/")!
    static let privacy = URL(string: "https://pearl-inc.app/confidentialite/")!
    static let terms = URL(string: "https://pearl-inc.app/conditions/")!
    static let legal = URL(string: "https://pearl-inc.app/mentions-legales/")!
    static let supportEmail = "laplateformemjh@gmail.com"

    /// E-mail au support, avec l'identifiant du compte dans l'objet pour retrouver le joueur.
    static func mail(accountId: String?) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        let subject = accountId.map { "Pearl Inc. (identifiant \($0))" } ?? "Pearl Inc."
        components.queryItems = [URLQueryItem(name: "subject", value: subject)]
        return components.url ?? URL(string: "mailto:\(supportEmail)")!
    }

    /// « version 0.1 (1) ».
    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "version \(short) (\(build))"
    }
}

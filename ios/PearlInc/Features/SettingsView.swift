import AuthenticationServices
import SwiftUI
import PearlCore

/// Réglages : le compte (déconnexion, suppression), la musique, les sons, les vibrations, les probabilités, les achats,
/// l'aide et les informations légales. Exigences d'Apple : suppression du compte dans l'app (5.1.1 (v)),
/// politique de confidentialité accessible depuis l'app, « Restaurer les achats ».
struct SettingsView: View {
    @Environment(GameModel.self) private var game
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Audio.musicKey) private var music = true
    @AppStorage(Audio.soundsKey) private var sounds = true
    @AppStorage(Haptics.settingKey) private var haptics = true
    @AppStorage(Notifications.settingKey) private var notify = false
    @State private var notificationsDenied = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                account
                Section("Jeu") {
                    Toggle(isOn: $music) { Label("Musique", systemImage: "music.note") }
                        .tint(Palette.gold)
                        .onChange(of: music) { game.audio.settingsChanged() }
                    Toggle(isOn: $sounds) { Label("Sons", systemImage: "speaker.wave.2") }
                        .tint(Palette.gold)
                    Toggle(isOn: $haptics) { Label("Vibrations", systemImage: "iphone.radiowaves.left.and.right") }
                        .tint(Palette.gold)
                    Toggle(isOn: Binding(get: { notify }, set: { on in
                        if on {
                            Task {
                                notify = await Notifications.enable()
                                notificationsDenied = await Notifications.isDenied()
                            }
                        } else {
                            Notifications.disable()
                            notify = false
                        }
                    })) {
                        Label("Huîtres revenues", systemImage: "bell")
                    }
                    .tint(Palette.gold)
                    if notificationsDenied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        } label: {
                            Text("Les notifications de Pearl Inc. sont coupées dans les Réglages d’iOS. Les rallumer")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    // La langue se choisit dans les réglages d'iOS (une langue pour cette app seule).
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    } label: {
                        LabeledContent {
                            Text(AppLanguage.isFrench ? "Français" : "English").foregroundStyle(.secondary)
                        } label: {
                            Label("Langue", systemImage: "globe")
                        }
                    }
                    NavigationLink {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 18) {
                                OddsList()
                                if game.hasEcrins {
                                    Text("Écrins").font(.title3.weight(.bold))
                                    EcrinOddsList()
                                }
                            }
                            .padding(20)
                        }
                            .scrollContentBackground(.hidden)
                            .navigationTitle("Probabilités")
                    } label: {
                        Label("Probabilités", systemImage: "percent")
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
            if auth.accountKind == .anonymous {
                Text("Sans compte, tu ne pourras plus revenir sur ce compte ni sur sa partie.")
            } else {
                Text("Ta partie reste sur ton compte. Tu la retrouveras en te reconnectant avec le même compte.")
            }
        }
        .confirmationDialog("Supprimer ton compte ?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Supprimer définitivement", role: .destructive) {
                auth.deleteAccount { game.eraseLocalGame() }
            }
        } message: {
            Text("Ton compte et ta partie sauvegardée sont effacés pour de bon. La partie sur cet iPhone (collection, huîtres, poussière d’or) repart de zéro. Les coquilles achetées reviennent avec « Restaurer les achats ». Les achats ne sont pas remboursés : pour cela, passe par Apple.")
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
                        Group { if copied { Text("Copié") } else { Text(verbatim: id) } }
                            .font(.body.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .accessibilityHint("Copie l’identifiant")
            }
            if auth.accountKind == .anonymous {
                SignInWithAppleButton(.continue, onRequest: auth.prepareAppleRequest, onCompletion: auth.handleAppleResult)
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    .accessibilityHint("Lie ta partie à ton compte Apple pour la retrouver sur un autre iPhone")
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
                    Text("Sans compte, ta partie est sauvegardée sur cet iPhone et sur un compte invité, mais elle ne se retrouve pas sur un autre iPhone, ni après une déconnexion. Continue avec Apple pour la garder.")
                } else {
                    Text("Ta partie est sauvegardée sur ton compte : reconnecte-toi sur un autre iPhone pour la retrouver.")
                }
                if let error = auth.errorMessage {
                    Text(error).foregroundStyle(Color(hex: 0xFFB4A8))
                }
            }
        }
        .listRowBackground(Color.white.opacity(0.08))
    }

    private var accountTitle: LocalizedStringKey {
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

/// Les pages du site (support, légal) et le contact, dans la langue de l'app.
enum SiteLinks {
    private static func page(_ french: String, _ english: String) -> URL {
        URL(string: "https://pearl-inc.app" + (AppLanguage.isFrench ? french : english))!
    }
    static var support: URL { page("/support/", "/en/support/") }
    static var privacy: URL { page("/confidentialite/", "/en/privacy/") }
    static var terms: URL { page("/conditions/", "/en/terms/") }
    static var legal: URL { page("/mentions-legales/", "/en/legal-notice/") }
    static let supportEmail = "laplateformemjh@gmail.com"

    /// E-mail au support, avec l'identifiant du compte dans l'objet pour retrouver le joueur.
    static func mail(accountId: String?) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        let subject = accountId.map { id in String(localized: "Pearl Inc. (identifiant \(id))") } ?? "Pearl Inc."
        components.queryItems = [URLQueryItem(name: "subject", value: subject)]
        return components.url ?? URL(string: "mailto:\(supportEmail)")!
    }

    /// « version 0.1 (1) ».
    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return String(localized: "version \(short) (\(build))")
    }
}

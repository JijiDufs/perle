import AuthenticationServices
import CryptoKit
import Foundation
import Supabase

/// Gère la session du joueur : Sign in with Apple, code reçu par e-mail, ou partie sans compte.
@MainActor
final class AuthViewModel: ObservableObject {
    enum Step: Equatable {
        case choose          // écran principal
        case email           // saisie de l'adresse
        case code(String)    // saisie du code reçu à cette adresse
    }

    @Published var session: Session?
    @Published var step: Step = .choose
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Nonce brut envoyé à Supabase ; Apple reçoit son empreinte SHA-256.
    private var currentNonce: String?

    init() {
        session = supabase.auth.currentSession
        Task { await listenToAuthChanges() }
    }

    private func listenToAuthChanges() async {
        for await (_, session) in supabase.auth.authStateChanges {
            self.session = session
        }
    }

    // MARK: - Sign in with Apple

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            // L'utilisateur a fermé la fenêtre Apple : ce n'est pas une erreur à afficher.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = String(localized: "La connexion avec Apple n’a pas abouti. Réessaie dans un instant.")
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = String(localized: "Apple n’a pas renvoyé d’identifiant. Réessaie dans un instant.")
                return
            }
            run {
                try await supabase.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
                )
            }
        }
    }

    // MARK: - Code par e-mail

    func sendCode(to rawEmail: String) {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@"), email.contains(".") else {
            errorMessage = String(localized: "Cette adresse e-mail ne semble pas complète.")
            return
        }
        run {
            try await supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
            self.step = .code(email)
        }
    }

    func verify(code: String, email: String) {
        let token = code.filter(\.isNumber)
        guard token.count == 6 else {
            errorMessage = String(localized: "Le code contient 6 chiffres.")
            return
        }
        run {
            try await supabase.auth.verifyOTP(email: email, token: token, type: .email)
        }
    }

    // MARK: - Sans compte

    /// Crée un joueur anonyme : sa progression est sauvegardée, il pourra lier Apple ou un e-mail plus tard.
    func playAsGuest() {
        run { try await supabase.auth.signInAnonymously() }
    }

    func signOut() {
        run { try await supabase.auth.signOut() }
    }

    // MARK: - Le compte (Réglages)

    enum AccountKind { case anonymous, apple, email }

    var accountKind: AccountKind? {
        guard let user = session?.user else { return nil }
        if user.isAnonymous { return .anonymous }
        if case .string("apple") = user.appMetadata["provider"] { return .apple }
        return .email
    }

    var accountEmail: String? { session?.user.email }

    /// Début de l'identifiant du compte, à donner au support.
    var shortAccountId: String? { session.map { String($0.user.id.uuidString.prefix(8)).lowercased() } }

    /// Supprime le compte et toutes ses données (fonction `delete_account` de Supabase, en cascade),
    /// puis déconnecte. `onDeleted` efface la partie locale (règle 5.1.1 (v) de l'App Store).
    func deleteAccount(onDeleted: @escaping @MainActor () -> Void) {
        run(failure: String(localized: "La suppression n’a pas abouti. Vérifie ta connexion et réessaie, ou écris-nous.")) {
            try await supabase.rpc("delete_account").execute()
            onDeleted()
            // Le compte n'existe plus côté serveur : on oublie seulement la session sur cet iPhone.
            try? await supabase.auth.signOut(scope: .local)
        }
    }

    // MARK: - Outils

    private func run(failure: String? = nil, _ action: @escaping () async throws -> Void) {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do { try await action() } catch { errorMessage = failure ?? Self.message(for: error) }
        }
    }

    private static func message(for error: Error) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("expired") || (text.contains("invalid") && text.contains("otp")) {
            return String(localized: "Ce code est incorrect ou a expiré. Demande-en un nouveau.")
        }
        if text.contains("rate limit") {
            return String(localized: "Trop de demandes d’affilée. Attends une minute avant de réessayer.")
        }
        if (error as? URLError) != nil {
            return String(localized: "Pas de connexion internet. Vérifie ton réseau puis réessaie.")
        }
        return String(localized: "La connexion n’a pas abouti. Réessaie dans un instant.")
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in charset.randomElement(using: &generator)! })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

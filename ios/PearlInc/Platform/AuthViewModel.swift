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
            errorMessage = "La connexion avec Apple n’a pas abouti. Réessaie dans un instant."
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Apple n’a pas renvoyé d’identifiant. Réessaie dans un instant."
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
            errorMessage = "Cette adresse e-mail ne semble pas complète."
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
            errorMessage = "Le code contient 6 chiffres."
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

    // MARK: - Outils

    private func run(_ action: @escaping () async throws -> Void) {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do { try await action() } catch { errorMessage = Self.message(for: error) }
        }
    }

    private static func message(for error: Error) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("expired") || (text.contains("invalid") && text.contains("otp")) {
            return "Ce code est incorrect ou a expiré. Demande-en un nouveau."
        }
        if text.contains("rate limit") {
            return "Trop de demandes d’affilée. Attends une minute avant de réessayer."
        }
        if (error as? URLError) != nil {
            return "Pas de connexion internet. Vérifie ton réseau puis réessaie."
        }
        return "La connexion n’a pas abouti. Réessaie dans un instant."
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

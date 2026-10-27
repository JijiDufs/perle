import AuthenticationServices
import SwiftUI

/// Écran de connexion : la perle luit dans le lagon, les choix tiennent dans un panneau de verre.
struct LoginView: View {
    @ObservedObject var auth: AuthViewModel
    @State private var email = ""
    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            LagoonBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 40)
                header
                Spacer(minLength: 32)
                panel
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .animation(.snappy(duration: 0.35), value: auth.step)
        .preferredColorScheme(.dark)
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 18) {
            PearlAppIcon(size: 112)
            VStack(spacing: 8) {
                Text("Pearl Inc.")
                    .font(.system(size: 44, weight: .bold))
                    .tracking(-1.4)
                Text("Ouvre des huîtres,\ntrouve la perle rare.")
                    .font(.system(size: 19, weight: .medium))
                    .multilineTextAlignment(.center)
                    .opacity(0.88)
            }
            .foregroundStyle(.white)
            .shadow(color: Color(hex: 0x002832).opacity(0.35), radius: 12, y: 4)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Panneau

    private var panel: some View {
        VStack(spacing: 14) {
            switch auth.step {
            case .choose:          chooseContent
            case .email:           emailContent
            case .code(let mail):  codeContent(for: mail)
            }

            if let message = auth.errorMessage {
                Text(message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color(hex: 0xFFD2C8))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: 440)
        .glassPanel(cornerRadius: 32, shade: 0)
        .disabled(auth.isLoading)
        .overlay { if auth.isLoading { ProgressView().tint(.white) } }
    }

    private var chooseContent: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signIn,
                                  onRequest: auth.prepareAppleRequest,
                                  onCompletion: auth.handleAppleResult)
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(Capsule())

            Button { auth.errorMessage = nil; auth.step = .email } label: {
                Label("Continuer avec un e-mail", systemImage: "envelope.fill")
            }
            .buttonStyle(GlassButtonStyle())

            Button("Jouer sans compte", action: auth.playAsGuest)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(height: 44)

            Text("Sans compte, ta partie ne se retrouve pas sur un autre iPhone. Avec Apple ou un e-mail, elle est sauvegardée sur ton compte.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("En continuant, tu acceptes les [conditions d’utilisation](\(SiteLinks.terms.absoluteString)) et la [politique de confidentialité](\(SiteLinks.privacy.absoluteString)).")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .tint(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emailContent: some View {
        VStack(spacing: 12) {
            Text("Ton adresse e-mail")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("On t’envoie un code à 6 chiffres. Inscrit avant la sortie ? Utilise la même adresse pour récupérer ta coquille Première marée.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            TextField("", text: $email, prompt: Text("prenom@exemple.fr").foregroundStyle(.white.opacity(0.45)))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .focused($focused)
                .onSubmit { auth.sendCode(to: email) }
                .modifier(GlassField())

            Button("Recevoir le code") { auth.sendCode(to: email) }
                .buttonStyle(PearlButtonStyle())

            backButton { auth.step = .choose }
        }
        .onAppear { focused = true }
    }

    private func codeContent(for mail: String) -> some View {
        VStack(spacing: 12) {
            Text("Entre ton code")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Envoyé à \(mail)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))

            TextField("", text: $code, prompt: Text("000000").foregroundStyle(.white.opacity(0.35)))
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .semibold, design: .rounded).monospacedDigit())
                .tracking(10)
                .focused($focused)
                .onChange(of: code) { _, new in
                    code = String(new.filter(\.isNumber).prefix(6))
                    if code.count == 6 { auth.verify(code: code, email: mail) }
                }
                .modifier(GlassField())

            Button("Valider") { auth.verify(code: code, email: mail) }
                .buttonStyle(PearlButtonStyle())

            HStack(spacing: 22) {
                backButton { code = ""; auth.step = .email }
                Button("Renvoyer le code") { code = ""; auth.sendCode(to: mail) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .onAppear { focused = true }
    }

    private func backButton(_ action: @escaping () -> Void) -> some View {
        Button("Retour") { auth.errorMessage = nil; action() }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))
            .frame(height: 40)
    }
}

#Preview("Connexion") {
    LoginView(auth: AuthViewModel())
}

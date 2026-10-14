import Foundation
import Observation
import GoogleMobileAds
import UserMessagingPlatform

/// Pub récompensée, par **AdMob** (Google), avec le consentement RGPD de Google (UMP).
/// Seul fichier qui parle à la régie : les écrans et le Core n'en savent rien.
/// Ce que rapporte une pub et combien par jour : le Core (Economy.rewardedAdOysters / rewardedAdsPerDay).
/// En Debug, sans pub disponible (simulateur hors ligne, pas de stock), la pub simulée prend le relais.
@MainActor
@Observable
final class RewardedAds: NSObject, FullScreenContentDelegate {
    /// Bloc d'annonces « avec récompense ». Aujourd'hui celui de TEST de Google partout :
    /// en Release, mettre celui de Pearl Inc. (et l'App ID dans PearlInc-Info.plist) avant la soumission.
    #if DEBUG
    static let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #endif

    /// Durée de la pub simulée, en secondes (une vraie pub dure de 15 à 30 s).
    static let simulatedSeconds = 5
    /// Après un échec de chargement, on réessaie au bout de ce délai.
    static let retryDelay: Duration = .seconds(60)
    /// Une pub chargée expire au bout d'une heure (règle de Google) : on en recharge une.
    static let adLifetime: TimeInterval = 3600

    /// La pub simulée est à l'écran (Debug seulement).
    private(set) var isShowing = false
    /// Une vraie pub est chargée, prête à être montrée.
    private(set) var isReady = false
    /// Le joueur doit pouvoir revoir ses choix de confidentialité (RGPD) : bouton dans les Réglages.
    private(set) var privacyOptionsRequired = false

    @ObservationIgnored private var consentRequested = false
    @ObservationIgnored private var sdkStarted = false
    @ObservationIgnored private var isLoading = false
    @ObservationIgnored private var ad: RewardedAd?
    @ObservationIgnored private var loadedAt = Date.distantPast
    @ObservationIgnored private var earned = false
    @ObservationIgnored private var completion: ((Bool) -> Void)?

    /// Le bouton « Regarder une pub » peut servir.
    var canShow: Bool {
        #if DEBUG
        true
        #else
        isReady
        #endif
    }

    /// Au premier affichage du jeu : consentement (formulaire de Google si la loi l'exige),
    /// puis démarrage d'AdMob et chargement de la première pub.
    func start() async {
        guard !consentRequested else { return }
        consentRequested = true
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // Hors ligne ou formulaire indisponible : le consentement d'une séance précédente reste valable.
        }
        await afterConsent()
    }

    /// « Choix de confidentialité des pubs » (Réglages) : rouvre le formulaire de Google.
    func showPrivacyOptions() async {
        try? await ConsentForm.presentPrivacyOptionsForm(from: nil)
        await afterConsent()
    }

    /// Montre une pub ; `completion(true)` si elle a été regardée jusqu'au bout.
    func show(completion: @escaping (Bool) -> Void) {
        guard self.completion == nil else { return }
        if let ad, Date().timeIntervalSince(loadedAt) < Self.adLifetime {
            self.completion = completion
            earned = false
            ad.present(from: nil) { [weak self] in
                MainActor.assumeIsolated { self?.earned = true }
            }
            return
        }
        discardAd()
        load()
        #if DEBUG
        self.completion = completion
        isShowing = true
        #else
        completion(false)
        #endif
    }

    /// Fin de la pub simulée (appelé par l'écran de la pub simulée).
    func finish(rewarded: Bool) {
        isShowing = false
        complete(rewarded: rewarded)
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        discardAd()
        complete(rewarded: earned)
        load()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        discardAd()
        complete(rewarded: false)
        load()
    }

    // MARK: - Interne

    private func afterConsent() async {
        let consent = ConsentInformation.shared
        privacyOptionsRequired = consent.privacyOptionsRequirementStatus == .required
        guard consent.canRequestAds else { return }
        if !sdkStarted {
            sdkStarted = true
            _ = await MobileAds.shared.start()
        }
        load()
    }

    private func load() {
        guard sdkStarted, ad == nil, !isLoading, ConsentInformation.shared.canRequestAds else { return }
        isLoading = true
        Task {
            do {
                let ad = try await RewardedAd.load(with: Self.adUnitID, request: Request())
                ad.fullScreenContentDelegate = self
                self.ad = ad
                loadedAt = Date()
                isReady = true
                isLoading = false
            } catch {
                isLoading = false
                try? await Task.sleep(for: Self.retryDelay)
                load()
            }
        }
    }

    private func discardAd() {
        ad = nil
        isReady = false
    }

    private func complete(rewarded: Bool) {
        completion?(rewarded)
        completion = nil
    }
}

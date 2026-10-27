import Foundation
import Observation
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

/// Pub récompensée, par **AdMob** (Google), avec le consentement RGPD de Google (UMP) et la fenêtre de suivi d'Apple
/// (ATT), demandés au premier « Regarder une pub » (1.2). Pubs personnalisées seulement si le joueur accepte le suivi.
/// Seul fichier qui parle à la régie : les écrans et le Core n'en savent rien.
/// Ce que rapporte une pub et combien par jour : le Core (Economy.rewardedAdOysters / rewardedAdsPerDay).
/// En Debug, sans pub disponible (simulateur hors ligne, pas de stock), la pub simulée prend le relais.
@MainActor
@Observable
final class RewardedAds: NSObject, FullScreenContentDelegate {
    /// Bloc d'annonces « avec récompense » (3 huîtres). En Debug, celui de TEST de Google : on ne voit
    /// jamais ses propres vraies pubs en développement (risque de suspension du compte AdMob).
    #if DEBUG
    static let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let adUnitID = "ca-app-pub-1299710250358184/7814403570"
    #endif

    /// Durée de la pub simulée, en secondes (une vraie pub dure de 15 à 30 s).
    static let simulatedSeconds = 5
    /// Après un échec de chargement, on réessaie au bout de ce délai.
    static let retryDelay: Duration = .seconds(60)
    /// Une pub chargée expire au bout d'une heure (règle de Google) : on en recharge une.
    static let adLifetime: TimeInterval = 3600
    /// Première pub : après les réponses du joueur, on attend au plus ce temps qu'elle se charge.
    static let firstAdWait: Duration = .seconds(10)

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

    /// Le bouton « Regarder une pub » peut servir : une pub est prête, ou c'est la première (le toucher pose
    /// d'abord les questions, puis la pub se charge).
    var canShow: Bool {
        #if DEBUG
        true
        #else
        isReady || !consentRequested
        #endif
    }

    /// Au lancement : si le joueur a déjà répondu au formulaire de Google et à la fenêtre d'Apple, AdMob démarre pour
    /// que la pub soit prête. Rien ne s'affiche jamais ici : une question qui manque attend le premier
    /// « Regarder une pub ».
    func startIfConsentKnown() async {
        let status = ConsentInformation.shared.consentStatus
        guard status == .obtained || status == .notRequired,
              ATTrackingManager.trackingAuthorizationStatus != .notDetermined else { return }
        try? await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
        await afterConsent()
    }

    /// Consentement (formulaire de Google si la loi l'exige), fenêtre de suivi d'Apple si elle n'a jamais été
    /// montrée, puis démarrage d'AdMob et chargement d'une pub.
    func start() async {
        guard !consentRequested else { return }
        consentRequested = true
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // Hors ligne ou formulaire indisponible : le consentement d'une séance précédente reste valable.
        }
        // La récompense ne dépend jamais de la réponse (règle 5.1.2 d'Apple).
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
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
        if !consentRequested {
            // Première pub de la séance sans pub prête : d'abord les questions qui manquent (Google, puis Apple),
            // ensuite la pub dès qu'elle est chargée.
            self.completion = completion
            Task {
                await start()
                let deadline = ContinuousClock.now + Self.firstAdWait
                while ad == nil, ContinuousClock.now < deadline { try? await Task.sleep(for: .milliseconds(250)) }
                guard let waiting = self.completion else { return }
                self.completion = nil
                show(completion: waiting)
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
        // Pubs personnalisées seulement si le joueur a accepté le suivi (fenêtre d'Apple, modifiable dans les Réglages
        // d'iOS) ; sinon non personnalisées. En Europe, le formulaire de Google s'applique en plus.
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState =
            ATTrackingManager.trackingAuthorizationStatus == .authorized ? .enabled : .disabled
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

import Foundation
import Observation
import StoreKit

/// Achats intégrés d'Apple (StoreKit 2), docs/duo-gadget.md §6 ter : huîtres et poussière d'or (consommables),
/// skins (non consommables). Les prix affichés viennent toujours de StoreKit, jamais écrits en dur.
/// Les transactions sont vérifiées par StoreKit (signées par Apple), sans serveur.
/// Ce qu'un achat donne est décidé par le Core (PlayerState.grant…), pas ici.
@MainActor
@Observable
final class Store {
    private(set) var products: [String: Product] = [:]
    /// Achat en cours (identifiant du produit).
    private(set) var purchasing: String?
    /// Un achat est arrivé (achat, achat différé validé plus tard, ou restauration) : à donner au joueur.
    @ObservationIgnored var onDeliver: ((String) -> Void)?
    @ObservationIgnored private var updates: Task<Void, Never>?

    /// Charge les produits, écoute les achats arrivés hors de l'app et restaure les skins déjà achetés.
    func start(productIds: [String]) {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.deliver(result) }
        }
        Task {
            if let loaded = try? await Product.products(for: productIds) {
                products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            }
            await syncEntitlements()
        }
    }

    /// Prix localisé (« 2,99 € »), nil tant que StoreKit ne l'a pas donné.
    func price(_ productId: String) -> String? { products[productId]?.displayPrice }

    /// Achète un produit. true si l'achat est validé et livré.
    func purchase(_ productId: String) async -> Bool {
        guard let product = products[productId], purchasing == nil else { return false }
        purchasing = productId
        defer { purchasing = nil }
        guard let result = try? await product.purchase(), case .success(let verification) = result else { return false }
        return await deliver(verification)
    }

    /// « Restaurer les achats » : les skins achetés sur un autre téléphone.
    func restore() async {
        try? await AppStore.sync()
        await syncEntitlements()
    }

    /// Relit les skins déjà achetés (sans fenêtre Apple), par exemple après une partie remise à zéro.
    func refreshEntitlements() {
        Task { await syncEntitlements() }
    }

    private func syncEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                onDeliver?(transaction.productID)
            }
        }
    }

    @discardableResult
    private func deliver(_ result: VerificationResult<Transaction>) async -> Bool {
        guard case .verified(let transaction) = result else { return false }
        if transaction.revocationDate == nil { onDeliver?(transaction.productID) }
        await transaction.finish()
        return transaction.revocationDate == nil
    }
}

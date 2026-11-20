import Foundation
import PearlCore

/// Mise à jour disponible : la version de Pearl Inc. en ligne sur l'App Store (service public de recherche d'Apple,
/// rien sur le joueur n'est envoyé), si elle est plus récente que celle installée. Apple met parfois quelques heures à
/// annoncer une nouvelle version : la fenêtre arrive alors au lancement suivant.
enum AppUpdate {
    /// Fiche de Pearl Inc. sur l'App Store (identifiant de l'app : 6822782842).
    static let storePage = URL(string: "https://apps.apple.com/app/id6822782842")!
    private static let lookup = URL(string: "https://itunes.apple.com/lookup?id=6822782842")!

    private struct Lookup: Decodable {
        struct App: Decodable { let version: String }
        let results: [App]
    }

    /// La version en ligne si elle est plus récente ; nil sinon, hors ligne ou en cas d'erreur.
    static func available() async -> String? {
        let installed = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        var request = URLRequest(url: lookup, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "GET"
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let store = (try? JSONDecoder().decode(Lookup.self, from: data))?.results.first?.version,
              isNewerVersion(store, than: installed) else { return nil }
        return store
    }
}

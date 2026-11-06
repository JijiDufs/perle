import UIKit

/// L'app est en portrait, sauf sur l'écran intérieur de l'iPhone Duo, qui se tient aussi en paysage (pli horizontal) :
/// un testeur ne pouvait jouer que dans un sens (2026-11-06). Info.plist déclare les deux ; on choisit ici.
final class OrientationDelegate: NSObject, UIApplicationDelegate {
    @MainActor private static var mask: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        MainActor.assumeIsolated { Self.mask }
    }

    /// Paysage permis tant qu'un pli est là (écran intérieur) ; sinon on revient en portrait.
    @MainActor static func allowLandscape(_ allowed: Bool) {
        let wanted: UIInterfaceOrientationMask = allowed ? .allButUpsideDown : .portrait
        guard wanted != mask else { return }
        mask = wanted
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
        }
    }
}

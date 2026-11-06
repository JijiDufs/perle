import UIKit

/// Retours haptiques. Première version avec les retours UIKit standard ;
/// Core Haptics (résistance qui monte, battement de cœur) viendra ensuite.
@MainActor
final class Haptics {
    /// Réglage « Vibrations » (écran Réglages), activé par défaut.
    static let settingKey = "pearlinc.settings.haptics"
    private var isEnabled: Bool { UserDefaults.standard.object(forKey: Self.settingKey) as? Bool ?? true }

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        light.prepare()
        rigid.prepare()
        soft.prepare()
    }

    /// Un cran de résistance.
    func tick() { if isEnabled { light.impactOccurred(intensity: 0.6) } }

    /// La coquille cède.
    func pop() { if isEnabled { rigid.impactOccurred(intensity: 1) } }

    /// La perle se fêle.
    func crack() { if isEnabled { notification.notificationOccurred(.error) } }

    /// Sur la charnière du Duo : la coquille cède, sans claquement sec (on croyait casser le téléphone).
    func softPop() { if isEnabled { soft.impactOccurred(intensity: 0.8) } }

    /// Sur la charnière du Duo : la perle se fêle, un seul coup sourd au lieu de la triple alerte.
    func softCrack() { if isEnabled { soft.impactOccurred(intensity: 1) } }

    /// Pulsation du suspense, plus forte pour les perles rares.
    func suspensePulse(tier: Int) { if isEnabled { heavy.impactOccurred(intensity: 0.4 + 0.2 * CGFloat(tier)) } }

    /// La carte apparaît.
    func reveal(tier: Int) {
        guard isEnabled else { return }
        if tier >= 2 { notification.notificationOccurred(.success) } else { rigid.impactOccurred(intensity: 0.7) }
    }
}

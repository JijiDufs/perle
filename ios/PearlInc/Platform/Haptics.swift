import UIKit

/// Retours haptiques. Première version avec les retours UIKit standard ;
/// Core Haptics (résistance qui monte, battement de cœur) viendra ensuite.
@MainActor
final class Haptics {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        light.prepare()
        rigid.prepare()
    }

    /// Un cran de résistance.
    func tick() { light.impactOccurred(intensity: 0.6) }

    /// La coquille cède.
    func pop() { rigid.impactOccurred(intensity: 1) }

    /// La perle se fêle.
    func crack() { notification.notificationOccurred(.error) }

    /// Pulsation du suspense, plus forte pour les perles rares.
    func suspensePulse(tier: Int) { heavy.impactOccurred(intensity: 0.4 + 0.2 * CGFloat(tier)) }

    /// La carte apparaît.
    func reveal(tier: Int) {
        if tier >= 2 { notification.notificationOccurred(.success) } else { rigid.impactOccurred(intensity: 0.7) }
    }
}

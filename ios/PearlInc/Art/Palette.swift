import SwiftUI

/// Couleurs de la direction « lagon lumineux + luxe » (AGENTS.md §6).
enum Palette {
    static let gold = Color(hex: "#E2B04A")
    static let night = Color(hex: "#0B1B2B")
    static let lagoonTop = Color(hex: "#1B8FA6")
    static let lagoonMid = Color(hex: "#3FB7B9")
    static let sand = Color(hex: "#D9C9A0")
    static let flesh = Color(hex: "#E8DCC4")
}

extension Color {
    /// Couleur depuis « #RRGGBB » (les couleurs du catalogue).
    init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(digits, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// Transition douce entre deux bornes (0 avant `from`, 1 après `to`).
func smoothstep(_ from: Double, _ to: Double, _ value: Double) -> Double {
    let x = min(1, max(0, (value - from) / (to - from)))
    return x * x * (3 - 2 * x)
}

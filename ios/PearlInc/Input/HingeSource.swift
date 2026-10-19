import SwiftUI
import UIKit
import os

/// Source de geste « charnière » (iPhone Duo, iOS 27.1+) : transmet l'angle du téléphone en degrés
/// (0 = fermé, 180 = à plat), ou nil sur un iPhone sans charnière. Le jeu en fait des OpeningSample
/// (PearlCore/Hinge.swift). On passe par UIHingeInteraction, qui donne aussi l'état de départ
/// (`onHingeChange` de SwiftUI ne prévient qu'aux changements).
/// En Debug, l'argument de lancement `-SimulatedHinge` remplace la charnière par un curseur.
struct HingeInput: ViewModifier {
    let onChange: (Double?) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *), !HingeInput.simulated {
            content.background(HingeObserver(onChange: onChange).allowsHitTesting(false))
        } else {
            content
        }
    }

    static var simulated: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-SimulatedHinge")
        #else
        false
        #endif
    }
}

extension View {
    func hingeInput(_ onChange: @escaping (Double?) -> Void) -> some View {
        modifier(HingeInput(onChange: onChange))
    }
}

@available(iOS 27.1, *)
private struct HingeObserver: UIViewRepresentable {
    let onChange: (Double?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let coordinator = context.coordinator
        view.addInteraction(UIHingeInteraction { _, update in
            let degrees = update.hinge.map { Double($0.angle) * 180 / .pi }
            #if DEBUG
            Logger(subsystem: "app.pearlinc", category: "charniere")
                .debug("charnière : \(degrees.map { String(format: "%.1f°", $0) } ?? "aucune", privacy: .public) \(String(describing: update.hinge?.status.rawValue), privacy: .public)")
            #endif
            coordinator.onChange(degrees)
        })
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.onChange = onChange
    }

    @MainActor
    final class Coordinator {
        var onChange: (Double?) -> Void
        init(onChange: @escaping (Double?) -> Void) { self.onChange = onChange }
    }
}

#if DEBUG
/// Curseur de charnière simulée (Debug, `-SimulatedHinge`) : 0° = fermé, 180° = à plat.
struct SimulatedHingeSlider: View {
    let onChange: (Double?) -> Void
    @State private var degrees = 0.0

    static var isEnabled: Bool { HingeInput.simulated }

    var body: some View {
        VStack(spacing: 4) {
            Text(verbatim: "Charnière simulée : \(Int(degrees))°").font(.caption.monospacedDigit())
            Slider(value: $degrees, in: 0...180)
                .tint(.white)
                .onChange(of: degrees) { _, value in onChange(value) }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .glass(RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .onAppear { onChange(degrees) }
    }
}
#endif

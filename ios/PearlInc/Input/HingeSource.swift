import SwiftUI
import UIKit
import os

/// Source de geste « charnière » (iPhone Duo, iOS 27.1+) : transmet l'angle du téléphone en degrés
/// (0 = fermé, 180 = à plat), ou nil sur un iPhone sans charnière. Le jeu en fait des OpeningSample
/// (PearlCore/Hinge.swift). On passe par UIHingeInteraction, qui donne aussi l'état de départ
/// (`onHingeChange` de SwiftUI ne prévient qu'aux changements).
/// En Debug, l'argument de lancement `-SimulatedHinge` remplace la charnière par un curseur.
/// Donne aussi la position du pli de l'écran intérieur (abscisse en points dans la fenêtre, nil sur
/// l'écran extérieur ou sans charnière) : la charnière de l'huître s'y aligne, comme sur pearl-inc.app.
struct HingeInput: ViewModifier {
    let onChange: (Double?) -> Void
    let onFold: (Double?) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *), !HingeInput.simulated {
            content.background(HingeObserver(onChange: onChange, onFold: onFold).allowsHitTesting(false))
        } else {
            content
        }
    }

    /// Debug, `-SimulatedFold` : un pli au milieu de l'écran, comme l'écran intérieur du Duo.
    static var simulatedFold: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-SimulatedFold")
        #else
        false
        #endif
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
    func hingeInput(_ onChange: @escaping (Double?) -> Void, fold onFold: @escaping (Double?) -> Void) -> some View {
        modifier(HingeInput(onChange: onChange, onFold: onFold))
    }
}

@available(iOS 27.1, *)
private struct HingeObserver: UIViewRepresentable {
    let onChange: (Double?) -> Void
    let onFold: (Double?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    func makeUIView(context: Context) -> FoldView {
        let view = FoldView()
        view.onFold = onFold
        view.isUserInteractionEnabled = false
        let coordinator = context.coordinator
        view.addInteraction(UIHingeInteraction { [weak view] _, update in
            view?.reportFold()
            let degrees = update.hinge.map { Double($0.angle) * 180 / .pi }
            #if DEBUG
            Logger(subsystem: "app.pearlinc", category: "charniere")
                .debug("charnière : \(degrees.map { String(format: "%.1f°", $0) } ?? "aucune", privacy: .public) \(String(describing: update.hinge?.status.rawValue), privacy: .public)")
            #endif
            coordinator.onChange(degrees)
        })
        return view
    }

    func updateUIView(_ view: FoldView, context: Context) {
        context.coordinator.onChange = onChange
        view.onFold = onFold
    }

    /// Lit le pli (zone réservée « division ») à chaque mise en page, donc à chaque changement d'écran.
    final class FoldView: UIView {
        var onFold: ((Double?) -> Void)?
        private var lastFold: Double??

        override func layoutSubviews() {
            super.layoutSubviews()
            reportFold()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportFold()
        }

        func reportFold() {
            guard let window else { return }
            // Pli vertical seulement (téléphone ouvert comme un livre), même à plat (zone inactive).
            let fold = reservedRegions(kind: .division, options: .includeInactive)
                .map { convert($0.frame, to: window) }
                .first { $0.height > $0.width }
                .map { Double($0.midX) }
            guard lastFold != .some(fold) else { return }
            lastFold = .some(fold)
            onFold?(fold)
        }
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

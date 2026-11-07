import AVFoundation
import SwiftUI

/// Essai : le lagon en vidéo en boucle (`lagoon-loop.mp4`, montée en aller-retour pour boucler sans couture)
/// à la place du dessin. Réglage de test : `defaults write app.pearlinc.PearlInc LagoonVideo -bool true`.
struct LagoonVideo: UIViewRepresentable {
    static let url = Bundle.main.url(forResource: "lagoon-loop", withExtension: "mp4")
    static var isEnabled: Bool { url != nil && UserDefaults.standard.bool(forKey: "LagoonVideo") }

    func makeUIView(context: Context) -> PlayerView { PlayerView() }
    func updateUIView(_ view: PlayerView, context: Context) {}

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private let player = AVQueuePlayer()
        private var looper: AVPlayerLooper?

        override init(frame: CGRect) {
            super.init(frame: frame)
            guard let url = LagoonVideo.url, let layer = layer as? AVPlayerLayer else { return }
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            layer.player = player
            layer.videoGravity = .resizeAspectFill
            player.isMuted = true
            player.play()
        }

        required init?(coder: NSCoder) { nil }
    }
}

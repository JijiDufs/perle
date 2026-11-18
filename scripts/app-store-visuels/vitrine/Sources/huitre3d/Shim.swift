import AppKit
import SwiftUI

// Le code de l'app est écrit pour iOS : mêmes noms sur Mac. Les photos et textures sont chargées par Bundle.main,
// le script les copie à côté de l'exécutable.
typealias UIImage = NSImage
typealias UIColor = NSColor
extension Image { init(uiImage: NSImage) { self.init(nsImage: uiImage) } }

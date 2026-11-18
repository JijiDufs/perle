// QR code de la fiche App Store de Pearl Inc., pour le bas de pearl-inc.app (visiteurs sur ordinateur).
// Fait par CoreImage, relu par Vision avant d'être écrit : si la relecture ne redonne pas l'adresse, rien n'est écrit.
// Usage : swift scripts/site/qr.swift > site/img/qr-app-store.svg
import AppKit
import CoreImage
import Vision

let url = "https://apps.apple.com/app/pearl-inc/id6822782842"  // APP_STORE_URL de site/index.html
let filter = CIFilter(name: "CIQRCodeGenerator")!
filter.setValue(Data(url.utf8), forKey: "inputMessage")
filter.setValue("M", forKey: "inputCorrectionLevel")
let image = filter.outputImage!, context = CIContext()

let zoom = CGAffineTransform(scaleX: 12, y: 12)
let request = VNDetectBarcodesRequest()
try! VNImageRequestHandler(cgImage: context.createCGImage(image.transformed(by: zoom), from: image.extent.applying(zoom))!).perform([request])
precondition(request.results?.first?.payloadStringValue == url, "QR code illisible")

// Un module = un pixel ; chaque suite de modules noirs d'une ligne devient un rectangle du chemin.
let bitmap = NSBitmapImageRep(cgImage: context.createCGImage(image, from: image.extent)!)
let n = bitmap.pixelsWide
var path = ""
for y in 0..<n {
    var x = 0
    while x < n {
        guard bitmap.colorAt(x: x, y: y)!.brightnessComponent < 0.5 else { x += 1; continue }
        let start = x
        while x < n, bitmap.colorAt(x: x, y: y)!.brightnessComponent < 0.5 { x += 1 }
        path += "M\(start) \(y)h\(x - start)v1h-\(x - start)z"
    }
}
print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"-1 -1 \(n + 2) \(n + 2)\" shape-rendering=\"crispEdges\">"
    + "<rect x=\"-1\" y=\"-1\" width=\"\(n + 2)\" height=\"\(n + 2)\" fill=\"#fff\"/><path fill=\"#06343c\" d=\"\(path)\"/></svg>")

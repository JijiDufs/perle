// Outils image ↔ vidéo pour la vidéo de lancement (AVFoundation : pas besoin de ffmpeg).
//   swift frames.swift extract <vidéo> <dossier> [fps] [début fin] → dossier/00000.jpg… (images à fps constant)
//   swift frames.swift encode <dossier png> <sortie.mp4> <fps> [son.wav]
//   swift frames.swift ui <sortie.png> <bandes en pt « y0-y1,y0-y1 »> <images…>
//     → l'interface de l'app seule (PNG transparent) : les pixels immobiles d'une prise à l'autre, dans les bandes.
import AVFoundation
import AppKit

let args = CommandLine.arguments
func fail(_ s: String) -> Never { FileHandle.standardError.write((s + "\n").data(using: .utf8)!); exit(1) }

func extract(_ src: String, _ dir: String, _ fps: Double, _ from: Double = 0, _ to: Double? = nil) async throws {
    let asset = AVURLAsset(url: URL(fileURLWithPath: src))
    let duration = try await asset.load(.duration).seconds
    let gen = AVAssetImageGenerator(asset: asset)
    gen.requestedTimeToleranceBefore = .zero
    gen.requestedTimeToleranceAfter = .zero
    gen.appliesPreferredTrackTransform = true
    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let count = Int(((to ?? duration) - from) * fps)
    for i in 0..<count {
        let t = CMTime(seconds: from + Double(i) / fps, preferredTimescale: 6000)
        let (cg, _) = try await gen.image(at: t)
        let rep = NSBitmapImageRep(cgImage: cg)
        let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!
        try data.write(to: URL(fileURLWithPath: String(format: "%@/%05d.jpg", dir, i)))
    }
    print("\(count) images, \(String(format: "%.2f", duration)) s → \(dir)")
}

func encode(_ dir: String, _ out: String, _ fps: Int32, _ wav: String?) async throws {
    let files = try FileManager.default.contentsOfDirectory(atPath: dir).filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") }.sorted()
    guard let first = NSImage(contentsOfFile: dir + "/" + files[0])?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { fail("pas d'image") }
    let w = first.width, h = first.height
    // L'image d'abord (seule), le son ensuite : écrire les deux pistes ensemble bloque AVAssetWriter.
    let silent = URL(fileURLWithPath: wav == nil ? out : out + ".video.mp4")
    try? FileManager.default.removeItem(at: silent)
    let writer = try AVAssetWriter(outputURL: silent, fileType: .mp4)
    let video = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: w, AVVideoHeightKey: h,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 14_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                          AVVideoMaxKeyFrameIntervalKey: Int(fps)]])
    video.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: video, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: w, kCVPixelBufferHeightKey as String: h])
    writer.add(video)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)
    for (i, f) in files.enumerated() {
        while !video.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 2_000_000) }
        guard let img = NSImage(contentsOfFile: dir + "/" + f)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { fail("image illisible \(f)") }
        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb!), width: w, height: h, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb!),
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        CVPixelBufferUnlockBaseAddress(pb!, [])
        adaptor.append(pb!, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
    }
    video.markAsFinished()
    await writer.finishWriting()
    if writer.status != .completed { fail("échec : \(String(describing: writer.error))") }
    guard let wav else { print("\(files.count) images \(w)×\(h) → \(out)"); return }
    // Le son : composition image + musique, réencodée en AAC par l'export.
    let comp = AVMutableComposition()
    let v = AVURLAsset(url: silent), a = AVURLAsset(url: URL(fileURLWithPath: wav))
    let range = CMTimeRange(start: .zero, duration: try await v.load(.duration))
    try comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        .insertTimeRange(range, of: try await v.loadTracks(withMediaType: .video)[0], at: .zero)
    try comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        .insertTimeRange(range, of: try await a.loadTracks(withMediaType: .audio)[0], at: .zero)
    let url = URL(fileURLWithPath: out)
    try? FileManager.default.removeItem(at: url)
    let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough)!
    try await export.export(to: url, as: .mp4)
    try? FileManager.default.removeItem(at: silent)
    print("\(files.count) images \(w)×\(h) + son → \(out)")
}

/// L'interface (barres, messages, onglets) ne bouge pas, le décor (lagon, salon) si : on garde les pixels
/// dont l'écart type sur les images est faible, avec leur moyenne, dans les bandes données (points, × 3).
func ui(_ out: String, _ bands: String, _ paths: [String]) {
    let imgs = paths.map { NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: $0)))! }
    let w = imgs[0].pixelsWide, h = imgs[0].pixelsHigh, n = Double(imgs.count)
    let ranges = bands.split(separator: ",").map { $0.split(separator: "-").map { Double($0)! * 3 } }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: w * 4, bitsPerPixel: 32)!
    let dst = rep.bitmapData!
    let srcs = imgs.map { ($0.bitmapData!, $0.bytesPerRow, $0.bitsPerPixel / 8) }
    for y in 0..<h {
        let yy = Double(y)
        // Bord des bandes adouci sur 12 px.
        let inBand = ranges.map { min(1, max(0, (yy - $0[0]) / 12), max(0, ($0[1] - yy) / 12)) }.max() ?? 0
        for x in 0..<w {
            var sum = [0.0, 0, 0], sq = 0.0
            for (d, bpr, bpp) in srcs { let o = y * bpr + x * bpp
                let r = Double(d[o]), g = Double(d[o + 1]), b = Double(d[o + 2]); sum[0] += r; sum[1] += g; sum[2] += b; sq += r * r + g * g + b * b }
            let mean = sum.map { $0 / n }
            let variance = max(0, sq / n - mean.reduce(0) { $0 + $1 * $1 }) / 3
            let still = 1 - min(1, max(0, (variance.squareRoot() - 2.5) / 5))
            let o = (y * w + x) * 4
            let a = still * inBand
            dst[o] = UInt8(mean[0] * a); dst[o + 1] = UInt8(mean[1] * a); dst[o + 2] = UInt8(mean[2] * a); dst[o + 3] = UInt8(a * 255)
        }
    }
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
    print("interface (\(imgs.count) images) → \(out)")
}

switch args.count > 1 ? args[1] : "" {
case "extract": try await extract(args[2], args[3], args.count > 4 ? Double(args[4])! : 30, args.count > 6 ? Double(args[5])! : 0, args.count > 6 ? Double(args[6])! : nil)
case "ui": ui(args[2], args[3], Array(args[4...]))
case "encode": try await encode(args[2], args[3], Int32(args[4])!, args.count > 5 ? args[5] : nil)
default: fail("usage : swift frames.swift extract|encode …")
}

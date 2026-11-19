// Musique et effets sonores de la vidéo « Pearl Inc. fait peau neuve », générés par code (comme les sons de l'app : aucune licence).
// Instruments de scripts/video-lancement/music.swift. 120 battements par minute, do – sol – la mineur – fa (les mesures
// commencent aux secondes impaires : la chute de l'accroche tombe à 3 s), calée sur le montage de index.html (instants en secondes).
// usage : swift music.swift <sortie.wav>
import Foundation

let SR = 48000.0, DUR = 32.0, N = Int(SR * DUR)
var L = [Float](repeating: 0, count: N), R = L, pads = L, rev = L
var seed: UInt64 = 0x9E3779B97F4A7C15
func noise() -> Double { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return Double(seed % 2_000_001) / 1_000_000 - 1 }
func hz(_ midi: Double) -> Double { 440 * pow(2, (midi - 69) / 12) }
func env(_ t: Double, a: Double, d: Double) -> Double { t < a ? t / a : exp(-(t - a) / d) }

/// Pose un son (mono) à l'instant t : gain, panoramique (-1…1), part envoyée à la réverbération, bus des nappes.
func put(_ t: Double, _ s: [Double], _ g: Double, pan: Double = 0, send: Double = 0, pad: Bool = false) {
    let i0 = Int(t * SR)
    let gl = g * sqrt((1 - pan) / 2) * 1.414, gr = g * sqrt((1 + pan) / 2) * 1.414
    for (k, v) in s.enumerated() {
        let i = i0 + k; if i < 0 || i >= N { continue }
        if pad { pads[i] += Float(v * g) } else { L[i] += Float(v * gl); R[i] += Float(v * gr) }
        rev[i] += Float(v * g * send)
    }
}
func buf(_ d: Double, _ f: (Double) -> Double) -> [Double] { (0..<Int(d * SR)).map { f(Double($0) / SR) } }
/// Filtre passe-bas à un pôle (fréquence de coupure fixe).
func lowpass(_ s: [Double], _ fc: Double) -> [Double] { let a = 1 - exp(-2 * .pi * fc / SR); var y = 0.0; return s.map { y += a * ($0 - y); return y } }
func highpass(_ s: [Double], _ fc: Double) -> [Double] { let lp = lowpass(s, fc); return zip(s, lp).map { $0 - $1 } }
/// Passe-bande à variable d'état, coupure qui varie dans le temps.
func bandSweep(_ s: [Double], _ fc: (Double) -> Double, q: Double = 2) -> [Double] {
    var low = 0.0, band = 0.0
    return s.enumerated().map { i, x in
        let f = 2 * sin(.pi * min(fc(Double(i) / SR), 9000) / SR)
        low += f * band; let high = x - low - band / q; band += f * high; return band
    }
}
func saw(_ p: Double) -> Double { 2 * (p - floor(p + 0.5)) }
func tri(_ p: Double) -> Double { 2 / .pi * asin(sin(2 * .pi * p)) }

// ---------- Instruments ----------
func kick(_ g: Double = 1) -> [Double] {
    var ph = 0.0
    return buf(0.45) { t in ph += (45 + 120 * exp(-t / 0.03)) / SR; return g * (sin(2 * .pi * ph) * exp(-t / 0.22) + 0.3 * noise() * exp(-t / 0.004)) }
}
func clap() -> [Double] { bandSweep(buf(0.25) { t in noise() * (env(t, a: 0.001, d: 0.06) + 0.6 * exp(-max(0, t - 0.012) / 0.01) * (t > 0.012 ? 1 : 0)) }, { _ in 1500 }, q: 1.2) }
func hat(_ d: Double = 0.045) -> [Double] { highpass(buf(d * 3) { t in noise() * exp(-t / d) }, 7000) }
func pluck(_ f: Double, _ d: Double = 0.35) -> [Double] { lowpass(buf(d) { t in (0.7 * tri(f * t) + 0.3 * saw(f * t)) * env(t, a: 0.003, d: d / 3.5) }, 5000) }
func bass(_ f: Double, _ d: Double) -> [Double] { lowpass(buf(d) { t in (0.6 * saw(f * t) + 0.8 * sin(2 * .pi * f * t)) * env(t, a: 0.005, d: d * 0.7) * min(1, (d - t) / 0.02) }, 420) }
func pad(_ fs: [Double], _ d: Double, cutoff: Double = 1800) -> [Double] {
    lowpass(buf(d) { t in
        let a = min(1, t / 0.35) * min(1, (d - t) / 0.4)
        return a * fs.reduce(0) { s, f in s + (saw(f * 0.997 * t) + saw(f * 1.003 * t + 0.3) + 0.5 * saw(f * 2.001 * t)) / 2.5 } / Double(fs.count)
    }, cutoff)
}
func bell(_ f: Double, _ d: Double = 1.6) -> [Double] { buf(d) { t in (sin(2 * .pi * f * t) + 0.35 * sin(2 * .pi * f * 2.76 * t) * exp(-t / 0.2) + 0.15 * sin(2 * .pi * f * 5.4 * t) * exp(-t / 0.08)) * env(t, a: 0.002, d: d / 4) } }
func impact(_ g: Double = 1) -> [Double] {
    var ph = 0.0
    let boom = buf(2.2) { t in ph += (32 + 70 * exp(-t / 0.08)) / SR; return sin(2 * .pi * ph) * exp(-t / 0.6) }
    let crash = highpass(buf(2.2) { t in noise() * exp(-t / 0.5) }, 3500)
    return zip(boom, crash).map { g * ($0 + 0.25 * $1) }
}
func whoosh(_ d: Double) -> [Double] { bandSweep(buf(d) { t in noise() * sin(.pi * min(1, t / d)) }, { t in 300 * pow(30, t / d) }, q: 1.5) }
func riser(_ d: Double) -> [Double] {
    let n = bandSweep(buf(d) { t in noise() * pow(t / d, 2) }, { t in 400 * pow(20, t / d) }, q: 3)
    var ph = 0.0
    let tone = buf(d) { t in ph += hz(45 + 24 * t / d) / SR; return saw(ph) * 0.25 * pow(t / d, 2) }
    return zip(n, lowpass(tone, 3000)).map { $0 + $1 }
}
func pop() -> [Double] { var ph = 0.0; return buf(0.18) { t in ph += (900 * exp(-t / 0.02) + 120) / SR; return sin(2 * .pi * ph) * exp(-t / 0.05) + 0.4 * noise() * exp(-t / 0.006) } }
func shimmer(_ d: Double, _ notes: [Double]) -> [Double] {
    buf(d) { t in let k = min(1, t / d); return notes.enumerated().reduce(0) { s, e in s + sin(2 * .pi * e.element * t * (1 + 0.003 * sin(t * 30 + Double(e.offset)))) * (0.5 + 0.5 * sin(t * 40 + Double(e.offset) * 2)) } / Double(notes.count) * k * k }
}

// ---------- Harmonie : do, sol, la mineur, fa (une mesure de 2 s chacune, à partir de 3 s) ----------
let CH: [[Double]] = [[60, 64, 67], [59, 62, 67], [57, 60, 64], [57, 60, 65]]
let ROOT: [Double] = [36, 43, 45, 41]
// L'accroche (0 – 3 s) : la mineur puis fa, la chute sur do.
func chord(_ t: Double) -> Int { t < 3 ? (t < 1.5 ? 2 : 3) : Int(floor((t - 3) / 2)) % 4 }
let beat = 0.5
var kicks: [Double] = []

func groove(_ t0: Double, _ t1: Double, energy: Double = 1) {
    var t = t0
    while t < t1 - 0.001 {
        let b = Int((t / beat).rounded()), bar = Int(((t - 1) / beat).rounded())
        kicks.append(t); put(t, kick(), 0.9 * energy)
        if b % 2 == 1 { put(t, clap(), 0.35 * energy, send: 0.25) }
        put(t + beat / 2, hat(), 0.16 * energy, pan: 0.3)
        put(t + beat / 4, hat(0.02), 0.07 * energy, pan: -0.3); put(t + 3 * beat / 4, hat(0.02), 0.07 * energy, pan: -0.3)
        let c = chord(t)
        for e in 0..<2 { put(t + Double(e) * beat / 2, bass(hz(ROOT[c]), beat / 2), 0.55 * energy) }
        let tones = CH[c].map { $0 + 12 } + [CH[c][0] + 24]
        let pattern = [0, 2, 1, 3]
        for s in 0..<4 { put(t + Double(s) * beat / 4, pluck(hz(tones[pattern[(b * 4 + s) % 4]])), 0.13 * energy, pan: s % 2 == 0 ? -0.35 : 0.35, send: 0.3) }
        // Une nappe par mesure (jusqu'à la mesure suivante si le groove reprend en cours de mesure).
        if bar % 4 == 0 || t == t0 {
            let barEnd = 1 + 2 * (floor((t - 1) / 2) + 1)
            put(t, pad(CH[c].map(hz), min(barEnd - t, t1 - t)), 0.22 * energy, send: 0.4, pad: true)
        }
        t += beat
    }
}
func arp(_ t: Double, _ notes: [Double], _ g: Double, gap: Double = 0.07) { for (i, n) in notes.enumerated() { put(t + Double(i) * gap, bell(hz(n)), g, pan: Double(i % 3 - 1) * 0.4, send: 0.5) } }
let star: [Double] = [72, 76, 79, 83, 86, 91]  // comme l'app : do mi sol si ré sol
let sparkle: [Double] = [84, 88, 91, 95, 98]

// 0 → 3 s : l'accroche. La 1.1, le balayage lumineux, la 1.2, la montée.
put(0, pad(CH[2].map(hz), 1.5, cutoff: 900), 0.2, send: 0.5, pad: true)
put(1.5, pad(CH[3].map(hz), 1.5, cutoff: 1400), 0.24, send: 0.5, pad: true)
for (i, t) in stride(from: 0.0, to: 3.0, by: beat / 2).enumerated() {
    let c = chord(t), tones = CH[c].map { $0 + 12 } + [CH[c][0] + 24]
    put(t, pluck(hz(tones[[0, 2, 1, 3][i % 4]])), 0.06 + 0.05 * t / 3, pan: i % 2 == 0 ? -0.35 : 0.35, send: 0.4)
}
put(0.05, bell(hz(84), 1.2), 0.1, send: 0.6)
put(1.04, whoosh(0.55), 0.4, pan: -0.2, send: 0.2)                  // le balayage
put(1.5, shimmer(1.4, sparkle.map(hz)), 0.05, send: 0.6)
arp(1.25, [79, 84, 88], 0.15, gap: 0.25)                             // « fait peau neuve. »
put(1.58, pop(), 0.4)                                                // « Version 1.2 »
put(1.6, riser(1.4), 0.3, send: 0.3)
for t in stride(from: 2.0, to: 3.0, by: beat / 4) { put(t, hat(0.02), 0.05 + 0.08 * (t - 2), pan: 0.2) }
var roll = 2.5, step = 0.125
while roll < 3.0 { put(roll, clap(), 0.1 + 0.25 * (roll - 2.5) / 0.5, send: 0.2); roll += step; if roll > 2.74 { step = 0.0625 } }
put(2.5, whoosh(0.5), 0.35, pan: 0.2, send: 0.2)                    // le zoom dans l'huître
// 3 → 9 s : l'huître 3D (pop, lumière, perle dorée), puis les perles.
groove(3, 9)
put(3.0, impact(1.2), 0.8, send: 0.4)
put(3.55, pop(), 0.5); put(3.55, kick(0.6), 0.3)
put(3.6, shimmer(1.6, star.map(hz)), 0.04, send: 0.6)                // la lumière dans l'entrebâillement
arp(5.2, star, 0.16); put(5.2, impact(0.6), 0.45, send: 0.3)
put(5.32, pop(), 0.35)
put(6.5, whoosh(0.5), 0.4, send: 0.2)                               // dans la perle
for (i, t) in [7.0, 7.25, 7.5, 7.75, 8.0, 8.25, 8.5, 8.625, 8.75, 8.875].enumerated() {
    put(t, bell(hz([69, 72, 74, 76, 79, 81, 84, 86, 88, 91][i]), 0.9), 0.11, pan: Double(i % 3 - 1) * 0.4, send: 0.5)
}
// 9 → 10 s : la perle maudite. Tout s'arrête, bourdon dissonant, cœur qui bat.
put(9.0, pad([hz(33), hz(34), hz(45), hz(46)], 1.1, cutoff: 500), 0.5, send: 0.3)
for (t, g) in [(9.0, 0.9), (9.28, 0.55), (9.5, 0.8), (9.78, 0.5)] { put(t, kick(), g); kicks.append(t) }
arp(9.0, [57, 58, 63, 56], 0.18, gap: 0.09); put(9.0, impact(1.0), 0.6, send: 0.4)
put(9.72, whoosh(0.35), 0.4, pan: -0.4, send: 0.2)                  // coup de fouet vers les écrins
// 10 → 20,5 s : les écrins, les trouvailles, le site.
groove(10, 20.5)
put(10.55, pop(), 0.45)                                              // l'écrin s'ouvre
put(11.3, shimmer(0.7, [hz(96), hz(100), hz(103)]), 0.06, send: 0.6)   // ça scintille…
arp(11.42, sparkle, 0.14, gap: 0.05)                                  // éclat parfait
arp(12.3, star, 0.15); put(12.3, impact(0.5), 0.4, send: 0.3)        // les bijoux jaillissent
put(12.72, whoosh(0.35), 0.4, pan: 0.3, send: 0.2)
for i in 0..<9 { put(12.98 + Double(i) * 0.085, pluck(hz([72, 74, 76, 79, 81, 84, 86, 88, 91][i]), 0.2), 0.09, pan: Double(i % 3 - 1) * 0.5, send: 0.3) }
arp(14.0, [79, 84, 88], 0.16, gap: 0.09); put(14.0, pop(), 0.45)     // le canard : trois notes qui sautillent
put(14.36, pop(), 0.3)
put(14.78, whoosh(0.3), 0.35, send: 0.2)
put(15.0, impact(0.6), 0.4, send: 0.3)
put(16.4, whoosh(0.45), 0.3, pan: 0.3, send: 0.2)                   // vers le téléphone
put(16.8, riser(1.5), 0.22, send: 0.3)                               // le pouce qui ouvre l'huître du site
put(17.25, pop(), 0.45)
arp(19.05, star, 0.15); put(19.05, shimmer(1.0, star.map(hz)), 0.04, send: 0.6)
put(20.12, whoosh(0.4), 0.35, send: 0.2)
// 20,5 → 23 s : l'iPhone Duo s'ouvre.
groove(20.5, 23, energy: 0.85)
put(20.75, whoosh(0.9), 0.25, pan: -0.3, send: 0.3)
arp(21.65, star, 0.16); put(21.65, bell(hz(91), 1.4), 0.08, send: 0.6)
put(22.72, whoosh(0.3), 0.35, send: 0.2)
// 23 → 27 s : + 50, merci, les corrections.
groove(23, 27)
put(23.0, impact(1.0), 0.7, send: 0.4)
for n in stride(from: 5.0, through: 50, by: 5) { let t = 23 + 0.9 * (1 - cbrt(1 - n / 50)); put(t, pluck(hz(72 + n / 5 * 2), 0.18), 0.1, send: 0.3) }
arp(24.0, star, 0.16); put(24.0, impact(0.6), 0.45, send: 0.3)       // « Merci ! »
put(24.48, whoosh(0.35), 0.3, send: 0.2)
for (i, t) in [24.75, 25.125, 25.5, 25.875].enumerated() { put(t, pop(), 0.35); put(t, bell(hz([76, 79, 83, 84][i]), 1.0), 0.1, send: 0.5) }
put(26.72, whoosh(0.3), 0.35, send: 0.2)
// 27 → 32 s : « Mets à jour sur l'App Store ». Tout le monde, puis un accord qui reste.
groove(27, 31)
put(27.0, impact(1.3), 0.85, send: 0.4)
arp(27.12, star, 0.15)
put(27.72, pop(), 0.4); put(27.72, bell(hz(84), 1.2), 0.1, send: 0.5)
arp(29.0, [79, 84, 88], 0.1, gap: 0.12)
kicks.append(31); put(31, kick(1.1), 1)
put(31, pad([hz(48), hz(52), hz(55), hz(62), hz(67)], 1.0, cutoff: 2600), 0.34, send: 0.6, pad: true)
put(31, bass(hz(36), 1.0), 0.6)
arp(31.0, [72, 79, 84, 88, 91, 96], 0.12, gap: 0.09)

// ---------- Mélange : nappes « pompées » par la grosse caisse, réverbération, limiteur ----------
kicks.sort()
var ki = 0
for i in 0..<N {
    let t = Double(i) / SR
    while ki + 1 < kicks.count && kicks[ki + 1] <= t { ki += 1 }
    let since = kicks.isEmpty || kicks[ki] > t ? 1.0 : t - kicks[ki]
    let duck = Float(1 - 0.55 * exp(-since / 0.12))
    L[i] += pads[i] * duck; R[i] += pads[i] * duck
}
// Réverbération de Schroeder (4 peignes, 2 passe-tout), un peu décalée entre les canaux.
func reverb(_ x: [Float], _ off: Int) -> [Float] {
    var y = [Float](repeating: 0, count: x.count)
    for (d, g) in [(1557, 0.84), (1617, 0.83), (1491, 0.82), (1422, 0.81)] as [(Int, Float)] {
        let dd = (d + off) * 2; var bufc = [Float](repeating: 0, count: dd); var j = 0, lp: Float = 0
        for i in 0..<x.count { let o = bufc[j]; lp = 0.7 * o + 0.3 * lp; bufc[j] = x[i] + lp * g; j = (j + 1) % dd; y[i] += o * 0.25 }
    }
    for d in [225, 556] { let dd = (d + off) * 2; var b = [Float](repeating: 0, count: dd); var j = 0
        for i in 0..<y.count { let o = b[j]; let v = y[i] + o * 0.5; b[j] = v; y[i] = o - v * 0.5; j = (j + 1) % dd } }
    return y
}
let rl = reverb(rev, 0), rr = reverb(rev, 23)
let fade = 31.3
var peak: Float = 0
for i in 0..<N {
    let t = Double(i) / SR
    let g = Float(t > fade ? max(0, (DUR - t) / (DUR - fade)) : 1) * Float(min(1, t / 0.01))
    L[i] = tanhf((L[i] + rl[i] * 0.5) * 0.9) * g; R[i] = tanhf((R[i] + rr[i] * 0.5) * 0.9) * g
    peak = max(peak, abs(L[i]), abs(R[i]))
}
// WAV 16 bits stéréo, crête à -1 dB.
let norm = 0.89 / max(peak, 1e-6)
var data = Data()
func le<T: FixedWidthInteger>(_ v: T) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
data.append(contentsOf: Array("RIFF".utf8)); le(UInt32(36 + N * 4)); data.append(contentsOf: Array("WAVEfmt ".utf8))
le(UInt32(16)); le(UInt16(1)); le(UInt16(2)); le(UInt32(SR)); le(UInt32(SR * 4)); le(UInt16(4)); le(UInt16(16))
data.append(contentsOf: Array("data".utf8)); le(UInt32(N * 4))
for i in 0..<N { le(Int16(max(-1, min(1, L[i] * norm)) * 32767)); le(Int16(max(-1, min(1, R[i] * norm)) * 32767)) }
try! data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("\(DUR) s → \(CommandLine.arguments[1])")

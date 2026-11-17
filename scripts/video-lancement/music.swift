// Musique et effets sonores de la vidéo de lancement, générés par code (comme les sons de l'app : aucune licence).
// 120 battements par minute, la mineur (la – fa – do – sol), calée sur le montage de index.html (instants en secondes).
// usage : swift music.swift <sortie.wav>
import Foundation

let SR = 48000.0, DUR = 35.0, N = Int(SR * DUR)
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

// ---------- Harmonie : la mineur, fa, do, sol (une mesure de 2 s chacune) ----------
let CH: [[Double]] = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
let ROOT: [Double] = [45, 41, 36, 43]
func chord(_ t: Double) -> Int { Int(floor(t / 2)) % 4 }
let beat = 0.5
var kicks: [Double] = []

func groove(_ t0: Double, _ t1: Double, energy: Double = 1) {
    var t = t0
    while t < t1 - 0.001 {
        let b = Int((t / beat).rounded())
        kicks.append(t); put(t, kick(), 0.9 * energy)
        if b % 2 == 1 { put(t, clap(), 0.35 * energy, send: 0.25) }
        put(t + beat / 2, hat(), 0.16 * energy, pan: 0.3)
        put(t + beat / 4, hat(0.02), 0.07 * energy, pan: -0.3); put(t + 3 * beat / 4, hat(0.02), 0.07 * energy, pan: -0.3)
        let c = chord(t)
        for e in 0..<2 { put(t + Double(e) * beat / 2, bass(hz(ROOT[c]), beat / 2), 0.55 * energy) }
        let tones = CH[c].map { $0 + 12 } + [CH[c][0] + 24]
        let pattern = [0, 2, 1, 3]
        for s in 0..<4 { put(t + Double(s) * beat / 4, pluck(hz(tones[pattern[(b * 4 + s) % 4]])), 0.13 * energy, pan: s % 2 == 0 ? -0.35 : 0.35, send: 0.3) }
        if b % 4 == 0 || t == t0 { put(t, pad(CH[c].map(hz), min(2, t1 - t)), 0.22 * energy, send: 0.4, pad: true) }
        t += beat
    }
}

// 0 → 10 s : l'accroche (l'huître dorée), puis les trois cartes.
groove(0, 10)
// 10 → 13,6 s : la perle maudite. Bourdon dissonant, cœur qui bat.
put(10, pad([hz(33), hz(34), hz(45), hz(46)], 3.7, cutoff: 500), 0.5, send: 0.3)
for t in stride(from: 10.0, to: 13.5, by: 1.0) { put(t, kick(), 0.8); put(t + 0.28, kick(), 0.5); kicks.append(t) }
put(10.4, shimmer(2.2, [hz(88), hz(89), hz(95)]), 0.05, send: 0.5)
// 13,6 → 17 s : l'iPhone Duo s'ouvre. La montée, jusqu'à la perle.
put(13.6, pad([hz(53), hz(57), hz(60)], 1.9, cutoff: 900), 0.22, send: 0.4, pad: true)
put(15.5, pad([hz(55), hz(59), hz(62)], 1.5, cutoff: 1400), 0.26, send: 0.4, pad: true)
for t in stride(from: 14.0, to: 17.0, by: beat) { put(t, kick(), 0.75); kicks.append(t); put(t, bass(hz(t < 15.5 ? 41 : 43), beat), 0.45) }
for t in stride(from: 15.5, to: 17.0, by: beat / 4) { put(t, hat(0.02), 0.08, pan: 0.2) }
var roll = 15.5, step = 0.125
while roll < 17.0 { put(roll, clap(), 0.12 + 0.25 * (roll - 15.5) / 1.5, send: 0.2); roll += step; if roll > 16.25 { step = 0.0625 } }
put(14.5, riser(2.5), 0.28, send: 0.3)
// 17 → 31 s : la perle sur le Duo, les écrins (iPhone, Duo), la collection. Tout le monde.
groove(17, 31)
// 31 → 35 s : la fin. Un accord qui reste.
kicks.append(31); put(31, kick(1.1), 1)
put(31, pad([hz(48), hz(52), hz(55), hz(62), hz(67)], 4.0, cutoff: 2600), 0.34, send: 0.6, pad: true)
put(31, bass(hz(36), 2.5), 0.6)

// ---------- Effets, calés sur l'image ----------
for t in [6.4, 7.6, 8.8, 10.0, 13.6, 19.6, 24.2, 29.0, 31.0] { put(t - 0.35, whoosh(0.45), 0.35, pan: 0.2, send: 0.2) }
for t in [1.1, 6.43, 7.63, 8.83, 10.9, 15.6, 20.35, 25.45, 29.1] { put(t, pop(), 0.45) }
func arp(_ t: Double, _ notes: [Double], _ g: Double, gap: Double = 0.07) { for (i, n) in notes.enumerated() { put(t + Double(i) * gap, bell(hz(n)), g, pan: Double(i % 3 - 1) * 0.4, send: 0.5) } }
let star: [Double] = [72, 76, 79, 83, 86, 91]  // comme l'app : do mi sol si ré sol
put(2.6, shimmer(2.0, star.map(hz)), 0.04, send: 0.6)                    // la lumière dorée, pendant le suspense
arp(4.6, star, 0.16); put(4.6, impact(0.6), 0.5, send: 0.3)
arp(7.0, Array(star.prefix(5)), 0.13)
arp(8.2, [79, 84, 88], 0.15, gap: 0.09)           // le canard : trois notes qui sautillent
arp(9.4, star, 0.15); put(9.4, impact(0.4), 0.4)
arp(13.0, [57, 58, 63, 56], 0.18, gap: 0.09); put(13.0, impact(1.2), 0.8, send: 0.4)
put(17.0, impact(1.2), 0.75, send: 0.4); put(17.0, shimmer(2.0, star.map(hz)), 0.05, send: 0.6)
arp(19.0, star, 0.16)
put(21.4, shimmer(0.85, [hz(96), hz(100), hz(103)]), 0.06, send: 0.6)   // ça scintille…
arp(22.25, [84, 88, 91, 95, 98], 0.14, gap: 0.05)                        // éclat parfait, variante Aurore
arp(23.4, star, 0.15); put(23.4, impact(0.5), 0.45)
put(26.5, shimmer(0.85, [hz(96), hz(100), hz(103)]), 0.06, send: 0.6)
arp(27.33, [84, 88, 91, 95, 98], 0.14, gap: 0.05)
arp(28.9, star, 0.13)
arp(30.0, [76, 81], 0.12)
arp(31.1, [72, 79, 84, 88, 91, 96], 0.12, gap: 0.09)

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
let fade = 34.0
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

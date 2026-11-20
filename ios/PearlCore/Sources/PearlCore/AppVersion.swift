// Mise à jour disponible : la version de l'App Store est-elle plus récente que celle installée ?
// Numéros « 1.2.1 » comparés morceau par morceau (1.10 > 1.9, 1.2 = 1.2.0).

public func isNewerVersion(_ store: String, than installed: String) -> Bool {
    let a = store.split(separator: ".").map { Int($0) ?? 0 }
    let b = installed.split(separator: ".").map { Int($0) ?? 0 }
    for i in 0..<max(a.count, b.count) {
        let x = i < a.count ? a[i] : 0, y = i < b.count ? b[i] : 0
        if x != y { return x > y }
    }
    return false
}

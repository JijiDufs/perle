// Stock d'huîtres (énergie, cahier §5), miroir de src/core/stock.ts : un maximum, et une huître
// qui revient à intervalle fixe. Les huîtres achetées ou offertes peuvent dépasser le maximum ;
// la recharge gratuite reprend quand on repasse en dessous.

public struct StockState: Codable, Sendable, Equatable {
    public var count: Int
    /// Instant (ms) à partir duquel court la prochaine recharge.
    public var lastRefillAt: Double

    public init(count: Int, lastRefillAt: Double) {
        self.count = count
        self.lastRefillAt = lastRefillAt
    }
}

private let minuteMs = 60_000.0

public func rechargeIntervalMs(_ tuning: Tuning) -> Double {
    tuning.oysterRechargeMinutes * minuteMs
}

/// Ajoute les huîtres revenues depuis la dernière recharge, sans dépasser le maximum.
public func refreshStock(_ stock: StockState, now: Double, _ tuning: Tuning) -> StockState {
    let max = tuning.oysterStockMax
    if stock.count >= max { return StockState(count: Swift.max(stock.count, 0), lastRefillAt: now) }
    // Horloge reculée (changement d'heure manuel) : on repart de maintenant, sans rien gagner.
    if now < stock.lastRefillAt { return StockState(count: stock.count, lastRefillAt: now) }
    let interval = rechargeIntervalMs(tuning)
    let gained = Int(((now - stock.lastRefillAt) / interval).rounded(.down))
    if gained <= 0 { return stock }
    let count = Swift.min(max, stock.count + gained)
    return StockState(count: count, lastRefillAt: count >= max ? now : stock.lastRefillAt + Double(gained) * interval)
}

/// Retire une huître. nil si le stock est vide.
public func consumeOyster(_ stock: StockState, now: Double, _ tuning: Tuning) -> StockState? {
    let fresh = refreshStock(stock, now: now, tuning)
    if fresh.count <= 0 { return nil }
    // Si le stock était plein, le minuteur démarre maintenant.
    let lastRefillAt = fresh.count >= tuning.oysterStockMax ? now : fresh.lastRefillAt
    return StockState(count: fresh.count - 1, lastRefillAt: lastRefillAt)
}

/// Temps (ms) avant la prochaine huître, ou nil si le stock est plein.
public func nextRefillIn(_ stock: StockState, now: Double, _ tuning: Tuning) -> Double? {
    let fresh = refreshStock(stock, now: now, tuning)
    if fresh.count >= tuning.oysterStockMax { return nil }
    return Swift.max(0, fresh.lastRefillAt + rechargeIntervalMs(tuning) - now)
}

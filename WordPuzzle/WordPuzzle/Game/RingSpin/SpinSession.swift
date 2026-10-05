import Foundation

/// Phase 12 D-12, cosmetic only: NET signed displacement (not path length) so wiggling cannot farm it. Landing home forces net to a multiple of 360 degrees, so in practice it means 6+ net revolutions that land every letter back in its pre-spin slot. No points, no rank (Phase 8 D-04..D-06).
struct SpinSession {
    static let jackpotRevolutions: Double = 5

    private(set) var isOpen: Bool
    private(set) var startAngle: Double

    init() {
        isOpen = false
        startAngle = 0
    }

    mutating func begin(at angle: Double) {
        guard !isOpen else { return }
        isOpen = true
        startAngle = angle
    }

    mutating func end(finalAngle: Double) -> Bool {
        guard isOpen else { return false }
        isOpen = false
        return Self.isJackpot(netAngle: finalAngle - startAngle)
    }

    mutating func reset() {
        isOpen = false
        startAngle = 0
    }

    static func isJackpot(netAngle: Double) -> Bool {
        let slot = Double.pi / 3
        let slots = Int((netAngle / slot).rounded())
        return abs(netAngle) > jackpotRevolutions * 2 * .pi && slots % 6 == 0
    }
}

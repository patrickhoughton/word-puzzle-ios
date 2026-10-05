import CoreGraphics
import Foundation

/// Phase 10 D-01/D-02: decides whether two consecutive empty-space taps (off every tile)
/// form a double-tap. Pure value type: time and positions are injected so it is
/// deterministic in unit tests. LetterGridView feeds it from its single
/// DragGesture(minimumDistance: 0) — no second gesture recognizer (Phase 3 Pitfall 1).
struct EmptyDoubleTapDetector {
    /// Max seconds between the two taps' touch-up events (inclusive).
    var maxInterval: TimeInterval = 0.3
    /// A touch counts as a "tap" only if it moved less than this between down and up.
    var maxTapTravel: CGFloat = 10
    /// The two taps must land within one tap target of each other (inclusive).
    var maxSeparation: CGFloat = 44

    private var last: (time: Date, point: CGPoint)?

    /// Call on touch-up when the touch began AND ended off every tile.
    /// Returns true exactly when this tap completes a double-tap.
    mutating func registerEmptyTap(start: CGPoint, end: CGPoint, at time: Date) -> Bool {
        guard hypot(end.x - start.x, end.y - start.y) < maxTapTravel else {
            last = nil
            return false
        }
        if let prev = last,
           time.timeIntervalSince(prev.time) <= maxInterval,
           hypot(end.x - prev.point.x, end.y - prev.point.y) <= maxSeparation {
            last = nil // a triple-tap must not fire twice in a row
            return true
        }
        last = (time, end)
        return false
    }

    /// Call for any tile touch or non-tap touch so "tile tap then gap tap" never counts.
    mutating func reset() { last = nil }
}

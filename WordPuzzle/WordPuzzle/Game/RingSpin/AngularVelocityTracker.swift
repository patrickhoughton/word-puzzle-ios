import Foundation

/// Phase 12 D-04: the dial follows the finger 1:1 via accumulatedAngle; release velocity is measured over the last `window` seconds of timestamped samples (DragGesture.Value.time). We do not use DragGesture.Value.velocity: it is cartesian and derived from predictedEndLocation (12-RESEARCH).
struct AngularVelocityTracker {
    var window: TimeInterval
    var minSpan: TimeInterval
    var maxSpeed: Double
    var restSpeed: Double

    private(set) var accumulatedAngle: Double = 0
    private var samples: [(time: Date, angle: Double)] = []
    private var lastRaw: Double?

    init(window: TimeInterval = 0.1, minSpan: TimeInterval = 0.016, maxSpeed: Double = 24, restSpeed: Double = 0.3) {
        self.window = window
        self.minSpan = minSpan
        self.maxSpeed = maxSpeed
        self.restSpeed = restSpeed
    }

    var sampleCount: Int { samples.count }

    mutating func reset() {
        samples.removeAll()
        lastRaw = nil
        accumulatedAngle = 0
    }

    mutating func add(rawAngle: Double, at time: Date) {
        if let last = lastRaw {
            accumulatedAngle += Self.normalizedDelta(rawAngle - last)
        } else {
            accumulatedAngle = 0
        }
        lastRaw = rawAngle
        samples.append((time, accumulatedAngle))
        if samples.count > 32 { samples.removeFirst(samples.count - 32) }
    }

    func velocity(at releaseTime: Date) -> Double {
        let recent = samples.filter { releaseTime.timeIntervalSince($0.time) <= window }
        guard recent.count >= 2, let f = recent.first, let l = recent.last else { return 0 }
        let span = l.time.timeIntervalSince(f.time)
        guard span >= minSpan else { return 0 }
        let w = min(max((l.angle - f.angle) / span, -maxSpeed), maxSpeed)
        return abs(w) < restSpeed ? 0 : w
    }

    static func normalizedDelta(_ delta: Double) -> Double {
        var d = delta.truncatingRemainder(dividingBy: 2 * .pi)
        if d <= -.pi { d += 2 * .pi } else if d > .pi { d -= 2 * .pi }
        return d
    }
}

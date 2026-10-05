import Foundation

struct RingSpinTrajectory: Equatable {
    let tuning: RingSpinTuning
    let startAngle: Double
    let releaseVelocity: Double
    let handoffTime: TimeInterval
    let handoffAngle: Double
    let handoffVelocity: Double
    let targetAngle: Double
    var duration: TimeInterval { handoffTime + tuning.settleDuration }
    init(startAngle: Double, velocity: Double, tuning: RingSpinTuning = .standard) {
        self.tuning = tuning
        self.startAngle = startAngle
        self.releaseVelocity = 0
        self.handoffTime = 0
        self.handoffAngle = startAngle
        self.handoffVelocity = 0
        self.targetAngle = 0
    }
    func angle(at t: TimeInterval) -> Double { 0 }
    func velocity(at t: TimeInterval) -> Double { 1 }
    func isFinished(at t: TimeInterval) -> Bool { false }
}

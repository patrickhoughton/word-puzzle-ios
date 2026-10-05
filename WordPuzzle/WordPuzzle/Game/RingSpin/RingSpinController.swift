import SwiftUI
import QuartzCore

/// Events leaving the controller. All haptics, sounds and commits are driven from these.
enum RingSpinEvent: Equatable {
    case began
    case ticks(count: Int, speed: Double)
    case clunk
    case settled(slots: Int)
    case jackpot
}

enum RingSpinPhase: Equatable { case idle, tracking, coasting }

/// Single source of truth for the outer-ring angle (Phase 12).
///
/// Responsibilities: dial tracking 1:1 after a slop (D-04), closed-form inertial coast (D-05) and exact
/// slot landing (D-06), grab to stop (D-13), tile lock while active (D-14), Shuffle/sheet cancel (D-15)
/// and Reduce Motion snapping (D-18). ALL haptics/sounds/commits leave through `onEvent`; the controller
/// never touches GameViewModel, SoundManager, or UIKit feedback.
@MainActor @Observable
final class RingSpinController {
    static let slop: CGFloat = 10

    private(set) var angle: Double = 0
    private(set) var phase: RingSpinPhase = .idle
    var isActive: Bool { phase != .idle }

    @ObservationIgnored var reduceMotion = false
    @ObservationIgnored var onEvent: ((RingSpinEvent) -> Void)?
    @ObservationIgnored let tuning: RingSpinTuning

    @ObservationIgnored private let clock: () -> TimeInterval
    @ObservationIgnored private let usesDisplayLink: Bool
    @ObservationIgnored private var tracker: AngularVelocityTracker
    @ObservationIgnored private var session = SpinSession()
    @ObservationIgnored private var trajectory: RingSpinTrajectory?
    @ObservationIgnored private var releaseTime: TimeInterval = 0
    @ObservationIgnored private var trackStartAngle: Double = 0
    @ObservationIgnored private var didExceedSlop = false
    @ObservationIgnored private var ignoresCurrentTouch = false
    @ObservationIgnored private var displayLink: CADisplayLink?

    init(tuning: RingSpinTuning = .standard,
         clock: @escaping () -> TimeInterval = { CACurrentMediaTime() },
         usesDisplayLink: Bool = true) {
        self.tuning = tuning
        self.clock = clock
        self.usesDisplayLink = usesDisplayLink
        self.tracker = AngularVelocityTracker(maxSpeed: tuning.maxReleaseSpeed, restSpeed: tuning.restSpeed)
    }

    func touchDown() {
        ignoresCurrentTouch = false
        didExceedSlop = false
        if phase == .coasting {
            stopDisplayLink()
            trajectory = nil
            phase = .tracking
        }
    }

    func track(point: CGPoint, start: CGPoint, center: CGPoint, time: Date) {
        guard !ignoresCurrentTouch else { return }
        if !didExceedSlop {
            guard hypot(point.x - start.x, point.y - start.y) >= Self.slop else { return }
            didExceedSlop = true
            if phase == .idle {
                session.begin(at: angle)
                phase = .tracking
                onEvent?(.began)
            }
            trackStartAngle = angle
            tracker.reset()
        }
        guard !HexFlowerLayout.isInCenterDeadZone(point, center: center) else { return }
        tracker.add(rawAngle: HexFlowerLayout.touchAngle(of: point, center: center), at: time)
        let newAngle = trackStartAngle + tracker.accumulatedAngle
        emitTicks(from: angle, to: newAngle, speed: abs(tracker.velocity(at: time)))
        angle = newAngle
    }

    func release(time: Date) {
        defer { didExceedSlop = false }
        guard !ignoresCurrentTouch, phase == .tracking else { return }
        if reduceMotion {
            finish(at: SlotMath.nearestSlotAngle(angle), allowJackpot: true)
            return
        }
        let w = didExceedSlop ? tracker.velocity(at: time) : 0
        trajectory = RingSpinTrajectory(startAngle: angle, velocity: w, tuning: tuning)
        releaseTime = clock()
        phase = .coasting
        startDisplayLink()
    }

    func step() {
        guard phase == .coasting, let trajectory else { return }
        let t = clock() - releaseTime
        let newAngle = trajectory.angle(at: t)
        emitTicks(from: angle, to: newAngle, speed: abs(trajectory.velocity(at: t)))
        angle = newAngle
        if trajectory.isFinished(at: t) { finish(at: trajectory.targetAngle, allowJackpot: true) }
    }

    func cancelAndCommit() {
        guard phase != .idle else { return }
        ignoresCurrentTouch = true
        finish(at: SlotMath.nearestSlotAngle(angle), allowJackpot: false)
    }

    func reset() {
        stopDisplayLink()
        trajectory = nil
        session.reset()
        tracker.reset()
        didExceedSlop = false
        ignoresCurrentTouch = true
        phase = .idle
        angle = 0
    }

    private func emitTicks(from a: Double, to b: Double, speed: Double) {
        let c = SlotMath.crossings(from: a, to: b)
        if c > 0 { onEvent?(.ticks(count: c, speed: speed)) }
    }

    private func finish(at target: Double, allowJackpot: Bool) {
        stopDisplayLink()
        trajectory = nil
        angle = target
        onEvent?(.clunk)
        let slots = SlotMath.slotsMoved(finalAngle: target)
        let isJackpot = session.end(finalAngle: target) && allowJackpot
        tracker.reset()
        phase = .idle
        // Commit + angle reset in ONE animation-disabled pass; letter-keyed tiles make it a visual no-op.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            onEvent?(.settled(slots: slots))
            angle = 0
        }
        if isJackpot { onEvent?(.jackpot) }
    }

    // MARK: Display link

    private final class DisplayLinkTarget: NSObject {
        weak var owner: RingSpinController?
        @objc func fire(_ link: CADisplayLink) {
            guard let owner else { link.invalidate(); return }
            MainActor.assumeIsolated { owner.step() }
        }
    }

    private func startDisplayLink() {
        guard usesDisplayLink, displayLink == nil else { return }
        let proxy = DisplayLinkTarget()
        proxy.owner = self
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkTarget.fire(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

import SwiftUI

/// GAME-03 / D-09: progress is shown as an original rank TIER plus a found-word
/// count — never as a bare score number.
/// Presentation-only: takes values, no view-model reference.
struct ScoreBarView: View {
    let rank: RankTier
    let foundCount: Int
    let totalCount: Int
    /// 0...unbounded (Phase 8 D-05): > 1 means completion bonuses pushed past max.
    /// The ProgressView clamps itself; overflow is drawn separately.
    let progress: Double
    /// D-03/D-04: free puzzles left today, or nil for premium users (nothing renders).
    /// Passed in rather than read from the environment — this view has zero
    /// GameViewModel/store coupling by design (Phase 3 decision).
    let freePuzzlesRemaining: Int?
    /// The daily allowance the remaining count is out of. Passed in (as
    /// `GameViewModel.freePuzzlesPerDay`) so the literal 3 lives in exactly one place.
    let freePuzzlesPerDay: Int
    /// Phase 8 D-11: pangrams found / in puzzle. 0 total hides the chip (fixtures/previews only).
    var foundPangrams: Int = 0
    var totalPangrams: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// One-shot "you crossed 100%" burst: start time drives the particle burst, the
    /// counter drives the haptic (monotonic, RESEARCH Pitfall 3).
    @State private var burstStart: Date?
    @State private var burstCount = 0
    @State private var burstScale: CGFloat = 1

    static func pangramCounterText(found: Int, total: Int) -> String { "\(found)/\(total)" }

    /// D-05: strict > so exactly 100% (Legend) stays a plain full bar.
    static func isOverflow(progress: Double) -> Bool { progress.isFinite && progress > 1 }

    /// Badge beside "Mythic Grandmaster": whole percent, rounded up so any overflow reads > 100%.
    static func overflowPercentText(progress: Double) -> String {
        "\(Int((progress * 100 - 1e-9).rounded(.up)))%"
    }

    private var isOverflow: Bool { Self.isOverflow(progress: progress) }

    static func accessibilityText(rank: RankTier, foundCount: Int, totalCount: Int, foundPangrams: Int, totalPangrams: Int, progress: Double, freePuzzlesRemaining: Int?, freePuzzlesPerDay: Int) -> String {
        var text = "Rank \(rank.displayName). \(foundCount) of \(totalCount) words found."
        if totalPangrams > 0 {
            text += " \(foundPangrams) of \(totalPangrams) pangrams found."
        }
        if isOverflow(progress: progress) {
            text += " Progress beyond maximum, \(overflowPercentText(progress: progress).dropLast()) percent."
        }
        if let freePuzzlesRemaining {
            text += " \(freePuzzlesRemaining) of \(freePuzzlesPerDay) free puzzles remaining today."
        }
        return text
    }

    private var pangramsComplete: Bool { totalPangrams > 0 && foundPangrams >= totalPangrams }

    @ViewBuilder
    private var rankTitle: some View {
        if rank == .mythicGrandmaster {
            HStack(spacing: GameTheme.xs) {
                Image(systemName: "sparkles").accessibilityHidden(true)
                Text(rank.displayName)
                if isOverflow {
                    Text(Self.overflowPercentText(progress: progress))
                        .font(GameTheme.labelFont.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.black.opacity(0.85))
                        .padding(.horizontal, GameTheme.xs)
                        .background(LinearGradient(colors: [GameTheme.overflowGoldLight, GameTheme.overflowGold],
                                                   startPoint: .top, endPoint: .bottom), in: Capsule())
                        .contentTransition(reduceMotion ? .identity : .numericText())
                }
            }
            .font(GameTheme.headingFont)
            .foregroundStyle(GameTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.opacity)
        } else {
            Text(rank.displayName)
                .font(GameTheme.headingFont)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.opacity)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.sm) {
            // UX-03 gap fix: shrink-to-fit on one line at accessibility Dynamic
            // Type sizes instead of truncating ("Novi...", "0 of 7...") or
            // wrapping, which would grow this row's height and risk pushing the
            // control row off the bottom of the screen (no ScrollView here).
            HStack {
                rankTitle
                Spacer()
                HStack(spacing: GameTheme.xs) {
                    Text("\(foundCount) of \(totalCount) words")
                        .font(GameTheme.labelFont)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    // Phase 7 D-02: tappability cue. The whole bar is the tap target (wrapped in a
                    // Button by GameView); the chevron is decorative.
                    Image(systemName: "chevron.right")
                        .font(GameTheme.labelFont)
                        .foregroundStyle(Color.secondary)
                        .accessibilityHidden(true)
                }
            }

            HStack(spacing: GameTheme.sm) {
                if totalPangrams > 0 {
                    HStack(spacing: GameTheme.xs) {
                        Image(systemName: pangramsComplete ? "checkmark.seal.fill" : "checkmark.seal")
                            .foregroundStyle(pangramsComplete ? GameTheme.accent : Color.secondary)
                        Text(Self.pangramCounterText(found: foundPangrams, total: totalPangrams))
                            .foregroundStyle(Color.secondary)
                            .monospacedDigit()
                            .contentTransition(reduceMotion ? .identity : .numericText())
                    }
                    .font(GameTheme.labelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                } else if freePuzzlesRemaining == nil {
                    // Keep the row one label line tall (premium + no pangrams: previews only).
                    Text(" ").font(GameTheme.labelFont).accessibilityHidden(true)
                }
                Spacer(minLength: 0)
                if let freePuzzlesRemaining {
                    Text("\(freePuzzlesRemaining) of \(freePuzzlesPerDay) free puzzles today")
                        .font(GameTheme.labelFont)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            ProgressView(value: progress.isFinite ? min(max(progress, 0), 1) : 0)
                .progressViewStyle(.linear)
                .tint(GameTheme.accent)
                .opacity(isOverflow ? 0 : 1)
                .scaleEffect(y: burstScale)
                .overlay {
                    if isOverflow {
                        OverflowBar(reduceMotion: reduceMotion, burstStart: burstStart)
                            .scaleEffect(y: burstScale)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        }
        .padding(GameTheme.md)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
        .onChange(of: isOverflow) { wasOverflow, nowOverflow in
            // Only a live crossing celebrates; appearing already past 100% stays calm.
            guard !wasOverflow, nowOverflow else { return }
            burstCount += 1
            guard !reduceMotion else { return }
            burstStart = .now
            withAnimation(GameTheme.overflowBurstAnimation) { burstScale = GameTheme.overflowBurstScale }
            withAnimation(GameTheme.overflowBurstAnimation.delay(0.18)) { burstScale = 1 }
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: burstCount)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        Self.accessibilityText(rank: rank, foundCount: foundCount, totalCount: totalCount,
                               foundPangrams: foundPangrams, totalPangrams: totalPangrams,
                               progress: progress, freePuzzlesRemaining: freePuzzlesRemaining,
                               freePuzzlesPerDay: freePuzzlesPerDay)
    }
}

/// D-05 (strengthened): thick molten-gold capsule with a drifting gradient, pulsing glow,
/// a bright shimmer, sparkles rising off the bar, and a one-shot particle burst when the
/// bar first crosses 100%. Reduce Motion: the same capsule, static, with a steady glow.
/// Sparkles and burst draw in an overlay above the bar, so none of this affects layout.
private struct OverflowBar: View {
    let reduceMotion: Bool
    let burstStart: Date?

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let pulse = reduceMotion ? 0.5 : 0.5 + 0.5 * sin(2 * .pi * t / GameTheme.overflowGlowPulseSeconds)
            let glowOpacity = lerp(GameTheme.overflowGlowOpacityRange, pulse)
            let glowRadius = lerp(GameTheme.overflowGlowRadiusRange, pulse)

            GeometryReader { geo in
                let w = geo.size.width
                let flow = CGFloat((t / GameTheme.overflowFlowSeconds).truncatingRemainder(dividingBy: 1))
                let shimmerPhase = CGFloat((t / GameTheme.overflowShimmerSeconds).truncatingRemainder(dividingBy: 1))
                let shimmerW = w * GameTheme.overflowShimmerWidthFraction

                ZStack(alignment: .leading) {
                    // Gradient twice the bar width, slid left over one period, so the colours flow.
                    LinearGradient(colors: [GameTheme.overflowGoldDeep, GameTheme.overflowGold, GameTheme.overflowGoldLight,
                                            GameTheme.overflowGold, GameTheme.overflowGoldDeep, GameTheme.overflowGold,
                                            GameTheme.overflowGoldLight, GameTheme.overflowGold, GameTheme.overflowGoldDeep],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: w * 2)
                        .offset(x: -flow * w)
                    if !reduceMotion {
                        LinearGradient(colors: [.clear, .white.opacity(GameTheme.overflowShimmerOpacity), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: shimmerW)
                            .offset(x: -shimmerW + shimmerPhase * (w + shimmerW))
                    }
                }
                .frame(width: w, height: GameTheme.overflowBarHeight, alignment: .leading)
                .clipShape(Capsule())
                .shadow(color: GameTheme.overflowGold.opacity(glowOpacity), radius: glowRadius)
                .frame(maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    if !reduceMotion {
                        Canvas { context, size in
                            drawSparkles(in: &context, size: size, t: t)
                            if let burstStart {
                                drawBurst(in: &context, size: size, elapsed: timeline.date.timeIntervalSince(burstStart))
                            }
                        }
                        .frame(height: GameTheme.overflowSparkleRise + GameTheme.overflowBarHeight + 24)
                        .offset(y: 12)
                    }
                }
            }
        }
    }

    private func lerp<T: BinaryFloatingPoint>(_ r: ClosedRange<T>, _ f: Double) -> T {
        r.lowerBound + (r.upperBound - r.lowerBound) * T(f)
    }

    /// Cheap deterministic per-particle randomness (no state, stable across frames).
    private func rand(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i * 7919 + salt * 104729)) * 43758.5453
        return x - x.rounded(.down)
    }

    private func star(at p: CGPoint, radius r: CGFloat) -> Path {
        var path = Path()
        let inner = r * 0.32
        for k in 0..<8 {
            let a = Double(k) * .pi / 4 - .pi / 2
            let rr = k.isMultiple(of: 2) ? r : inner
            let pt = CGPoint(x: p.x + rr * cos(a), y: p.y + rr * sin(a))
            k == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }

    private func drawSparkles(in context: inout GraphicsContext, size: CGSize, t: Double) {
        let barY = size.height - 12 - GameTheme.overflowBarHeight / 2
        for i in 0..<GameTheme.overflowSparkleCount {
            let period = 1.4 + rand(i, 1) * 1.4
            let u = ((t / period) + rand(i, 2)).truncatingRemainder(dividingBy: 1)
            let x = CGFloat(rand(i, 3)) * size.width + CGFloat(sin(t * 2 + Double(i))) * 3
            let y = barY - CGFloat(u) * GameTheme.overflowSparkleRise
            let r = CGFloat(1.8 + rand(i, 4) * 2.6) * CGFloat(1 - u * 0.4)
            let color = i.isMultiple(of: 3) ? Color.white : (i.isMultiple(of: 2) ? GameTheme.overflowGoldLight : GameTheme.overflowGold)
            context.opacity = sin(.pi * u)
            context.fill(star(at: CGPoint(x: x, y: y), radius: r), with: .color(color))
        }
        context.opacity = 1
    }

    private func drawBurst(in context: inout GraphicsContext, size: CGSize, elapsed: Double) {
        guard elapsed >= 0, elapsed < GameTheme.overflowBurstSeconds else { return }
        let u = elapsed / GameTheme.overflowBurstSeconds
        let ease = 1 - pow(1 - u, 3)
        let barY = size.height - 12 - GameTheme.overflowBarHeight / 2
        for i in 0..<GameTheme.overflowBurstParticles {
            // Spread along the whole bar, flung upward and outward.
            let origin = CGPoint(x: CGFloat(rand(i, 5)) * size.width, y: barY)
            let angle = -.pi / 2 + (rand(i, 6) - 0.5) * .pi * 0.9
            let dist = CGFloat(18 + rand(i, 7) * 30) * CGFloat(ease)
            let p = CGPoint(x: origin.x + dist * CGFloat(cos(angle)), y: origin.y + dist * CGFloat(sin(angle)))
            context.opacity = 1 - u
            context.fill(star(at: p, radius: CGFloat(2.5 + rand(i, 8) * 3.5)),
                         with: .color(i.isMultiple(of: 2) ? GameTheme.overflowGoldLight : .white))
        }
        context.opacity = 1
    }
}

/// Phase 7 D-01: the Button wrapping ScoreBarView in GameView. Plain (no accent tint on
/// the bar's text, RESEARCH Pitfall 3) with a slight fade while pressed; no layout change.
struct ScoreBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Mid round") {
    ScoreBarView(
        rank: .adept,
        foundCount: 12,
        totalCount: 31,
        progress: 0.18,
        freePuzzlesRemaining: nil,
        freePuzzlesPerDay: 3
    )
    .padding()
}

#Preview("Legend") {
    ScoreBarView(
        rank: .legend,
        foundCount: 31,
        totalCount: 31,
        progress: 1.0,
        freePuzzlesRemaining: nil,
        freePuzzlesPerDay: 3
    )
    .padding()
}

#Preview("Free user, 2 puzzles left") {
    ScoreBarView(
        rank: .adept,
        foundCount: 12,
        totalCount: 31,
        progress: 0.18,
        freePuzzlesRemaining: 2,
        freePuzzlesPerDay: 3
    )
    .padding()
}

#Preview("Pangram counter 1/3") {
    ScoreBarView(rank: .adept, foundCount: 12, totalCount: 31, progress: 0.4,
                 freePuzzlesRemaining: 2, freePuzzlesPerDay: 3,
                 foundPangrams: 1, totalPangrams: 3)
        .padding()
}

#Preview("Overflow, Mythic Grandmaster") {
    ScoreBarView(rank: .mythicGrandmaster, foundCount: 31, totalCount: 31, progress: 1.08,
                 freePuzzlesRemaining: nil, freePuzzlesPerDay: 3,
                 foundPangrams: 3, totalPangrams: 3)
        .padding()
}

#Preview("Mythic at AX5") {
    ScoreBarView(rank: .mythicGrandmaster, foundCount: 31, totalCount: 31, progress: 1.08,
                 freePuzzlesRemaining: nil, freePuzzlesPerDay: 3,
                 foundPangrams: 3, totalPangrams: 3)
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
}

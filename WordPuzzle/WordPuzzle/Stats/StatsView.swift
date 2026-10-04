import SwiftUI

/// Phase 9 Stats screen (09-UI-SPEC). Value-in/closure-out: takes only a PlayerStats snapshot.
struct StatsView: View {
    // Inputs (value-in/closure-out: NO @Environment store reads here)
    let stats: PlayerStats
    /// true in the top-bar sheet (shows a Done toolbar button); false when pushed from Settings,
    /// whose own sheet already has Done (UI-SPEC Presentation).
    var showsDoneButton: Bool = true
    var onDone: () -> Void = {}

    // Pinned copy (09-UI-SPEC Copywriting Contract)
    static let title = "Stats"
    static let doneButtonLabel = "Done"
    static let entryAccessibilityLabel = "Stats"
    static let nudgeText = "Finish a round to start your stats!"
    static let streakSuffix = "day streak"
    static let zeroStreakHeadline = "Start a streak today!"
    static let atRiskHint = "Play today to keep it!"
    static let todayHeader = "TODAY"
    static let lifetimeHeader = "LIFETIME"
    static let puzzlesTodayCaption = "Puzzles today"
    static let todayScoreCaption = "Score"
    static let wordsFoundCaption = "Words found"
    static let bestScoreCaption = "Best score"
    static let gamesPlayedCaption = "Games played"
    static let averageScoreCaption = "Average score"
    static let averageWordsCaption = "Avg words / game"
    static let pangramsCaption = "Pangrams found"
    static let sweepsCaption = "Pangram sweeps"
    static let bestRankCaption = "Best rank"
    static let emptyValue = "—"
    static let notAvailableSpoken = "not available"
    static let todaySectionSpoken = "Today"
    static let lifetimeSectionSpoken = "Lifetime"

    // MARK: Pure presentation logic

    static func valueText(_ value: Int?) -> String { value.map(String.init) ?? emptyValue }

    static func streakHeadline(currentStreak: Int) -> String {
        currentStreak > 0 ? "\(currentStreak) \(streakSuffix)" : zeroStreakHeadline
    }

    static func longestLine(longestStreak: Int) -> String? {
        longestStreak > 0 ? "Longest: \(longestStreak)" : nil
    }

    static func streakHint(_ stats: PlayerStats) -> String? {
        stats.currentStreak > 0 && stats.streakAtRisk ? atRiskHint : nil
    }

    static func showsNudge(_ stats: PlayerStats) -> Bool { stats.gamesPlayed == 0 }

    static func bestRankText(_ rank: RankTier?) -> String { rank?.displayName ?? emptyValue }

    static func showsGlow(_ rank: RankTier?) -> Bool { rank == .mythicGrandmaster }

    static func tileAccessibilityLabel(caption: String, value: Int?, sectionPrefix: String? = nil) -> String {
        [sectionPrefix, caption, value.map(String.init) ?? notAvailableSpoken]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    static func heroAccessibilityLabel(_ stats: PlayerStats) -> String {
        func days(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }
        if stats.currentStreak > 0 {
            var label = "Current streak \(days(stats.currentStreak)). Longest streak \(days(stats.longestStreak))."
            if let hint = streakHint(stats) { label += " " + hint }
            return label
        }
        var label = zeroStreakHeadline
        if stats.longestStreak > 0 { label += " Longest streak \(days(stats.longestStreak))." }
        return label
    }

    static func gridColumnCount(isAccessibilitySize: Bool) -> Int { isAccessibilitySize ? 1 : 2 }

    // MARK: Body

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GameTheme.lg) {
                if Self.showsNudge(stats) { nudge }
                heroCard
                todaySection
                lifetimeSection
            }
            .padding(.horizontal, GameTheme.lg)
            .padding(.top, GameTheme.md)
            .padding(.bottom, GameTheme.xl)
        }
        .background(GameTheme.dominant)
        .navigationTitle(Self.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Self.doneButtonLabel) { onDone() }.font(GameTheme.bodyFont)
                }
            }
        }
    }

    private var nudge: some View {
        Text(Self.nudgeText)
            .font(GameTheme.bodyFont)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var heroCard: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: GameTheme.md))
            : AnyLayout(HStackLayout(alignment: .center, spacing: GameTheme.md))
        return layout {
            Image(systemName: "flame.fill")
                .font(GameTheme.displayFont)
                .foregroundStyle(stats.currentStreak > 0
                                 ? GameTheme.accent
                                 : Color.secondary.opacity(GameTheme.dimmedFlameOpacity))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: GameTheme.xs) {
                if stats.currentStreak > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: GameTheme.xs) {
                        CountUpNumber(value: stats.currentStreak).font(GameTheme.displayFont)
                        Text(Self.streakSuffix).font(GameTheme.headingFont)
                    }
                } else {
                    Text(Self.zeroStreakHeadline).font(GameTheme.headingFont)
                }
                if let line = Self.longestLine(longestStreak: stats.longestStreak) {
                    Text(line).font(GameTheme.labelFont).foregroundStyle(.secondary)
                }
                if let hint = Self.streakHint(stats) {
                    Text(hint).font(GameTheme.bodyFont).foregroundStyle(.secondary)
                }
            }
        }
        .padding(GameTheme.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameTheme.secondarySurface,
                    in: RoundedRectangle(cornerRadius: GameTheme.celebrationCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.heroAccessibilityLabel(stats)))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(GameTheme.labelFont)
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: GameTheme.sm),
              count: Self.gridColumnCount(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize))
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: GameTheme.sm) {
            sectionHeader(Self.todayHeader)
            LazyVGrid(columns: columns, alignment: .leading, spacing: GameTheme.sm) {
                StatTile(caption: Self.puzzlesTodayCaption, value: stats.puzzlesToday)
                StatTile(caption: Self.todayScoreCaption, value: stats.todayScore)
                StatTile(caption: Self.wordsFoundCaption, value: stats.todayWords,
                         sectionPrefix: Self.todaySectionSpoken)
            }
        }
    }

    private var lifetimeSection: some View {
        VStack(alignment: .leading, spacing: GameTheme.sm) {
            sectionHeader(Self.lifetimeHeader)
            LazyVGrid(columns: columns, alignment: .leading, spacing: GameTheme.sm) {
                StatTile(caption: Self.bestScoreCaption, value: stats.bestScore)
                StatTile(caption: Self.gamesPlayedCaption, value: stats.gamesPlayed)
                StatTile(caption: Self.averageScoreCaption, value: stats.averageScore, animates: false)
                StatTile(caption: Self.wordsFoundCaption, value: stats.totalWords,
                         sectionPrefix: Self.lifetimeSectionSpoken)
                StatTile(caption: Self.averageWordsCaption, value: stats.averageWords, animates: false)
                StatTile(caption: Self.pangramsCaption, value: stats.pangrams)
                StatTile(caption: Self.sweepsCaption, value: stats.sweeps)
            }
            bestRankTile
        }
    }

    private var bestRankTile: some View {
        VStack(alignment: .leading, spacing: GameTheme.xs) {
            Text(Self.bestRankCaption).font(GameTheme.labelFont).foregroundStyle(.secondary)
            rankName
        }
        .padding(GameTheme.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameTheme.secondarySurface,
                    in: RoundedRectangle(cornerRadius: GameTheme.celebrationCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(Self.bestRankCaption), \(stats.bestRank?.displayName ?? Self.notAvailableSpoken)"))
    }

    @ViewBuilder private var rankName: some View {
        if stats.bestRank == nil {
            Text(Self.emptyValue).font(GameTheme.headingFont).foregroundStyle(.primary)
        } else if Self.showsGlow(stats.bestRank) {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let p = OverflowGlow.pulse(time: t, reduceMotion: reduceMotion)
                HStack(spacing: GameTheme.xs) {
                    Image(systemName: "sparkles").accessibilityHidden(true)
                    Text(Self.bestRankText(stats.bestRank))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.accent)
                .shadow(color: GameTheme.overflowGold.opacity(OverflowGlow.opacity(pulse: p)),
                        radius: OverflowGlow.radius(pulse: p))
            }
        } else {
            Text(Self.bestRankText(stats.bestRank))
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

private struct StatTile: View {
    let caption: String
    let value: Int?
    var sectionPrefix: String? = nil
    var animates: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.xs) {
            valueView
                .font(GameTheme.displayFont)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(caption)
                .font(GameTheme.labelFont)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .padding(GameTheme.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameTheme.secondarySurface,
                    in: RoundedRectangle(cornerRadius: GameTheme.celebrationCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(StatsView.tileAccessibilityLabel(
            caption: caption, value: value, sectionPrefix: sectionPrefix)))
    }

    @ViewBuilder private var valueView: some View {
        if let value, animates {
            CountUpNumber(value: value)
        } else {
            Text(StatsView.valueText(value))
        }
    }
}

private struct CountUpNumber: View {
    let value: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAnimatedIn = false
    private var shown: Int { (reduceMotion || hasAnimatedIn) ? value : 0 }
    var body: some View {
        Text(shown, format: .number)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(shown)))
            .onAppear {
                guard !reduceMotion, !hasAnimatedIn else { return }
                withAnimation(.easeOut(duration: GameTheme.statsCountUpSeconds)) { hasAnimatedIn = true }
            }
    }
}

#Preview("New player") { NavigationStack { StatsView(stats: .empty) } }

private let previewActive = PlayerStats(
    puzzlesToday: 2, todayScore: 87, todayWords: 21, currentStreak: 4, longestStreak: 12,
    gamesPlayed: 37, bestScore: 142, totalWords: 640, averageScore: 71, averageWords: 17,
    bestRank: .legend, pangrams: 19, sweeps: 3)

#Preview("Active streak") { NavigationStack { StatsView(stats: previewActive) } }

#Preview("At risk") {
    var s = previewActive
    s.streakAtRisk = true
    s.puzzlesToday = 0
    return NavigationStack { StatsView(stats: s) }
}

#Preview("Mythic") {
    var s = previewActive
    s.bestRank = .mythicGrandmaster
    return NavigationStack { StatsView(stats: s) }
}

#Preview("Zero streak, longest 5") {
    NavigationStack {
        StatsView(stats: PlayerStats(currentStreak: 0, longestStreak: 5, gamesPlayed: 9))
    }
}

#Preview("AX5") {
    NavigationStack { StatsView(stats: previewActive) }
        .environment(\.dynamicTypeSize, .accessibility5)
}

import SwiftUI

/// Phase 7 in-round Found Words sheet. Presentation-only: value-in/closure-out, no
/// view-model or store reads (only `@Environment(\.dynamicTypeSize)` is allowed).
/// ScrollView + LazyVStack, not a system list container. Row styling is copied from MissedWordsView
/// (D-08/D-14/D-17: copy, not refactor).
struct FoundWordsView: View {
    // MARK: - Frozen copy (07-UI-SPEC Copywriting Contract)
    static let title = "Found Words"
    static let emptyNudge = "No words yet — get swiping!"
    static let doneButtonLabel = "Done"
    static let scoreBarAccessibilityHint = "Shows the words you've found"

    static func subtitle(rank: RankTier, foundCount: Int, totalCount: Int) -> String {
        "\(rank.displayName) — \(foundCount) of \(totalCount) words"
    }

    static func groupTitle(length: Int, found: Int, total: Int) -> String {
        "\(length) Letters · \(found) of \(total)"
    }

    static func groupAccessibilityLabel(length: Int, found: Int, total: Int) -> String {
        "\(length) letters, \(found) of \(total) found" + (found == total ? ", complete" : "")
    }

    static func pointsText(_ points: Int) -> String { "+\(points)" }

    static func rowAccessibilityLabel(_ word: FoundWord) -> String {
        let pts = word.points == 1 ? "1 point" : "\(word.points) points"
        return word.isPangram ? "\(word.text), pangram, \(pts)" : "\(word.text), \(pts)"
    }

    let groups: [FoundWordGroup]
    let rank: RankTier
    let foundCount: Int
    let totalCount: Int
    let onDone: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if foundCount == 0 { nudge }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: GameTheme.sm) {
                        ForEach(groups) { group in
                            groupHeader(group)
                            ForEach(group.found) { wordRow($0) }
                        }
                    }
                    .padding(.horizontal, GameTheme.lg)
                    .padding(.bottom, GameTheme.lg)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GameTheme.dominant)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Self.doneButtonLabel) { onDone() }
                        .font(GameTheme.bodyFont)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: GameTheme.sm) {
            Text(Self.title)
                .font(GameTheme.headingFont)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityAddTraits(.isHeader)
            Text(Self.subtitle(rank: rank, foundCount: foundCount, totalCount: totalCount))
                .font(GameTheme.labelFont)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .multilineTextAlignment(.center)
        .padding(GameTheme.lg)
    }

    private var nudge: some View {
        Text(Self.emptyNudge)
            .font(GameTheme.bodyFont)
            .foregroundStyle(Color.secondary)
            .multilineTextAlignment(.center)
            .padding(.vertical, GameTheme.md)
            .padding(.horizontal, GameTheme.lg)
    }

    private func groupHeader(_ group: FoundWordGroup) -> some View {
        HStack(spacing: GameTheme.xs) {
            Text(Self.groupTitle(length: group.length, found: group.found.count, total: group.total))
                .font(GameTheme.headingFont)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if group.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.accent)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, GameTheme.md)
        .padding(.horizontal, GameTheme.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.groupAccessibilityLabel(length: group.length, found: group.found.count, total: group.total)))
        .accessibilityAddTraits(.isHeader)
    }

    private func wordRow(_ word: FoundWord) -> some View {
        HStack(spacing: GameTheme.sm) {
            Text(word.text)
                .font(GameTheme.bodyFont)
                .foregroundStyle(word.isPangram ? GameTheme.accent : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .layoutPriority(1)
            if word.isPangram { pangramBadge }
            Spacer()
            Text(Self.pointsText(word.points))
                .font(GameTheme.bodyFont)
                .foregroundStyle(Color.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.vertical, GameTheme.sm)
        .padding(.horizontal, GameTheme.md)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(Self.rowAccessibilityLabel(word)))
    }

    @ViewBuilder
    private var pangramBadge: some View {
        let badge = Label("Pangram", systemImage: "checkmark.seal.fill")
            .font(GameTheme.labelFont)
            .foregroundStyle(GameTheme.accent)
        if dynamicTypeSize.isAccessibilitySize {
            badge.labelStyle(.iconOnly)
        } else {
            badge.labelStyle(.titleAndIcon)
        }
    }
}

// MARK: - Previews (letters acdelns)

private enum FoundWordsPreviewData {
    static let midRound: [FoundWordGroup] = [
        FoundWordGroup(length: 4, found: [FoundWord(text: "cane", points: 1, isPangram: false)], total: 2),
        FoundWordGroup(length: 5, found: [], total: 2),
        FoundWordGroup(length: 6, found: [
            FoundWord(text: "candle", points: 6, isPangram: false),
            FoundWord(text: "scaled", points: 6, isPangram: false)
        ], total: 3),
        FoundWordGroup(length: 7, found: [FoundWord(text: "candles", points: 14, isPangram: true)], total: 1)
    ]
    static let empty: [FoundWordGroup] = [
        FoundWordGroup(length: 4, found: [], total: 2),
        FoundWordGroup(length: 5, found: [], total: 2),
        FoundWordGroup(length: 6, found: [], total: 3),
        FoundWordGroup(length: 7, found: [], total: 1)
    ]
    static let complete: [FoundWordGroup] = [
        FoundWordGroup(length: 4, found: [
            FoundWord(text: "cane", points: 1, isPangram: false),
            FoundWord(text: "clan", points: 1, isPangram: false)
        ], total: 2),
        FoundWordGroup(length: 5, found: [], total: 2)
    ]
}

#Preview("Mid-round with pangram") {
    FoundWordsView(groups: FoundWordsPreviewData.midRound, rank: .adept, foundCount: 4, totalCount: 8, onDone: {})
}

#Preview("Empty") {
    FoundWordsView(groups: FoundWordsPreviewData.empty, rank: .adept, foundCount: 0, totalCount: 8, onDone: {})
}

#Preview("Group complete") {
    FoundWordsView(groups: FoundWordsPreviewData.complete, rank: .adept, foundCount: 2, totalCount: 4, onDone: {})
}

#Preview("Accessibility XXL") {
    FoundWordsView(groups: FoundWordsPreviewData.midRound, rank: .adept, foundCount: 4, totalCount: 8, onDone: {})
        .environment(\.dynamicTypeSize, .accessibility5)
}

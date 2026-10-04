# Phase 7: Found Words View - Research

**Researched:** 2026-10-04
**Domain:** SwiftUI (iOS 17) in-round sheet, MVVM value-in/closure-out, Swift Testing
**Confidence:** HIGH (all findings come from reading the existing codebase. There are no new libraries.)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The entire `ScoreBarView` becomes the tap target. Tapping it opens the found-words list as a `.sheet`. There is no new top-bar button and no inline strip.
- **D-02:** `ScoreBarView` gets a small chevron (`›`, e.g. SF Symbol `chevron.right`) after the "12 of 31 words" text as the tappability cue. VoiceOver: the bar is exposed as a button with a hint that it shows found words.
- **D-03:** Sheet uses `.presentationDetents([.medium, .large])`. It opens at half height and can be dragged to full.
- **D-04:** The sheet is modal (standard sheet behavior). The board is NOT interactive while the sheet is open, at either detent.
- **D-05:** Sheet has a "Done" button (same pattern as `SettingsView`) AND supports swipe-to-dismiss.
- **D-06:** Length groups ordered shortest first (4 Letters, 5 Letters, ...), matching `MissedWordsView`.
- **D-07:** Words within a group are alphabetical (NOT order found, even though `foundWords` is stored most-recent-first).
- **D-08:** One word per row, reusing `MissedWordsView`'s row styling (secondarySurface rounded background, `GameTheme.bodyFont`).
- **D-09:** Sheet header: title "Found Words" plus subtitle "<Rank> — N of M words", the same subtitle format as `MissedWordsView`'s header.
- **D-10:** Group header shows found-of-total for that length, e.g. **"4 Letters · 3 of 9"**. This is a deliberate hint (it reveals how many words of each length exist). The user chose it knowingly over a hint-free header.
- **D-11:** EVERY word length that exists in the puzzle's `validWords` gets a group header, including lengths with zero found (e.g. "7 Letters · 0 of 2"). Empty groups show the header only, with no rows.
- **D-12:** A completed group (found == total) shows a checkmark on its header in the accent color, e.g. "5 Letters · 4 of 4 ✓".
- **D-13:** Each row shows the points that word earned, right-aligned, as "+N" (via `ScoreCalculator.points(for:isPangram:)`; e.g. a 7-letter pangram shows "+14").
- **D-14:** Pangrams are identified EXACTLY as in `MissedWordsView`: word text in `GameTheme.accent` plus a `Label("Pangram", systemImage: "checkmark.seal.fill")` badge in accent. Accessibility label "<word>, pangram".
- **D-15:** No separate pangram count/hint line ("Pangrams: 1 of 2"). That overlaps Phase 8 (all-pangrams bonus).
- **D-16:** Before any word is found, the sheet still opens. It shows all group headers at "0 of N" plus a short friendly nudge line at the top (playful tone consistent with Phase 6, e.g. "No words yet — get swiping!"). The score bar is tappable at all times during `.playing`.
- **D-17:** `MissedWordsView` is left completely alone this phase. There is no shared-component refactor and no visual change.

### Claude's Discretion
- Exact nudge-line copy (playful, short).
- Exact separator/format of group header ("·" vs "—") and the checkmark glyph/symbol.
- Whether group data is a new view-model computed property (e.g. `foundWordGroups` with `found`/`total` per length) or a new struct alongside `MissedWordGroup`. The view must stay value-in/closure-out (only `GameView` touches `GameViewModel`).
- Dynamic Type handling for the "+N" column and header at accessibility sizes (follow Phase 5 shrink-to-fit patterns).
- Whether the found-words sheet is a new file `FoundWordsView.swift` in `Game/Views/` (expected).

### Deferred Ideas (OUT OF SCOPE)
- Shared row/pangram-badge component between FoundWordsView and MissedWordsView. Declined for this phase; possible later cleanup.
- Pangram count hint ("Pangrams: 1 of 2"). Belongs with Phase 8 (all-pangrams bonus).
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs are mapped (TBD). The planner should treat D-01..D-17 as the requirements. Suggested internal IDs: FW-ENTRY (D-01..05), FW-DATA (D-06, 07, 10, 11, 12, 13), FW-ROW (D-08, 14), FW-EMPTY (D-16), FW-ISOLATION (D-17).

| ID | Description | Research Support |
|----|-------------|------------------|
| FW-ENTRY | Score bar tappable, chevron, sheet with detents and Done | GameView sheet pattern, SettingsView Done pattern |
| FW-DATA | Groups by length, found/total, alphabetical, points | `foundWordGroups` view-model property, which tests can cover |
| FW-ROW | Row and pangram styling copied from MissedWordsView | Row code verified below |
| FW-EMPTY | Nudge plus all-zero headers | Data contract below |
| FW-ISOLATION | MissedWordsView untouched | `git diff` check |
</phase_requirements>

## Summary

This phase is pure SwiftUI work on code that already exists, so it needs no new libraries. The pieces are a new `FoundWordsView` (value-in/closure-out), a `foundWordGroups` computed property on `GameViewModel` next to `missedWordGroups`, and a small `ScoreBarView` change (chevron plus accessibility). `GameView` also gets a `Button` wrapper with a `.sheet`. `GameViewModel` already exposes `foundWords` (most-recent-first), `pangramSet`, `rank`, `foundCount` and `totalWordCount`. The per-length totals come from `puzzle.validWords`.

The main design choice is where the points live. The view must not call `ScoreCalculator` or touch the VM (the UI-SPEC says points are computed in GameView or the view-model). Put them in the data struct (`FoundWord { text, points, isPangram }`). The view then gets everything it needs as plain values and renders no logic. That also makes the grouping logic unit-testable without a view.

Mind two integration subtleties. First, `GameView` presents a `fullScreenCover` using `.constant(...)` for roundOver and paywalled. The new sheet flag must be reset when `roundPhase` leaves `.playing`. Second, `.sheet` is applied on the same view chain as the existing cover and the Settings sheet. Multiple `.sheet` modifiers on one view work in iOS 17 as long as each has its own `isPresented` binding. Settings already does this next to the cover.

**Primary recommendation:** Add `FoundWord`/`FoundWordGroup` structs and `GameViewModel.foundWordGroups` (unit-tested with the existing `fixturePuzzle()`), create `FoundWordsView.swift` by copying `MissedWordsView.wordRow` (don't refactor), and wrap `ScoreBarView` in a `Button` with `.buttonStyle(.plain)` in `GameView.playingLayout`.

## Standard Stack

No new dependencies (CLAUDE.md: no third-party additions needed).

| Library | Version | Purpose |
|---------|---------|---------|
| SwiftUI | iOS 17 SDK | `.sheet`, `.presentationDetents`, `.presentationDragIndicator`, `NavigationStack`, `ScrollView`+`LazyVStack` |
| Observation (`@Observable`) | iOS 17 | Existing `GameViewModel` |
| Swift Testing (`import Testing`) | Xcode 16+ | Existing test style (`@Suite`, `@Test`, `#expect`) |

No `npm view` check is applicable.

## Architecture Patterns

### Recommended file changes
```
WordPuzzle/WordPuzzle/Game/GameViewModel.swift         # + FoundWord, FoundWordGroup structs, foundWordGroups
WordPuzzle/WordPuzzle/Game/Views/FoundWordsView.swift  # NEW (the Xcode project uses a synchronized root group, objectVersion 77, so new files are picked up automatically with no pbxproj edit)
WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift    # chevron + hint
WordPuzzle/WordPuzzle/Game/Views/GameView.swift        # Button wrapper, @State, .sheet, onChange reset
WordPuzzle/WordPuzzleTests/GameViewModelTests.swift    # foundWordGroups tests
WordPuzzle/WordPuzzleTests/FoundWordsViewTests.swift   # NEW, frozen copy constants
```

### Pattern 1: Data in the view-model (Claude's discretion, recommended)
```swift
struct FoundWord: Identifiable, Equatable {
    let text: String
    let points: Int
    let isPangram: Bool
    var id: String { text }
}
struct FoundWordGroup: Identifiable, Equatable {
    let length: Int
    let found: [FoundWord]   // alphabetical
    let total: Int
    var isComplete: Bool { found.count == total }
    var id: Int { length }
}

// in GameViewModel, next to missedWordGroups
var foundWordGroups: [FoundWordGroup] {
    guard let puzzle else { return [] }
    let totals = Dictionary(grouping: puzzle.validWords, by: \.count).mapValues(\.count)
    let foundByLength = Dictionary(grouping: foundWords, by: \.count)
    return totals.keys.sorted().map { length in
        let words = (foundByLength[length] ?? []).sorted().map {
            FoundWord(text: $0,
                      points: ScoreCalculator.points(for: $0, isPangram: pangramSet.contains($0)),
                      isPangram: pangramSet.contains($0))
        }
        return FoundWordGroup(length: length, found: words, total: totals[length]!)
    }
}
```
Use `.sorted()` (the same as `missedWordGroups`) for alphabetical order. The words are lowercase ENABLE words, so there are no case issues. Check `puzzle.validWords` for duplicates (it is probably an array built from a set). Don't dedupe unless a test shows duplicates.

### Pattern 2: Entry point in GameView
```swift
@State private var isShowingFoundWords = false

Button { isShowingFoundWords = true } label: {
    ScoreBarView(...)
}
.buttonStyle(ScoreBarButtonStyle())   // plain + opacity 0.7 when pressed
.padding(.horizontal, GameTheme.lg).padding(.top, GameTheme.sm)
.accessibilityHint(Text("Shows the words you've found"))

.sheet(isPresented: $isShowingFoundWords) {
    FoundWordsView(groups: viewModel.foundWordGroups, pangrams: viewModel.pangramSet,
                   rank: viewModel.rank, foundCount: viewModel.foundCount,
                   totalCount: viewModel.totalWordCount, onDone: { isShowingFoundWords = false })
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
.onChange(of: viewModel.roundPhase) { _, p in if p != .playing { isShowingFoundWords = false } }
```
Existing `.onChange(of: roundPhase)` already exists for sound. Add the reset to it or add a second modifier (both are fine). `ScoreBarView` has `.accessibilityElement(children: .combine)` and a custom label. A `Button` wrapper adds the `.isButton` trait automatically, so `.accessibilityAddTraits(.isButton)` is redundant but harmless. Put the hint on the Button, not inside ScoreBarView, so ScoreBarView previews and tests keep working.

The chevron goes inside ScoreBarView's trailing group (the "N of M words" text). Wrap the text and `Image(systemName: "chevron.right")` in an `HStack(spacing: GameTheme.xs)`, with `.accessibilityHidden(true)` on the image. Because `.combine` is used with an explicit label, the chevron is already not read. Confirm `GameTheme.xs` exists (the UI-SPEC lists xs = 4pt; the CONTEXT lists only sm/md/lg, so grep for it and add no new token if it is missing; use 4 literally via a spacing constant).

### Pattern 3: Sheet content
`NavigationStack` wrapping a `VStack` (header, optional nudge, `ScrollView`+`LazyVStack`). Mirror `SettingsView`: `.navigationBarTitleDisplayMode(.inline)` plus toolbar. Note that the existing SettingsView uses `ToolbarItem(placement: .topBarTrailing)`, while the UI-SPEC says `.confirmationAction`. Both place Done on the trailing edge. Prefer `.topBarTrailing` to match the real code. The title is rendered by the in-body header (Heading, centered), so do NOT also set `.navigationTitle("Found Words")` visibly. Either skip the title or use an empty one, otherwise the title appears twice.

Sheet content backgrounds: set `.background(GameTheme.dominant)` as SettingsView does.

### Anti-Patterns to Avoid
- Using `List` (CLAUDE.md and the UI-SPEC both forbid it). Use `ScrollView`+`LazyVStack`.
- Having the view read `GameViewModel` or `@Environment` stores.
- Editing `MissedWordsView` (D-17). Copy the row code instead.
- Fixed font sizes. Use the `GameTheme` fonts.
- Calling `ScoreCalculator` inside the view body.

## Don't Hand-Roll

| Problem | Use Instead |
|---------|-------------|
| Points per word | `ScoreCalculator.points(for:isPangram:)` |
| Rank display | `RankTier.displayName` |
| Sheet sizing/dismiss | `.presentationDetents`, `.presentationDragIndicator`, and the system swipe-to-dismiss |
| Accessibility-size detection | `@Environment(\.dynamicTypeSize).isAccessibilitySize` (the same as GameView) |
| Pressed-state button | A tiny `ButtonStyle` (`configuration.isPressed ? 0.7 : 1`) |

## Common Pitfalls

### Pitfall 1: Sheet flag stuck true across round end
**What goes wrong:** `roundPhase` goes to `.roundOver` and the `fullScreenCover` presents, while the sheet flag stays true. When the next round starts the sheet re-appears.
**Why:** The cover uses `.constant(...)` and the sheet uses `@State`.
**How to avoid:** Reset the flag in `onChange(of: roundPhase)` when it is not `.playing`. In practice Finish Round is unreachable while a modal sheet is up, but the reset is cheap insurance.
**Warning signs:** The found-words sheet appears at the start of a new round.

### Pitfall 2: Double title
In-body "Found Words" plus a navigation title duplicate each other. Use only one.

### Pitfall 3: Button wrapper breaks the ScoreBarView look
A default `Button` tints the label with the accent color. Use `.buttonStyle(.plain)` (or the custom style) so the secondary and primary colors are preserved. The UI-SPEC explicitly requires this.

### Pitfall 4: Accessibility label of the combined row
`.accessibilityElement(children: .combine)` plus `.accessibilityLabel` replaces the combined text. Build the full label as "<word>[, pangram], N points" and make the group header a single element with `.accessibilityAddTraits(.isHeader)` and the label "4 letters, 3 of 9 found[, complete]".

### Pitfall 5: Dynamic Type at AX sizes
Word `.lineLimit(1).minimumScaleFactor(0.5).layoutPriority(1)`. The Pangram badge becomes `.labelStyle(.iconOnly)` when `dynamicTypeSize.isAccessibilitySize`. The "+N" uses `.monospacedDigit()`. Group header single line with shrink-to-fit. Add a `#Preview` using `.environment(\.dynamicTypeSize, .accessibility5)` (or XXL per the UI-SPEC).

### Pitfall 6: Empty puzzle / nil puzzle
`foundWordGroups` returns `[]` when `puzzle` is nil. The view must render fine with zero groups (the header only), which is only relevant outside `.playing`.

### Pitfall 7: Hint leakage is intentional
D-10/D-11 intentionally reveal per-length totals. Do not "fix" this.

## Code Examples

Row (copied from `MissedWordsView.wordRow`, extended with points):
```swift
private func wordRow(_ w: FoundWord) -> some View {
    HStack(spacing: GameTheme.sm) {
        Text(w.text).font(GameTheme.bodyFont)
            .foregroundStyle(w.isPangram ? GameTheme.accent : Color.primary)
            .lineLimit(1).minimumScaleFactor(0.5).layoutPriority(1)
        if w.isPangram {
            Label("Pangram", systemImage: "checkmark.seal.fill")
                .font(GameTheme.labelFont).foregroundStyle(GameTheme.accent)
                .labelStyle(dynamicTypeSize.isAccessibilitySize ? AnyLabelStyle(.iconOnly) : AnyLabelStyle(.titleAndIcon))
        }
        Spacer()
        Text("+\(w.points)").font(GameTheme.bodyFont).foregroundStyle(Color.secondary)
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
    }
    .padding(.vertical, GameTheme.sm).padding(.horizontal, GameTheme.md)
    .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 8))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(w.isPangram ? "\(w.text), pangram, \(w.points) points" : "\(w.text), \(w.points) points"))
}
```
`AnyLabelStyle` is not a SwiftUI type. A simpler approach is an `if/else` returning two `Label`s, or a small `@ViewBuilder`. `.labelStyle` takes a concrete generic type, so a ternary of different styles does not compile. Use `if isAccessibilitySize { label.labelStyle(.iconOnly) } else { label.labelStyle(.titleAndIcon) }`.

Frozen copy constants (the same pattern as `SettingsView`/`PaywallView`) so tests can pin them:
```swift
static let title = "Found Words"
static let emptyNudge = "No words yet — get swiping!"
static let doneButtonLabel = "Done"
static func groupTitle(length: Int, found: Int, total: Int) -> String { "\(length) Letters · \(found) of \(total)" }
static func groupAccessibilityLabel(...) -> String
```

## State of the Art

`.presentationDetents` and `.presentationDragIndicator` are available from iOS 16, so there are no concerns at the iOS 17 target. `@Observable` is already in use.

## Environment Availability

| Dependency | Available | Version |
|------------|-----------|---------|
| Xcode / xcodebuild | yes | targets WordPuzzle, WordPuzzleTests, WordPuzzleUITests; scheme WordPuzzle |
| iOS Simulator | yes | iPhone 17 Pro, 17 Pro Max, 17e available |

No other external dependencies.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), `@MainActor` suites |
| Config file | `WordPuzzle/WordPuzzle.xcodeproj` (scheme WordPuzzle; the test target is `WordPuzzleTests`, which uses a synchronized folder) |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/GameViewModelTests -only-testing:WordPuzzleTests/FoundWordsViewTests` |
| Full suite command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests` (skips the UI tests and the performance tests if they are slow; drop the flag for everything) |

Run commands from the repo root. Confirm the exact `-only-testing` suite identifiers (struct name) at execution. `GameViewModelTests` is the existing suite name (verify with `grep "@Suite" WordPuzzleTests/GameViewModelTests.swift`).

### Decision to Test Map
| Decisions | Behavior | Type | Command / Check | Exists? |
|-----------|----------|------|-----------------|---------|
| D-06, D-11 | Group lengths ascending, including zero-found lengths (fixture lengths 4, 5, 6) | unit | GameViewModelTests `testFoundWordGroupsIncludeEveryLengthAscending` | Wave 0 |
| D-07 | Alphabetical within a group after finding words out of order | unit | `testFoundWordGroupsAlphabetical` (submit "lance", "cane"; with a second 6-letter word, check that order is sorted) | Wave 0 |
| D-10, D-12 | found/total counts; `isComplete` true when all found | unit | `testFoundWordGroupsCountsAndCompletion` | Wave 0 |
| D-13, D-14 | `points` equals `ScoreCalculator.points`; `isPangram` flag from `pangramSet` (use a fixture with a pangram, e.g. a 7-letter pangram, +14) | unit | `testFoundWordGroupsPointsAndPangram` | Wave 0 |
| D-16 | 0 found: all groups present with empty `found` | unit | `testFoundWordGroupsEmptyBeforeAnyWord` | Wave 0 |
| D-09, D-10, D-16 copy | Title, nudge, Done label, group title format, accessibility label strings frozen | unit | FoundWordsViewTests | Wave 0 |
| D-01..D-05 | Entry button, sheet detents, Done, swipe | manual (or UI test) | Run on the simulator: tap the score bar, check the medium and large detents, Done and swipe dismiss, board inert behind the sheet. Optional XCUITest in `WordPuzzleUITests` by tapping the element with the "Rank ..." label | manual |
| D-02 | VoiceOver button and hint | manual | Accessibility Inspector | manual |
| D-14 | Visual parity of the pangram with MissedWordsView | manual | Compare the `#Preview`s | manual |
| D-17 | MissedWordsView untouched | automated check | `git diff --stat -- WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift` is empty | n/a |
| Build gate | Compiles; previews exist | build | `xcodebuild build -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` | n/a |

Note: the repo has `scripts/compliance-guards.sh`. Run it as a regression gate (check what it greps for, e.g. no `List`, no network).

### Sampling Rate
- **Per task commit:** the quick run command (view-model and copy tests)
- **Per wave merge:** full `WordPuzzleTests`
- **Phase gate:** full suite green, plus a manual simulator pass of the D-01..D-05 checklist, before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `GameViewModelTests.swift` additions (or a new `FoundWordGroupsTests.swift`). `fixturePuzzle()` is `private` in GameViewModelTests, so either extend that file or duplicate the fixture. Add a pangram variant fixture (e.g. `pangrams: ["candles"]` with 7-letter `validWords`) for the points test.
- [ ] `FoundWordsViewTests.swift`, the frozen-copy constants (mirror `SettingsViewTests`).
- No framework install is needed.

## Open Questions

1. **`GameTheme.xs` exists?**
   - Known: the UI-SPEC lists xs = 4pt. CONTEXT lists `sm/md/lg`. Unverified in `GameTheme.swift`.
   - Recommendation: grep first. If it is missing, use a literal `4` or add `xs` to GameTheme (the one exception to "no new tokens").
2. **XCUITest for the entry point?**
   - Unclear whether this is worth it. The score bar is an `.combine` element, so it may surface as a button with a label starting "Rank ...". Recommend manual verification plus the optional UI test only if it is cheap.

## Sources

### Primary (HIGH confidence): the repo itself
- `Game/Views/MissedWordsView.swift`, `ScoreBarView.swift`, `GameView.swift`, `Settings/SettingsView.swift`, `Game/GameViewModel.swift`, `Services/ScoreCalculator.swift`
- `WordPuzzleTests/GameViewModelTests.swift`, `SettingsViewTests.swift`, `DynamicTypeTests.swift`
- `07-CONTEXT.md`, `07-UI-SPEC.md`, `.planning/config.json` (nyquist_validation: true)

### Tertiary (training knowledge, LOW-MEDIUM)
- SwiftUI `.labelStyle` needing a concrete type, and multiple `.sheet` modifiers working with separate bindings. Both are standard behavior. Verify by compiling.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (nothing new)
- Architecture: HIGH (it mirrors existing code)
- Pitfalls: MEDIUM-HIGH (the sheet and cover interaction was reasoned, not run)

**Research date:** 2026-10-04
**Valid until:** 30 days

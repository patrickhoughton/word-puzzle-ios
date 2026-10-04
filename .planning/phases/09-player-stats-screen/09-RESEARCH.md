# Phase 9: Player Stats Screen - Research

**Researched:** 2026-10-04
**Domain:** SwiftUI stats screen + SwiftData additive schema change (iOS 17+, existing codebase)
**Confidence:** HIGH (codebase-verified); MEDIUM on the old-schema migration test technique

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
D-01 Two entry points: top-bar icon on LEFT of GameView top bar (headingFont, .secondary, minTapTarget frame, VoiceOver "Stats"; DEBUG ladybug coexists) AND a "Stats" `NavigationLink` row in SettingsView below the sound toggle that PUSHES inside Settings' NavigationStack.
D-02 Top-bar presentation is a `.sheet` with Done + swipe-to-dismiss, no detents.
D-03 Reverses Phase 5 D-03; update SettingsView doc comment.
D-04 MissedWordsView gets ONE compact tappable line "Best {B} · Streak {S}" opening the full stats sheet. Values read AFTER finishRound() recorded the round (already true). Reverses Phase 7 D-17 for this addition only.
D-05 Paywall unchanged.
D-06 Today: puzzlesPlayedToday (STARTED rounds), todayTotalScore, todayTotalWordsFound.
D-07 Streak: currentStreak (grace-day semantics) + longest streak (derived from GameRecord dates, same local-calendar-day logic).
D-08 Lifetime existing: totalGamesPlayed (FINISHED), bestScore, totalWordsFound.
D-09 Derived: average score, average words/game (no schema change).
D-10 Newly tracked: best rank reached, lifetime pangrams, pangram sweeps.
D-11 Optional fields on GameRecord (rank raw value, pangramsFound, hadSweep) written by finishRound() from rank, foundPangramCount, sweepBonus > 0. Must be optional/defaulted so lightweight migration works. Existing installs must launch without data loss. Plan MUST include a migration test (old-schema store opening under new schema) and on-device verification against a store with real history.
D-12 Old rounds count from now on; nil fields contribute nothing; no backfill, no footnote.
D-13 Lifetime pangrams count finished rounds only.
D-14 Best rank = highest RankTier across records with stored rank; Mythic Grandmaster only if actually reached.
D-15 PersistenceStore frozen API stays source-compatible; add methods alongside; extend record(...) with DEFAULTED params.
D-16 Hero streak card + TODAY 2-col tile grid + LIFETIME 2-col tile grid + prominent Best rank.
D-17 Best rank in GameTheme.accent gold; Mythic Grandmaster gets the ScoreBar glow.
D-18 Count-up animation from 0, must respect Reduce Motion, short.
D-19 Dynamic Type: survive AX5 on physical device, shrink-to-fit numbers, grid may collapse to 1 column; ScrollView.
D-20 New player (0 games): full layout with zeros, averages "—", best rank "—", one playful nudge line at top.
D-21 Grace-day streak: "at risk" hint; needs a played-today vs alive-via-yesterday signal.
D-22 Zero streak: encouraging copy, dimmed flame, "Longest: M" if M > 0.
D-23 Averages are whole numbers, rounded to nearest.

### Claude's Discretion
SF Symbol for top-bar icon and ladybug coexistence; tile ordering/styling; exact copy (pin as `static let`); new GameRecord field names/types and whether rank is stored as RankTier.rawValue (Int); longest-streak algorithm (full history OK, stay consistent with currentStreak day logic); count-up duration/easing; VoiceOver (tile = one element "<caption>, <value>", hero = one sentence); file location (`Game/Views/StatsView.swift` or `Stats/StatsView.swift`) with a value snapshot struct (e.g. `PlayerStats`) built by GameView; MissedWordsView summary as defaulted value params + closure.

### Deferred Ideas (OUT OF SCOPE)
"New best!" callout on end-of-round; charts/history graphs, per-day history, sharing, reset-stats, achievements, any paywall change.
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs mapped (TBD). Derived must-haves from goal + CONTEXT + UI-SPEC:

| ID (derived) | Description | Research Support |
|----|-------------|------------------|
| P9-A | GameRecord gains optional rank/pangramsFound/hadSweep; finishRound writes them; old stores migrate with no data loss | Pattern 1, Pitfall 1, migration test |
| P9-B | PersistenceStore gains longestStreak, averageScore, averageWordsPerGame, bestRank, totalPangramsFound, totalSweeps, playedToday helper; record(...) extended with defaults | Pattern 2 |
| P9-C | `PlayerStats` snapshot + `StatsView` (hero, TODAY, LIFETIME, best rank, states) per UI-SPEC | Pattern 3 |
| P9-D | Entry points: top-bar icon + sheet, Settings NavigationLink row, MissedWordsView summary line | Pattern 4, Pitfall 2 |
| P9-E | Count-up animation honoring Reduce Motion; Dynamic Type collapse; VoiceOver labels | Pattern 5 |
</phase_requirements>

## Summary

Everything needed already exists in-repo: `PersistenceStore` (all existing queries, `todayBounds`, grace-day `currentStreak`), `GameRecord` (3 plain fields, no versioned schema/migration plan), `RankTier` (Int raw value, Comparable, `mythicGrandmaster` hidden 11th case), `GameTheme` tokens, and ScoreBarView's glow constants. No new libraries. This phase is additive Swift only. The Xcode project uses `objectVersion = 77` (file-system-synchronized groups), so new `.swift` files placed under `WordPuzzle/WordPuzzle/...` and `WordPuzzle/WordPuzzleTests/...` are picked up without editing `project.pbxproj`.

The riskiest parts: (1) the SwiftData schema change must be additive/optional so automatic lightweight migration applies to real on-device history; (2) presenting the stats sheet FROM the round-over `fullScreenCover` (a sheet attached to GameView's root will not present while that cover is up); (3) the per-launch `GameView` snapshot must be built from fresh store reads each time the sheet opens (stores are `@Observable` but values are computed reads, not stored state).

**Primary recommendation:** Add three optional stored properties to `GameRecord` (`rankRaw: Int?`, `pangramsFound: Int?`, `hadSweep: Bool?`) with an init that defaults them to nil, keep `makeContainer` unchanged, add store queries that fetch-and-reduce in Swift, build a `PlayerStats` struct via one `persistenceStore.playerStats(now:)` function, and attach the MissedWordsView's stats sheet INSIDE the cover content.

## Standard Stack

No new dependencies (CLAUDE.md: SwiftUI iOS 17+, @Observable MVVM, SwiftData, no third-party). Everything is first-party.

| Piece | Use | Notes |
|-------|-----|-------|
| SwiftData `@Model` | New optional fields on `GameRecord` | Additive optional properties = automatic lightweight migration (HIGH, Apple documented behaviour) |
| SwiftUI `LazyVGrid`, `ScrollView`, `NavigationStack/NavigationLink` | Layout and Settings push | Per UI-SPEC |
| `contentTransition(.numericText(value:))` | Count-up | iOS 17+ API (`numericText(value:)` iOS 17) |
| Swift Testing (`@Test`, `#expect`, `@Suite`) | All unit tests | Existing convention (not XCTest) |

**Installation:** none.

## Architecture Patterns

### Recommended structure
```
WordPuzzle/WordPuzzle/
  Services/GameRecord.swift          # + 3 optional fields
  Services/PersistenceStore.swift    # + record() defaulted params, + query methods, + playerStats(now:)
  Services/PlayerStats.swift         # value struct snapshot (Equatable, Sendable)
  Stats/StatsView.swift              # mirrors Settings/ folder; value-in/closure-out
  Game/GameTheme.swift               # + dimmedFlameOpacity = 0.4, statsCountUpSeconds = 0.6
  Game/GameViewModel.swift           # finishRound passes rank/pangrams/sweep
  Game/Views/GameView.swift          # icon, isShowingStats sheet, snapshot
  Game/Views/MissedWordsView.swift   # summary line (defaulted params)
  Settings/SettingsView.swift        # NavigationLink row + stats value param
WordPuzzleTests/ PersistenceStatsTests.swift, StatsViewTests.swift, StatsMigrationTests.swift
```

### Pattern 1: Additive GameRecord fields (D-11)
Verified current model: `date`, `score`, `wordsFoundCount`; `makeContainer` uses `ModelContainer(for: GameRecord.self, RoundStartRecord.self, ...)` with NO `VersionedSchema`/`SchemaMigrationPlan` (grep confirmed). Adding optional properties with no `@Attribute` rename is inferred lightweight migration; no plan needed.
```swift
@Model final class GameRecord {
    var date: Date
    var score: Int
    var wordsFoundCount: Int
    var rankRaw: Int?          // RankTier.rawValue
    var pangramsFound: Int?
    var hadSweep: Bool?
    init(date: Date = .now, score: Int, wordsFoundCount: Int,
         rankRaw: Int? = nil, pangramsFound: Int? = nil, hadSweep: Bool? = nil) { ... }
}
```
Do NOT use non-optional properties with property-level defaults (`var x: Int = 0`) as the only mechanism: that also migrates, but D-12 requires old rounds to be distinguishable (nil = no data) for best rank. Use optionals. Do not rename or retype existing fields (that breaks lightweight inference).

### Pattern 2: PersistenceStore additions (D-15)
- `record(score:wordsFoundCount:rank: RankTier? = nil, pangramsFound: Int? = nil, hadSweep: Bool? = nil, date: Date = .now)`. CAUTION on parameter ORDER: existing calls use `record(score:wordsFoundCount:date:)`; Swift requires labeled args in declaration order, so new params must go AFTER `date` (or the existing `date:` call sites fail to compile). Put them last: `record(score:, wordsFoundCount:, date: = .now, rank: = nil, pangramsFound: = nil, hadSweep: = nil)`. ~30 existing test call sites then compile unchanged.
- `longestStreak()`: fetch all GameRecord, `Set(records.map { calendar.startOfDay(for: $0.date) })`, sort ascending, walk runs where `calendar.date(byAdding: .day, value: 1, to: prev) == next` (compare by calendar day add, NOT `timeIntervalSince` / 86400, to be DST-safe). Return max run. Use the same injected `calendar`. Must be `>= currentStreak(now:)` — note currentStreak is capped to a 400-day window; use `max(longestStreak(), currentStreak())` in the snapshot to guarantee the invariant for any future edge case.
- `averageScore()` / `averageWordsPerGame()` return `Int?` (nil when 0 games, never divide by zero): `Int((Double(total)/Double(n)).rounded())` (D-23 nearest; `.rounded()` is half-away-from-zero, fine).
- `bestRank() -> RankTier?`: `records.compactMap { $0.rankRaw }.max().flatMap(RankTier.init(rawValue:))`. Unknown raw values (future tiers) map to nil safely.
- `totalPangramsFound()`: `reduce { $0 + ($1.pangramsFound ?? 0) }`; `totalSweeps()`: `count { $0.hadSweep == true }`.
- `hasFinishedRoundToday(now:)`: `fetchCount` with the `todayBounds` predicate on GameRecord > 0. At-risk = `currentStreak > 0 && !hasFinishedRoundToday` (D-21). It must use GameRecord (finished), not RoundStartRecord, because streaks are derived from GameRecord.
- Fetch-and-reduce in Swift (no SUM pushdown; existing Pitfall 3 in file).
- One `playerStats(now:) -> PlayerStats` aggregator avoids GameView duplicating logic and makes the snapshot unit-testable.

### Pattern 3: PlayerStats + StatsView (value-in/closure-out)
`PlayerStats` fields: `puzzlesToday, todayScore, todayWords, currentStreak, longestStreak, streakAtRisk, gamesPlayed, bestScore, totalWords, averageScore: Int?, averageWords: Int?, bestRank: RankTier?, pangrams, sweeps`; `static let empty`. `StatsView(stats:, showsDoneButton: Bool, onDone:)`. Put pure presentation logic (headline text, hint, empty-state flag, tile VoiceOver label, value string with "—") as `static func`s on StatsView/PlayerStats so tests do not need to render views (project pattern: SettingsViewTests / PaywallViewTests assert on statics).

### Pattern 4: Entry points
- Settings: `NavigationLink` row inside the existing `VStack`. NavigationLink in a plain VStack (not a List) renders as a tappable label without chevron, so draw the chevron explicitly (`Image(systemName: "chevron.right")`) and keep `frame(minHeight: minTapTarget)`; use `.buttonStyle(.plain)` to avoid blue tint. Destination `StatsView(stats:, showsDoneButton: false)`. SettingsView gets `stats: PlayerStats = .empty` (defaulted so existing tests/previews compile). GameView must refresh the snapshot when the Settings sheet opens (compute in the sheet content closure, which re-evaluates on presentation, or set `@State statsSnapshot` in the button actions).
- Top bar: add stats Button as first item in the left HStack before the `#if DEBUG` ladybug Menu (UI-SPEC: stats outermost-left, ladybug right of it with `sm` gap). The leading `Spacer()` stays.
- Sheet state `@State private var isShowingStats`. Snapshot refreshed on open (`statsSnapshot = persistenceStore.playerStats()` then set flag).

### Pattern 5: Count-up and Reduce Motion
```swift
// StatTile: displayed value state, set on appear
@State private var shown = 0
Text(shown, format: .number)
    .contentTransition(.numericText(value: Double(shown)))
    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
    .onAppear {
        guard !reduceMotion else { shown = value; return }
        withAnimation(.easeOut(duration: GameTheme.statsCountUpSeconds)) { shown = value }
    }
```
Initialize `shown` to `reduceMotion ? value : 0` is not possible in `init` (environment unavailable); instead use `.onAppear` as above, and for Reduce Motion set without animation (flash of 0 for one frame is avoidable by making `shown` start as `value` and animating from 0 only when motion allowed: set `shown = 0` in a `.task`/onAppear then animate — prefer the first approach and accept). Set `.accessibilityLabel` from the FINAL value (not `shown`) so VoiceOver never reads intermediates. `numericText` interpolates digit rolls but a full-value jump 0 -> N animates as a digit roll rather than counting every integer; this satisfies D-18 ("tick up") at 0.6 s. A true integer-by-integer count would need a timer/`TimelineView` and is not worth it (flag if the user wants it).
Glow for Mythic: copy ScoreBarView's approach (`TimelineView(.animation)` with `lerp` over `overflowGlowOpacityRange/RadiusRange`, pulse = 0.5 when reduceMotion). Reuse, do not re-derive; check whether `lerp` is private in ScoreBarView and extract to a shared internal helper if so.

### Anti-Patterns to Avoid
- Storing a streak/longest-streak counter (CONTEXT: derive at read time).
- Adding stats reads to child views (only GameView touches stores).
- Inline magic numbers (add to GameTheme).
- Changing `makeContainer`'s model list or introducing `VersionedSchema` without need (adds risk to on-disk stores for no benefit).
- `fetch(...).count` instead of `fetchCount`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Number roll animation | Timer-driven counter | `contentTransition(.numericText)` | Built-in, honors animation context |
| Schema migration | Manual copy/migrate step | SwiftData automatic lightweight migration via optional fields | Zero code, proven |
| Day-boundary math | Rolling 24h / `timeIntervalSince` | Injected `Calendar` + `startOfDay` + `date(byAdding: .day)` | DST-safe, already the store's convention |
| Grid | Manual HStack rows | `LazyVGrid` with `GridItem(.flexible())` | Dynamic Type collapse by swapping columns array |
| Glow | New glow effect | ScoreBarView's shadow constants | Locked by D-17 |

## Runtime State Inventory

This is not a rename phase, but there IS a schema change, so the runtime-state question applies to persisted data:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | On-device SwiftData store (default location) with GameRecord/RoundStartRecord rows from real use (user's iPhone 15 Pro) | Code only: optional fields. Verify by migration test AND by installing over the existing on-device build via `scripts/install-on-device.sh` (do not uninstall first) |
| Live service config | None - no backend | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None (new files auto-included by synchronized groups) | None |

## Common Pitfalls

### Pitfall 1: Migration silently fails and the app crashes/wipes on launch
**What goes wrong:** `ModelContainer(for:)` throws on an incompatible schema change; `try?`/`try!` at app start loses or crashes on the store.
**Why:** Non-additive changes (rename, type change, non-optional w/o default).
**Avoid:** Only add optionals; leave existing fields untouched. Check how WordPuzzleApp builds the container (error handling on failure) and do not add a fallback that deletes the store.
**Detect:** Migration test + on-device install over existing data (history count unchanged).

### Pitfall 2: Sheet from inside fullScreenCover
**What goes wrong:** MissedWordsView lives inside `GameView`'s `.fullScreenCover`. A `.sheet` modifier on GameView's root cannot present while the cover is up (SwiftUI/UIKit: a presenter that already presents a modal cannot present another; the sheet is dropped with a console warning).
**Avoid:** Attach `.sheet(isPresented:)` to the content INSIDE the cover (the `else` branch wrapping MissedWordsView, or on MissedWordsView's call site inside the closure), with its own `@State`/binding owned by GameView (`isShowingStatsFromRoundOver`) or a single `isShowingStats` bound in both places only if only one is attached at a time. Simplest: one `@State isShowingStats` in GameView, a `.sheet` attached on the root (for top bar, shown when no cover) and a second `.sheet` on the cover content using a SEPARATE state `isShowingRoundOverStats` so the two never fight. Dismiss returns to round-over, per UI-SPEC. Also: `.onChange(of: roundPhase)` already resets found-words sheet; add `isShowingStats = false` there when leaving `.playing`? Careful: do NOT reset the round-over stats sheet when phase changes to `.roundOver` (that is the intended context). Reset round-over stats state when "Next Puzzle" continues.
**Verify:** UI test or manual on device/simulator (Simulator-only quirks noted in STATE: gear icon did not render in iPhone 17 simulator; confirm entry icons on physical device).

### Pitfall 3: Parameter order breaking existing call sites
`record(score:wordsFoundCount:date:)` is called ~30 times in tests. New params must follow `date`. See Pattern 2.

### Pitfall 4: Stale snapshot
Snapshot built once at GameView init would show stale numbers. Build on each presentation (and for MissedWordsView, at render time of roundOver, after `finishRound`, which is already ordered correctly: record then flip phase). The paywall branch of the cover is untouched.

### Pitfall 5: Longest streak vs current streak inconsistency
currentStreak is windowed to 400 days; longestStreak over full history. Clamp with `max`. Also multiple sessions in one day collapse to one day; sessions at 23:59/00:01 are separate days (local calendar).

### Pitfall 6: Pangram/sweep semantic mismatch
`hadSweep` = `sweepBonus > 0` at finishRound (Phase 8). `foundPangramCount` is the count found in that round. Both only recorded for FINISHED rounds (D-13). Rank stored is `viewModel.rank` at finish, computed from score including bonuses, so Mythic Grandmaster is reachable (score > maxScore).

### Pitfall 7: "Words found" ambiguity and VoiceOver
Two tiles with the same caption: prefix section ("Today, Words found, 12"). Hero must be a single combined element; flame `accessibilityHidden`.

### Pitfall 8: AX5 layout
Per STATE: Simulator is wider than iPhone 15 Pro; AX5 must be checked on the physical device. 1-column at `dynamicTypeSize.isAccessibilitySize`.

### Pitfall 9: Swift Testing + MainActor
View statics tests use `@MainActor @Suite struct`. Suites that load the word list need `@Suite(.serialized)` (not needed for pure store tests).

## Code Examples

### Longest streak
```swift
func longestStreak() -> Int {
    let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
    let days = Set(records.map { calendar.startOfDay(for: $0.date) }).sorted()
    var best = 0, run = 0
    var previous: Date?
    for day in days {
        if let p = previous, calendar.date(byAdding: .day, value: 1, to: p) == day { run += 1 } else { run = 1 }
        best = max(best, run); previous = day
    }
    return best
}
```

### finishRound
```swift
persistenceStore?.record(score: score, wordsFoundCount: foundWords.count,
                         rank: rank, pangramsFound: foundPangramCount, hadSweep: sweepBonus > 0)
```
Existing GameViewModelTests that inspect records still compile (defaults).

### Migration test technique (MEDIUM confidence; verify it compiles and fails without optionals)
In the test target define a legacy schema whose entity name matches the production model:
```swift
enum LegacySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [GameRecord.self, RoundStartRecord.self] }
    @Model final class GameRecord { var date: Date; var score: Int; var wordsFoundCount: Int
        init(date: Date, score: Int, wordsFoundCount: Int) { ... } }
    @Model final class RoundStartRecord { var date: Date; init(date: Date) { self.date = date } }
}
```
Steps: (1) temp URL via `FileManager.default.temporaryDirectory`; (2) `ModelContainer(for: Schema(versionedSchema: LegacySchemaV1.self), configurations: ModelConfiguration(url: url))`, insert 3 legacy GameRecords + 1 RoundStartRecord, `save()`, release container; (3) `PersistenceStore.makeContainer(url: url)` must not throw; assert `totalGamesPlayed() == 3`, `bestScore()`, `totalWordsFound()` unchanged, `bestRank() == nil`, `totalPangramsFound() == 0`, `totalSweeps() == 0`; (4) record a new round with new fields and assert it aggregates. Check RoundStartRecord's real field list before writing the legacy copy (read `Services/RoundStartRecord.swift`). Fallback if same-named nested models collide at runtime: write the legacy store with a raw `sqlite3` fixture generated once and committed as a test resource, or rely on the on-device install-over verification as the authoritative check. Entity names are derived from the class name, which is why nested same-named classes in a VersionedSchema namespace work.

### NavigationLink row in Settings
```swift
NavigationLink {
    StatsView(stats: stats, showsDoneButton: false, onDone: {})
} label: {
    HStack { Text(Self.statsRowLabel).font(GameTheme.bodyFont); Spacer()
             Image(systemName: "chevron.right").font(GameTheme.labelFont).foregroundStyle(.secondary) }
    .frame(minHeight: GameTheme.minTapTarget)
}
.buttonStyle(.plain).padding(GameTheme.md)
```
Add `Self.statsRowLabel = "Stats"` and update the doc comment (D-03). Note both sheets (Stats and Settings) have their own `NavigationStack`; the pushed StatsView must not add a nested NavigationStack, so StatsView itself is stack-less and the top-bar sheet wraps it in `NavigationStack` + Done toolbar (only when `showsDoneButton`).

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| ObservableObject | @Observable (iOS 17) | Already project standard |
| `contentTransition(.numericText())` | `.numericText(value:)` iOS 17 | Use value overload for count-up direction |

## Open Questions

1. **Old-schema migration test compiles with same-named nested @Model classes?**
   - Known: VersionedSchema namespacing is the documented pattern; entity name = class name.
   - Unclear: runtime collision with the production `GameRecord` in the same test module (`@testable import`).
   - Recommendation: spike this first (Wave 0/Task 1); fallback is committed sqlite fixture + on-device install-over.
2. **Stats sheet over fullScreenCover** needs hands-on device/simulator confirmation (Pitfall 2).
3. **Count-up granularity:** `numericText` rolls digits, not every integer. Accept (recommended).
4. **`lerp`/glow helper** privacy in ScoreBarView: check and extract if private.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | build + tests | yes | Xcode 26.x (project uses iOS 26.5 sim) | none |
| iPhone 17 / iPhone 17 Pro simulators | tests | yes (both Shutdown/available) | iOS 26.x | use idle `iPhone 17 Pro` when other agents run parallel (Phase 5 deviation: name collisions cause bootstrap crashes) |
| Physical iPhone 15 Pro + `scripts/install-on-device.sh` | on-device migration + AX5 check | assumed (used in Phase 5) | - | manual QA checkpoint (user preference: automate checkpoints, Wi-Fi install script) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Test`, `#expect`) plus XCUITest target for UI (`WordPuzzleUITests`) |
| Config file | `WordPuzzle/WordPuzzle.xcodeproj` scheme `WordPuzzle` (shared); no separate config |
| Quick run command | `cd /Users/patrickhoughton/Documents/GitHub/word-puzzle-ios/WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/PersistenceStatsTests` |
| Full suite command | `cd /Users/patrickhoughton/Documents/GitHub/word-puzzle-ios/WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests` |

(Project history: `platform=iOS Simulator,name=iPhone 17` is the default destination; `iPhone 17 Pro` used when contention. Swift Testing suites are selected with `-only-testing:WordPuzzleTests/<SuiteStruct>`. Exclude UI tests from the full unit run via `-only-testing:WordPuzzleTests` since `AppStoreScreenshotTests` is a screenshot harness.) Last known baseline: 68 tests / 12 suites in Phase 5; more since. Confirm exact count when starting.

### Phase Requirements -> Test Map
| Req | Behavior | Type | Automated Command | File Exists? |
|-----|----------|------|-------------------|-------------|
| P9-A | record() with new fields persists; defaults nil keeps old call sites | unit | `-only-testing:WordPuzzleTests/PersistenceStatsTests` | Wave 0 |
| P9-A | Old-schema store opens under new schema, data intact | unit (temp URL) | `-only-testing:WordPuzzleTests/StatsMigrationTests` | Wave 0 |
| P9-A | finishRound writes rank/pangrams/sweep | unit | `-only-testing:WordPuzzleTests/GameViewModelTests` (extend; `@Suite(.serialized)`, loads word list) | extend existing |
| P9-B | longestStreak: gaps, same-day dupes, DST day, >= current, empty | unit | PersistenceStatsTests | Wave 0 |
| P9-B | averages whole/rounded, nil at 0 games; bestRank max & ignores nil; mythic; pangram/sweep totals ignoring nil | unit | PersistenceStatsTests | Wave 0 |
| P9-B | at-risk helper (alive via yesterday vs played today vs 0) | unit | PersistenceStatsTests | Wave 0 |
| P9-C | copy constants frozen; headline/hint/empty-state/value-string/VoiceOver label functions; "—" for nil | unit | `-only-testing:WordPuzzleTests/StatsViewTests` | Wave 0 |
| P9-D | SettingsView.statsRowLabel, stats accessibility label, MissedWordsView summary string `Best 142 · Streak 4` | unit | StatsViewTests / SettingsViewTests (extend) | extend |
| P9-D | Sheet presents over round-over cover; icon visible | manual (device) / optional XCUITest | physical device | manual |
| P9-E | Count-up honors Reduce Motion; glow steady | manual (visual) | simulator toggle Reduce Motion | manual |
| P9-E | AX5 layout (1 column, shrink-to-fit) | manual on iPhone 15 Pro (simulator width misleading per STATE) | - | manual |
| P9-A | Existing-install upgrade keeps history | manual on device: install over existing build via `scripts/install-on-device.sh`, compare games played before/after | - | manual |

### Sampling Rate
- Per task commit: quick run on the touched suite
- Per wave merge: full `WordPuzzleTests` run
- Phase gate: full suite green plus `scripts/compliance-guards.sh` (if part of the project's gate; check) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `WordPuzzleTests/PersistenceStatsTests.swift` (new store methods)
- [ ] `WordPuzzleTests/StatsMigrationTests.swift` (legacy-schema fixture; spike technique first)
- [ ] `WordPuzzleTests/StatsViewTests.swift` (copy + pure presentation functions)
- [ ] Extend `GameViewModelTests` (finishRound writes fields), `SettingsViewTests`
- Framework install: none

## Project Constraints (from CLAUDE.md)
- SwiftUI iOS 17+, MVVM with `@Observable`; no third-party packages; no network calls.
- Persistence: SwiftData for history/stats (`PersistenceStore`), @AppStorage for flags; Core Data forbidden.
- Word list/validation unaffected.
- Use `ScrollView`+`LazyVStack` rather than `List` for word-game UI (applies in spirit; stats uses ScrollView/VStack/LazyVGrid, no List).
- All file-changing work must go through a GSD command (execute-phase).
- User memory: automate checkpoints; device testing via Wi-Fi install script.
- Never use emojis in output; hero flame is an SF Symbol, not an emoji.

## Sources

### Primary (HIGH confidence, codebase read this session)
- `Services/PersistenceStore.swift`, `GameRecord.swift`, `Game/RankTier.swift`, `GameViewModel.swift` (finishRound ~L241), `GameView.swift`, `MissedWordsView.swift`, `SettingsView.swift`, `GameTheme.swift`, `ScoreBarView.swift`, tests (`PersistenceStoreTests`, `SettingsViewTests`, `DynamicTypeTests`), `.planning/STATE.md`, `.planning/config.json`, project.pbxproj (objectVersion 77)

### Secondary (MEDIUM, training knowledge not re-verified online this session)
- SwiftData automatic lightweight migration for additive optional properties; VersionedSchema namespacing and entity naming; "presenter already presenting" sheet limitation; `numericText(value:)` iOS 17 availability. Recommend a quick compile spike for the migration test and sheet-over-cover behavior.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new deps, all in-repo
- Architecture: HIGH for store/view patterns; MEDIUM for migration-test technique and sheet-in-cover specifics
- Pitfalls: HIGH (derived from actual code), sheet-in-cover MEDIUM

**Research date:** 2026-10-04
**Valid until:** 2026-11-04

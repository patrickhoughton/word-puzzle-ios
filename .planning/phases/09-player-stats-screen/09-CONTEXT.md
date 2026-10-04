# Phase 9: Player Stats Screen - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Surface the player's stats in a screen they can actually see. The screen shows `PersistenceStore`'s existing lifetime stats (`totalGamesPlayed`, `bestScore`, `totalWordsFound`, `currentStreak`, `puzzlesPlayedToday`) and today's totals (`todayTotalScore`, `todayTotalWordsFound`). It also adds three derived stats (average score, average words per game, longest streak) and three newly tracked stats (best rank reached, lifetime pangrams, pangram sweeps). The new tracked stats need new optional fields on `GameRecord`.

The screen opens from a new top-bar icon and from a Stats row in Settings. A compact best/streak summary goes on the end-of-round screen.

Out of scope: charts and history graphs, per-day history lists, sharing stats, achievements, resetting stats, and any change to the paywall.

</domain>

<decisions>
## Implementation Decisions

### Entry Points & Presentation
- **D-01:** There are **two entry points to the same stats screen**:
  - **Top-bar icon:** a new stats icon (e.g. SF Symbol `chart.bar` or similar) on the LEFT side of `GameView`'s top bar, mirroring the gear on the right. Same styling as the gear: `GameTheme.headingFont`, `.secondary`, and a `minTapTarget` frame. It needs a VoiceOver label (e.g. "Stats"). The DEBUG ladybug menu also sits on the left in DEBUG builds, so the planner places them so they don't collide.
  - **Settings row:** a "Stats" row in `SettingsView`, below the sound toggle, implemented as a `NavigationLink` that **pushes** the stats screen inside Settings' existing `NavigationStack` (standard iOS settings pattern, with a back button).
- **D-02:** From the top bar, stats is presented as a **`.sheet` with a "Done" button and swipe-to-dismiss**, the same pattern as `SettingsView` and Found Words. No detents (full sheet).
- **D-03:** This deliberately reverses Phase 5 D-03, which kept Settings to a single control and deferred stats. Update the `SettingsView` doc comment accordingly.
- **D-04:** **End-of-round mini-summary:** `MissedWordsView` gets one compact, inline line showing **best score + current streak** (e.g. "Best 142 · Streak 4"). The line is **tappable** and opens the full stats sheet, the same way the score bar opens Found Words. This reverses Phase 7 D-17 ("MissedWordsView left alone") for this one addition only; don't redesign the screen. The values are read AFTER `finishRound()` has recorded the round, so they include this round. That ordering already holds: Phase 3-01 records before flipping to `.roundOver`.
- **D-05:** **The paywall is unchanged.** It keeps its own "Today's Stats" block and gets no link to the stats screen.

### Stats Shown
- **D-06:** **Today:** puzzles today (`puzzlesPlayedToday`, which counts STARTED rounds, the free-tier counter), today's score (`todayTotalScore`), today's words (`todayTotalWordsFound`). All already exist.
- **D-07:** **Streak:** current streak (`currentStreak`, including grace-day semantics) and the **longest streak ever** (new, derived from `GameRecord` dates; must apply the same local-calendar-day logic as `currentStreak`).
- **D-08:** **Lifetime, existing:** games played (`totalGamesPlayed`, FINISHED rounds), best score (`bestScore`), total words found (`totalWordsFound`).
- **D-09:** **Lifetime, derived (no schema change):** **average score** (total score ÷ games played) and **average words per game** (total words ÷ games played).
- **D-10:** **Lifetime, newly tracked (schema change):** **best rank reached**, **lifetime pangrams found**, and **pangram sweeps** (count of rounds with a sweep).

### New Tracked Data (GameRecord schema change)
- **D-11:** Add **optional** fields to `GameRecord` (e.g. `rank` raw value, `pangramsFound`, `hadSweep`), written by `finishRound()` from the view model's existing `rank`, `foundPangramCount`, and `sweepBonus > 0`. They must be optional or defaulted so SwiftData lightweight migration handles existing on-disk stores. **Existing installs must launch without data loss.** The planner must include a migration test (an old-schema store opening under the new schema) and on-device verification against a store that has real history.
- **D-12:** **Old rounds count from now on.** Pre-update rounds have nil for the new fields and simply contribute nothing to pangram/sweep totals or best rank. No backfill and no "since update" footnote.
- **D-13:** **Lifetime pangrams count finished rounds only**, consistent with every other lifetime stat being written once at Finish Round. Abandoned rounds contribute nothing.
- **D-14:** Best rank is the highest `RankTier` across records with a stored rank. Hidden-tier note: Mythic Grandmaster only appears here if the player has actually reached it, consistent with Phase 8 D-06's "hidden" intent.
- **D-15:** `PersistenceStore`'s frozen API from Phase 2 stays source-compatible. Add new methods alongside (e.g. `longestStreak()`, `averageScore()`, `bestRank()`, `totalPangramsFound()`, `totalSweeps()`), and extend `record(...)` with defaulted parameters so existing call sites and tests still compile.

### Layout & Style
- **D-16:** **Hero + tile grid layout** (the user picked this preview):
  - A **hero streak card** at the top: flame + "N day streak", with "Longest: M" beneath.
  - A **TODAY** section header, then a 2-column grid of big-number tiles (number large, caption small).
  - A **LIFETIME** section header, then a 2-column tile grid for best score, games played, average score, words found, avg words/game, pangrams found, and pangram sweeps.
  - **Best rank** is shown prominently in the lifetime area (e.g. a full-width row/tile, "Best rank: Legend").
- **D-17:** **Best rank uses accent styling**: the tier name in `GameTheme.accent` gold. **Mythic Grandmaster** gets the same glow treatment it has on the score bar (Phase 8).
- **D-18:** **Count-up animation**: the numbers tick up from 0 when the screen opens (e.g. `contentTransition(.numericText())` with an animated value). This **must respect Reduce Motion**: with it on, numbers appear static. Keep it short so it doesn't feel like waiting.
- **D-19:** Phase 5 Dynamic Type rules apply. Tiles must survive AX5 on a physical device (shrink-to-fit numbers; the grid may collapse to 1 column at accessibility sizes, planner's call). The screen scrolls (`ScrollView`); unlike the game board, there's no gesture conflict here.

### Empty & Edge States
- **D-20:** **A new player (0 finished games)** sees the full layout with zeros. Averages show **"—"** (never divide by zero), and best rank shows "—" or is hidden. Add **one playful nudge line** at the top (e.g. "Finish a round to start your stats!"), in the same tone as Found Words' empty state (Phase 7 D-16).
- **D-21:** **Grace-day streak**: when the streak is alive only via the grace day (played yesterday, not yet today), the hero card adds an **"at risk" hint**, e.g. "4 day streak — play today to keep it!". This needs a way to tell "played today" apart from "alive via yesterday" (e.g. a new `PersistenceStore` helper or a check of today's finished rounds).
- **D-22:** **Zero streak**: the hero card shows **encouraging copy**, e.g. "Start a streak today!", with the flame dimmed. "Longest: M" is still shown if M > 0.
- **D-23:** **Averages are whole numbers**, rounded to the nearest whole number.

### Claude's Discretion
- The exact SF Symbol for the top-bar stats icon, and how it coexists with the DEBUG ladybug.
- Tile ordering within the Today and Lifetime grids, tile styling (use `GameTheme.secondarySurface` rounded tiles, consistent with existing rows), and the exact hero-card styling.
- Exact copy for captions, the nudge line, the at-risk hint, and zero-streak text (playful tone, short). Pin user-facing strings as `static let` constants for tests, following the `SettingsView`/`PaywallView` pattern.
- Field names and types for the new `GameRecord` properties, and whether rank is stored as `RankTier.rawValue` (Int).
- Longest-streak algorithm (full history vs. a bounded window; full history is fine at this data scale, but stay consistent with the `currentStreak` day logic).
- Count-up duration and easing.
- VoiceOver: each tile reads as one element, "<caption>, <value>"; the hero card reads as a single sentence.
- Whether the stats view is a new file `Game/Views/StatsView.swift` or `Stats/StatsView.swift` (mirroring `Settings/`), taking a value snapshot struct (e.g. `PlayerStats`) built by `GameView` from `PersistenceStore`. It must stay value-in/closure-out: only `GameView` touches the stores and the view model.
- Whether the summary line in `MissedWordsView` is a new value parameter (e.g. `bestScore`, `currentStreak`, `onShowStats`) with defaults so existing tests and previews still compile.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Stats data source
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift`: all existing stat queries, `todayBounds`, and `currentStreak` (with grace-day logic) to extend
- `WordPuzzle/WordPuzzle/Services/GameRecord.swift`: the `@Model` getting new optional fields
- `WordPuzzle/WordPuzzle/Services/RoundStartRecord.swift`: started-round model (backs `puzzlesPlayedToday`)
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` (`finishRound()` ~line 241, `rank`, `foundPangramCount`, `sweepBonus`): the write site for new fields
- `WordPuzzle/WordPuzzle/Game/RankTier.swift`: tier enum including hidden `mythicGrandmaster`
- `.planning/phases/02-persistence-entitlements/02-CONTEXT.md`: original schema decisions (D-01) and service wiring (D-07)

### UI patterns to match
- `WordPuzzle/WordPuzzle/Settings/SettingsView.swift`: sheet + NavigationStack + Done pattern; gets the Stats row
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` (top bar ~line 256, sheets ~line 100): entry-point integration and store reads
- `WordPuzzle/WordPuzzle/Game/Views/PaywallView.swift` (`statRow`, Today's Stats): existing stats presentation (unchanged this phase)
- `WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift`: gets the tappable best/streak summary line
- `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift`: Mythic Grandmaster glow treatment to reuse for best rank
- `WordPuzzle/WordPuzzle/Game/GameTheme.swift`: all spacing/typography/color tokens (no inline magic numbers)
- `.planning/phases/05-polish-compliance-app-store/05-CONTEXT.md`: D-03 (now reversed), D-04/D-05 Dynamic Type rules
- `.planning/phases/07-found-words-view/07-CONTEXT.md`: sheet/Done pattern, empty-state nudge tone, D-17 (now partially reversed)
- `.planning/phases/08-all-pangrams-bonus/08-CONTEXT.md`: D-06 hidden Mythic Grandmaster tier, sweep semantics

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PersistenceStore`: `totalGamesPlayed()`, `bestScore()`, `totalWordsFound()`, `currentStreak(now:)`, `puzzlesPlayedToday(now:)`, `todayTotalScore(now:)`, `todayTotalWordsFound(now:)` are all ready to read.
- `PaywallView.statRow`: an existing caption/value row, a reference for captions.
- `ScoreBarView`'s Mythic Grandmaster glow can be reused for the best-rank display.
- `SettingsView`'s `static let` copy constants plus `SettingsViewTests` are the pattern for pinned, testable strings.

### Established Patterns
- `@Observable` stores injected via `.environment()`; only `GameView` reads them, and child views are value-in/closure-out.
- Sum/average must be computed in Swift (SwiftData has no SUM pushdown, per RESEARCH Pitfall 3 in PersistenceStore).
- Streaks are derived at read time from `GameRecord.date` and never stored as a counter. Longest streak must follow the same rule.
- Test suites that load the word list use `@Suite(.serialized)`. `PersistenceStoreTests` uses in-memory or temp-URL containers via `makeContainer(inMemory:url:)`, so migration tests can use a temp URL.
- Copy is pinned as `static let` constants for tests.

### Integration Points
- `GameView` top bar: add the stats icon (left side) and an `isShowingStats` sheet.
- `SettingsView`: add a `NavigationLink` row. It needs the stats snapshot passed in (value-in), since Settings has no store access.
- `GameViewModel.finishRound()`: pass rank, pangram count, and sweep flag to `record(...)`.
- `MissedWordsView`: new summary line plus an `onShowStats` closure. Handle presenting a sheet from within the `fullScreenCover` (stats sheet on top of the round-over cover).

</code_context>

<specifics>
## Specific Ideas

- The user picked the "Hero + tile grid" preview: a streak hero card ("🔥 4 day streak / Longest: 12"), then TODAY and LIFETIME headers over 2-column big-number tiles, then a "Best rank: Legend" line.
- End-of-round summary example: "Best 142 · Streak 4", tappable.
- At-risk example: "4 day streak — play today to keep it!"
- Zero-streak example: "Start a streak today!" with a dimmed flame.
- Empty-state nudge example: "Finish a round to start your stats!"

</specifics>

<deferred>
## Deferred Ideas

- A "New best!" callout on the end-of-round screen when a round beats the previous best score. It was offered but not chosen; this could be a future polish item.
- Charts/history graphs, per-day history, sharing stats, and a reset-stats control were not discussed and are out of scope.

</deferred>

---

*Phase: 09-player-stats-screen*
*Context gathered: 2026-10-04*

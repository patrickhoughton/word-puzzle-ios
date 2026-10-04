# Phase 8: All-Pangrams Bonus (Completion Bonuses) - Research

**Researched:** 2026-10-04
**Domain:** SwiftUI / iOS 17+ game-state, scoring, animation sequencing (no new libraries)
**Confidence:** HIGH (code read directly; frequency numbers measured empirically; Kenney clip names MEDIUM)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Bonus = **+7 per pangram in the puzzle** (`7 x puzzle.pangrams.count`), awarded once when the last pangram is found.
- **D-02:** Applies to every puzzle, including 1-pangram puzzles (finding the only pangram triggers the sweep: +7 pangram, +7 sweep, plus length points).
- **D-03:** Bonus is added to `score`, persisted via `finishRound()` -> `PersistenceStore.record(score:)`. NOT included in `maxPossibleScore` (stays `ScoreCalculator.score(for: validWords, pangrams:)`).
- **D-04:** Bonus counts toward rank. Reaching Legend without all words is accepted.
- **D-05:** Progress can exceed 100%. `progressFraction` must stop clamping to 1 for rank/overflow purposes. `ProgressView` may stay clamped; overflow is a separate glowing/shimmer visual.
- **D-06:** New hidden 11th tier above Legend: **"Mythic Grandmaster"** (exact name). Unlocks at any score STRICTLY > 100% of max. `tier(score:maxScore:)` must treat it as `score > maxScore`, not `>=`. Hidden (never shown as next step). Must use shrink-to-fit (`lineLimit(1)` + `minimumScaleFactor`) and be checked at AX5 on a physical device.
- **D-07:** Bonus lands instantly mid-round on the game screen the moment the last pangram is accepted.
- **D-08:** Animation: pangram-by-pangram tally (+7, +14, +21...) then total folds into score. Must speed up for big sets; pick a max total duration.
- **D-09:** Copy: **"Pangram sweep! +N"**.
- **D-10:** New distinct fanfare clip from CC0 Kenney packs (new `SoundEffect` case). Tick per pangram during tally; strong success haptic at the end. Respects `soundEffectsEnabled` and `.ambient` session.
- **D-11:** Pangram count shown in BOTH: board badge near the score bar (e.g. seal icon + "1/3") and a "Pangrams · X of N" line in the Found Words sheet (reverses Phase 7 D-15).
- **D-12:** Count is a deliberate hint, consistent with Phase 7 D-10.
- **D-13:** No cap, no generator change. `PuzzleGenerator` untouched this phase.
- **D-14:** Length-completion bonus: finding every word of a given length awards a bonus equal to that length, once per length per round. "All words of length L" is defined over `puzzle.validWords` (same groups as Phase 7 Found Words sheet).
- **D-15:** Same scoring rules as sweep: added to `score`, persisted, counts toward rank, excluded from `maxPossibleScore`, can push past 100%.
- **D-16:** Lighter celebration: short popup "5 Letters complete! +5", success sound + haptic, NO tally.
- **D-17:** Stacking: if one word completes a length group AND the pangram set, award both, celebrated in sequence: length popup first, then sweep tally.
- **D-18:** Unit-testable pure function e.g. `ScoreCalculator.lengthCompletionBonus(length:) -> Int` (returns `length`). View-model tracks completed lengths so bonus never double-awards.

### Claude's Discretion
- Exact fanfare clip, tick sound, haptic type, tally per-step timing and speed-up curve.
- Overflow glow/shimmer styling; how Mythic Grandmaster looks distinct from Legend.
- Board pangram counter placement/icon/format, post-sweep state, VoiceOver label.
- How the sweep shows on `MissedWordsView` header (keep minimal).
- Whether sweep is a new `SubmissionOutcome` field/case or separate view-model state. Views must stay value-in/closure-out (only `GameView` touches `GameViewModel`).
- Sound for length-completion popup; whether Found Words sheet shows earned bonus beside the checkmark.
- Whether input is blocked during tally (prefer not).
- `ScoreCalculator` pure function for sweep bonus (e.g. `sweepBonus(pangramCount:)`).

### Deferred Ideas (OUT OF SCOPE)
- Capping pangram count in the generator, or removing the sampling bias toward many-pangram letter sets (declined, D-13).
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs are mapped (TBD). Must-haves are derived from CONTEXT D-01..D-18 and 08-UI-SPEC.md. Suggested synthetic IDs for the planner/validation map:

| ID | Description | Research Support |
|----|-------------|------------------|
| BON-01 | Sweep bonus formula `7 x pangrams.count`, once, incl. 1-pangram (D-01/02) | `ScoreCalculator.sweepBonus(pangramCount:)`; detection in `submitCurrentWord()` |
| BON-02 | Bonus in `score`, persisted, not in `maxPossibleScore` (D-03/04/15) | `score +=` in VM; `maxPossibleScore` untouched |
| BON-03 | Unclamped progress + overflow cue (D-05) | `progressFraction` drop `min(1,)`; `ScoreBarView` clamps `ProgressView` itself |
| BON-04 | Mythic Grandmaster tier, strict `>` (D-06) | `RankTier` special-case in `tier(score:maxScore:)` |
| BON-05 | Sweep tally celebration + sound/haptic (D-07..D-10) | Celebration queue in GameView; new `SoundEffect` cases |
| BON-06 | Pangram counter on board + Found Words (D-11/12) | New value-in params on `ScoreBarView`, `FoundWordsView` |
| BON-07 | Length-completion bonus + pill, once per length (D-14..D-18) | `ScoreCalculator.lengthCompletionBonus`; VM `completedLengths` |
| BON-08 | Stacking order + MissedWordsView lines (D-17, UI-SPEC 7) | Ordered celebration queue; `sweepBonus`/`lengthBonusTotal` params |
</phase_requirements>

## Summary

This phase is pure in-repo SwiftUI/Swift work: no new dependencies. All integration points exist and were read: `ScoreCalculator` (pure enum), `RankTier` (10-case enum looped via `allCases`), `GameViewModel` (`@MainActor @Observable`, counter-based feedback triggers), `ScoreBarView`/`FoundWordsView`/`MissedWordsView` (value-in presentation views), `SoundManager`/`SoundEffect` (enum with `allCases`, wav files in `Sounds/`). The hardest design work is (a) a sequential celebration queue that never overlaps and tolerates round end, and (b) keeping `RankTier` correct with a strict-`>` hidden tier.

Empirical frequency (3,000 puzzles simulated with the real generator logic against `enable-clean.txt`, plus CONTEXT's 20,000-puzzle run): the bonuses are small relative to max score. Median max score is ~938; the sweep bonus is a median 3.1% of max (p90 6.6%); ALL possible bonuses (sweep + every length group) combined are a median 9.6% of max (p90 20.5%, worst case 61%). Consequence: **Mythic Grandmaster realistically requires finding roughly 80-95% of base points plus every completion bonus**, so it is a genuinely rare tier (good for a hidden prestige tier), and Legend-via-bonus (D-04) means a player needs ~90% of base score plus bonuses, not "100% without effort".

**Primary recommendation:** Add pure functions to `ScoreCalculator`, model bonuses in the view-model as a small ordered `[CompletionEvent]` queue plus counters (`sweepCount`, `lengthBonusCount`) for `.sensoryFeedback`, apply score immediately at submission (final score identical regardless of animation timing), and have `GameView` drain the event queue sequentially in a single `Task` that is cancelled on round end / new round.

## Empirical Frequency Measurements (requested)

Method: Python replica of `generatePuzzle` (random pangram word from words with 7 unique letters -> its letter set -> random center order, first center with >= 20 valid words; pangram = valid word whose letter set == 7 letters). 3,000 puzzles, seed 1, `WordPuzzle/WordPuzzle/enable-clean.txt` (171,615 words >= 4 letters; 37,855 pangram-words). Script was in the session scratchpad (not committed). Results agree with CONTEXT's 20,000-puzzle run (1 pangram: 22.6% there vs 23.7% here).

| Metric | Value |
|--------|-------|
| Valid words per puzzle, median | ~175 |
| Max score, median | ~938 |
| Puzzles with exactly 1 pangram | 23.7% |
| Puzzles with <= 3 pangrams | 51.1% |
| Median pangram count | 3 |
| Puzzles with >= 10 pangrams | 20.1% |
| Puzzles with >= 20 pangrams | 7.0% |
| Sweep bonus as % of max score: median / p90 | 3.1% / 6.6% |
| Sum of ALL length bonuses as % of max: median | 6.1% |
| Sweep + all length bonuses as % of max: p10 / median / p90 / worst | 5.2% / 9.6% / 20.5% / 60.7% |
| Length groups per puzzle: median / min | 8 / 4 (lengths 4..~11+) |
| Group size distribution (all groups) | size 1: 10.6%, 2-3: 10.9%, 4-10: 17.3%, 11-30: 26.1%, 31+: 35.1% |
| Puzzles with at least one single-word length group | 59.9% |
| Puzzles with a length group of size <= 3 | 88.6% |
| Puzzles with a length group of size <= 5 | 96.1% |
| 4-letter group size, median | 37 |
| Longest length in puzzle, median | 11 |
| Same-word stack in the simplest case (1 pangram AND it is the only word of its length) | 4.3% of puzzles (more stacks occur when all pangrams share a length; not separately measured) |

Planning implications:
1. The length bonus WILL fire in nearly every round (96% of puzzles have a group of <= 5 words) but mostly on the long, rare lengths; the short, large groups (4-7 letters, 30+ words) are the "hard" completions. Reward magnitude (+L) is tiny vs ~940 max; it is a feel/celebration feature, not a score driver. Do not tune rank math around it.
2. A single-word group (60% of puzzles) means one long word triggers both its normal points and a "N Letters complete" pill. Tests and UI must handle pill + normal feedback on the same submission (UI-SPEC 5: completion sound REPLACES word_accepted; sweep fanfare REPLACES pangram_found).
3. Stacking (D-17) is uncommon but real (>= 4.3%); it must be unit-tested explicitly.
4. 7% of puzzles have >= 20 pangrams; the tally speed-up (cap 1.2s total, UI-SPEC) is genuinely needed. The generator's bias toward many-pangram sets is real (median 3 vs. uniform-over-letter-sets), accepted in D-13.

## Standard Stack

No new packages. Everything is first-party.

| Component | Version | Purpose | Notes |
|-----------|---------|---------|-------|
| SwiftUI | iOS 17+ target | UI, animation, `.sensoryFeedback` | Already in use; CLAUDE.md: no game engine |
| Observation (`@Observable`) | iOS 17 | VM state | Existing pattern |
| Swift Testing (`import Testing`, `@Test`, `@Suite`) | Xcode bundled | Unit tests | Existing suites use it, not XCTest |
| AVFoundation (`AVAudioPlayer`) | system | SFX | Existing `SoundManager`, `.ambient` category |
| Kenney "Interface Sounds" (CC0) | n/a | New fanfare/tick/lighter-success wavs | Same pack as existing; record in `Sounds/LICENSE.txt` |

Alternatives considered and rejected: TimelineView/Canvas particle systems (overkill for a tally); third-party confetti libs (CLAUDE.md: no extra dependencies); `Task.sleep`-chained animation vs `phaseAnimator`/`keyframeAnimator` (see Pattern 3).

**Installation:** none. New asset files go in `WordPuzzle/WordPuzzle/Sounds/` (project uses `PBXFileSystemSynchronizedRootGroup`, objectVersion 77, so files dropped into the folder are picked up automatically; verify they land in the app target's Copy Bundle Resources, since `Bundle.main.url(forResource:)` is how `SoundManager` loads them and a missing bundle entry fails silently via `continue`).

## Architecture Patterns

### Files touched
```
Services/ScoreCalculator.swift   + sweepBonus(pangramCount:), lengthCompletionBonus(length:)
Game/RankTier.swift              + .mythicGrandmaster, strict-> rule in tier(score:maxScore:)
Game/GameViewModel.swift         + completion state/queue/counters, unclamped progress, bonus-aware score
Services/SoundManager.swift      + SoundEffect cases (pangram_sweep, sweep_tick, optional length_complete)
Sounds/*.wav + LICENSE.txt       + new CC0 clips + attribution lines
Game/GameTheme.swift             + celebration timing tokens (no inline magic numbers)
Game/Views/ScoreBarView.swift    + foundPangrams/totalPangrams params, detail row, overflow shimmer, mythic styling
Game/Views/FoundWordsView.swift  + "Pangrams · X of N" line, "+L" on complete groups
Game/Views/MissedWordsView.swift + sweepBonus / lengthBonusTotal params
Game/Views/GameView.swift        + celebration overlay host, event-queue drain task, sound/haptic hooks
Game/Views/CompletionCelebrationViews (new) value-in SweepTallyCard, LengthCompletePill
```

### Pattern 1: Pure bonus functions (D-01, D-18)
```swift
// ScoreCalculator
static let pangramBonusPerWord = 7          // single source; points(for:) currently inlines 7
static func sweepBonus(pangramCount: Int) -> Int { max(0, pangramCount) * pangramBonusPerWord }
static func lengthCompletionBonus(length: Int) -> Int { length >= 4 ? length : 0 }
```
Replace the inline `7` in `points(for:isPangram:)` with the constant so the sweep and per-word bonus can never drift (D-01 says sweep == +7 per pangram).

### Pattern 2: Detection in `submitCurrentWord()` (after the existing insert)
Order matters. After `foundWordSet.insert(word)`:
```swift
// existing: points, score += points, lastOutcome, acceptedSubmissionCount += 1
var events: [CompletionEvent] = []
let length = word.count
if !completedLengths.contains(length), lengthTotals[length] == foundCountByLength(length) {   // all of length found
    completedLengths.insert(length)
    let b = ScoreCalculator.lengthCompletionBonus(length: length)
    score += b; lengthBonusTotal += b
    events.append(.lengthComplete(length: length, bonus: b))
}
if isPangram, !sweepAwarded, pangramSet.isSubset(of: foundWordSet) {
    sweepAwarded = true
    let b = ScoreCalculator.sweepBonus(pangramCount: pangramSet.count)
    score += b; sweepBonus = b
    events.append(.pangramSweep(bonus: b, pangrams: <found order or sorted>))
}
```
Length event is appended BEFORE sweep (D-17). Maintain `lengthTotals: [Int: Int]` (computed once in `startNewRound(with:)` from `validWords`) and `foundCountByLength` incrementally (a small `[Int: Int]` dictionary), so detection is O(1), not a regroup per submission. Do NOT reuse `foundWordGroups` (it regroups all words and sorts each time; fine for the sheet, wasteful per submission).

Guard edge cases: `pangramSet.isEmpty` (test fixture `fixturePuzzle` has `pangrams: []`) must never award a sweep (empty set is a subset of everything: the `isPangram` check already prevents it, keep that guard). `lengthTotals[length]` is always non-nil for an accepted word (it is in validWords) but a test fixture could include words absent from validWords only if dictionary-valid; the generator-mirroring checks make this unreachable for real puzzles, but fixtures like `fixturePuzzle()` list only 5 words while the wordList accepts many more: a submitted word not in `puzzle.validWords` would have `lengthTotals[length] == nil`. Treat nil as "do not award" (`guard let total`). Decide explicitly whether such a word also scores (existing behavior: yes, it scores). Keep as-is.

State to add (all `private(set)`, reset in `startNewRound(with:)`): `completedLengths: Set<Int>`, `sweepAwarded: Bool` (or `sweepBonus: Int`, 0 = none), `lengthBonusTotal: Int`, `sweepCount: Int` / `lengthBonusCount: Int` (monotonic, never reset, for `.sensoryFeedback` triggers per project Pitfall 3), `pendingCelebrations: [CompletionEvent]`.

SubmissionOutcome recommendation: leave `.accepted(word:points:isPangram:)` UNCHANGED (existing tests and `WordDisplayView` pattern-match on it; adding an associated value forces edits across tests and GameView `case let .accepted(_, _, isPangram)`). Model bonuses as separate VM state (`pendingCelebrations`), which satisfies the "views value-in/closure-out" constraint. `points` in the outcome should stay the word's own points (the "+N" floating feedback) and not include bonuses.

### Pattern 3: Celebration queue draining in GameView
- VM exposes `pendingCelebrations` and a `consumeNextCelebration() -> CompletionEvent?` (or `celebrationQueue` + `completeCurrentCelebration()`).
- `GameView` owns `@State private var activeCelebration: CompletionEvent?` and a `Task` (stored `@State private var celebrationTask: Task<Void, Never>?`) started from `.onChange(of: viewModel.acceptedSubmissionCount)`; the task loops: pop next event, set `activeCelebration` with `withAnimation`, `try await Task.sleep(for:)` through the phases, clear, repeat. Cancel and clear on `roundPhase != .playing` and when a new round starts (UI-SPEC state table: "Round ends mid-celebration: dismiss immediately").
- For the sweep tally drive a `@State tallyStep: Int` incremented by the task at `stepDuration = clamp(1.2 / N, 0.03, 0.3)` (UI-SPEC). `Task.sleep`-driven state is simpler to cancel, test (inject durations), and to sync with ticks/sounds than `phaseAnimator`/`keyframeAnimator`, which cannot fire sounds. Use `.contentTransition(.numericText())` on the running counter.
- Queue cap: UI-SPEC says at most 2 queued (one word yields at most 2 events), so a normal submission never builds a backlog; if a second word completes something while a celebration is still showing, append and play sequentially (never overlap).
- Score timing: score is applied in the VM at submission (immediate). The score bar updating "when the tally folds" is a visual nicety; UI-SPEC explicitly allows applying at start provided final score identical. Recommended: apply immediately (simplest, no round-end race: tapping Finish Round mid-tally records the correct score via `finishRound()`).
- Reduce Motion: `@Environment(\.accessibilityReduceMotion)`; branch durations/transitions per UI-SPEC.
- Announcements: `AccessibilityNotification.Announcement("Pangram sweep! plus \(n) points").post()` (iOS 17 API). Verify it compiles under the project's iOS 17 target (it is iOS 17+).

### Pattern 4: RankTier with a hidden strict-> tier (D-06)
Current `tier(score:maxScore:)` loops `RankTier.allCases` with `>= requiredScore`. Adding `case mythicGrandmaster` with `thresholdPercent` 100 would make it reachable at exactly 100% (WRONG). Required behavior:
```swift
case .mythicGrandmaster: // thresholdPercent: 100 (still), but entry is strictly greater
static func tier(score: Int, maxScore: Int) -> RankTier {
    guard maxScore > 0 else { return .novice }
    if score > maxScore { return .mythicGrandmaster }
    var result = RankTier.novice
    for tier in RankTier.allCases where tier != .mythicGrandmaster
        && score >= tier.requiredScore(maxScore: maxScore) { result = tier }
    return result
}
```
Notes: `requiredScore(maxScore:)` for mythic should return `maxScore + 1` (smallest integer score strictly above max) so any caller reading "points needed" is consistent; `thresholdPercent` for mythic: leave documented as "> 100" (e.g. return 100 with doc, or Double just above); tests currently assert `allCases.map(\.thresholdPercent) == [0,2,5,8,15,25,40,50,70,100]` and 10 names; these tests MUST be updated (names get an 11th "Mythic Grandmaster"; percentages decide how mythic is represented). Prefer keeping `allCases` complete (11) and updating the tests, since `Comparable` via `rawValue` keeps ordering. Also existing assertion `tier(score: 150, maxScore: 100) == .legend` flips to `.mythicGrandmaster`; add `score: 101` -> mythic, `score: 100` -> legend, `maxScore: 0` -> novice still. Because `maxScore > 0` guard precedes, score>0 with max 0 stays novice (preserve).

Nothing in the app lists tiers as "next tier" today (grep of `allCases` usage outside RankTier/tests found none in views; planner should re-grep `RankTier.allCases` once before editing to confirm), so "hidden" is satisfied by simply never rendering a next tier.

### Pattern 5: Unclamped progress (D-05)
`GameViewModel.progressFraction`: remove `min(1, ...)`; keep `guard maxPossibleScore > 0`. Contract becomes "0 ... unbounded". `ScoreBarView` already clamps `ProgressView` value to 0...1 itself (`min(max(progress,0),1)`); overflow = `progress > 1` (strict). Update the doc comment `/// 0...1` on `ScoreBarView.progress`. Grep for other `progressFraction` consumers (tests in `GameViewModelTests` may assert clamping, to be updated; I could not list matches because the combined grep errored on macOS quoting, planner/executor should `grep -rn progressFraction WordPuzzle*`).

### Pattern 6: ScoreBarView additions
New value-in params: `foundPangrams: Int`, `totalPangrams: Int` (progress already passed). Detail row: counter chip leading + free-puzzles text trailing; row always renders (stable height). Fold the counter and "Progress beyond maximum." into the existing combined accessibility label. Overflow shimmer: `.overlay` of a `LinearGradient` with `.mask`/`.clipShape(Capsule())`, animated with an `@State phase` driven by `withAnimation(.linear(duration: 2).repeatForever(autoreverses: false))` in `.onAppear`/`.onChange(of: isOverflow)`; gate by `accessibilityReduceMotion`. `allowsHitTesting(false)` so the whole bar remains the Found Words button target.

### Anti-Patterns to Avoid
- **Bool triggers for haptics/sounds:** use monotonic counters (`sweepCount`, `lengthBonusCount`); a Bool set true twice never fires again (Phase 3 Pitfall 3).
- **Regrouping `foundWordGroups` per submission** to detect completion: use incremental per-length counters.
- **Putting bonuses in `maxPossibleScore`:** violates D-03; tier math assumes max excludes bonuses.
- **Blocking input during the tally:** UI-SPEC says no; overlay is `allowsHitTesting(false)`.
- **Awarding the sweep when `pangramSet` is empty** (isSubset of empty is true).
- **Double-playing sounds:** UI-SPEC 5 says completion/sweep sounds REPLACE word_accepted/pangram_found for that submission. The existing `.onChange(of: acceptedSubmissionCount)` plays the per-word sound; it must consult VM state (e.g. whether this submission produced a celebration) to choose which effect plays. Compute the effect in one place (extend `SoundEffect.forSubmission` with a `celebration:` parameter and unit-test it).
- **Magic numbers in views:** put durations/max-tally/tick-cap in `GameTheme` (project convention).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptics | CoreHaptics engine | `.sensoryFeedback(.success, trigger: counter)` | Already the project pattern; respects system settings |
| Numeric tick-up text | Manual per-frame string interpolation | `Text` + `.contentTransition(.numericText())` + `.monospacedDigit()` | Built in, Reduce-Motion aware via `withAnimation` gating |
| Screen-reader announcements | Custom AVSpeech | `AccessibilityNotification.Announcement(...).post()` | System-managed, queued correctly with VoiceOver |
| Audio playback | New audio engine | Extend `SoundManager` / `SoundEffect` | Preload, `.ambient`, enabled gate already tested |
| Per-length completion math | Re-derive from `foundWordGroups` | Incremental `[Int: Int]` counters seeded from `validWords` at round start | O(1), testable |
| Shimmer | Third-party shimmer lib | `LinearGradient` + animated offset | One small overlay; CLAUDE.md: no extra deps |

## Runtime State Inventory
Skipped: this is not a rename/refactor/migration phase. One persistence note: `GameRecord`/`PersistenceStore.record(score:wordsFoundCount:)` stores `score`; after this phase stored scores can exceed `maxPossibleScore`. I did not read `GameRecord`/`PersistenceStore`; the planner should check no persistence code, today-total aggregation, or `PaywallView` stat assumes `score <= max` or clamps (see Open Questions). No schema change is needed (score is an Int).

## Common Pitfalls

### Pitfall 1: Mythic reachable at exactly 100%
**What goes wrong:** treating mythic as another percent threshold with `>=`. **Avoid:** explicit `score > maxScore` branch, excluded from the `allCases` loop. **Detect:** boundary test `tier(100,100) == .legend`, `tier(101,100) == .mythicGrandmaster`.

### Pitfall 2: Existing tests encode the 10-tier / clamp assumptions
`RankTierTests` (`allCases.count == 10`, names list, thresholds list, `150 -> .legend`), `SoundManagerTests.testAllCasesCountIsFour`, and probably `GameViewModelTests` progress assertions will fail. Plan an explicit task to update them rather than treating red tests as regressions.

### Pitfall 3: Overlapping or stranded celebrations
Two events (length + sweep) from one word, rapid consecutive words, or round end mid-animation. **Avoid:** single drain Task, cancel on phase change/new round, clear `activeCelebration` on cancel. Add `.task(id:)` or explicit cancel in `.onChange(of: roundPhase)`. **Detect:** unit-test the VM queue ordering; manual test: finish round mid-tally.

### Pitfall 4: Sound/haptic double fire
Per-word accepted sound/haptic + completion fanfare + `WordDisplayView`'s existing counter-based haptics. Decide which haptic wins; `WordDisplayView` already has `.sensoryFeedback` keyed on `acceptedCount` (not read in detail here; inspect before adding a second `.success` haptic on the same frame, since two `.success` haptics within milliseconds are felt as one muddied buzz). Suggested: delay the celebration haptic to the tally end (sweep) / pill appear (length), which UI-SPEC already places at the final frame.

### Pitfall 5: New wav not in the bundle
`SoundManager.init` silently `continue`s if a resource is missing; `play` then no-ops silently. **Avoid:** extend `SoundManagerTests`' bundling test (it already covers "resource-bundling"; add the new cases so `SoundEffect.allCases` all resolve in `Bundle.main`).

### Pitfall 6: Dynamic Type / AX5 layout
New detail row and mythic name are additional text in a no-ScrollView layout. All new text: `lineLimit(1)` + `minimumScaleFactor(0.5)`; the sparkles icon + "Mythic Grandmaster" (18 chars) in the title row shares width with "N of M words" + chevron. **Requires physical-device AX5 check** (Phase 5-06). `DynamicTypeTests` exists; extend if it renders views at AX sizes.

### Pitfall 7: Sweep detection relies on the word being a pangram
Only evaluate the sweep when the just-accepted word is a pangram AND `pangramSet.isSubset(of: foundWordSet)`; otherwise a later non-pangram word would re-trigger. `sweepAwarded` flag prevents repeat even though `alreadyFound` rejection already prevents re-submitting.

### Pitfall 8: Round state reset
`startNewRound(with:)` must reset `completedLengths`, per-length counters, `sweepAwarded/sweepBonus`, `lengthBonusTotal`, `pendingCelebrations`; counters used as haptic triggers should NOT be reset (monotonic). MissedWordsView reads `sweepBonus`/`lengthBonusTotal` at `.roundOver`, before the next round resets them (order is safe because reset happens on `startNewRound`).

## Code Examples

### SoundEffect additions (naming follows existing style: camelCase case, snake_case raw = filename)
```swift
case pangramSweep = "pangram_sweep"
case sweepTick    = "sweep_tick"
// optional: case lengthComplete = "length_complete"  (or reuse .pangramFound, UI-SPEC allows)
```
Tick throttling (UI-SPEC): at most 12 ticks; for N > 12 tick every `ceil(N/12)`-th step. `SoundManager.play` does `player.stop(); currentTime = 0; play()`, which restarts the same player: ticks closer than the clip length will cut each other off, so pick a very short tick clip (<= ~60 ms) or accept truncation. At the 0.03s minimum step the throttle (<= 12 ticks over <= 1.2s = >= 100 ms apart) keeps ticks audible.

### Tally step timing
```swift
static func sweepStepDuration(pangramCount n: Int) -> Double {
    guard n > 0 else { return 0 }
    return min(0.3, max(0.03, 1.2 / Double(n)))
}
// Put in ScoreCalculator or GameTheme as a pure function so it is unit-testable.
```
Show per-step words only when step >= 0.08s (UI-SPEC), i.e. n <= 15.

### Sound candidates (MEDIUM, from Kenney Interface Sounds pack naming; verify by listening)
Existing mappings come from `confirmation_001/004`, `error_004`, `maximize_006`. The same pack (CC0, https://kenney.nl/assets/interface-sounds) contains the families `tick_00x`, `confirmation_00x`, `maximize_00x`, `bong_001`, `open_00x`, `question_00x`, `scale_00x`. Suggested: tick = `tick_001`/`tick_002`; length-complete = `confirmation_002` or `confirmation_003` (lighter than `confirmation_004` used for round_end); sweep fanfare = a longer `maximize_00x` variant other than `006` (e.g. `maximize_008` or `maximize_009`) or `confirmation_00x` layered. The pack is NOT present on this machine (searched `maximize_00*`); the executor must download from kenney.nl. Convert with `afconvert -f WAVE -d LEI16@44100 -c 1 in.ogg out.wav` (note `afconvert` does not read Ogg Vorbis; use `ffmpeg` (not installed) or Audacity; or download Kenney's included OGG and convert via a tool the executor installs, e.g. `brew install ffmpeg`: `ffmpeg -i in.ogg -ar 44100 -ac 1 -sample_fmt s16 out.wav`). Confirm clip choices by ear on device; this is a human-verify item. Append lines to `Sounds/LICENSE.txt` in the existing "wav <- Audio/clip.ogg" format.

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| `ObservableObject` | `@Observable` (iOS 17) | already used |
| UIKit haptic generators | `.sensoryFeedback(_:trigger:)` (iOS 17) | already used; use counters |
| `UIAccessibility.post(.announcement)` | `AccessibilityNotification.Announcement` (iOS 17) | preferred for new code |
| `withAnimation` completion handling | `withAnimation(_:completionCriteria:_:completion:)` (iOS 17) | optional; Task-based sequencing chosen for cancel/sound sync |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | build + tests | yes | (iOS 26.5 simulators present: iPhone 17, 17 Pro, 17e, Air...) | none needed |
| Simulator | `xcodebuild test` | yes | iPhone 17 (69610FE7-0679-4A4E-9A92-66ACC9F97EDB) | any available iPhone |
| python3 | frequency script (already run) | yes | 3.x | n/a |
| afconvert | wav conversion | yes | system | (cannot read Ogg) |
| ffmpeg | ogg -> wav | NO | - | `brew install ffmpeg`, or download WAV variants / use Audacity |
| Kenney Interface Sounds pack | new clips | NO local copy | - | download from kenney.nl (network at execution time) |
| Physical device + Wi-Fi install script (`scripts/install-on-device.sh`) | AX5 check, haptics, audio feel | per user memory: yes (preferred checkpoint path) | - | none for haptics (Simulator has none) |

**Blocking:** none. Sound asset acquisition needs network and an ogg->wav converter (the executor may need to install ffmpeg).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Test`, `@Suite`), `@testable import WordPuzzle`; UI tests via XCTest in `WordPuzzleUITests` |
| Config file | `WordPuzzle/WordPuzzle.xcodeproj` shared scheme `WordPuzzle` (no separate config) |
| Quick run command | `cd WordPuzzle && xcodebuild test -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/RankTierTests -only-testing:WordPuzzleTests/ScoreCalculatorTests` |
| Full suite command | `cd WordPuzzle && xcodebuild test -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests` |
| Note | Verify exact `-only-testing` identifiers (Swift Testing suites are addressed by type name, e.g. `WordPuzzleTests/RankTierTests`); `GameViewModelTests` loads the full ENABLE list (`@Suite(.serialized)`), so it is the slow one |

### Decision -> Test Map
| Decision | Behavior | Test Type | Command / Target | File Exists? |
|----------|----------|-----------|------------------|-------------|
| D-01 | `sweepBonus(pangramCount: 3) == 21`, 0 -> 0, 1 -> 7 | unit | ScoreCalculatorTests | exists, add cases |
| D-02 | 1-pangram fixture: finding it awards word points + 7 (pangram) + 7 (sweep) | unit | GameViewModelTests | exists, add |
| D-03 | `maxPossibleScore` unchanged after sweep; `finishRound()` persists score incl. bonus | unit | GameViewModelTests (+ PersistenceStoreTests read-back) | exists, add |
| D-04/D-06 | `tier(100,100)==.legend`; `tier(101,100)==.mythicGrandmaster`; name exact "Mythic Grandmaster"; max 0 -> novice; allCases count 11 | unit | RankTierTests | exists, UPDATE old assertions |
| D-05 | `progressFraction > 1` after bonus; 0 when max 0; ScoreBarView clamps ProgressView only | unit (VM) + visual | GameViewModelTests; manual/preview | exists, update |
| D-07/D-17 | Same word completing length group + sweep yields events in order [length, sweep]; both bonuses scored | unit | GameViewModelTests | add |
| D-08 | `sweepStepDuration` clamps (n=1 -> 0.3, n=4 -> 0.3, n=40 -> 0.03, n=86 -> 0.03); total steps <= 1.2s (+ epsilon) | unit | ScoreCalculatorTests or new CelebrationTimingTests | add |
| D-09 | copy strings exact ("Pangram sweep! +21", "5 Letters complete! +5") via static funcs | unit | new CompletionCopyTests / FoundWordsViewTests style | add |
| D-10 | new `SoundEffect` cases exist, resolve in `Bundle.main`, `allCases.count == 6` (or 7), sweep fanfare != pangramFound; enabled gate honored | unit | SoundManagerTests | exists, UPDATE count test |
| D-11 | `FoundWordsView` line "Pangrams · X of N" static func; ScoreBar label includes "1 of 3 pangrams found." | unit (static copy) | FoundWordsViewTests | exists, add |
| D-12/D-13 | Generator untouched | review | `git diff -- PuzzleGenerator.swift` empty | n/a |
| D-14/D-18 | `lengthCompletionBonus(length: 5) == 5`; awarded once (second completion attempt impossible: duplicate rejection) ; multiple lengths each awarded once; incomplete group no award | unit | ScoreCalculatorTests + GameViewModelTests | add |
| Reset | New round clears sweep/length state, counter 0/N | unit | GameViewModelTests | add |
| Empty pangram set | fixture with `pangrams: []` never sweeps | unit | GameViewModelTests | add |
| UI-SPEC celebrations | tally card, pill, shimmer, Reduce Motion, VoiceOver announcement, AX5 fit | manual (device) | `scripts/install-on-device.sh`; AX5 + Reduce Motion + silent switch | manual-only (animation/haptics/audio can't be asserted in unit tests) |
| Stack ordering visual | pill then sweep sequentially, no overlap, round end mid-tally dismisses | manual (device) + optional UI test | device checkpoint | manual |

### Sampling Rate
- Per task commit: quick run command (RankTierTests, ScoreCalculatorTests, SoundManagerTests; < 30 s, none load the word list).
- Per wave merge: full `WordPuzzleTests` (includes word-list-loading suites).
- Phase gate: full suite green plus device checkpoint (AX5 + Reduce Motion + haptics + audio) before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] Update `RankTierTests` (11 tiers, mythic boundary) and `SoundManagerTests.testAllCasesCountIsFour`, in the same plan that changes the code so the suite stays green.
- [ ] Add GameViewModel fixtures: (a) 1-pangram puzzle with a single-word longest group (stack case), (b) multi-pangram puzzle, (c) `pangrams: []`. Existing `pangramFixturePuzzle` (`candles` only) can serve (a) if `candles` is also the only 7-letter word: it is (length 7 group = ["candles"]), so it already exercises the stack case; add a 2-pangram fixture.
- [ ] Framework install: none.

## Open Questions

1. **Does anything downstream assume `score <= maxPossibleScore`?**
   - Known: I did not read `PersistenceStore`, `GameRecord`, `PaywallView` (today score aggregate). Planner should grep for `maxPossibleScore`/`score` consumers and confirm no clamping or percentage display exists. Recommendation: treat as a quick check task; no change expected.
2. **Which exact Kenney clips?** Needs listening; recommend a short device/Simulator audition checkpoint (user prefers automated checkpoints: provide an install script run; subjective sound choice is inherently human).
3. **Sound on the same frame:** the sweep fanfare is supposed to replace `pangram_found` when the accepted word completes the sweep (UI-SPEC 5). `GameView.onChange(of: acceptedSubmissionCount)` fires at submission time, while the fanfare is specified for the tally's final frame (1.2s later). Recommendation: at submission play NO per-word sound when a sweep is pending (or play the plain `pangram_found` immediately and the fanfare at the end; UI-SPEC says replace). Planner should pick and document: suggested "suppress pangram_found, tick during tally, fanfare at the end".
4. **MissedWordsView data source:** it needs `sweepBonus` and `lengthBonusTotal` from the VM (`GameView` passes values). Straightforward; no open risk.
5. **`WordDisplayView` haptics:** it keys haptics on `acceptedCount`; confirm how many distinct haptics fire for a pangram word today before layering `.success` (see Pitfall 4).

## Project Constraints (from CLAUDE.md)
- iOS only, SwiftUI, no game engine; iOS 17+ minimum; MVVM with `@Observable`; no TCA; no third-party dependencies for this (CLAUDE.md lists none needed); no network calls.
- Persistence: SwiftData via `PersistenceStore` for history/stats; `@AppStorage` for flags. No new persistence is required here.
- Word list/validation unchanged.
- All file changes must go through a GSD workflow (executor via `/gsd:execute-phase`).
- Conventions per existing code (not yet formalized in CLAUDE.md): value-in/closure-out views, `GameTheme` tokens for all spacing/type/color/motion, counter-based haptic triggers, Dynamic Type shrink-to-fit, Swift Testing for unit tests, CC0 audio attributed in `Sounds/LICENSE.txt`.
- User memory: prefers automated checkpoints and device testing via the Wi-Fi install script (`scripts/install-on-device.sh`).

## Sources

### Primary (HIGH confidence)
- Repository source read directly: `Services/ScoreCalculator.swift`, `Game/RankTier.swift`, `Game/GameViewModel.swift`, `PuzzleEngine/{PuzzleModel,PuzzleGenerator,WordList}.swift`, `Services/SoundManager.swift`, `Game/Views/{GameView,ScoreBarView,FoundWordsView,MissedWordsView}.swift`, `Game/GameTheme.swift`, `Sounds/LICENSE.txt`, `WordPuzzleTests/{RankTierTests,SoundManagerTests,FoundWordsViewTests,GameViewModelTests}.swift`.
- `.planning/phases/08-all-pangrams-bonus/08-CONTEXT.md`, `08-UI-SPEC.md`.
- Empirical simulation (3,000 puzzles) against `enable-clean.txt` replicating `generatePuzzle`.

### Secondary (MEDIUM confidence)
- Kenney Interface Sounds pack (https://kenney.nl/assets/interface-sounds), CC0 per existing `LICENSE.txt`; clip family names from prior knowledge plus existing mappings, not re-verified this session.

### Tertiary (LOW confidence)
- iOS 17 API availability of `AccessibilityNotification.Announcement`, `.contentTransition(.numericText())`, `sensoryFeedback` is from training knowledge (all shipped with iOS 17 / 2023); `sensoryFeedback` and `@Observable` already compile in this project. Verify `AccessibilityNotification` compiles at first use.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, first-party only, matches existing code.
- Architecture: HIGH, based on direct reading of all integration points; the event-queue design is a recommendation, not verified by prototype.
- Pitfalls: HIGH for code-derived ones (tier boundary, test updates, reset, empty pangram set); MEDIUM for haptic/sound overlap (`WordDisplayView` not fully read).
- Frequency data: HIGH (measured), with sampling error ~ +/-1 pp at n=3000.

**Research date:** 2026-10-04
**Valid until:** 2026-11-03 (stable stack)

# Phase 11: First-Launch Tutorial - Research

**Researched:** 2026-10-04
**Domain:** SwiftUI guided onboarding on top of an existing @Observable MVVM game (no new libraries)
**Confidence:** HIGH (codebase-derived; no third-party dependencies involved)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Scripted practice puzzle. Fixed hand-picked puzzle, step-by-step prompts; each step waits for the player to actually perform the action. Swipe-down-to-submit must be performed once to be learned.
- **D-02:** Strict guided steps. Only the highlighted target (tile, gesture, button) responds; other input ignored. After the last guided step the board is free.
- **D-03:** Ending: "You're ready!" moment, free play allowed on the practice board, tapping Finish starts the first real generated puzzle (D-10). Practice board has NO missed-words reveal and is NOT recorded in stats or history.
- **D-04:** Practice puzzle letters are Claude's discretion (easy first word, findable pangram, small word count, a way to make the guided "missing center letter" miss). Lock exact letters and center during planning. Reusing `stagedPuzzle(spec:from:)` is likely, but it is currently gated to the screenshot launch argument.
- **D-05:** Every mechanic gets a guided step inside the practice puzzle, no deferred just-in-time tips. Suggested order (planner may refine): 1 tap to build; 2 gold center letter via one guided miss; 3 swipe down to submit; 4 Delete removes last letter, tapping the word clears it; 5 drag across tiles; 6 Shuffle (button AND double-tap empty space); 7 pangram (7-letter word = bonus, player finds it); 8 score/rank bar, tap opens Found Words; 9 Finish Round. Short steps, ~2 minute target.
- **D-06:** One guided mistake: build a word without the center letter and submit, see real rejection feedback (shake + "missing center letter" message) before the rule is explained. Every other step is a success.
- **D-07:** The practice puzzle is free. MUST NOT call `recordRoundStarted()`, MUST NOT count toward the 3 free puzzles/day (`puzzlesPlayedToday`), MUST NOT write a `GameRecord`, MUST NEVER trigger the paywall gate.
- **D-08:** New installs only. If any game history exists (any `GameRecord` or `RoundStartRecord`) on launch, set the flag and skip the tutorial.
- **D-09:** A new install with no history sees the tutorial even if premium (e.g. restored purchase). Skippable (D-11).
- **D-10:** Finish step explains the button; tapping it starts the real puzzle. During the tutorial Finish skips the missed-words screen, marks the tutorial seen, then calls the normal `requestNextRound(isPremium:)` path.
- **D-11:** Small "Skip tutorial" link always visible, no confirmation. Skipping marks seen and starts a real puzzle through the normal path.
- **D-12:** Replay from Settings -> "How to Play" (new row alongside Sound Effects and Stats), restarts at step 1. Replay must not cost a free puzzle or corrupt the in-progress real round. Whether the real round resumes or a fresh one starts is the planner's call, but it must not record an extra round start or lose saved stats.
- **D-13:** An interrupted tutorial restarts from step 1. Only completing (D-10) or skipping (D-11) sets the "seen" flag. Step index is not persisted.
- Out of scope: new game mechanics, scoring/rank/paywall changes, analytics (v1 ships zero analytics, Phase 5 D-06).

### Claude's Discretion
- Prompt UI (banner vs speech bubbles) — fixed banner is the safer AX5 default; must survive Dynamic Type to AX5 and respect Reduce Motion. (UI-SPEC has since locked: fixed banner + pulsing highlight.)
- Exact tutorial copy (playful, Phase 6 tone).
- The practice letters (D-04).
- Tutorial state machine structure (inside `GameViewModel`, separate controller, etc.) and how "only the target responds" filtering is done.
- Sounds/haptics (default: normal game feedback).
- VoiceOver handling of guided steps (at minimum: steps announced, Skip reachable).

### Deferred Ideas (OUT OF SCOPE)
- Just-in-time contextual tips during real play (rejected in favor of D-05). Not backlogged.
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs are mapped (TBD). Derive coverage from CONTEXT decisions. Suggested working IDs for plan traceability:

| ID | Description | Research Support |
|----|-------------|------------------|
| TUT-01 | Scripted practice puzzle with strict guided steps (D-01/02/05/06) | `TutorialController` state machine + input gating in GameView closures; curated `Puzzle` literal |
| TUT-02 | Practice is free and unrecorded (D-03/07) | Separate `GameViewModel(persistenceStore: nil)` instance — structurally cannot write records |
| TUT-03 | First-launch gating, new-install only (D-08/09/13) | Tri-state `UserDefaults` key + `PersistenceStore.hasAnyHistory()` in the launch `.task` |
| TUT-04 | Skip + Finish hand-off (D-10/11) | `TutorialController.complete()/skip()` -> mark seen -> `requestNextRound(isPremium:)` |
| TUT-05 | Replay from Settings (D-12) | `onHowToPlay` closure in `SettingsView`; real `GameViewModel` untouched underneath |
| TUT-06 | Accessibility (UI-SPEC) | Banner wraps through AX5, Reduce Motion steady highlight, announcements via existing `announce(_:)` |
| TUT-07 | Existing UI tests/screenshot automation unbroken | `-hasSeenTutorial YES` launch argument added to every existing UI test |
</phase_requirements>

## Summary

This phase needs no new libraries. Everything is built from existing SwiftUI, `@Observable`, `@AppStorage`/`UserDefaults`, SwiftData (read-only history probe), `GameTheme`, and the existing `OverflowGlow` pulse math. The work is: (1) a pure, unit-testable tutorial state machine, (2) an input-gating layer inside `GameView` (the only view allowed to touch the VM), (3) value-in/closure-out banner/highlight views, (4) launch gating, (5) a Settings row, and (6) not breaking the UI tests/screenshot script, all of which launch fresh installs and would now land in the tutorial.

The single most important architectural recommendation: **run the practice puzzle on a second `GameViewModel` instance constructed with `persistenceStore: nil`.** `startNewRound(with:)` already does `persistenceStore?.recordRoundStarted()` and `finishRound()` does `persistenceStore?.record(...)`, so a nil store makes D-07 and D-12 true by construction (zero code paths can write a `RoundStartRecord` or `GameRecord`), leaves the real round's state completely untouched during Settings replay, and requires no snapshot/restore logic. Inject it into the subtree with `.environment(practiceViewModel)`, which overrides the app-level `GameViewModel` for `GameView`'s `@Environment(GameViewModel.self)`.

Second key finding: `stagedPuzzle(spec:from:)` is wrapped in `#if DEBUG` (PuzzleGenerator.swift:45-60). It does NOT exist in Release builds, so it cannot be reused as-is. Use a hand-curated `Puzzle` literal for the practice board (also gives a small, clean word list), validated by a unit test against the bundled word list.

**Primary recommendation:** Build `TutorialController` (@Observable, pure state machine, owns a nil-store practice `GameViewModel`), host it by passing an optional `tutorial:` parameter into `GameView`, gate input in GameView's existing closures, add a tri-state `hasSeenTutorial` UserDefaults key, and add `-hasSeenTutorial YES` to every existing UI test.

## Project Constraints (from CLAUDE.md)

- SwiftUI, iOS 17+ (project deployment target 17.6), MVVM with `@Observable`; no game engine, no third-party dependencies for this.
- Only `GameView` touches `GameViewModel`; all other views are value-in/closure-out (Phase 3/4 rule).
- Persistence split: `@AppStorage`/UserDefaults for flags; SwiftData for history/stats. The tutorial-seen flag is a UserDefaults flag.
- No networking APIs (`scripts/compliance-guards.sh` Guard 1 greps for URLSession etc.). No `Font.system(size:)` outside whitelisted `HexTileView` (compliance guard) — use `GameTheme` Dynamic Type fonts only.
- No analytics in v1 (Phase 5 D-06).
- Dynamic Type through AX5 and Reduce Motion must be respected.
- GSD workflow: edits go through GSD commands (planning/execution), not direct edits.
- Do not use TCA, Core Data, Firebase, etc. (irrelevant here, no new deps).

## Standard Stack

### Core (all existing; nothing to install)
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SwiftUI + Observation (`@Observable`) | iOS 17.6 target (Xcode 27.0 toolchain) | Controller, banner, highlight | Project mandate; matches `GameViewModel` convention |
| `UserDefaults`/`@AppStorage` | system | `hasSeenTutorial` flag | Project convention for flags (`SoundManager.soundEffectsEnabledKey` pattern) |
| SwiftData `PersistenceStore` | existing | History probe (D-08) | Add `hasAnyHistory()` using `fetchCount` on `GameRecord` and `RoundStartRecord` |
| `GameTheme` + `OverflowGlow` | existing | Tokens, pulse math | UI-SPEC mandates reuse |
| Swift Testing (`@Test`, `@Suite`) | Xcode 27 | Unit tests | Existing unit target uses it |
| XCTest/XCUITest | Xcode 27 | UI tests | Existing UI target |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Second nil-store `GameViewModel` | Same VM with a `startPracticeRound` that skips recording + snapshot/restore for replay | Needs a `RoundSnapshot` for resume, more places that can accidentally record; rejected |
| Optional `tutorial:` param on `GameView` | Separate `TutorialGameView` duplicating layout | Duplicates ~200 lines of layout/celebration/sound wiring; rejected |
| Third-party coach-mark libs (e.g. TipKit) | TipKit | TipKit is popover-tip oriented, cannot gate input or script steps; CONTEXT locked a scripted-practice format |

**Installation:** none. New files go in existing folders; the Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so new `.swift` files under `WordPuzzle/WordPuzzle/` and `WordPuzzle/WordPuzzleTests/` are picked up automatically (no pbxproj edit).

## Architecture Patterns

### Recommended Project Structure
```
WordPuzzle/WordPuzzle/
├── Tutorial/
│   ├── TutorialController.swift   # @MainActor @Observable state machine + practice VM + seen-flag helpers
│   ├── TutorialStep.swift         # enum Step, copy table, allowed-actions per step (pure, testable)
│   └── PracticePuzzle.swift       # curated Puzzle literal (non-DEBUG)
├── Game/Views/
│   ├── TutorialBannerView.swift   # value-in/closure-out banner + Skip link + Ready card
│   └── TutorialHighlight.swift    # ViewModifier: pulsing accent ring + dim
└── (edits) WordPuzzleApp.swift, ContentView.swift, GameView.swift, LetterGridView.swift,
    SettingsView.swift, PersistenceStore.swift, GameViewModel.swift, GameTheme.swift
```

### Pattern 1: Practice board = second GameViewModel with nil store (D-07, D-12)
**What:** `TutorialController` owns `let practice = GameViewModel(wordList:, persistenceStore: nil)` and starts it with `practice.startNewRound(with: PracticePuzzle.make())`.
**Why it works:** `GameViewModel.startNewRound(with:)` line 218 `persistenceStore?.recordRoundStarted()` and `finishRound()` line 247 `persistenceStore?.record(...)` are optional-chained, so with nil they are no-ops. `requestNextRound` is never called on the practice VM, so the paywall gate is unreachable (D-07).
**Hosting:**
```swift
// ContentView.swift
struct ContentView: View {
    @Environment(TutorialController.self) private var tutorial
    var body: some View {
        if tutorial.isActive {
            GameView(tutorial: tutorial)
                .environment(tutorial.practice)   // overrides GameViewModel for this subtree
        } else {
            GameView()
        }
    }
}
```
Replay: the real `GameViewModel` is held by `WordPuzzleApp` `@State`, so its state survives the root swap. On replay completion/skip, `tutorial.isActive = false` and the real round resumes with no extra round start (satisfies D-12 "resumes" option). On first-launch completion/skip, the app calls `gameViewModel.requestNextRound(isPremium:)` (D-10/D-11) because no real round exists yet.
**Caveat:** swapping the root view identity discards GameView `@State` (open sheets, celebration task). `GameView` already cancels celebrations on phase change; also set `isShowingSettings = false` before activating (see Pitfall 4).

### Pattern 2: Pure state machine, events in, gating out
**What:** `TutorialController` holds `step`, exposes `allows(_ action: TutorialAction) -> Bool` and `handle(_ event: TutorialEvent)`. GameView translates real UI callbacks into events; the controller never touches views.
```swift
enum TutorialAction { case tapLetter(Character), delete, clearWord, submit, shuffleButton,
                      backgroundDoubleTap, scoreBar, finish, topBar }
// GameView wraps each existing closure:
onLetterTouched: { ch in
    guard tutorial?.allows(.tapLetter(ch)) ?? true else { return }
    activeVM.append(ch)
    tutorial?.handle(.wordChanged(activeVM.currentWord))
}
```
Advancement is driven by observable VM state GameView already watches (`acceptedSubmissionCount`, `rejectedSubmissionCount`, `shuffleCount`, `currentWord`) via `.onChange`, forwarded as events. Keep the step table (target, allowed actions, advance condition, copy) as pure data so each step can be unit-tested without a view.
**Strict gating specifics:**
- Letter steps: allow only the NEXT expected letter (`target[currentWord.count]`); highlight only that tile (single focus; works for drag too since `LetterGridView` just calls `onLetterTouched` for each newly entered tile, ignoring is safe).
- `WordDisplayView` internals (drag follow, armed border) still animate on a filtered swipe; only the `onSubmit`/`onClear` callbacks are gated. Acceptable; do not edit `WordDisplayView` gesture code.
- The background double-tap layer and `LetterGridView.onEmptyDoubleTap` both call `shuffleOuterLetters()`; gate both closures (UI-SPEC: only live on the shuffle step).
- Top-bar Stats/Settings buttons: `.disabled(tutorial.isGuided)` + `.opacity(0.35)`; Skip is never gated.
- Score bar button: gated except step 8 and free play.

### Pattern 3: Highlight/dim as value-in parameters
`LetterGridView` is presentation-only; add defaulted params (existing call sites and previews compile unchanged): `highlightedLetter: Character? = nil`, `dimsOthers: Bool = false`. Tiles have unique letters within a puzzle, so letter is a safe key; center tile exempt from dim when target (UI-SPEC). Controls (Shuffle, Delete, Finish, score bar, word display) get the `TutorialHighlight` modifier from GameView. Pulse: `TimelineView(.animation(paused: reduceMotion))` + `OverflowGlow.pulse(time:reduceMotion:)`, `GameTheme.overflowGlowPulseSeconds`, stroke `tutorialHighlightStroke` (precedent: `ScoreBarView.swift:189`, `StatsView.swift:210`).

### Pattern 4: Tri-state launch gating (D-08/D-09/D-13)
```swift
enum TutorialFlag {
    static let seenKey = "hasSeenTutorial"
    /// nil = never decided (fresh install, or interrupted tutorial) ; true = seen ; false = forced show
    static var state: Bool? { UserDefaults.standard.object(forKey: seenKey) as? Bool }
}
// WordPuzzleApp .task, after `await wordList.load()`:
let shouldTutorial: Bool
switch TutorialFlag.state {
case true?:  shouldTutorial = false
case false?: shouldTutorial = true                       // explicit -hasSeenTutorial NO (UI test)
case nil:
    if persistenceStore.hasAnyHistory() {                // D-08
        UserDefaults.standard.set(true, forKey: TutorialFlag.seenKey); shouldTutorial = false
    } else { shouldTutorial = true }
}
if shouldTutorial { tutorial.begin(...) }                // do NOT call requestNextRound
else { gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium) }
```
`@AppStorage` cannot distinguish "absent" from default, so the launch decision must read `UserDefaults.object(forKey:)`. `@AppStorage("hasSeenTutorial")` is still fine for writes/reads elsewhere (same suite key). Interrupted tutorial leaves the key absent -> restarts next launch (D-13). Because the practice VM writes nothing, history stays empty so the check stays "show".
`PersistenceStore.hasAnyHistory()`: `fetchCount` on both models (never `fetch(...).count`, per existing convention at PersistenceStore line ~63).
**Important ordering:** on a tutorial launch the real `GameViewModel` stays in `.loading` and never starts a round until Finish/Skip, so no `RoundStartRecord` is written before the player chooses (D-07). The real GameView is not shown, so the "Loading words..." state is not visible.

### Pattern 5: Finish routing in tutorial mode (D-10)
In `GameView`, `finishRoundButton` action: `if let tutorial { tutorial.finish(); return }` before `viewModel.finishRound()`. `tutorial.finish()` sets seen, sets `isActive = false`, and invokes an injected `onFirstRealRound` closure (App-level) which calls `requestNextRound(isPremium:)` — only when no real round is in progress (first launch). The practice VM's `roundPhase` never leaves `.playing`, so the `fullScreenCover` condition (`.roundOver || .paywalled`) is never true.

### Pattern 6: Settings row (D-12)
Add `static let howToPlayRowLabel = "How to Play"` and `let onHowToPlay: () -> Void` (give it a default `= {}` so existing `SettingsView(soundEffectsEnabled:onDone:)` calls in tests/previews compile). Row styled like the Stats row but a `Button` (not NavigationLink): `Image(systemName: "questionmark.circle")`, `.accessibilityIdentifier("settingsHowToPlayRow")`. GameView handler: set `isShowingSettings = false`, then activate the tutorial after the sheet dismisses (see Pitfall 4). Add a frozen-copy test next to `SettingsViewTests`.

### Anti-Patterns to Avoid
- **Reusing `startNewRound()`/`requestNextRound` for practice:** records a round start and can trigger the paywall (violates D-07).
- **Using `stagedPuzzle` in Release:** it is `#if DEBUG`; will not compile in Release if referenced from non-DEBUG code.
- **Persisting the step index:** D-13 says restart from step 1.
- **A second gesture recognizer over the hex grid or a full-screen transparent blocking overlay for input filtering:** Phase 3 Pitfall 1 (competing recognizers swallow taps) and Phase 10 gesture layering. Filter in closures instead; never add hit-testable overlays over the grid (UI-SPEC: banner only hit-testable on Skip).
- **Putting tutorial logic inside `LetterGridView`/`WordDisplayView`:** they must stay value-in/closure-out.
- **Making `GameViewModel.currentWord` publicly settable:** add a narrow internal method (see Pitfall 6) rather than removing `private(set)`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pulsing glow math | New animation timing | `OverflowGlow.pulse/opacity/radius` + `GameTheme.overflowGlow*` | Already handles Reduce Motion (steady 0.5) |
| Announcements | New VoiceOver plumbing | GameView's existing `announce(_:)` (`AccessibilityNotification.Announcement`) | UI-SPEC mandates reuse |
| Rejection feedback for the guided miss | Custom shake/message | Real `submitCurrentWord()` -> `reject(.missingCenterLetter)` -> `WordDisplayView` | D-06 wants the REAL feedback |
| Sounds/haptics | Tutorial-specific sounds | Existing `SoundManager`/`.sensoryFeedback` wiring in GameView | Default per CONTEXT |
| Round isolation/snapshot | Snapshot-restore of real round state | Second `GameViewModel(persistenceStore: nil)` | Zero write paths; no restore bugs |
| Word validation for practice | Custom checker | `GameViewModel.submitCurrentWord()` against shared `WordList` | Same rules as real play |
| Celebrations on pangram step | Custom confetti | Existing Phase 8 sweep/length-pill drain in GameView | UI-SPEC: may play, intended payoff |

**Key insight:** every behavior being taught already exists and is correct; the tutorial is a thin gating/prompting skin over the real game code. Any custom re-implementation would teach behavior that diverges from the real game.

## Runtime State Inventory

Not a rename/refactor/migration phase — omitted by rule. One related note: this phase introduces ONE new persisted key (`hasSeenTutorial`, UserDefaults). No data migration. Existing players (history present) get the flag set on first post-update launch via D-08.

## Practice Puzzle (D-04): findings and recommendation

**Do not generate; hand-curate a `Puzzle` literal** (non-DEBUG, in `Tutorial/PracticePuzzle.swift`), with a small `validWords` list of familiar words, and lock it with a unit test that asserts: every `validWords` entry is in the bundled `WordList`, is >= 4 letters, contains the center, and uses only the 7 letters; `pangrams` all use all 7 letters; the miss word has >= 4 letters, lacks the center, and is in the word list (ideally); every scripted word (build, submit, drag, pangram) is in `validWords`. `submitCurrentWord()` also accepts any in-dictionary word that fits the letters even if not in `validWords` (counted as an "extra"), so a curated list never blocks the player.

Verified against `enable-clean.txt` (ran a script over the bundled list). **Candidate (MEDIUM confidence, planner must lock after a quick on-device feel check):** pangram DOLPHIN, letters D O L P H I N, center **P**:
- Pangram: `dolphin` (the ONLY pangram in this letter set, and a friendly word).
- Center-P words available (all verified in ENABLE): `hoop, loop, plod, plop, poll, polo, pond, pool, pooh, hippo, lipid, polio, pinon, poind, poplin, dollop, lipoid, opioid, pinion, diploid, dolphin, ...` (38 total with center P — curate a ~12-word `validWords` subset of familiar ones: e.g. `pond, plod, polo, pool, loop, hippo, polio, poplin, dolphin`).
- Build step word (4 letters, obvious): `POND` or `POLO`.
- Guided miss word (>= 4 letters, no P, real words; must be >= 4 so the rejection is `missingCenterLetter`, not `tooShort` — `submitCurrentWord` checks length first, GameViewModel.swift:278): `HOLD`, `LION`, `HIND`, `IDOL` all verified in ENABLE.
- Drag step word: must NOT have consecutive repeated letters (the drag recognizer's `index != lastTouchedIndex` guard means "LOOP"/"POLL" cannot be dragged); `POND`/`PLOD`-style words are fine.
- Other tried sets (RAINBOW/W, JOURNAL/N, CHARITY/Y) have weirder valid lists; DOLPHIN/P was the most readable. Planner may substitute but must re-run the validation test.

**Bonus-event design pitfall:** the puzzle's length buckets and single pangram mean (a) finding `dolphin` triggers the Phase 8 pangram SWEEP celebration immediately (only one pangram -> sweep completes), and (b) a word that completes its length bucket fires a length pill. Curate `validWords` so scripted steps 1-6 words do NOT complete a length bucket (include >= 2 words at each of lengths 4/5/6, plus the 7-letter pangram as the sole 7), so celebrations only appear on the pangram step. The sweep card runs ~2-3s; delay advancing past step 7 until it finishes (or accept overlap since the card is `allowsHitTesting(false)`).

## Common Pitfalls

### Pitfall 1: Existing UI tests and the screenshot script land in the tutorial
**What goes wrong:** `WordPuzzleUITests` (testExample, launch performance), `StatsPresentationUITests`, and `AppStoreScreenshotTests` all launch fresh installs with zero history and then wait for the "Finish Round"/"Center letter R" board. With the tutorial gating, `Finish Round` still exists but the board is the practice puzzle, the stats test expects "Games played, 0" then plays real rounds, and the screenshot test relies on `-ScreenshotPuzzle harmony:r` (read in `GameViewModel.startNewRound()`, which the tutorial path bypasses).
**How to avoid:** Add `app.launchArguments += ["-hasSeenTutorial", "YES"]` to EVERY existing `XCUIApplication()` launch (WordPuzzleUITests x2, StatsPresentationUITests, AppStoreScreenshotTests, WordPuzzleUITestsLaunchTests if it launches). XCUITest `-key value` arguments land in the NSArgumentDomain, which `UserDefaults.standard.object(forKey:)` and `@AppStorage` read with highest precedence (arguments are not persisted; they only override reads). Because the tri-state check reads `object(forKey:)`, `YES` -> seen. Use `-hasSeenTutorial NO` for the new tutorial UI test so it forces the tutorial even if earlier runs left history on the simulator (state `false` -> show, bypassing the history check). Also update `scripts/capture-app-store-screenshots.sh` docs only if needed (the test itself carries the argument; the script uninstalls first).
**Warning signs:** UI tests time out waiting for "Next Puzzle"/"Games played, 1".

### Pitfall 2: Racing the launch task / blank frames
First launch currently shows `ProgressView("Loading words...")` while the word list loads. With the tutorial, the practice puzzle also needs the word list (submit validation uses `wordList.contains`). Start the tutorial only after `await wordList.load()` in the same sequential `.task` (do not add a second concurrent `.task`; the existing comment documents the ordering hazard). While `tutorial.isActive` is false and the real VM is `.loading`, the app shows the existing loading view — acceptable.

### Pitfall 3: Daily-count leakage
Any call to `startNewRound(with:)`/`requestNextRound` on the REAL VM before the player finishes/skips records a round start. Verify with a test: after a full practice run and completing the tutorial, `puzzlesPlayedToday()` equals exactly 1 (only the real round started on hand-off), `totalGamesPlayed()` == 0. After skip/replay-from-Settings mid-round: unchanged counts. Also `ScoreBarView` takes `freePuzzlesRemaining`; pass `nil` in tutorial mode so the practice board shows no "x of 3 left" counter.

### Pitfall 4: Presenting/dismissing Settings while swapping the root
Setting `isShowingSettings = false` and flipping `tutorial.isActive = true` in the same tick swaps the root (and destroys the Settings sheet host) mid-dismissal, which logs presentation warnings and can drop the swap. Use `.sheet(isPresented:onDismiss:)` on the Settings sheet and set a `pendingReplay` flag in `onHowToPlay`; start the tutorial in `onDismiss`. (Same family as Phase 9 RESEARCH Pitfall 2.)

### Pitfall 5: Guided-miss ordering (D-06)
The banner must not explain the rule before the miss, and must explain it AFTER the shake/message has been seen. `WordDisplayView` shows the message for ~1.1s and the shake lasts ~0.4s. Advance the banner on `rejectedSubmissionCount` change after a short delay (~0.9s, cancellable `Task`, inject the delay so tests can zero it). If the player somehow submits the miss word before the delay ends, ignore. Rejection reason checks order: too short -> missing center, so miss word must be >= 4 letters. Also if the player in step 2 builds a different wrong word, only the exact miss word letters are allowed by gating, so no surprises.

### Pitfall 6: Steps that need pre-filled input
Step 4 (Delete/clear) needs letters already in the display, and each step transition must clear any leftover `currentWord` (step 1 builds a word that is never submitted). `GameViewModel.currentWord` is `private(set)` and the only non-DEBUG mutators are `append`, `deleteLast`, `clearCurrentWord`. Prefer calling `append` N times and `clearCurrentWord()` from the controller (no new VM API). Step 4 sub-steps: delete once (advance when length decreases), then tap the word to clear (advance when empty).

### Pitfall 7: Strict drag gating vs. hit-test path
In the drag step the finger may cross non-target tiles (e.g. center) between targets; with "ignore all but the next expected letter" this is harmless. But `LetterGridView` sets `lastTouchedIndex` even for ignored tiles, which is fine. Avoid words requiring a tile twice (repeats). Double-tap on tiles appends the letter twice by design (Phase 10 D-01) — gating handles it because the second touch is not the expected letter unless the word has a double letter.

### Pitfall 8: Pangram step can stall a player
Step 7 is open-ended ("find it"). Add a hint ladder: after 2 rejected submissions or ~25s idle, the banner adds "Hint: it starts with D" and after another ~25s highlights tiles in sequence (reuse the single-target highlighter with the pangram word as the target). Skip link already exists as the escape hatch but should not be the only one. During step 7 allow all tiles/Delete/clear/submit live (no single target) and accept any submission (non-pangram words give normal feedback and count) — advance only on an accepted pangram.

### Pitfall 9: Banner at AX5 / small screens
UI-SPEC: banner drops the step counter and uses title + one sentence at accessibility sizes, scroll capped at 40% height. `playingLayout` is a `VStack` with spacers sized for no banner; inserting the banner may squeeze the grid at AX5. The existing layout was tuned (UX-03 gap fixes: word display single-line shrink-to-fit). Put the banner in `.safeAreaInset(edge: .top)` or at the top of the VStack and verify at AX5 on the smallest available simulator. Note: only iPhone 17e and up are installed (no SE); use iPhone 17e as the smallest-width check (MEDIUM: could not confirm its width vs SE; document as manual check).

### Pitfall 10: Step 8 vs Found Words sheet
Tapping the score bar presents `FoundWordsView` as a sheet; the banner sits behind it. Advance step 8 when the sheet is DISMISSED (use `.sheet(onDismiss:)` on the found-words sheet or `onChange(of: isShowingFoundWords)` false transition), not when it opens, so the Finish step text is not hidden. `roundPhase` stays `.playing`, so the existing `onChange(of: roundPhase)` auto-dismiss does not fire.

### Pitfall 11: Free-play state and Finish highlighting
In free play the Ready card replaces the banner (UI-SPEC) and the Finish button keeps the highlight; all other input live including Settings/Stats. Stats sheet reads `persistenceStore.playerStats()` — fine (shows real stats, practice excluded). `FoundWordsView` reads the practice VM via GameView's `viewModel` — correct because GameView uses the injected practice VM.

### Pitfall 12: Compliance guard on fonts
`scripts/compliance-guards.sh` fails on `Font.system(size:)` outside the whitelist. Use only `GameTheme` font tokens in all tutorial views. Run `bash scripts/compliance-guards.sh` as part of verification.

## Code Examples

### History probe (PersistenceStore)
```swift
// Source: pattern from existing puzzlesPlayedToday() (fetchCount, not fetch().count)
func hasAnyHistory() -> Bool {
    let games = (try? context.fetchCount(FetchDescriptor<GameRecord>())) ?? 0
    let starts = (try? context.fetchCount(FetchDescriptor<RoundStartRecord>())) ?? 0
    return games + starts > 0
}
```

### GameView wiring sketch (only GameView touches VMs)
```swift
struct GameView: View {
    var tutorial: TutorialController? = nil          // nil => normal game; call sites `GameView()` unchanged
    @Environment(GameViewModel.self) private var viewModel   // practice VM when injected by ContentView
    // wrap closures:
    onSubmit: { if tutorial?.allows(.submit) ?? true { viewModel.submitCurrentWord() } }
    // Finish:
    Button { if let tutorial { tutorial.finish() } else { viewModel.finishRound() } }
    // advance events:
    .onChange(of: viewModel.rejectedSubmissionCount) { _, _ in tutorial?.handle(.rejected(viewModel.lastOutcome)) }
    .onChange(of: viewModel.acceptedSubmissionCount) { _, _ in tutorial?.handle(.accepted(viewModel.lastOutcome)) }
    .onChange(of: viewModel.shuffleCount) { _, _ in tutorial?.handle(.shuffled) }
}
```
Existing sound/haptic `onChange` handlers keep working unchanged against the practice VM. Announce on step change: `.onChange(of: tutorial?.step) { announce(title + ". " + instruction) }`.

### Test launch arguments
```swift
// Existing UI tests:
app.launchArguments += ["-hasSeenTutorial", "YES"]
// New tutorial UI test (force show regardless of leftover simulator history):
app.launchArguments += ["-hasSeenTutorial", "NO"]
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `ObservableObject` + `@Published` | `@Observable` (iOS 17) | Controller is a plain `@Observable` class; pass via `.environment(_:)`/init |
| `DragGesture` + overlays to block input | Closure-level gating | Avoids gesture conflicts documented in Phase 3/10 |
| TipKit | Not suited | TipKit shows dismissible tips; cannot script/gate. Not used |

**Deprecated/outdated:** none relevant. `sensoryFeedback`, `AccessibilityNotification.Announcement` are current (already used in the project).

## Open Questions

1. **Exact practice letters** — DOLPHIN/P is the recommended candidate; lock after the validation test and a feel check (is "P" as center natural? alternative center `O`/`N` give bigger lists). Recommendation: lock DOLPHIN/P, curated ~12 words.
2. **Replay end behavior** — recommended: resume the real round untouched (nothing recorded). Alternative (fresh round) costs a free puzzle, violating the spirit of D-12. Planner can adopt "resume".
3. **Where the first-launch hand-off closure lives** — recommended: `TutorialController.onFinished: (() -> Void)?` set by `WordPuzzleApp`; closure calls `gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium)` only when the real VM is `.loading` (first launch), nothing on replay.
4. **iPhone SE-size AX5 verification** — no SE simulator installed; use smallest available (iPhone 17e) and note as manual check.
5. **UI-SPEC "Step N of 9" vs actual sub-steps** (step 4 has two sub-actions, step 7 may have hints): keep 9 displayed steps; sub-steps are internal.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | Build/test | yes | 27.0 (27A266a) | — |
| iOS Simulator (iPhone 17 Pro booted; 17, 17e, Air, 17 Pro Max available) | Unit/UI tests | yes | — | — |
| StoreKit config (WordPuzzle.storekit, wired in scheme Test action) | Paywall-dependent UI tests only | yes | — | — |
| Real device Wi-Fi install script (`scripts/install-on-device.sh`) | Manual device checks (per user memory: automate his checkpoints; test via Wi-Fi install) | assumed (not probed) | — | Simulator |

No blocking missing dependencies.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Unit framework | Swift Testing (`import Testing`, `@Suite`, `@Test`), target `WordPuzzleTests`; shared `WordList` loaded once in `@Suite(.serialized)` suites (Phase 1 decision: avoid parallel word-list loads) |
| UI framework | XCTest/XCUITest, target `WordPuzzleUITests` (3 test classes + launch tests) |
| Config | Scheme `WordPuzzle` (`WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme`) runs both test targets; no test plan file |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests -quiet` |
| Full suite command | same without `-only-testing` (adds UI tests; slower) |
| Compliance | `bash scripts/compliance-guards.sh` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TUT-01 | Step machine: each step's allowed actions, advance conditions, strict gating (wrong letter ignored, only next letter allowed), guided-miss ordering (post-miss text only after rejection), free play after last step | unit | `-only-testing:WordPuzzleTests/TutorialControllerTests` | Wave 0 |
| TUT-01 | Practice puzzle validity (all valid/scripted/miss words in WordList, rules hold, one pangram, no early length-bucket completion by scripted words) | unit | `-only-testing:WordPuzzleTests/PracticePuzzleTests` | Wave 0 |
| TUT-02 | Practice run leaves `puzzlesPlayedToday()`, `totalGamesPlayed()` at 0; finish/skip hand-off yields exactly 1 round start; never `.paywalled`/`.roundOver` | unit (in-memory container) | `-only-testing:WordPuzzleTests/TutorialControllerTests` | Wave 0 |
| TUT-03 | Launch decision: absent+no history -> show; absent+history (GameRecord only, RoundStartRecord only) -> seen set and skip; true -> skip; false -> show; interrupted run leaves flag unset | unit (isolated `UserDefaults(suiteName:)`) | `-only-testing:WordPuzzleTests/TutorialLaunchGateTests` | Wave 0 |
| TUT-03 | `PersistenceStore.hasAnyHistory()` | unit | `-only-testing:WordPuzzleTests/PersistenceStoreTests` (extend) | extend existing |
| TUT-04/05 | Skip/finish set seen; replay does not set/clear anything wrongly and does not touch the real VM (`roundPhase`, `foundWords`, counts unchanged) | unit | `TutorialControllerTests` | Wave 0 |
| TUT-05 | Settings row label frozen, `onHowToPlay` default compiles, existing initializers still compile | unit | `-only-testing:WordPuzzleTests/SettingsViewTests` (extend) | extend existing |
| TUT-06 | Banner copy fits constraints (<= 2 sentences, AX layout flag), Reduce-Motion pulse = 0.5 | unit | `TutorialControllerTests` / `DynamicTypeTests` (extend) | extend |
| TUT-07 | Existing UI tests still pass with `-hasSeenTutorial YES` | UI | `-only-testing:WordPuzzleUITests/StatsPresentationUITests` etc. | edit existing (4 launch sites) |
| TUT-01..05 | End-to-end tutorial on simulator: step through taps, miss, swipe, delete/clear, drag, shuffle, find pangram, tap score bar, Finish -> real board with "Center letter" + counter shows 2 free left; skip path; replay path | UI | `-only-testing:WordPuzzleUITests/TutorialUITests` (launch `-hasSeenTutorial NO`) | Wave 0 |

UI-test notes for the new `TutorialUITests`: tiles have labels `"Letter X"`/`"Center letter X"`; word display label `"Assembled word …"`; reuse the `enter(_:)`/`submit()` helpers from `AppStoreScreenshotTests` (swipe-down 140pt via `press(forDuration:thenDragTo:)`). Add accessibility identifiers `tutorialBanner`, `tutorialSkipLink`, `settingsHowToPlayRow`. The banner must not alter tile labels.

### Sampling Rate
- **Per task commit:** quick unit command above (target the new suites + `SettingsViewTests`, `PersistenceStoreTests`).
- **Per wave merge:** full `-only-testing:WordPuzzleTests` + `bash scripts/compliance-guards.sh`.
- **Phase gate:** full suite incl. UI tests green; manual checks: AX5 on smallest simulator, Reduce Motion, VoiceOver announcement/Skip reachability, device Wi-Fi run of the full tutorial, dark mode.

### Wave 0 Gaps
- [ ] `WordPuzzleTests/TutorialControllerTests.swift` (state machine, gating, free/unrecorded guarantees)
- [ ] `WordPuzzleTests/PracticePuzzleTests.swift` (curated puzzle validity against bundled list)
- [ ] `WordPuzzleTests/TutorialLaunchGateTests.swift` (tri-state flag + history probe; use an isolated `UserDefaults(suiteName:)` injected into the gate function so tests do not touch `.standard`)
- [ ] `WordPuzzleUITests/TutorialUITests.swift`
- [ ] Add `-hasSeenTutorial YES` to: `WordPuzzleUITests.swift` (2 launches), `StatsPresentationUITests.swift`, `AppStoreScreenshotTests.swift`, and check `WordPuzzleUITestsLaunchTests.swift`
- Framework install: none needed.

## Sources

### Primary (HIGH confidence — direct code/doc inspection)
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` (round lifecycle, optional-chained persistence, submit rule order, shuffle gating)
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift`, `LetterGridView.swift`, `WordDisplayView.swift`, `ScoreBarView.swift`, `HexTileView.swift`
- `WordPuzzle/WordPuzzle/WordPuzzleApp.swift`, `ContentView.swift`, `Settings/SettingsView.swift`
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift`, `RoundStartRecord.swift`
- `WordPuzzle/WordPuzzle/PuzzleEngine/PuzzleGenerator.swift` (`stagedPuzzle` is `#if DEBUG`), `WordList.swift`
- `WordPuzzle/WordPuzzleUITests/*.swift`, `scripts/capture-app-store-screenshots.sh`, `scripts/compliance-guards.sh`, scheme XML
- `.planning/phases/11-first-launch-tutorial/11-CONTEXT.md`, `11-UI-SPEC.md`
- Local run: Python analysis of `enable-clean.txt` for practice-letter candidates

### Secondary (MEDIUM confidence)
- Behavior of XCUITest `-key value` launch arguments populating NSArgumentDomain and being read by `UserDefaults.standard`/`@AppStorage` (well-established Cocoa behavior; recommended to confirm with the first UI test run in Wave 0). Not re-verified against Apple docs in this session.

### Tertiary (LOW confidence)
- None relied on.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all pieces exist in the repo.
- Architecture: HIGH for the nil-store VM isolation, flag gating, and closure-level gating (verified in code); MEDIUM for view-hosting details (root swap + Settings dismissal timing needs device/simulator confirmation).
- Pitfalls: HIGH for UI-test breakage, `#if DEBUG` stagedPuzzle, bonus-event interference; MEDIUM for AX5 layout (needs on-device check).
- Practice letters: MEDIUM — validated against word list, subjective "easy" quality.

**Research date:** 2026-10-04
**Valid until:** 2026-11-03 (stable; invalidated only by changes to Phases 6-10 code paths)

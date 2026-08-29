# Phase 3: Core Game UI — Context

**Gathered:** 2026-08-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the real, playable game screen replacing the Phase 2 debug panel: a complete round from puzzle display through word submission, live scoring, shuffle, and an end-of-round missed-words reveal that flows straight into the next puzzle. No daily-limit gating (Phase 4), no sound effects/Dynamic Type polish (Phase 5).

</domain>

<decisions>
## Implementation Decisions

### Letter Grid & Interaction
- **D-01:** Honeycomb hex layout — one center hex visually distinguished (color/border) surrounded by 6 outer hexes, per CLAUDE.md's recommended custom `Shape`/hex-clipped `ZStack` approach.
- **D-02:** Input supports BOTH tap-to-append (tap letters in sequence) AND swipe/drag-to-connect across letters (NYT-style continuous drag). Either path appends to the current word. User explicitly chose this over tap-only despite the added gesture-handling complexity for a first iOS project.
- **D-03:** Shuffle button (PUZZ-04) animates the 6 outer letters into new random positions (`withAnimation` + position swap) — not an instant jump.

### Word Input & Submission
- **D-04:** The in-progress word displays above the hex grid, updating live as letters are tapped/dragged.
- **D-05:** A Delete button removes the last letter; tapping the assembled word itself clears it entirely.
- **D-06:** Submission is a swipe-down gesture on the assembled word (drag it downward past a threshold) — there is NO dedicated Submit button. This was a deliberate, explicit user choice (initially proposed as a two-finger pinch, then revised to swipe-down) — do not substitute a button in planning or research.

### Feedback & Scoring Display
- **D-07:** Invalid word: the word display shakes and shows a generic "Not a valid word" message. Phase 3 does NOT distinguish reasons (already found / too short / missing center letter / not in list) — that granularity is out of scope for this pass.
- **D-08:** Valid word: the word display briefly highlights/pops and shows the points earned ("+N") before clearing, in addition to the required haptic (RET-03).
- **D-09:** Score/progress uses a rank/tier system, not a plain number. Use NYT Spelling Bee's standard 10 tiers and thresholds, expressed as a percentage of the puzzle's maximum possible score:
  - Beginner: 0%
  - Good Start: 2%
  - Moving Up: 5%
  - Good: 8%
  - Solid: 15%
  - Nice: 25%
  - Great: 40%
  - Amazing: 50%
  - Genius: 70%
  - Queen Bee / King Bee: 100%
  - Maximum possible score for a puzzle = `ScoreCalculator.score(for:pangrams:)` applied to ALL of `Puzzle.validWords`, using `Puzzle.pangrams` as the pangram set — computed once when the puzzle is generated.

### Round Structure & Missed-Word Reveal
- **D-10:** A round ends only when the user taps a manual "Finish"/"End Round" button. No timer, no auto-end when all words are found.
- **D-11:** The missed-words reveal screen groups missed words by word length, with any missed pangram(s) specially highlighted.
- **D-12:** Dismissing the missed-words screen immediately starts a new puzzle via the existing `generatePuzzle(from:)` — no separate start/menu screen exists in Phase 3.

### Claude's Discretion
- Exact hex tile sizing/spacing and color palette for center vs. outer letters
- Exact wording of the "+N" points popup and the generic invalid-word message
- Swipe-down gesture distance/velocity threshold to trigger submission, and any visual cue that a word is "armed" to submit
- Whether `persistenceStore.record(score:wordsFoundCount:)` is called at Finish-tap time before or after the missed-words screen renders — planner picks whichever is simplest to test
- Whether `UITextChecker` (CLAUDE.md's secondary validator, intended for rejecting proper nouns) is actually needed in Phase 3 — since the bundled ENABLE word list (`enable-clean.txt`, loaded by `WordList`) only contains valid lowercase dictionary words already, proper nouns would not validate against it regardless of `UITextChecker`. Planner/researcher should confirm whether this makes `UITextChecker` unnecessary for the MVP round-play flow.
- GameViewModel structure and how puzzle/round state (current word, found words, score) is owned — follow CLAUDE.md's MVVM + `@Observable` pattern

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03 define acceptance criteria for Phase 3
- `.planning/ROADMAP.md` §"Phase 3: Core Game UI" — 5 success criteria are the source of truth for what "done" means

### Project Instructions
- `CLAUDE.md` §"Key APIs & Frameworks" — hex tile via custom `Shape`/`ZStack` clip, `ScrollView` + `LazyVStack` for word lists (not `List`), MVVM + `@Observable` architecture, `UITextChecker` as secondary/proper-noun validator only

### Prior Phase Context
- `.planning/phases/01-word-engine-puzzle-generation/01-CONTEXT.md` — D-05 (4-letter word floor), D-08 (UITextChecker deferred to Phase 3+)
- `.planning/phases/02-persistence-entitlements/02-CONTEXT.md` — D-01/D-02 (GameRecord schema and scoring formula, now implemented in `ScoreCalculator`), D-07 (`@Observable` + `.environment()` service pattern)

No external specs or ADRs beyond project files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WordPuzzle/WordPuzzle/PuzzleEngine/PuzzleGenerator.swift` — `generatePuzzle(from: WordList, maxAttempts:)` is the entry point for starting and restarting rounds (D-12)
- `WordPuzzle/WordPuzzle/PuzzleEngine/PuzzleModel.swift` — `Puzzle` (letters, centerLetter, validWords, pangrams, hasPangram) is the round's data source
- `WordPuzzle/WordPuzzle/PuzzleEngine/WordList.swift` — `@Observable`, async `load()`, O(1) `.contains(word)` for word validation (GAME-02)
- `WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift` — `points(for:isPangram:)` and `score(for:pangrams:)` implement the scoring formula (D-09 max-score calc reuses this)
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` — `record(score:wordsFoundCount:date:)` must be called at round end to satisfy RET-02 lifetime-stat accumulation
- `WordPuzzle/WordPuzzle/Services/EntitlementStore.swift` — not consumed by Phase 3 gameplay itself; Phase 4 gates on it

### Established Patterns
- `@Observable final class` for all service/state types (`WordList`, `PersistenceStore`, `EntitlementStore`) — a `GameViewModel` should follow the same pattern
- Services are instantiated in `WordPuzzleApp.swift` and injected via `.environment()`; views read them with `@Environment(Type.self)`

### Integration Points
- **`WordList` is NOT YET wired into `WordPuzzleApp.swift`** — it is currently only exercised in `WordPuzzleTests/`. Phase 3 must instantiate it, call `.load()` (async, e.g. via `.task`), inject it via `.environment()`, and gate puzzle generation until `isLoaded` is true.
- `WordPuzzle/WordPuzzle/ContentView.swift` currently renders `EntitlementDebugPanel` in DEBUG builds — its own header comment states Phase 3 replaces `ContentView` with the real game screen and deletes `EntitlementDebugPanel`. Do this deletion as part of Phase 3.
- `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` is the injection root — a new `GameViewModel` (or equivalent) is added here alongside the existing `persistenceStore` and `entitlementStore`.

</code_context>

<specifics>
## Specific Ideas

- The submit gesture is a swipe/drag-DOWN on the assembled word — this was explicitly chosen over both a Submit button and a two-finger pinch. Do not plan around a button.
- Rank tiers must use the exact NYT Spelling Bee names and percentages listed in D-09 — this is a recognizable system players expect, not a placeholder to be redesigned.
- Missed words must be grouped by length with pangrams highlighted (D-11) — a flat undifferentiated list does not satisfy this decision.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 3 scope. Per-reason invalid-word messaging (already found / too short / missing center letter / not in list) was considered and explicitly deferred past Phase 3 (see D-07) rather than dropped — a future polish phase could add it.

</deferred>

---

*Phase: 03-core-game-ui*
*Context gathered: 2026-08-29*

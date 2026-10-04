# Phase 8: All-Pangrams Bonus - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an extra scoring bonus, with an in-round celebration, for finding EVERY pangram in a puzzle. This sits on top of the existing per-word +7 pangram bonus. It also adds a pangram counter so players can chase the bonus. The rank ladder gets an overflow state and a hidden tier, because the bonus can push score past the puzzle's max.

**Scope addition (user request, same session):** Phase 8 also adds a **length-completion bonus**, awarded for finding every word of a given length (D-14..D-18). Phase 8 is effectively "Completion Bonuses". The directory name stays `08-all-pangrams-bonus`.

Not in scope: changing puzzle generation, capping pangram counts, or redesigning `MissedWordsView` beyond showing the sweep.

### Frequency finding (roadmap item 3, answered during discussion)
I simulated 20,000 puzzles using the real `generatePuzzle` algorithm against `enable-clean.txt`. Pangrams per puzzle:
1 = 22.6%, 2 = 17.2%, 3–5 = 24.9%, 6–10 = 17.4%, 11+ ≈ 18% (long tail up to 86, driven by ENABLE inflections).
Multi-pangram puzzles are the norm. The generator also favors many-pangram letter sets, because it seeds from a uniformly random pangram *word*. The bonus will fire often on small sets and rarely on huge ones. The user accepted this (D-13).

</domain>

<decisions>
## Implementation Decisions

### Bonus Formula & Rank
- **D-01:** Bonus = **+7 per pangram in the puzzle** (`7 × puzzle.pangrams.count`), awarded once when the last pangram is found. The effect: completing the set doubles each pangram's +7 bonus. Example: 3 pangrams → +21 sweep bonus.
- **D-02:** The bonus applies to **every puzzle, including 1-pangram puzzles** (22.6% of puzzles). Finding the only pangram triggers the sweep: +7 pangram bonus, +7 sweep bonus, plus its length points.
- **D-03:** The bonus is added to `score`, so it's also persisted via `finishRound()` → `PersistenceStore.record(score:)`. It is **NOT included in `maxPossibleScore`**. Max score stays `ScoreCalculator.score(for: validWords, pangrams:)`.
- **D-04:** The bonus **counts toward rank**. A player can reach Legend (100%) without finding every word. This was accepted knowingly.
- **D-05:** **Progress can exceed 100%.** `progressFraction` must no longer clamp to 1 for rank/overflow purposes. `ScoreBarView`'s bar fills to full, then shows a **glowing/shimmer overflow cue** for the extra. The `ProgressView` itself can stay clamped, with the overflow drawn as a separate visual.
- **D-06:** **New hidden 11th tier above Legend: "Mythic Grandmaster"** (exact name, as given by the user). It unlocks at **any score > 100% of max** (strictly greater). It is hidden: it doesn't appear as a known next step before you reach it. Add it to `RankTier` (e.g. `case mythicGrandmaster`, threshold just above 100). `tier(score:maxScore:)` logic must treat it as `score > maxScore`, not `>=`. This is the one sanctioned exception to the 03-UI-SPEC "tier names are exact" rule. The name is long, so it must follow the Phase 5 shrink-to-fit pattern (`lineLimit(1)` + `minimumScaleFactor`) and be checked at AX5 on a physical device.

### Moment of Celebration
- **D-07:** The bonus lands **instantly, mid-round**, on the game screen, the moment the last pangram is accepted. It is not deferred to the end of the round.
- **D-08:** Animation: a **pangram-by-pangram tally**. Each pangram flashes or appears in turn while the bonus counter ticks up (+7, +14, +21…), then the total folds into the score. The tally must **speed up for big sets**, so a 40-pangram sweep can't become a long block. Pick a max total duration.
- **D-09:** Copy: **"Pangram sweep! +N"**, where N is the total bonus.
- **D-10:** Sound and haptics: a **new, distinct fanfare clip** from the CC0 Kenney packs (not one of the existing four `SoundEffect` cases). Add a new `SoundEffect` case. Play a **tick per pangram** during the tally and a **strong success haptic** at the end. Respects the existing `soundEffectsEnabled` setting and `.ambient` session (silent switch).

### Pangram Progress Hint
- **D-11:** Show the pangram count in **both places**:
  - **On the board:** a small, always-visible pangram counter/badge near the score bar (e.g. seal icon + "1/3").
  - **In the Found Words sheet** (Phase 7): a "Pangrams · X of N" line. This reverses Phase 7 D-15, which deferred it to this phase.
- **D-12:** The count is a deliberate hint, consistent with Phase 7 D-10's per-length counts.

### Huge Pangram Counts
- **D-13:** **No cap and no generator change.** Puzzles with 20–86 pangrams stay as they are. Sweeping them is a rare, huge feat (e.g. 40 pangrams → +280). `PuzzleGenerator` is untouched this phase.

### Length-Completion Bonus (added mid-session by user request)
- **D-14:** When a player finds **every word of a given length** in the puzzle, award a bonus **equal to that length** (e.g. completing all 5-letter words → +5; all 8-letter words → +8). It's awarded once per length group per round. "All words of length L" is defined over `puzzle.validWords`, the same groups as Phase 7's Found Words sheet (D-11/D-12 there, where a completed group already shows a ✓).
- **D-15:** Scoring follows the **same rules as the pangram sweep**: added to `score` and persisted, **counts toward rank**, **excluded from `maxPossibleScore`**, and can push progress **past 100%** toward Mythic Grandmaster (D-04..D-06).
- **D-16:** Celebration is a **lighter version of the sweep**: a short popup like **"5 Letters complete! +5"**, with a success sound and haptic. **No tally animation**; the tally stays special to the pangram sweep. Copy format: "<L> Letters complete! +<L>" (Claude may tune wording within the playful tone).
- **D-17:** **Stacking:** if one word completes a length group AND the pangram set, award **both bonuses**, celebrated **in sequence**: length popup first, then the pangram sweep tally. If one word could ever complete multiple groups (it can't, since a word has one length), no special case is needed.
- **D-18:** Unit-testable pure function, e.g. `ScoreCalculator.lengthCompletionBonus(length:) -> Int` (returns `length`). The view-model tracks which lengths are already completed so the bonus never double-awards.

### Claude's Discretion
- Exact fanfare clip choice from the Kenney packs, tick sound, haptic type, and the tally's per-step timing and speed-up curve.
- Overflow glow/shimmer styling on the progress bar, and how Mythic Grandmaster looks visually distinct from Legend (e.g. accent glow).
- Board pangram counter: exact placement, icon, and format. What it shows after the sweep (e.g. checkmark/complete state). VoiceOver label.
- How the sweep shows on `MissedWordsView`'s end-of-round header (e.g. a "Pangram sweep! +N" line). Keep it minimal; don't redesign the screen.
- Whether the sweep is modeled as a new `SubmissionOutcome` field/case (e.g. `accepted(..., sweepBonus: Int?)`) or as separate view-model state. Must keep views value-in/closure-out (only `GameView` touches `GameViewModel`).
- Sound for the length-completion popup (reuse an existing clip or a lighter Kenney clip, distinct from the sweep fanfare), and whether the Found Words sheet rows/headers show the bonus earned for a completed group (e.g. "+5" beside the ✓).
- Whether input is blocked during the tally animation (prefer not blocking, or keep the tally short enough that it doesn't matter).
- `ScoreCalculator` gets a pure function for the sweep bonus (e.g. `sweepBonus(pangramCount:)`) so it's unit-testable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §"Phase 8: All-Pangrams Bonus" — goal and the three original open questions (UI, formula, frequency)

### Prior decisions this phase builds on or amends
- `.planning/phases/03-core-game-ui/03-CONTEXT.md` — D-09 rank ladder and max-score definition (amended by D-03..D-06 here); D-11 missed-words pangram highlighting
- `.planning/phases/06-differentiated-invalid-word-messaging/06-CONTEXT.md` — playful copy tone and feedback-intensity patterns
- `.planning/phases/07-found-words-view/07-CONTEXT.md` — Found Words sheet structure; D-14 pangram styling; D-15 deferred the pangram count to this phase (now reversed by D-11)
- `.planning/phases/05-polish-compliance-app-store/` — Kenney CC0 sound sourcing (05-01), Dynamic Type shrink-to-fit pattern and physical-device AX5 requirement (05-06)

No external specs. Requirements are fully captured in the decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Services/ScoreCalculator.swift`: `points(for:isPangram:)` gives +7 per pangram. Add the sweep-bonus function here.
- `PuzzleEngine/PuzzleModel.swift`: `Puzzle.pangrams: [String]` already plural. The count drives the bonus and the counter.
- `Game/GameViewModel.swift`: `pangramSet`, `foundWordSet`, `score`, `maxPossibleScore`, `lastOutcome`, `acceptedSubmissionCount`. The sweep is detectable in `submitCurrentWord()` right after insertion (`pangramSet.isSubset(of: foundWordSet)` and the word just found is a pangram).
- `Game/RankTier.swift`: a 10-case enum with threshold/displayName. Add the Mythic Grandmaster case; `tier(score:maxScore:)` needs the strict `>` rule for it.
- `Services/SoundManager.swift`: `SoundEffect` enum (`word_accepted`, `word_rejected`, `pangram_found`, `round_end` .wav). Add a new case and asset.
- `Game/Views/FoundWordsView.swift`: Phase 7 sheet. Add the "Pangrams · X of N" line.
- `Game/Views/MissedWordsView.swift`: header area for the end-of-round sweep mention.

### Established Patterns
- Counter-based `.sensoryFeedback`/`onChange` triggers (not Bool), so repeated events fire.
- Views are presentation-only (value-in/closure-out). Only `GameView` reads `GameViewModel`.
- `GameTheme` holds all tokens (spacing, colors, motion). No inline magic numbers.
- `progressFraction` currently does `min(1, …)` and `ScoreBarView` clamps the `ProgressView` to 0...1. Both need care for overflow (D-05).

### Integration Points
- `GameViewModel.submitCurrentWord()`: sweep detection and score increment.
- `ScoreBarView`: overflow glow, Mythic Grandmaster display, possibly the board pangram counter.
- `GameView`: hosts the tally overlay/animation and the sound/haptic `onChange` handlers.
- `RankTierTests`, `GameViewModelTests`, `ScoreCalculator` tests: extend for the bonus, the 1-pangram case, the >100% tier, length-completion awards (once per length), and same-word stacking (length + sweep).

</code_context>

<specifics>
## Specific Ideas

- "Scaled per pangram with an animation of accumulations to give visual reward": the visible tally is a core part of the feature, not decoration.
- "Progress bar can extend beyond 100% with rewarding visual cue": overflow must look like a reward, not a glitch.
- Tier name is exactly **"Mythic Grandmaster"**.
- Celebration copy is exactly **"Pangram sweep! +N"**.

</specifics>

<deferred>
## Deferred Ideas

- Capping pangram count in the generator, or removing the sampling bias toward many-pangram letter sets. Considered and declined (D-13). Revisit only if players report big-set puzzles feel unfair.

</deferred>

---

*Phase: 08-all-pangrams-bonus*
*Context gathered: 2026-10-04*

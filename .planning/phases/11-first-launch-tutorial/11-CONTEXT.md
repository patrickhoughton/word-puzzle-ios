# Phase 11: First-Launch Tutorial - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

A first-run onboarding that teaches the core mechanics by having the player do them on a scripted practice puzzle. It is shown once to new installs, can be skipped, and can be replayed from Settings. It is gated by an `@AppStorage` "tutorial seen" flag. Today `ContentView` loads straight into `GameView` and a real round on every launch.

Not in scope: new game mechanics, changes to scoring, rank or the paywall, or analytics on tutorial completion (v1 ships with zero analytics, per Phase 5 D-06).

</domain>

<decisions>
## Implementation Decisions

### Format
- **D-01:** **Scripted practice puzzle.** The format is not overlay coach marks on a random puzzle and not intro cards. On first launch the player gets a fixed, hand-picked practice puzzle with step-by-step prompts. Each step waits for the player to actually perform the action (tap, drag, swipe down, shuffle, and so on) before advancing. The player learns by doing. The deciding reason: swipe-down-to-submit (Phase 3 D-06) has no visible button and has to be performed once to be learned.
- **D-02:** **Strict guided steps.** During a guided step, only the highlighted target (tile, gesture or button) responds and other input is ignored, so the player can't wander off the script. After the last guided step the board is free.
- **D-03:** **Ending: a short free play, then the real puzzle.** After the last teaching step comes a "You're ready!" moment. The player may keep playing the practice board freely, and tapping Finish starts their first real generated puzzle (see D-10). The practice board has **no missed-words reveal** and is **not recorded in stats or history**.
- **D-04:** **Practice puzzle letters are Claude's discretion.** Pick a set with an easy, obvious first word for the "build" step, a findable pangram for the pangram step, a small total word count, and a way to make the guided "missing center letter" miss. Lock the exact letters and center during planning. Reusing the existing `stagedPuzzle(spec:from:)` path is likely, but it is currently gated to the screenshot launch argument.

### What to Teach (all in the practice script)
- **D-05:** **Every mechanic below gets a guided step, all inside the practice puzzle**, with no deferred just-in-time tips during real play. Suggested order (the planner may refine it):
  1. Tap letters to build a word (target tiles highlighted)
  2. Every word needs the gold center letter, taught with **one guided miss** (D-06)
  3. Swipe down on the word to submit it
  4. Delete removes the last letter; tapping the word clears it
  5. Drag across tiles as an alternative to tapping
  6. Shuffle: the button AND double-tap on empty space (Phase 10)
  7. Pangram: a word using all 7 letters is worth bonus points. The player finds it.
  8. The score/rank bar shows progress, and tapping it opens Found Words (Phase 7)
  9. Finish Round ends a puzzle (D-10)
  Keep each step short. The target is roughly a 2-minute tutorial.
- **D-06:** **One guided mistake.** One step deliberately has the player build a word without the center letter and submit it, so they see the real rejection feedback (shake + "missing center letter" message from Phase 6) before the rule is explained or confirmed. Every other scripted step is a success.

### Free Tier & Existing Users
- **D-07:** **The practice puzzle is free.** It must NOT call `recordRoundStarted()` and must NOT count toward the 3 free puzzles a day (`puzzlesPlayedToday`). It must NOT write a `GameRecord`. A new player still gets all 3 real puzzles on day one. The tutorial must also never trigger the paywall gate.
- **D-08:** **New installs only.** On launch, if any game history already exists (any `GameRecord` or `RoundStartRecord`), treat the tutorial as already seen: set the flag and skip it. Existing and updating players never see it automatically.
- **D-09:** A player with a new install and no history sees the tutorial even if they are premium (for example, a restored purchase on a new device). They can skip it (D-11).

### Finish Step
- **D-10:** **The Finish step explains the button, and tapping it starts the real puzzle.** Example copy: "When you're done, tap Finish to see the words you missed. Tap it now to start your first real puzzle!" During the tutorial, Finish skips the missed-words screen, then marks the tutorial seen and calls the normal `requestNextRound(isPremium:)` path.

### Skip, Replay & Interruption
- **D-11:** **A small "Skip tutorial" link is always visible** during the tutorial. It's low-key and needs no confirmation. Skipping marks the tutorial as seen and starts a real puzzle through the normal path.
- **D-12:** **Replay from Settings → "How to Play".** This is a new row in `SettingsView`, alongside Sound Effects and Stats. It restarts the practice puzzle from step 1. Replay must not cost a free puzzle or corrupt the in-progress real round. Whether the real round resumes afterward or a fresh one starts is the planner's call, but it must not record an extra round start or lose saved stats.
- **D-13:** **An interrupted tutorial restarts from step 1.** Only completing (D-10) or skipping (D-11) sets the "seen" flag. Quitting or backgrounding mid-tutorial leaves it unset, so the next launch starts the tutorial over. The step index is not persisted.

### Claude's Discretion
- **Prompt UI:** a fixed text banner + a glowing or pulsing highlight on the target, or pointing speech bubbles. The planner and UI phase pick. Whatever is chosen must survive Dynamic Type up to AX5 and respect Reduce Motion (Phase 5 D-04/D-05, Phase 9 D-18/D-19). A fixed banner is the safer default for AX5.
- The exact tutorial copy, which must be playful and consistent with Phase 6's tone.
- The practice letters (D-04).
- How the tutorial state machine is structured (inside `GameViewModel`, a separate `TutorialViewModel` or controller, and so on), and how "only the target responds" input filtering is done.
- Sounds and haptics during the tutorial. The default is the normal game feedback for real actions.
- VoiceOver handling of the guided steps. At minimum the steps must be announced and the Skip link must be reachable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` § "Phase 11: First-Launch Tutorial": the phase goal and its promotion from backlog 999.4
- `.planning/PROJECT.md`: validated requirements list (which mechanics exist to teach)

### Mechanics being taught (prior decisions)
- `.planning/phases/03-core-game-ui/03-CONTEXT.md`: D-01 to D-06 (honeycomb, tap+drag input, delete/clear, swipe-down submit, no Submit button), D-10 to D-12 (Finish Round, missed-words reveal, no start screen)
- `.planning/phases/03-core-game-ui/03-UI-SPEC.md`: layout, spacing scale and theme tokens
- `.planning/phases/06-differentiated-invalid-word-messaging/06-CONTEXT.md`: rejection reasons and copy tone (used by the D-06 guided miss)
- `.planning/phases/07-found-words-view/07-CONTEXT.md`: the score bar is the tap target for Found Words
- `.planning/phases/08-all-pangrams-bonus/08-CONTEXT.md`: pangram bonus and celebrations (what the pangram step may trigger)
- `.planning/phases/10-double-tap-shuffle/10-CONTEXT.md`: double-tap empty space to shuffle, and the `.playing` gating

### Free tier & persistence
- `.planning/phases/04-paywall-free-tier-gate/04-CONTEXT.md`: D-01/D-02 (paywall triggers; every round start counts, abandoned ones included). The tutorial must bypass this counting (D-07).
- `.planning/phases/05-polish-compliance-app-store/05-CONTEXT.md`: Dynamic Type and AX5 rules, Settings scope, and no analytics

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `stagedPuzzle(spec:from:)` (`WordPuzzle/WordPuzzle/PuzzleEngine/PuzzleGenerator.swift:47`): builds a fixed puzzle from a spec like `harmony:r`. It's used by the screenshot staging path in `GameViewModel.startNewRound()` (`GameViewModel.swift:193-201`). It can build the practice puzzle.
- `GameViewModel.startNewRound(with:)` (`GameViewModel.swift:217`) calls `persistenceStore?.recordRoundStarted()`, so the tutorial needs a start path that skips this (D-07).
- The `@AppStorage` flag pattern: `SoundManager.soundEffectsEnabledKey` declares the key, and GameView reads it. Mirror this for the tutorial-seen key.
- `SettingsView` already has the `NavigationLink` row style used for "Stats", so "How to Play" can copy it. The view is value-in/closure-out, so add a closure such as `onHowToPlay`.
- Existing feedback: the `WordDisplayView` shake and rejection message, `.sensoryFeedback` counter triggers, and `SoundManager`.

### Established Patterns
- `GameView` is the ONLY view that touches `GameViewModel`. All children are value-in/closure-out (Phase 3/4 rule). Tutorial overlays and banners should follow this.
- `roundPhase` (`.loading/.playing/.roundOver/.paywalled`) drives the root switch and the `fullScreenCover`. Adding a tutorial mode must not make the cover present (no missed-words screen or paywall during the tutorial).
- Launch sequence (`WordPuzzleApp.swift` `.task`): refresh entitlements → load product → load word list → `requestNextRound(isPremium:)`. The tutorial decision fits after the word list loads, in place of or before `requestNextRound`.
- Shuffle is phase-gated and returns a Bool (Phase 10). The gestures in `LetterGridView` and the background double-tap layer are where "only the target responds" filtering would hook in.

### Integration Points
- `WordPuzzleApp.swift` launch `.task`: branch to the tutorial on first launch (D-08 history check).
- `GameView`: the tutorial banner, highlight overlay and Skip link; the Finish-button behavior in tutorial mode (D-10).
- `SettingsView`: the new "How to Play" row (D-12).
- `PersistenceStore`: history-existence check for D-08 (any `GameRecord` or `RoundStartRecord`).

</code_context>

<specifics>
## Specific Ideas

- The user wants the tutorial to teach by doing, especially swipe-down-to-submit.
- The user wants everything taught in a single scripted pass, not spread across later tips.
- Example step copy from the discussion: "Tap these letters to spell ___", "Now swipe down on your word to submit it", "When you're done, tap Finish to see the words you missed. Tap it now to start your first real puzzle!"

</specifics>

<deferred>
## Deferred Ideas

- Just-in-time contextual tips during real play (considered as a pacing option and rejected in favor of D-05). Not backlogged.

</deferred>

---

*Phase: 11-first-launch-tutorial*
*Context gathered: 2026-10-04*

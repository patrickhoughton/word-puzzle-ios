# Phase 6: Differentiated Invalid-Word Messaging - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the single generic "Not a valid word" rejection message (Phase 3 D-07) with distinct, reason-specific feedback. `GameViewModel.submitCurrentWord()` must report WHY a word was rejected, and `WordDisplayView` must show a different message (and, for duplicates, different feedback intensity) per reason. No new screens, no logging/analytics of rejected words (that is backlog 999.10), no change to which words are valid.

</domain>

<decisions>
## Implementation Decisions

### Rejection Reasons
- **D-01:** Four player-facing reasons. The five existing guard checks in `submitCurrentWord()` map as follows:
  | Check | Reason |
  |-------|--------|
  | `word.count < 4` | too short |
  | missing `puzzle.centerLetter` | missing center letter |
  | `foundWordSet.contains(word)` | already found |
  | letters not ⊆ `puzzle.letters` | not a word (folded in, because tap/drag input can't produce outside letters) |
  | `!wordList.contains(word)` | not a word |
- **D-02:** Expose a typed reason: `SubmissionOutcome.rejected` becomes `.rejected(reason: RejectionReason)` (or equivalent), with an enum covering the four reasons. The view maps reason → text. Unit tests in `GameViewModelTests` assert each reason. Later features (999.10 rejected-word logging) key off `.notInWordList`-style reason only.

### Message Wording
- **D-03:** Playful tone. Use these exact strings:
  - Too short → **"Too tiny!"**
  - Missing center letter → **"Forgot the middle!"**
  - Already found → **"Got that one already"**
  - Not a word (dictionary or outside letter) → **"Hmm, not a word"**
- **D-04:** Fixed text only. Don't interpolate the word or the center letter into messages.

### Feedback Intensity
- **D-05:** **Already found = gentler feedback:** no shake, a single light haptic (not the double heavy `UIImpactFeedbackGenerator` burst), NO `wordRejected` sound, and the message shown in a neutral/secondary color, not `GameTheme.errorColor`. The player wasn't wrong, they just forgot.
- **D-06:** Too short, missing center letter, and not a word keep today's full rejection feedback unchanged: shake + double heavy haptic + `wordRejected` sound + error color. Only their text changes.

### Precedence
- **D-07:** When several checks fail, report the first failure in rule order: too short → missing center letter → (outside letter / already found / not in word list, in the existing guard order). Example: "cat" in a puzzle without C as center → "Too tiny!". This matches the current guard sequence, so a found word is "already found" before any dictionary lookup.

### Claude's Discretion
- Exact enum/case names and whether `rejectedSubmissionCount` still increments for duplicates or a separate counter/trigger is used. Whatever is chosen, the duplicate path must NOT play the reject sound (GameView's `onChange(of: rejectedSubmissionCount)` currently plays it unconditionally; `SoundEffect.forSubmission` may need the reason).
- Which neutral color token to use for the duplicate message (e.g. `GameTheme` secondary text color), and which light haptic (`.sensoryFeedback(.impact(weight: .light))` or similar).
- Message display duration (keep current timing unless it reads poorly).
- VoiceOver announcement of the reason. Nice to have if trivial; not required.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & prior decisions
- `.planning/ROADMAP.md` §"Phase 6: Differentiated Invalid-Word Messaging" — phase goal
- `.planning/phases/03-core-game-ui/03-CONTEXT.md` — D-07 (original generic rejection: shake + message), D-08 (accept feedback)
- `.planning/phases/05-polish-compliance-app-store/05-CONTEXT.md` — D-01 (SFX events incl. word rejected), D-04 (Dynamic Type: messages must scale), D-06 (no analytics in v1)
- `.planning/ROADMAP.md` §"Phase 999.10" — future consumer of the "not in dictionary" reason; not in scope here

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift:5` — `SubmissionOutcome` enum (`.accepted(word:points:isPangram:)`, `.rejected`), to be extended with a reason
- `GameViewModel.swift:173` `submitCurrentWord()` — single combined `guard` (lines 180-184) to split into ordered per-reason checks
- `Game/Views/WordDisplayView.swift:113` `showRejectedFeedback()` — shake + double heavy haptic + hardcoded "Not a valid word"; `feedbackIsError` toggles error color
- `Services/SoundManager.swift` `SoundEffect.forSubmission(accepted:isPangram:)` — picks the reject sound; needs to account for the duplicate exemption
- `WordPuzzleTests/GameViewModelTests.swift` — existing submission tests to extend per reason; `SoundManagerTests.swift` covers `forSubmission`

### Established Patterns
- Counter-based triggers (`acceptedSubmissionCount` / `rejectedSubmissionCount`) drive haptics and sounds via `onChange`, never Bools (RESEARCH Pitfall 3 from Phase 3)
- Guard order in `submitCurrentWord()` must stay consistent with `PuzzleGenerator.isValidPuzzleWord` (comment at line 178)
- Fonts come from `GameTheme` relative text styles (Phase 5 Dynamic Type)

### Integration Points
- `Game/Views/GameView.swift:102` — `onChange(of: rejectedSubmissionCount)` plays the reject sound; passes `lastOutcome`/`rejectedCount` into `WordDisplayView` (~line 152)

</code_context>

<specifics>
## Specific Ideas

- Messages are the playful set exactly as listed in D-03. The user picked them from a preview over the plainer options.
- Duplicate submissions should feel like a friendly reminder, not a mistake.

</specifics>

<deferred>
## Deferred Ideas

- Rejected-word logging (backlog 999.10) can reuse the new reason enum later. Out of scope here.
- A separate "uses a letter not in the puzzle" message isn't needed while input is tap/drag only. Revisit if keyboard input is ever added.

</deferred>

---

*Phase: 06-differentiated-invalid-word-messaging*
*Context gathered: 2026-10-04*

# Phase 7: Found Words View - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

An in-round view that lets the player see the words they've already found during the current round, grouped by word length (same organizing pattern as `MissedWordsView`'s round-end reveal). `GameViewModel.foundWords` already tracks these; this phase only surfaces them. The round-end `MissedWordsView` is NOT changed.

</domain>

<decisions>
## Implementation Decisions

### Entry Point & Presentation
- **D-01:** The entire `ScoreBarView` becomes the tap target. Tapping it opens the found-words list as a `.sheet` — no new top-bar button, no inline strip.
- **D-02:** `ScoreBarView` gets a small chevron (`›`, e.g. SF Symbol `chevron.right`) after the "12 of 31 words" text as the tappability cue. VoiceOver: the bar is exposed as a button with a hint that it shows found words.
- **D-03:** Sheet uses `.presentationDetents([.medium, .large])` — opens at half height, draggable to full.
- **D-04:** The sheet is modal (standard sheet behavior) — the board is NOT interactive while the sheet is open, at either detent.
- **D-05:** Sheet has a "Done" button (same pattern as `SettingsView`) AND supports swipe-to-dismiss.

### Ordering & Layout
- **D-06:** Length groups ordered shortest first (4 Letters, 5 Letters, …) — matches `MissedWordsView`.
- **D-07:** Words within a group are alphabetical (NOT order found, even though `foundWords` is stored most-recent-first).
- **D-08:** One word per row, reusing `MissedWordsView`'s row styling (secondarySurface rounded background, `GameTheme.bodyFont`).

### Row & Group Content
- **D-09:** Sheet header: title "Found Words" plus subtitle "<Rank> — N of M words" — same subtitle format as `MissedWordsView`'s header.
- **D-10:** Group header shows found-of-total for that length: e.g. **"4 Letters · 3 of 9"**. This is a deliberate hint (reveals how many words of each length exist) — user chose it knowingly over a hint-free header.
- **D-11:** EVERY word length that exists in the puzzle's `validWords` gets a group header, including lengths with zero found (e.g. "7 Letters · 0 of 2"). Empty groups show the header only, no rows.
- **D-12:** A completed group (found == total) shows a checkmark on its header in the accent color, e.g. "5 Letters · 4 of 4 ✓".
- **D-13:** Each row shows the points that word earned, right-aligned, as "+N" (via `ScoreCalculator.points(for:isPangram:)` — e.g. a 7-letter pangram shows "+14").
- **D-14:** Pangrams are identified EXACTLY as in `MissedWordsView`: word text in `GameTheme.accent` + `Label("Pangram", systemImage: "checkmark.seal.fill")` badge in accent. Accessibility label "<word>, pangram".
- **D-15:** No separate pangram count/hint line ("Pangrams: 1 of 2") — that overlaps Phase 8 (all-pangrams bonus).

### Empty State & Scope
- **D-16:** Before any word is found, the sheet still opens: shows all group headers at "0 of N" plus a short friendly nudge line at the top (playful tone consistent with Phase 6, e.g. "No words yet — get swiping!"). The score bar is tappable at all times during `.playing`.
- **D-17:** `MissedWordsView` is left completely alone this phase — no shared-component refactor, no visual change.

### Claude's Discretion
- Exact nudge-line copy (playful, short).
- Exact separator/format of group header ("·" vs "—") and the checkmark glyph/symbol.
- Whether group data is a new view-model computed property (e.g. `foundWordGroups` with `found`/`total` per length) or a new struct alongside `MissedWordGroup` — must keep the view value-in/closure-out (only `GameView` touches `GameViewModel`).
- Dynamic Type handling for the "+N" column and header at accessibility sizes (follow Phase 5 shrink-to-fit patterns).
- Whether the found-words sheet is a new file `FoundWordsView.swift` in `Game/Views/` (expected).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & prior decisions
- `.planning/ROADMAP.md` §"Phase 7: Found Words View" — phase goal (promoted from backlog 999.2)
- `.planning/phases/03-core-game-ui/03-CONTEXT.md` — D-11 (group by length, pangrams highlighted), MVVM/presentation-only view rules
- `.planning/phases/03-core-game-ui/03-UI-SPEC.md` — spacing scale, ScrollView+LazyVStack (never `List`) rule
- `.planning/phases/05-polish-compliance-app-store/05-CONTEXT.md` — D-04 Dynamic Type migration (relative text styles)
- `.planning/phases/06-differentiated-invalid-word-messaging/06-CONTEXT.md` — D-03 playful copy tone

### Code to mirror / integrate with
- `WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift` — row styling, pangram badge, header subtitle format to replicate (do not modify)
- `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift` — becomes tappable + gets chevron
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` — owns sheet state; existing Settings `.sheet` is the pattern
- `WordPuzzle/WordPuzzle/Settings/SettingsView.swift` — Done-button sheet pattern
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` — `foundWords`, `pangramSet`, `missedWordGroups`/`MissedWordGroup`, `puzzle.validWords`
- `WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift` — `points(for:isPangram:)` for "+N"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MissedWordsView.wordRow(_:)`: exact row + pangram badge styling to replicate (copy, not refactor — D-17).
- `GameViewModel.missedWordGroups`: `Dictionary(grouping:by: \.count)` pattern; the found-words version needs totals per length from `puzzle.validWords` too.
- `ScoreCalculator.points(for:isPangram:)`: per-word points.
- `GameTheme` tokens: `accent`, `secondarySurface`, `headingFont`, `bodyFont`, `labelFont`, `displayFont`, spacing `sm/md/lg`, `minTapTarget`.

### Established Patterns
- Only `GameView` reads `GameViewModel`; child views take values + closures and have `#Preview`s.
- Sheets: `@State private var isShowing...` in `GameView` + `.sheet(isPresented:)` (Settings).
- Lists: `ScrollView` + `LazyVStack`, never `List`.
- Text uses `.lineLimit(1).minimumScaleFactor(0.5)` shrink-to-fit in tight rows.

### Integration Points
- `GameView.playingLayout` — wrap `ScoreBarView` in a `Button` (or add tap gesture) that toggles the new sheet state.
- `GameView` `.sheet` modifier chain — add the found-words sheet next to Settings.

</code_context>

<specifics>
## Specific Ideas

- Pangrams must look identical to the missed-words view (user's explicit request).
- Group-header "found of total" counts are an intentional hint feature, and zero-count lengths are shown so the hint is complete.

</specifics>

<deferred>
## Deferred Ideas

- Shared row/pangram-badge component between FoundWordsView and MissedWordsView. Declined for this phase; possible later cleanup.
- Pangram count hint ("Pangrams: 1 of 2"). Belongs with Phase 8 (all-pangrams bonus).

</deferred>

---

*Phase: 07-found-words-view*
*Context gathered: 2026-10-04*

---
phase: 08
slug: all-pangrams-bonus
status: approved
reviewed_at: 2026-10-04
shadcn_initialized: false
preset: none
created: 2026-10-04
---

# Phase 8 — UI Design Contract

> Visual and interaction contract for Completion Bonuses (pangram sweep, length completion, overflow progress, Mythic Grandmaster tier, pangram counter).
> Source of truth for decisions: 08-CONTEXT.md D-01..D-18 (locked). Tokens: `GameTheme.swift`. Phase 3/5/7 UI-SPECs still apply; this spec only adds to them.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (native SwiftUI, iOS 17; design system = `GameTheme` enum) |
| Preset | not applicable |
| Component library | none (SwiftUI built-ins) |
| Icon library | SF Symbols (`checkmark.seal.fill`, `checkmark.seal`, `sparkles`, `checkmark.circle.fill`) |
| Font | System (SF), Dynamic Type text styles via `GameTheme` fonts |

---

## Spacing Scale

Reuses `GameTheme` tokens (multiples of 4). No new spacing tokens.

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| xs | 4pt | Icon-to-text gap in pangram counter; gap between group title and "+N" bonus |
| sm | 8pt | Spacing inside the detail row; gap between tally counter and pangram word |
| md | 16pt | Celebration card/pill internal padding (horizontal); header padding |
| lg | 24pt | Sweep card vertical padding; distance from top of board area to overlay |
| xl / xxl | 32 / 48pt | (unused) |

Exceptions: overflow glow shadow radius 8pt and overflow bar height equals existing ProgressView height (system default); celebration card corner radius 12pt (matches ScoreBarView card). Add `GameTheme.celebrationCornerRadius = 12` only if the executor wants to avoid the literal; otherwise reuse 12 as ScoreBarView does.

---

## Typography

Reuse the existing 4 roles, 2 weights (regular, semibold). No new fonts or sizes.

| Role | Token | Size | Weight | Line Height | Used for in this phase |
|------|-------|------|--------|-------------|------------------------|
| Display | `displayFont` | 34pt | semibold | system default | Sweep tally running counter "+14" (monospaced digits) |
| Heading | `headingFont` | 20pt | semibold | system default | "Pangram sweep! +N" final headline; "5 Letters complete! +5" pill text; "Mythic Grandmaster" rank name |
| Body | `bodyFont` | 17pt | regular | system default | Flashing pangram word in tally |
| Label | `labelFont` | 13pt | regular | system default | Board pangram counter "1/3"; "Pangrams · X of N" line; "+5" group bonus; missed-words sweep line |

Rules:
- Every new text element: `.lineLimit(1).minimumScaleFactor(0.5)` (Phase 5 shrink-to-fit). Never wraps, never grows layout.
- Tally counter and pangram counter use `.monospacedDigit()` so numbers do not jitter while ticking.
- "Mythic Grandmaster" (18 chars) shares the rank-name slot in `ScoreBarView`, already `lineLimit(1)` + `minimumScaleFactor(0.5)`. Must be verified at AX5 on a physical device (Phase 5-06 requirement). `Text(rank.displayName)` unchanged.
- Line height: system default; no `.lineSpacing`.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `GameTheme.dominant` | Screen background |
| Secondary (30%) | `GameTheme.secondarySurface` | Celebration card and pill backgrounds, ScoreBarView card, counter chip |
| Accent (10%) | `GameTheme.accent` (honeycomb gold #F5B800) | See reserved list |
| Destructive | n/a | No destructive actions; `errorColor` not used |

Accent reserved for (this phase's additions, on top of Phases 3/7 lists):
1. Sweep tally counter, "Pangram sweep! +N" headline text, and its `checkmark.seal.fill` icon
2. Length-completion pill "+N" amount and its `checkmark.circle.fill` icon (label text stays primary)
3. Overflow glow/shimmer on the progress bar (progress > 100%)
4. "Mythic Grandmaster" rank name plus leading `sparkles` icon (Legend and below stay primary)
5. Board pangram counter icon turns accent when all pangrams are found (`checkmark.seal.fill`); icon is secondary while incomplete
6. "Pangrams · X of N" line seal icon, only when X == N
7. Missed-words header "Pangram sweep! +N" line (only when earned)

Not accent: counter numbers "1/3" (secondary), "+5" next to group checkmark in Found Words (secondary), celebration card backgrounds (secondarySurface), card borders (none).

---

## Layout and Interaction Contract

### 1. Board pangram counter (D-11, D-12)
- Location: `ScoreBarView`, new "detail row" between the title row and the `ProgressView`. HStack: counter chip (leading) · Spacer · existing free-puzzles text (trailing, when present). Row always renders, so layout height is stable between free and premium users.
- Chip: `HStack(spacing: xs) { Image(systemName: pangramsComplete ? "checkmark.seal.fill" : "checkmark.seal"); Text("\(foundPangrams)/\(totalPangrams)") }`, `labelFont`, secondary color (icon accent when complete). No background pill; plain inline (avoids another surface).
- `ScoreBarView` stays value-in: new params `foundPangrams: Int`, `totalPangrams: Int`, `isOverflow`/`progress` (see below). No view-model coupling.
- Counter updates with `.contentTransition(.numericText())` inside `withAnimation(.default)`; disabled under Reduce Motion.
- Accessibility: part of the existing combined label, appended: "1 of 3 pangrams found." Do not add a separate focus stop. Row must not push the control row off screen at AX5; verify on device (no ScrollView in the playing layout).
- Free-puzzles line moves into the detail row (trailing); its copy and shrink-to-fit are unchanged.

### 2. Progress overflow (D-05)
- `progressFraction` is unclamped (may be > 1). The `ProgressView` stays clamped to 0...1 and renders full.
- Overflow cue when `progress > 1`: an accent gradient shimmer (a narrow `LinearGradient` highlight, white at 0.6 opacity to clear, 40% of bar width) sweeping left to right across the full bar every 2.0s (`.linear` repeatForever), plus a static accent glow `shadow(color: accent.opacity(0.6), radius: 8)` on the bar. Overlay on the `ProgressView`, `allowsHitTesting(false)`, clipped to the bar's capsule/frame.
- Reduce Motion (`accessibilityReduceMotion`): no shimmer; static glow only.
- Not shown at exactly 1.0 (strict `>`); at 1.0 the bar is plain full (Legend, unchanged from today).
- Accessibility: append "Progress beyond maximum." to the combined label when overflow.

### 3. Mythic Grandmaster tier (D-06)
- `RankTier.mythicGrandmaster`, displayName exactly "Mythic Grandmaster". Hidden: no UI lists the next tier.
- Display in `ScoreBarView` title row: `HStack(spacing: xs) { Image(systemName: "sparkles"); Text(name) }` in accent, `headingFont`, shrink-to-fit. The same rank string flows to Found Words subtitle and MissedWordsView subtitle as plain text (icon only in ScoreBarView).
- Entering the tier is not separately celebrated (the sweep/length celebration already fires). A `.numericText`-style crossfade of the rank name (`.contentTransition(.opacity)`) is enough.
- Subtitles elsewhere ("<Rank> — N of M words") use the existing label style, with no accent.

### 4. Pangram sweep tally (D-07..D-10)
- Trigger: the accepted word completes the pangram set (including the 1-pangram case, D-02). Fires instantly mid-round. Input is NOT blocked (overlay is `allowsHitTesting(false)`; the board remains usable). The new score is applied to the score bar when the tally folds.
- Host: an overlay in `GameView`'s playing layout, anchored `.top` over the letter-grid region with `lg` top padding (clear of the word display and score bar). Card: `secondarySurface` background, 12pt corner radius, `md` horizontal and `lg` vertical padding, subtle shadow (black 0.15, radius 8). Max width = grid width.
- Card content (VStack, spacing `sm`, centered):
  1. Running counter: `displayFont`, accent, monospaced digits: "+7", "+14", ... "+N".
  2. Current pangram word: `bodyFont`, primary, uppercase as displayed on board (words stored lowercase in model; show `.uppercased()`).
  3. Final frame replaces both with `headingFont` accent: seal icon + "Pangram sweep! +N".
- Sequence: card scales in from 0.9 and fades (0.15s `.spring(response: 0.3, dampingFraction: 0.7)`) -> N steps (counter increments by 7, word changes) -> final headline holds 0.8s -> fade out 0.3s while score bar updates.
- Step timing: `stepDuration = clamp(1.2s / N, min 0.03s, max 0.3s)`. Max total tally (steps) = 1.2s for any N; the 1-pangram case is a single 0.3s step. Total card lifetime max = 0.15 + 1.2 + 0.8 + 0.3 = about 2.45s.
- For steps shorter than 0.08s (N > 15) skip showing individual words; show only the counter ticking, but still tick sound is throttled (below).
- Sound/haptic: tick per step using the lightest tick (new `SoundEffect.sweep_tick`, or reuse `word_accepted` at reduced rate; planner/executor choice), at most 12 ticks total (for N > 12, tick every ceil(N/12)-th step). On the final frame: new `SoundEffect.pangram_sweep` fanfare (distinct Kenney CC0 clip, not the existing four) + `.sensoryFeedback(.success, trigger: sweepCount)` (counter-based trigger). Respects `soundEffectsEnabled` and the `.ambient` session.
- Reduce Motion: no scale, no per-step animation. Show the final "Pangram sweep! +N" card with a plain 0.2s crossfade, hold 1.0s, fade 0.2s. Sound and haptic unchanged (single fanfare, no ticks).
- Accessibility: card is `accessibilityHidden(true)`; instead post `AccessibilityNotification.Announcement("Pangram sweep! plus \(N) points")` once at the end. VoiceOver must not receive the intermediate counts.
- Stacking (D-17): if the same word also completes a length group, show the length pill first (its full ~1.5s lifetime), then the sweep card. Queue them in the view model/GameView sequentially; the score applies per event as each celebration finishes (or both at the start of the sequence; executor's choice, but the final score must be identical).

### 5. Length-completion pill (D-14..D-17)
- Trigger: an accepted word completes all words of its length (once per length per round).
- Pill: `secondarySurface` background in `Capsule()`, padding `sm` vertical / `md` horizontal, `checkmark.circle.fill` accent icon, text "5 Letters complete! +5" in `headingFont` (primary text; the "+5" run accent via `Text` concatenation or `AttributedString`). Anchored at the same top overlay position as the sweep card.
- Motion: slide down 8pt + fade in over 0.2s, hold 1.0s, fade out 0.3s (total 1.5s). No tally. Reduce Motion: crossfade only, no offset.
- Sound/haptic: a light success clip distinct from the sweep fanfare (reuse `pangram_found` or a new lighter Kenney clip; discretion) + `.sensoryFeedback(.success, trigger: lengthBonusCount)`.
- If a normal accepted-word feedback (word_accepted sound/haptic) also fires for the same submission, the completion sound replaces it (do not double-play; sweep fanfare replaces `pangram_found`).
- Accessibility: pill `accessibilityHidden(true)`; post `AccessibilityNotification.Announcement("5 letters complete, plus 5 points")`.
- Rapid successive bonuses (a different length completed within 1.5s of the previous): queue sequentially, never overlap; at most 2 queued (a single word can produce at most 2).

### 6. Found Words sheet additions (D-11, Phase 7 amended)
- Header: below the existing subtitle ("<Rank> — N of M words"), add a line "Pangrams · X of N" (`labelFont`, secondary, `xs` above), preceded by `checkmark.seal` (secondary) icon with `xs` gap; when X == N: `checkmark.seal.fill` accent. This reverses Phase 7 D-15.
- Completed group header (found == total): after the accent `checkmark.circle.fill`, append "+L" (`labelFont`, secondary, `xs` gap) showing the earned length bonus. Accessibility: group label becomes "4 letters, 9 of 9 found, complete, plus 4 bonus points".
- `FoundWordsView` gains `foundPangrams: Int` and `totalPangrams: Int` params (value-in); the group struct gains `bonus: Int?` (nil unless complete) or the view computes `length` itself (it equals the group length; prefer passing nothing new and showing `+\(group.length)`).
- Previews to add: all pangrams found; group complete with bonus.

### 7. MissedWordsView additions
- If a sweep occurred this round, add one line under the subtitle: `Label("Pangram sweep! +N", systemImage: "checkmark.seal.fill")`, `labelFont`, accent, `sm` above. If length bonuses were earned, one more line below in secondary: "Length bonuses +M" (`labelFont`). Params: `sweepBonus: Int` (0 = hide), `lengthBonusTotal: Int` (0 = hide). No other redesign; header spacing stays `sm`.
- The final score is not otherwise displayed (rank-based progress per D-09 of Phase 3).

### States
| State | Behavior |
|-------|----------|
| Sweep earned (N pangrams) | Tally card, fanfare, success haptic, counter chip turns complete |
| 1-pangram puzzle | Single-step tally (+7), same final headline |
| Length group completed | Pill + light sound + haptic, once per length per round |
| Same word completes group + sweep | Pill first, then sweep card (sequential) |
| Score > 100% of max | Bar full + shimmer/glow, rank "Mythic Grandmaster" with sparkles |
| Score exactly 100% | Legend, plain full bar |
| Reduce Motion on | Crossfades only; no shimmer; no per-step animation |
| Sound effects off | Visual celebration and haptics still play; no sound |
| Round ends mid-celebration | Dismiss overlays immediately; MissedWordsView takes over |
| Next round starts | Reset sweep/length-completed state, counter "0/N", overlays cleared |
| Shuffle/typing during tally | Allowed, no blocking |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | none new (existing "Next Puzzle", "Done" unchanged) |
| Sweep headline | "Pangram sweep! +N" (exact, N = 7 x pangram count) |
| Length-completion pill | "<L> Letters complete! +<L>" (e.g. "5 Letters complete! +5") |
| Hidden tier name | "Mythic Grandmaster" (exact) |
| Board counter | "1/3" (icon + fraction) |
| Found Words line | "Pangrams · 1 of 3" |
| Group bonus | "+5" beside the completed-group checkmark |
| Missed words sweep line | "Pangram sweep! +N"; secondary line "Length bonuses +M" |
| VoiceOver announcements | "Pangram sweep! plus N points"; "5 letters complete, plus 5 points" |
| Counter VoiceOver (in ScoreBar label) | "1 of 3 pangrams found." / "Progress beyond maximum." |
| Empty state | none (counter shows "0/N") |
| Error state | none: no failure paths in this phase |
| Destructive confirmation | none: no destructive actions in this phase |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none (not applicable, native SwiftUI) | not required |
| Third-party | none | not applicable |

No third-party dependencies. New audio assets must be CC0 (Kenney packs), recorded in the Phase 5 sound-attribution list.

---

## Pre-Populated From

| Source | Decisions Used |
|--------|---------------|
| 08-CONTEXT.md | 18 locked decisions (D-01..D-18) |
| 03/05/07 UI-SPECs, GameTheme, ScoreBarView, MissedWordsView | tokens, typography roles, shrink-to-fit, accent rules, row/card styling |
| Claude's discretion (defaults) | counter placement in new detail row, shimmer/glow styling, tally timing curve (1.2s cap), tick throttling, sparkles icon for Mythic, pill/card styling, Reduce Motion fallbacks, announcement copy, Found Words group "+L" bonus, missed-words lines |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-10-04

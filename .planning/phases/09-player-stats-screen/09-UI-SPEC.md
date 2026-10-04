---
phase: 09
slug: player-stats-screen
status: approved
reviewed_at: 2026-10-04
shadcn_initialized: false
preset: none
created: 2026-10-04
---

# Phase 9 — UI Design Contract

> Visual and interaction contract for the Player Stats Screen. Native SwiftUI (iOS 17+). All tokens come from `GameTheme` (`WordPuzzle/WordPuzzle/Game/GameTheme.swift`). No inline magic numbers; add new constants to `GameTheme`. "px" below means SwiftUI points.

Sources: CONTEXT.md D-01..D-23 (locked), GameTheme.swift, SettingsView.swift, PaywallView.swift (`statRow`), ScoreBarView.swift (Mythic glow). Items marked (default) are Claude's-discretion picks.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (native SwiftUI; shadcn not applicable) |
| Preset | not applicable |
| Component library | SwiftUI system controls (`NavigationStack`, `NavigationLink`, `ScrollView`, `LazyVGrid`) |
| Icon library | SF Symbols |
| Font | System (SF Pro) via Dynamic Type text styles in `GameTheme` |

Icons: top-bar entry `chart.bar.fill` (default; `chart.bar` acceptable if fill reads too heavy next to the gear), hero flame `flame.fill`, Settings row leading icon none (match the Sound row, text only).

---

## Spacing Scale

Existing `GameTheme` tokens, all multiples of 4:

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| xs | 4px | Gap between tile number and caption; flame-to-text gap |
| sm | 8px | Grid gutter (both axes); header-to-grid gap |
| md | 16px | Tile inner padding; hero card padding; hero inner VStack spacing |
| lg | 24px | Screen horizontal padding; gap between sections (hero / TODAY / LIFETIME) |
| xl | 32px | Bottom scroll inset |
| xxl | 48px | Top padding only inside the Settings push (matches Settings); not used in the sheet |

Exceptions: top-bar stats icon and the MissedWordsView summary line use `GameTheme.minTapTarget` (44) as a minimum frame. Tile and card corner radius 12 (reuse `GameTheme.celebrationCornerRadius`; matches PaywallView's 12, not a new value).

---

## Typography

Reuse the four `GameTheme` roles (Dynamic Type text styles, 2 weights: regular 400, semibold 600). Do not add roles.

| Role | Token | Size at Large | Weight | Line Height | Usage here |
|------|-------|---------------|--------|-------------|------------|
| Display | `displayFont` (largeTitle) | 34 | semibold | 1.2 | Tile big numbers; hero streak number |
| Heading | `headingFont` (title3) | 20 | semibold | 1.2 | Hero "day streak" label; Best rank tier name; top-bar icon |
| Body | `bodyFont` | 17 | regular | 1.5 | Nudge line, at-risk/zero-streak copy, Settings row label, MissedWords summary line |
| Label | `labelFont` (footnote) | 13 | regular | 1.5 | Tile captions, "Longest: M", section headers (TODAY / LIFETIME, uppercase, `.secondary`) |

Rules: tile numbers get `.minimumScaleFactor(0.5)` and `.lineLimit(1)`. Numbers use `.monospacedDigit()` so count-up does not jitter.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `GameTheme.dominant` (systemBackground) | Screen background |
| Secondary (30%) | `GameTheme.secondarySurface` (secondarySystemBackground) | Hero card, all stat tiles, best-rank tile |
| Accent (10%) | `GameTheme.accent` (honeycomb gold #F5B800) | See reserved list |
| Destructive | none needed | No destructive actions this phase |

Accent reserved for: (1) best-rank tier name text, (2) the lit hero flame icon when streak > 0. Never accent: the top-bar stats icon (`.secondary`, like the gear), the "Play today to keep it!" at-risk hint (`.secondary`), and the MissedWordsView summary line + its trailing `chevron.right` (`.secondary`). Tile numbers use `.primary`; captions and section headers use `.secondary`.

Mythic Grandmaster best rank: gold text plus the same glow as ScoreBarView's overflow capsule, i.e. `.shadow(color: GameTheme.overflowGold.opacity(glowOpacity), radius: glowRadius)` using `overflowGlowOpacityRange`, `overflowGlowRadiusRange`, `overflowGlowPulseSeconds`. Reduce Motion: steady glow at the 0.5 point of the ranges (mirrors ScoreBarView). Other tiers: gold text, no glow.

Dimmed flame (zero streak): `.secondary` at 0.4 opacity (add `GameTheme.dimmedFlameOpacity = 0.4`).

---

## Layout and Interaction Contract

### Screen structure (`StatsView`, value-in/closure-out, takes a `PlayerStats` snapshot + `onDone`)
`ScrollView` > `VStack(alignment: .leading, spacing: lg)`, horizontal padding `lg`, background `dominant`. Order top to bottom:
1. Nudge line (new player only, see states). `bodyFont`, `.secondary`, centered, plain text (no card).
2. Hero streak card (full width, secondarySurface, radius 12, padding `md`). Leading `flame.fill` at `displayFont`; trailing VStack: `"N day streak"` (number in displayFont, "day streak" in headingFont, baseline aligned) and `"Longest: M"` (labelFont, `.secondary`) beneath. Hint line below in bodyFont when at-risk or zero streak.
3. Section header `TODAY` then 2-column `LazyVGrid` (`GridItem(.flexible(), spacing: sm)` x2, row spacing `sm`): Puzzles today, Score, Words found. (3 tiles; last tile sits alone in the left column. Do not stretch it.)
4. Section header `LIFETIME` then 2-column grid, order: Best score, Games played, Average score, Words found, Avg words / game, Pangrams found, Pangram sweeps. (7 tiles.)
5. Best rank: full-width tile (secondarySurface, padding `md`) directly after the grid, spacing `sm`: caption `Best rank` (label) above tier name (headingFont, accent). Placed inside the LIFETIME section so it reads as a lifetime stat.

Tile anatomy: VStack(alignment: .leading, spacing xs): number (displayFont, primary) over caption (labelFont, secondary); `frame(maxWidth: .infinity, alignment: .leading)`; padding `md`; secondarySurface; radius 12. Tiles are not tappable and have no pressed state.

### Presentation
- Top bar: `.sheet(isPresented: $isShowingStats)`, full height, no detents, swipe-to-dismiss, `NavigationStack` with inline title "Stats" and trailing "Done" toolbar button (`bodyFont`), identical to SettingsView.
- Settings: `NavigationLink` row below Sound toggle, label "Stats" (`bodyFont`) with the system disclosure chevron, row padding `md`, min height 44. Pushed screen uses the same `StatsView` content with the system back button; hide the Done button when pushed (Settings sheet already has its own Done) via an `isPushed`/`showsDoneButton: Bool` parameter.
- Top-bar icon: left side of `GameView` top bar, `headingFont`, `.secondary`, `frame(minWidth/minHeight: minTapTarget)`, `accessibilityLabel("Stats")`. DEBUG ladybug: place the stats icon at the outermost left edge and the ladybug immediately to its right (`sm` gap) so release layout is identical minus the ladybug.
- MissedWordsView summary: one inline `Button` line, centered under the existing content block, `bodyFont` `.secondary`: `"Best 142 · Streak 4"` + trailing `chevron.right` (labelFont), min height 44, `accessibilityHint("Opens your stats")`. Opens the stats sheet presented over the round-over `fullScreenCover`; dismissing returns to round-over. Do not otherwise change the screen.

### Count-up animation (D-18)
On `onAppear`, numeric tiles and the hero number animate from 0 to value using `Text(value, format: .number)` with `.contentTransition(.numericText(value: ...))` and `withAnimation(.easeOut(duration: GameTheme.statsCountUpSeconds))`, `statsCountUpSeconds = 0.6` (default), all numbers simultaneously (no stagger). Reduce Motion (`@Environment(\.accessibilityReduceMotion)`): render final values immediately, no transition, no glow pulse. Averages and "—" values do not animate (dash is static text).

### Dynamic Type (D-19)
At `dynamicTypeSize.isAccessibilitySize` the grid collapses to a single column (`GridItem(.flexible())`) and the hero card stacks vertically (flame above text). Numbers shrink-to-fit before wrapping. Must be verified at AX5 on a physical device.

### Accessibility
- Each tile: `.accessibilityElement(children: .combine)`, label `"<caption>, <value>"` (e.g. "Best score, 142"; "Average score, not available" when "—").
- Hero card: single element, one sentence: "Current streak 4 days. Longest streak 12 days." plus hint sentence when shown.
- Section headers: `.accessibilityAddTraits(.isHeader)`.
- Decorative flame hidden from VoiceOver (`accessibilityHidden(true)`).
- Count-up must not announce intermediate values: set the accessibility label from the final value.

---

## States

| State | Behavior |
|-------|----------|
| New player (0 finished games) | Full layout, all numbers 0, averages "—", best rank tile shows "—" (not hidden, keeps layout stable), nudge line shown at top |
| Streak 0, longest > 0 | Flame dimmed, headline "Start a streak today!" replaces "N day streak", "Longest: M" still shown |
| Streak 0, longest 0 | Flame dimmed, "Start a streak today!", "Longest" line omitted |
| Streak alive via grace day (not played today) | Headline "N day streak" plus hint "Play today to keep it!" (bodyFont, `.secondary`) |
| Streak alive and played today | Headline only, no hint |
| Streak = 1 | "1 day streak" (singular "day" is still correct; no plural form needed) |
| Best rank = Mythic Grandmaster | Gold text plus glow; otherwise tier name in gold, no glow |
| Pre-update rounds | Nil new fields contribute nothing; no footnote (D-12) |
| Averages | Whole numbers, rounded to nearest (D-23); "—" when games played = 0 |
| Load/error | None; all values are synchronous local reads. If a store read fails, treat as 0 / "—" |

---

## Copywriting Contract

All strings pinned as `static let` constants on `StatsView` (and `SettingsView` / `MissedWordsView` for their additions) for tests.

| Element | Copy |
|---------|------|
| Primary CTA | "Done" (sheet dismiss; only button on screen) |
| Screen title | "Stats" |
| Settings row | "Stats" |
| Top-bar accessibility label | "Stats" |
| Nudge (new player) | "Finish a round to start your stats!" |
| Hero headline | "{N} day streak" |
| Hero longest | "Longest: {M}" |
| At-risk hint | "Play today to keep it!" |
| Zero-streak headline | "Start a streak today!" |
| Section headers | "TODAY", "LIFETIME" |
| Today captions | "Puzzles today", "Score", "Words found" |
| Lifetime captions | "Best score", "Games played", "Average score", "Words found", "Avg words / game", "Pangrams found", "Pangram sweeps", "Best rank" |
| Empty value | "—" |
| MissedWords summary | "Best {B} · Streak {S}" |
| Empty state heading/body | Nudge line above (no separate heading; the layout is never empty) |
| Error state | not applicable (no failure paths; local reads) |
| Destructive confirmation | not applicable (no destructive actions; reset stats is out of scope) |

Note: "Words found" appears in both Today and Lifetime; tile VoiceOver labels should prefix the section for disambiguation ("Today, Words found, 12" / "Lifetime, Words found, 340").

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable (native iOS) |
| Third-party | none | not applicable; no third-party UI packages added this phase |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-10-04

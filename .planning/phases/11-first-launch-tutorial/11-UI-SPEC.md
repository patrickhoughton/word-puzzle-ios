---
phase: 11
slug: first-launch-tutorial
status: approved
reviewed_at: 2026-10-04
shadcn_initialized: false
preset: none
created: 2026-10-04
---

# Phase 11 - UI Design Contract

> Visual and interaction contract for the first-launch tutorial. Native SwiftUI (iOS 17+); no web component library. All tokens come from the existing `GameTheme` enum (`WordPuzzle/WordPuzzle/Game/GameTheme.swift`). Units are points (pt). No new tokens are invented except the tutorial-specific constants listed under "New GameTheme constants".

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (shadcn not applicable; native SwiftUI) |
| Preset | not applicable |
| Component library | none (SwiftUI built-ins; value-in/closure-out child views) |
| Icon library | SF Symbols |
| Font | System (San Francisco) via Dynamic Type text styles (`GameTheme.displayFont/headingFont/bodyFont/labelFont`) |

Source: existing code (GameTheme), CONTEXT.md canonical refs (Phase 3/5 UI-SPECs).

---

## Spacing Scale

Reuse `GameTheme` tokens (all multiples of 4):

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| xs (`GameTheme.xs`) | 4pt | Gap between banner title and body; icon/text gap |
| sm (`GameTheme.sm`) | 8pt | Banner vertical padding; gap between banner and Skip link |
| md (`GameTheme.md`) | 16pt | Banner internal horizontal padding; "You're ready!" card inner spacing |
| lg (`GameTheme.lg`) | 24pt | Banner horizontal screen margin (matches score bar/word display margins) |
| xl (`GameTheme.xl`) | 32pt | not used |
| xxl (`GameTheme.xxl`) | 48pt | not used |

Exceptions: Skip tutorial link and any tappable tutorial control use `GameTheme.minTapTarget` (44pt) minimum hit area via `.frame(minHeight:)` + `.contentShape(Rectangle())`, even though its visible text is small.

---

## Typography

Dynamic Type text styles only (never fixed point sizes). 4 roles, 2 weights (regular, semibold), reusing existing tokens. Sizes shown at default "Large" category.

| Role | Token | Size | Weight | Line Height | Tutorial usage |
|------|-------|------|--------|-------------|----------------|
| Body | `GameTheme.bodyFont` | 17 | regular (400) | system default (~1.3, SwiftUI-managed) | Banner instruction text; "You're ready!" body |
| Label | `GameTheme.labelFont` | 13 | regular (400) | system default | "Skip tutorial" link; step counter ("Step 3 of 9") |
| Heading | `GameTheme.headingFont` | 20 | semibold (600) | system default | Banner step title (optional short headline) |
| Display | `GameTheme.displayFont` | 34 | semibold (600) | system default | "You're ready!" headline only |

Rules:
- Banner text must wrap (no `lineLimit(1)`), and must remain fully visible through AX5. At accessibility sizes the banner may use `.minimumScaleFactor(0.8)` ONLY as a last resort after wrapping; it must never truncate.
- Banner copy is limited to 1 heading line + at most 2 body sentences so it fits at AX5 without covering the honeycomb (see Layout).

---

## Color

Reuse existing 60/30/10 theme.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `GameTheme.dominant` (`systemBackground`) | Screen background (unchanged) |
| Secondary (30%) | `GameTheme.secondarySurface` (`secondarySystemBackground`) | Tutorial banner background; "You're ready!" card background |
| Accent (10%) | `GameTheme.accent` (honeycomb gold #F5B800, AccentColor asset) | See reserved list |
| Destructive/Error | `GameTheme.errorColor` (`systemRed`) | Not used by tutorial chrome. The guided-miss rejection message keeps its existing Phase 6 red styling in `WordDisplayView`. |

Accent reserved for (tutorial):
1. The pulsing highlight ring/glow around the current step's target (tile, button, score bar, word display)
2. The Finish/"Start playing" primary button on the "You're ready!" card
3. The step progress dots' active dot (if dots are used)

Accent is NOT used for banner text, the Skip link, or the banner background. Skip link uses `Color.secondary` text (matches the top-bar icon buttons).

Dimming: non-target elements during a guided step are dimmed with `.opacity(0.35)` (no color overlay) so the highlighted target remains the single visual focus. The center gold tile is exempt from dimming whenever it is the target.

---

## Layout and Components

All tutorial views are value-in/closure-out. Only `GameView` touches `GameViewModel` (Phase 3/4 rule); `GameView` passes the current step, text and closures down.

### Component inventory

| Component | Placement | Notes |
|-----------|-----------|-------|
| `TutorialBannerView` | Top of `playingLayout`, directly below the score bar's top spacing, above the `Spacer(minLength: md)` before the word display. Takes `.horizontal GameTheme.lg` padding. | Fixed text banner (chosen over speech bubbles: safest at AX5, never occludes tiles). Rounded rect, `GameTheme.celebrationCornerRadius` (12) corners, `secondarySurface` fill. Contains: step title (headingFont), instruction (bodyFont), and Skip link row. `.accessibilityElement(children: .combine)` for text; Skip is a separate focusable element. |
| `TutorialHighlight` (modifier) | Applied by `GameView` to the target (tile, Shuffle button, Delete button, score bar, word display, Finish button) | Rounded or hex-shaped stroke 4pt (`tutorialHighlightStroke`) in `GameTheme.accent` with soft glow (reuse the OverflowGlow shadow style: radius 5-14, opacity 0.45-0.9). Pulse period `GameTheme.overflowGlowPulseSeconds` (1.6s). Reduce Motion: steady ring at pulse 0.5 (same rule as `OverflowGlow.pulse(time:reduceMotion:)`). |
| `TutorialSkipLink` | Inside banner, trailing-aligned in the bottom row; at AX sizes full-width, leading-aligned below the instruction | Plain `Button` "Skip tutorial", labelFont, `Color.secondary`, underline off. 44pt min tap target. No confirmation. Always visible on every step including the final card. |
| `TutorialReadyCard` | Replaces the banner on the final step; overlays the same slot (not full-screen, board stays visible and playable per D-03) | Display "You're ready!" + body + primary "Finish" explanation (see copy). Contains no separate button: tapping the real Finish Round button in the control row is the CTA (D-10), and that button gets the accent highlight. |
| Step progress | Label text "Step N of 9" in labelFont above the title (preferred over dots; scales with Dynamic Type and is read by VoiceOver) | |
| Settings row "How to Play" | `SettingsView`, new `NavigationLink`-style row under Sound Effects, above or beside Stats; same row styling as the Stats row. SF Symbol `questionmark.circle`. Row triggers `onHowToPlay` closure (not a push); dismisses Settings then starts the practice puzzle. | |

### Interaction contract

- Strict guided steps (D-02): only the highlighted target responds. All other taps, drags, double-taps and gestures are ignored (no feedback, no shake). The background double-tap-shuffle layer is disabled except on the shuffle step.
- Advancement is automatic on the player performing the action (no "Next" button). Advance animation: banner content crossfades `.easeInOut(0.2)` (`GameTheme.reduceMotionCrossfadeSeconds`); with Reduce Motion, the crossfade is the only animation (no slide/scale).
- Success feedback uses the normal game feedback (accept shake-free pop, `.sensoryFeedback`, `SoundManager`) per Claude's-discretion default. No extra tutorial-specific sounds.
- Step 2 (guided miss, D-06): the player builds a word without the gold center letter and swipes down. The real rejection (shake + "Forgot the middle!") plays first; THEN the banner updates to explain the rule and re-highlights the center tile. Banner must not pre-announce the rule before the miss.
- No celebrations, rank-up toasts or missed-words screen present during the tutorial. `roundPhase` stays `.playing`; the `fullScreenCover` must not present. Pangram celebration from Phase 8 MAY play on the pangram step (it is the intended payoff).
- Skip link always live (never dimmed, never input-filtered). Settings and Stats top-bar buttons are dimmed and ignored during guided steps; they work again in free play (post-final step).
- Free play (after last teaching step): banner is replaced by the Ready card; highlight stays on Finish Round only; all board input is live. Score bar tap opens Found Words normally in free play.
- Finish Round in tutorial mode: no missed-words cover; marks tutorial seen then starts the real round via `requestNextRound(isPremium:)`. Transition: standard crossfade (same as existing round start); Reduce Motion keeps crossfade.
- Replay from Settings (D-12) uses the identical visuals; step 1 restart.

### Layout at large sizes

- Banner height is content-driven, with `.fixedSize(horizontal: false, vertical: true)`. The honeycomb must remain fully visible and tappable. At `dynamicTypeSize.isAccessibilitySize`, the banner drops the "Step N of 9" label and shortens to title + one body sentence; the layout may place the banner in a `ScrollView(.vertical)` capped at 40% of screen height so the grid is never pushed off. The planner should verify at AX5 on the smallest supported device (iPhone SE-size).
- Banner and highlight must not change hit-testing of the grid: banner uses `.allowsHitTesting(true)` only on the Skip link.

### Accessibility

- On each step change, post `UIAccessibility.post(notification: .announcement, ...)` with the step title + instruction (reuse GameView's existing `announce(_:)` helper).
- Highlighted target gets `.accessibilityHint` of the instruction while it is the target.
- Dimmed (inactive) controls are `.accessibilityHidden(false)` but report `.disabled` trait where they ignore input. The Skip link is reachable first in the rotor order after the banner text.
- VoiceOver users perform the swipe-down step via the existing word display accessibility action (Submit); the instruction copy must mention "or use the Submit action" only in the VoiceOver hint, not visible text.
- Contrast: banner text on `secondarySurface` uses default label colors (meets 4.5:1 in light and dark). Highlight ring accent on dark/light backgrounds is non-text and meets 3:1 against `systemBackground` with the 4pt stroke plus glow.

### New GameTheme constants (to add)

| Constant | Value |
|----------|-------|
| `tutorialDimmedOpacity` | 0.35 |
| `tutorialHighlightStroke` | 4 (line width) |
| `tutorialStepCount` | 9 (derived from steps list) |


---

## Copywriting Contract

Tone: playful, consistent with Phase 6 ("Forgot the middle!"). Short. Second person.

| Element | Copy |
|---------|------|
| Primary CTA (final step) | "Finish Round" button (existing control) highlighted; Ready card says: "When you're done, tap Finish Round to see the words you missed. Tap it now to start your first real puzzle!" |
| Skip link | "Skip tutorial" |
| Settings row | "How to Play" |
| Ready card headline | "You're ready!" |
| Ready card body | "Keep playing this practice board if you like." (then the Finish sentence above) |
| Empty state | not applicable (practice board is always populated) |
| Error state | Guided miss reuses the existing rejection: shake + "Forgot the middle!" (no new error copy). If the practice puzzle fails to build, silently skip the tutorial, mark seen and start a real round (no error UI). |
| Destructive confirmation | none (Skip has no confirmation, per D-11; practice is not recorded) |

Step copy (title / instruction). Planner may tighten but must keep each instruction at most 2 short sentences:

| # | Step | Title | Instruction |
|---|------|-------|-------------|
| 1 | Tap to build | "Build a word" | "Tap the glowing letters to spell {WORD}." |
| 2 | Center letter (guided miss) | "Try this one" | Pre-miss: "Now tap the glowing letters to spell {MISS_WORD}, then swipe down on it." Post-miss: "Oops! Every word must use the gold letter in the middle." (highlight center tile) |
| 3 | Swipe to submit | "Swipe down to submit" | "Spell {WORD} again, then swipe down on your word to submit it." |
| 4 | Delete / clear | "Fix a mistake" | "Tap Delete to remove the last letter. Tap your word to clear it all." |
| 5 | Drag | "Drag across letters" | "You can also slide your finger across the letters to spell {WORD}." |
| 6 | Shuffle | "Shuffle the letters" | "Tap Shuffle, or double-tap empty space, to mix up the outer letters." |
| 7 | Pangram | "Find the pangram" | "A word using all 7 letters is a pangram, worth bonus points. Can you find it?" |
| 8 | Score bar | "Track your progress" | "Your rank climbs as you find words. Tap the bar to see them all." |
| 9 | Finish | "You're ready!" | See Ready card. |

Placeholders `{WORD}`, `{MISS_WORD}` are filled from the practice puzzle (letters locked in planning per D-04).

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable (native SwiftUI, no registry) |
| Third-party | none | not applicable |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

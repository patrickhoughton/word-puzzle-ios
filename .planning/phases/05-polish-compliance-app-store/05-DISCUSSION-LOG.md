# Phase 5: Polish, Compliance & App Store - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-07
**Phase:** 5-polish-compliance-app-store
**Areas discussed:** Sound + settings screen, Dynamic Type strategy, Analytics scope (TelemetryDeck), App icon & screenshots

---

## Sound + Settings Screen

### Which player actions should get a sound effect? (multiSelect)

| Option | Description | Selected |
|--------|-------------|----------|
| Word accepted | Short positive chime/pop on a valid word submission | ✓ |
| Word rejected | Short negative buzz/thud on an invalid word | ✓ |
| Pangram found | Distinct celebratory sound, bigger than a normal accept | ✓ |
| Round end / paywall | Sound when the round finishes or the paywall appears | ✓ |

**User's choice:** All four.

### Where should the sound effect audio files come from?

| Option | Description | Selected |
|--------|-------------|----------|
| Free SFX library | Source short, royalty-free/CC0 sounds (Freesound, Kenney UI SFX pack, or system sound IDs) | ✓ |
| Apple system sounds | Built-in iOS system sound IDs, no bundled files at all | |
| Custom-made/commissioned | Record or commission original sounds | |

**User's choice:** Free SFX library (recommended).

### Where should the settings screen live, and what does it contain?

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal: sound toggle only | Just the UX-02 requirement — single on/off toggle | ✓ |
| Sound + haptics toggle | Add a haptics on/off toggle alongside sound | |
| Fold in Phase 999.1 stats screen too | Combine with backlogged player-stats screen | |

**User's choice:** Minimal: sound toggle only (recommended).
**Notes:** User confirmed "Next area" without further follow-up — settings entry point left to Claude's discretion.

---

## Dynamic Type Strategy

### How should Dynamic Type be handled given GameTheme's fixed-point fonts?

| Option | Description | Selected |
|--------|-------------|----------|
| Migrate to relative text styles | Replace fixed sizes with relative/scalable text styles across all Phase 3 views | ✓ |
| Cap max Dynamic Type size | Apply a dynamicTypeSize cap to prevent layout breakage | |
| Hybrid: scale chrome, cap the hex grid | Let UI chrome scale fully, exempt just the hex tiles | |

**User's choice:** Migrate to relative text styles (recommended).

### Follow-up: how should the hex tiles specifically be handled?

| Option | Description | Selected |
|--------|-------------|----------|
| Cap letter scaling inside tiles | Clamp hex tile letter size to a safe max; everything else scales freely | ✓ |
| Let tiles scale too, accept geometry changes | Make hex size itself responsive, reworking HexFlowerLayout's fixed-radius trigonometry | |

**User's choice:** Cap letter scaling inside tiles (recommended).
**Notes:** This follow-up was asked because a full literal migration (first answer) combined with genuinely scaling hex tile geometry would have been the more invasive "let tiles scale too" path — the two answers together land on: full Dynamic Type support everywhere except the hex grid's fixed geometry, where only the letter text is clamped.

---

## Analytics Scope (TelemetryDeck)

### Should TelemetryDeck ship in v1 or wait?

| Option | Description | Selected |
|--------|-------------|----------|
| Defer to v2 | Ship v1 with zero analytics; simplest "Data Not Collected" privacy label | ✓ |
| Integrate TelemetryDeck now | Wire up SDK in Phase 5, declare Device ID for analytics on privacy label | |

**User's choice:** Defer to v2 (recommended).

---

## App Icon & Screenshots

### Who/how should the app icon get designed?

| Option | Description | Selected |
|--------|-------------|----------|
| Claude drafts concepts, you pick/refine | Claude generates icon concept directions using the honeycomb + gold accent motif | ✓ |
| You already have a design in mind | User describes/provides the concept, Claude implements it | |
| Hire out / use a design tool later | Treated as outside this phase's Claude-driven work | |

**User's choice:** Claude drafts concepts, you pick/refine.

### What style should the App Store screenshots use?

| Option | Description | Selected |
|--------|-------------|----------|
| Captioned marketing screenshots | Simulator captures overlaid with marketing captions and device frames | ✓ |
| Plain simulator screenshots | Raw, uncaptioned Simulator screenshots | |

**User's choice:** Captioned marketing screenshots (recommended).

---

## Claude's Discretion

- Settings screen UI entry point/navigation
- Exact SFX library source and specific sound file selection
- Specific relative text style mapping per GameTheme font token; exact clamp mechanism for hex tile letters
- Icon concept directions to draft before presenting to Patrick
- Screenshot marketing copy wording and which screens to feature

## Deferred Ideas

- Haptics on/off toggle on the settings screen — deferred, settings stays minimal
- Folding Phase 999.1 (player stats screen) into this phase — deferred, stays a separate backlog item
- TelemetryDeck analytics integration — deferred to v2
- Hex tile geometry scaling with Dynamic Type — deferred as more invasive than the clamp approach

---
phase: 5
plan: 06
status: complete
---

# 05-06 Summary: Manual QA

## Pass/Fail Tally

11/11 manual checks passed. 1 failed on first pass and was fixed live (see Deviations); everything else passed on first verification.

| Requirement | Checks | Result |
|---|---|---|
| UX-01 (offline) | 1 | pass |
| UX-02 (sound) | 4 | pass |
| UX-03 (Dynamic Type) | 5 | pass (1 required a fix — see below) |
| UX-04 (iPad layout) | 1 | pass |

## Deviation from Plan: This Plan Did Write Application Code

05-06-PLAN.md's own `<verification>` section states this plan "touches no application code." That held for the first ~80% of execution, but a real defect was caught mid-QA and fixed live with Patrick's explicit approval each time, rather than deferred to a gap-closure plan as the plan's own protocol prescribes. Documenting this honestly rather than silently:

**What was found:** The AX5 GameView Simulator check initially reported `pass`, but this was a false pass — iPhone 17 Simulator's logical screen width (~402pt) is wider than a real iPhone 15 Pro (~393pt), which was just enough to avoid a truncation bug that exists on real hardware. A physical-device retest at AX5 found silent ellipsis truncation on four separate strings: "Novi...", "0 of 7...", "Tap or drag...", "F..." (Finish Round). Root cause: `Text` views sharing an `HStack` row with a `Spacer` and no `lineLimit`/wrap configuration — a standard SwiftUI Dynamic Type pitfall.

**What changed (commit `8ee88d6`):**
- `ScoreBarView.swift`: rank name + word count row shrinks-to-fit (`lineLimit(1)` + `minimumScaleFactor`) instead of truncating.
- `WordDisplayView.swift`: word/placeholder text shrinks-to-fit for the same reason.
- `GameView.swift`: `controlRow` moves Finish Round to its own full-width row below Shuffle/Delete, but *only* at `dynamicTypeSize.isAccessibilitySize` — default-size gameplay is unchanged. (An earlier attempt to also shrink-to-fit "Finish Round" in place needed a scale factor small enough to hurt legibility; splitting the row read better and there was just enough vertical budget once the other two views stopped growing.)

Explicitly considered and rejected: wrapping the whole `playingLayout` in a `ScrollView` at accessibility sizes. This was the "textbook" fix for the vertical-overflow symptom that appeared partway through iteration, but it risked interfering with `LetterGridView`'s `DragGesture(minimumDistance: 0)` and `WordDisplayView`'s swipe-to-submit gesture — a known SwiftUI gesture-conflict class. The shrink-to-fit approach avoids touching either gesture.

**Also fixed live, unrelated to this plan's QA script but raised by Patrick during testing:**
- `word_rejected.wav` swapped from `error_008.ogg` to `error_004.ogg` (gain -9dB) — the original read as too harsh. (commits `d6f8c93`, `a096062`)
- Rejected-word haptic strengthened from a single `.sensoryFeedback(.error)` to a manual double-hit `UIImpactFeedbackGenerator(style: .heavy)` burst, plus a slightly bigger/longer visual shake. (commits `4a38052`, `1587744`)

All four fixes were verified live on the physical iPhone 15 Pro before being committed, and the full test suite + compliance guards pass after each.

## Hex Clamp Ceiling

No re-tuning needed. The 40pt `HexTileView` letter clamp (from 05-02) held cleanly at AX5 on both Simulator and physical device — no glyph touched or crossed a hexagon edge.

## iPad Layout Result

Passes the bar the plan set: not stretched, not clipped, fully playable. Hex tiles render at their fixed 70pt size (small/centered on the much larger iPad canvas, which is expected, not a defect). Lots of unused white space is a design opportunity for a future dedicated iPad layout pass, out of scope here. The Settings gear icon did not render in the iPad Simulator screenshot — same known Simulator-only quirk confirmed separately on iPhone Simulator (renders fine on real iPhone hardware) — not independently confirmed on a physical iPad since none is available.

## Physical Device

iPhone 15 Pro (`iPhone16,1`), iOS 26.6.1. Same device used for prior phases' on-device verification (03-05, 04-04).

## Known Limitation, Not a Gap

The Airplane Mode paywall-specific sub-checks (offline price rendering, offline Restore Purchases behavior) could not be exercised: this device's signed-in Apple ID already holds an entitlement from earlier Phase 2/4 sandbox testing, so `Transaction.currentEntitlements` correctly reports premium immediately on launch and the app never reaches the paywall. This is the same MON-04 behavior already documented in Phase 02-05 (STATE.md) — not a defect. Core UX-01 (full gameplay offline, no crash, no silent failure) is fully verified. Per Patrick's explicit decision, this is recorded as expected/deferred rather than chased down with a fresh sandbox tester tonight.

## Also Discovered: Simulator-Only Quirk

The Settings gear button does not render in the iPhone 17 Simulator at any Dynamic Type size, confirmed via full uninstall/reinstall — but renders correctly on the physical iPhone 15 Pro. Logged to STATE.md Blockers/Concerns as a Simulator environment quirk (likely in the same family as the already-documented 02-04 Xcode 26.6/iOS 26.5 StoreKit Simulator bug), not a code defect.

---
phase: 5
plan: 06
status: in-progress
---

## Manual QA Results — Phase 05

| Check | Requirement | Result | Notes |
|---|---|---|---|
| AX5 — GameView playing layout | UX-03 | pass (after fix) | Initial Simulator check falsely passed (iPhone 17 Simulator's logical screen width is wider than a real iPhone 15 Pro, ~402pt vs ~393pt, enough to avoid the truncation entirely). Physical-device retest at AX5 found silent ellipsis truncation: "Novi...", "0 of 7...", "Tap or drag...", "F..." (Finish Round) -- root cause was Text views sharing an HStack row with a Spacer and no lineLimit/wrap config, the standard Dynamic Type trap. Fixed in commit 8ee88d6: ScoreBarView and WordDisplayView shrink-to-fit on one line (no height change at any size); GameView's Finish Round moves to its own full-width row below Shuffle/Delete only past the accessibility size threshold. Re-verified on the physical iPhone 15 Pro at AX5: gear row, score bar, word display, hex flower, and control row all fully visible, nothing truncated, nothing pushed off-screen. Hex grid drag/tap gesture unaffected (no ScrollView introduced). |
| AX5 — hex tile letters do not clip the hexagon | UX-03 | pass | Letters comfortably inside their hexagons at AX5 on both Simulator and physical device, none touching or crossing an edge. 40pt clamp ceiling holds. |
| AX5 — SettingsView | UX-03 | pass | Verified on physical iPhone 15 Pro at AX5: "Settings" title and "Done" button both fully visible top row, "Sound Effects" label wraps cleanly to two lines ("Sound"/"Effects") with no truncation, toggle switch clear of the label. |
| AX5 — MissedWordsView | UX-03 | pending | |
| AX5 — PaywallView | UX-03 | pass | Confirmed on Simulator (before the daily-limit reset): countdown, today's stats, price CTA, Restore Purchases all rendered without clipping at AX5. Not re-verified on physical device after the GameView fix, but PaywallView shares none of the fixed code (no ScoreBarView/WordDisplayView/controlRow usage), so the Simulator-vs-device discrepancy that affected GameView does not apply here. |
| SFX audible for all four events, toggle ON | UX-02 | pending | |
| SFX silent for all four events, toggle OFF | UX-02 | pending | |
| Sound preference survives app restart | UX-02 | pending | |
| SFX silenced by hardware mute switch | UX-02 | pending | |
| iPad — GameView layout does not stretch or clip the hex grid | UX-04 | pending | |
| Airplane Mode — full gameplay on a physical iPhone | UX-01 | pending | |

Physical device: Patrick's iPhone 15 Pro (iPhone16,1) is connected and paired (`available (paired)` per `xcrun devicectl list devices`).

---
status: partial
phase: 05-polish-compliance-app-store
source: [05-VERIFICATION.md]
started: 2026-10-06T00:18:17Z
updated: 2026-10-06T00:18:17Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. App Review decision on v1.0 (build 2) + Unlimited Puzzles IAP
expected: Apple approves submission 3699c1dc-49a9-472c-80b1-cb3eaeab2db1 on first review (no Guideline 2.1 / 3.1.1 / 5.1.1 rejection); Patrick then presses Release This Version
result: [pending]

### 2. AX5 Dynamic Type on screens added in Phases 6-12
expected: At the largest accessibility text size, the all-pangrams bonus callout (Phase 8) and the flick-to-spin ring (Phase 12) stay usable; known issue from 11-06 — on iPhone 17e at AX5 the score card clips at top and Finish Round clips at bottom
result: [pending]

### 3. Offline re-test of shipped build 2
expected: In Airplane Mode, every Phase 6-12 feature works (stats, found words, tutorial, spin, shuffle); paywall shows price and Restore Purchases without crashing (needs a device/tester without the entitlement)
result: [pending]

### 4. iPad Settings gear on a physical iPad
expected: The Settings gear is reachable and the sound toggle works on a real iPad (only seen in Simulator so far)
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps

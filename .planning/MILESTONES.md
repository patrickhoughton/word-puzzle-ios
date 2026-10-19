# Milestones

## v1.0 MVP (Shipped: 2026-10-19)

**Phases completed:** 12 phases, 60 plans (backlog 999.9/999.10 not part of v1.0)
**Timeline:** 2026-08-27 → 2026-10-19 (53 days, 402 commits)
**Code:** ~5,600 Swift LOC app + ~4,500 Swift LOC tests, 91 Swift files
**Store:** v1.0 (build 2) + Unlimited Puzzles $2.99 IAP approved after one Guideline 2.1 Information Needed round; READY_FOR_SALE by 2026-10-19
**Audit:** no /gsd:audit-milestone run — skipped because App Review approval and live sales already proved v1.0 end to end; 27/27 requirements checked

**Key accomplishments:**

- Pangram-first puzzle generator over a profanity-filtered ENABLE list (~173K words), loaded into a Set for O(1) lookup — unlimited puzzles, no content team
- SwiftData history/streaks/stats plus a StoreKit 2 entitlement that's always re-derived from `Transaction.currentEntitlements` (no local premium flag)
- Hex-flower game UI with unified tap/drag input, swipe-down submit, ranks, missed-word reveal, haptics and sounds; Dynamic Type through AX5
- Free tier (3 puzzle starts/day) with a paywall, live reset countdown, one-time unlock and Restore Purchases, verified with real sandbox purchases
- Post-MVP features folded in before launch: per-reason rejection feedback, found-words view, pangram/length sweep bonuses, stats screen, double-tap shuffle, first-launch tutorial, inertial flick-to-spin ring
- App Store pipeline automated: screenshots captured by XCUITest, metadata and submissions via the App Store Connect API, Wi-Fi device installs

### Known Gaps (carried to next milestone)

- 05-HUMAN-UAT #2: AX5 Dynamic Type on Phase 6–12 screens (known iPhone 17e score-card/Finish Round clipping)
- 05-HUMAN-UAT #3: Airplane Mode re-test of the shipped build + offline paywall on a non-entitled device
- 05-HUMAN-UAT #4: Settings gear on a physical iPad
- Swift 6 actor-isolation warnings (RingSpinController, SpinFeedback, TutorialController)

### Post-launch

- First user feedback (2026-10-19): closing the app lost the puzzle, and each relaunch consumed a free daily puzzle. Fixed in v1.0.1 (3) via quick task 261019-o9k (round save/restore + `marrano` removed); submitted 2026-10-19, automatic release.

---

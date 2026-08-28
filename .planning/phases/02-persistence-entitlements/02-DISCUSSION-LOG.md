# Phase 2: Persistence & Entitlements — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 02-persistence-entitlements
**Areas discussed:** Game record schema, App Store Connect setup, StoreKit testing strategy, Service wiring architecture

---

## Game Record Schema

| Option | Description | Selected |
|--------|-------------|----------|
| Date + score + words found count | Timestamp, user score, how many words found. Sufficient for all stats. | ✓ |
| Date + score + words found + words missed count | Also stores how many puzzle words were not found. Slightly richer stats. | |
| Date + full word lists | Every word found and every puzzle word stored. Maximum flexibility, larger footprint. | |

**User's choice:** Date + score + words found count (recommended default)
**Notes:** Full word lists not needed since puzzles are re-generatable from the engine.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Word length points (4=1pt, 5+=length, pangram +7) | Standard Spelling Bee scoring. | ✓ |
| Word count only (1 pt/word) | Simpler, no bonus for longer words or pangrams. | |
| You decide | Claude picks standard Spelling Bee scoring. | |

**User's choice:** Word length points — standard Spelling Bee scoring formula
**Notes:** Pangram bonus of +7 on top of word length score.

---

## App Store Connect Setup

| Option | Description | Selected |
|--------|-------------|----------|
| Not started — full walkthrough in Phase 2 plans | Plans begin with App Store Connect steps: Paid Agreement, app record, IAP product. | ✓ |
| Already started — just IAP product creation | Agreement already accepted, just need IAP product. | |
| Already done — skip to code | Everything set up, go straight to SwiftData/StoreKit code. | |

**User's choice:** Not started — include full first-timer walkthrough
**Notes:** App Store Connect setup is completely new territory. Plans must be step-by-step.

---

| Option | Description | Selected |
|--------|-------------|----------|
| com.patrickhoughton.wordpuzzle.unlimited | Reverse-domain format matching expected bundle ID. | ✓ |
| You decide | Claude picks based on bundle ID in Xcode project. | |
| I'll tell you | User has a specific product ID in mind. | |

**User's choice:** `com.patrickhoughton.wordpuzzle.unlimited`

---

## StoreKit Testing Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| StoreKit Configuration File + StoreKitTest | Local .storekit config, simulate in XCTest, no Apple ID needed. | ✓ |
| Sandbox environment only | Manual testing with sandbox Apple ID, no automated tests. | |
| You decide | Claude picks StoreKit Configuration File. | |

**User's choice:** StoreKit Configuration File + StoreKitTest framework

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — test both purchase and restore | StoreKitTest covers both flows. Validates MON-03 and MON-04. | ✓ |
| Purchase only — restore is manual | Automate purchase, test restore manually. | |

**User's choice:** Test both purchase AND restore flows in automated tests

---

## Service Wiring Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| SwiftUI .environment injection from app root | @Observable classes, injected at WordPuzzleApp, accessed via @Environment. | ✓ |
| @Observable singletons (shared instance) | Static .shared property. Simpler but harder to test/mock. | |
| You decide | Claude picks environment injection. | |

**User's choice:** SwiftUI `.environment()` injection — consistent with @Observable pattern from Phase 1

---

| Option | Description | Selected |
|--------|-------------|----------|
| App launch — .task on WindowGroup (Recommended) | Eager entitlement check before any view renders. Matches success criterion. | ✓ |
| Lazily on first view access | Deferred check; brief window where isPremium may be stale. | |

**User's choice:** `.task` on `WindowGroup` in `WordPuzzleApp.swift`

---

## Claude's Discretion

- SwiftData model/property naming (planner decides)
- Streak reset timezone (planner decides; local timezone expected)
- SwiftData ModelContainer configuration for tests vs. production (in-memory for XCTest is standard)

## Deferred Ideas

None — discussion stayed within Phase 2 scope.

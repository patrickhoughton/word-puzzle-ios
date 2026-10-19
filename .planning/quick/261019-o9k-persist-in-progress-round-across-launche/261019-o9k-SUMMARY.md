# Quick 261019-o9k Summary

In-progress round persisted via RoundSnapshotStore (UserDefaults JSON) and restored on launch without recording a new round start; slur "marrano" removed from bundled list.

Commits: 2b65ad5 (store + VM + tests), cb44e40 (launch wiring), 30c88e6 (word list), 84caa1e (test fix).

## Verification status
Executor could not run tests (stale CoreSimulator service, 1171.7 vs 1174.9.2). The orchestrator ran `xcrun simctl list`, which replaced the stale service, then ran the full WordPuzzleTests target on iPhone 17 (iOS 26.5). First run: one failure, RoundPersistenceTests.testPartialRoundTrip, `lengthBonusTotal == 0` but was 4. The test was wrong, not the code: "bead" is the fixture's only 4-letter word, so it correctly completes the 4-letter group (vm1 and vm2 state matched). Switched to "cabin" (84caa1e). Second run: all unit tests pass, including the previously-flaky EntitlementStoreTests. Physical-device check pending (Patrick, `bash scripts/install-on-device.sh`).

## Deviations
One test assertion corrected (84caa1e); no app-code deviations. Word-list line counts verified 172678 -> 172677 in both copies.

import XCTest
import StoreKit
import StoreKitTest
@testable import WordPuzzle

/// XCTest, not Swift Testing — intentional. SKTestSession has no verified Swift Testing
/// interop (02-RESEARCH Pitfall 4); this repo already mixes both frameworks.
/// @MainActor because EntitlementStore is MainActor-isolated by the app target's
/// SWIFT_DEFAULT_ACTOR_ISOLATION build setting.
@MainActor
final class EntitlementStoreTests: XCTestCase {

    private var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
        // "WordPuzzle" is the base filename of WordPuzzle.storekit. If this throws,
        // the file is not a member of the WordPuzzleTests target — see 02-01 Task 3.
        session = try SKTestSession(configurationFileNamed: "WordPuzzle")
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDown() async throws {
        session.clearTransactions()
        session = nil
        try await super.tearDown()
    }

    // MARK: - MON-04

    func testIsPremiumIsFalseWithoutAPurchase() async throws {
        let store = EntitlementStore()
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPremium, "A store with no transactions must not report premium")
    }

    /// Automated proof that the product ID string in EntitlementStore.swift matches the
    /// one in WordPuzzle.storekit. If someone edits either string, this test fails.
    func testUnlimitedProductResolvesFromConfiguration() async throws {
        let store = EntitlementStore()
        await store.loadProduct()
        let product = try XCTUnwrap(store.unlimitedProduct, "Product did not resolve — check that EntitlementStore.unlimitedProductID matches WordPuzzle.storekit")
        XCTAssertEqual(product.id, "com.patrickhoughton.wordpuzzle.unlimited")
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertTrue(product.displayPrice.contains("2.99"), "Expected 2.99, got \(product.displayPrice)")
    }

    func testPurchaseUnlocksPremium() async throws {
        // KNOWN ENVIRONMENT BUG (Phase 2, 2026-08-29): SKTestSession.buyProduct fails with
        // SKInternalErrorDomain Code=3 / "notEntitled" on this machine — Xcode 26.6 / iOS 26.5
        // Simulator fails to persist its own StoreKit test session state before any test logic
        // runs. Reproduced identically across: CLI and Xcode GUI runs, a full machine reboot +
        // Developer Mode enabled, an erased/recreated Simulator, a different Simulator device,
        // a restarted CoreSimulatorService, and with/without the (non-functional, since removed)
        // In-App Purchase entitlement. Not a code defect: the identical purchase/restore code
        // paths were independently verified with a real sandbox purchase on a physical device
        // in plan 02-05 (see 02-05-SUMMARY.md). Re-enable by deleting the XCTSkip line below
        // once Apple fixes the Simulator bug or this project moves to a newer Xcode.
        throw XCTSkip("SKTestSession fails on this machine's Simulator (SKInternalErrorDomain Code=3) — see comment above. Proven via real device sandbox purchase instead (02-05-SUMMARY.md).")

        let store = EntitlementStore()
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPremium)

        try await session.buyProduct(identifier: EntitlementStore.unlimitedProductID)
        await store.refreshEntitlements()

        XCTAssertTrue(store.isPremium, "isPremium must become true after a purchase appears in currentEntitlements")
    }

    // MARK: - MON-03

    func testRestoreUnlocksPremiumAfterFreshInstall() async throws {
        // KNOWN ENVIRONMENT BUG — see testPurchaseUnlocksPremium() above for full diagnosis.
        throw XCTSkip("SKTestSession fails on this machine's Simulator (SKInternalErrorDomain Code=3) — see comment above. Proven via real device sandbox purchase instead (02-05-SUMMARY.md).")

        // Simulate a purchase made previously (e.g. on another device / before reinstall).
        try await session.buyProduct(identifier: EntitlementStore.unlimitedProductID)

        // A brand new store instance carries no local state — this is the "fresh install"
        // condition. Restore must be enough to reach premium.
        let freshStore = EntitlementStore()
        XCTAssertFalse(freshStore.isPremium, "A newly constructed store starts unentitled")

        try await freshStore.restore()

        XCTAssertTrue(freshStore.isPremium, "Restore Purchases must re-grant premium without re-purchase")
    }

    func testClearingTransactionsRevokesPremium() async throws {
        // KNOWN ENVIRONMENT BUG — see testPurchaseUnlocksPremium() above for full diagnosis.
        throw XCTSkip("SKTestSession fails on this machine's Simulator (SKInternalErrorDomain Code=3) — see comment above. Proven via real device sandbox purchase instead (02-05-SUMMARY.md).")

        try await session.buyProduct(identifier: EntitlementStore.unlimitedProductID)
        let store = EntitlementStore()
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPremium)

        session.clearTransactions()

        let afterClear = EntitlementStore()
        await afterClear.refreshEntitlements()
        XCTAssertFalse(afterClear.isPremium, "isPremium must follow currentEntitlements, not a cached flag")
    }
}

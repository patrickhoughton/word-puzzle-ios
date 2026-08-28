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
        let store = EntitlementStore()
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPremium)

        try await session.buyProduct(identifier: EntitlementStore.unlimitedProductID)
        await store.refreshEntitlements()

        XCTAssertTrue(store.isPremium, "isPremium must become true after a purchase appears in currentEntitlements")
    }

    // MARK: - MON-03

    func testRestoreUnlocksPremiumAfterFreshInstall() async throws {
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

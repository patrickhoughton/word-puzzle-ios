import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

@MainActor
@Suite struct AppWiringTests {

    /// WordPuzzleApp.init() calls this exact code path at launch. If the GameRecord
    /// schema ever becomes un-migratable, this fails here rather than crashing on device.
    @Test func testProductionContainerCanBeCreated() throws {
        let container = try PersistenceStore.makeContainer()
        let store = PersistenceStore(container: container)
        // Every query the app root exposes must be callable without throwing.
        _ = store.puzzlesPlayedToday()
        _ = store.totalGamesPlayed()
        _ = store.bestScore()
        _ = store.totalWordsFound()
        _ = store.currentStreak()
    }

    @Test func testEntitlementStoreStartsUnentitled() async {
        let store = EntitlementStore()
        #expect(store.isPremium == false)
        #expect(EntitlementStore.unlimitedProductID == "com.patrickhoughton.wordpuzzle.unlimited")
    }
}

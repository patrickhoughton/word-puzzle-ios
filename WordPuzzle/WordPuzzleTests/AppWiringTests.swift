import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

@MainActor
@Suite(.serialized) struct AppWiringTests {

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

    /// Mirrors WordPuzzleApp's launch sequence: load the word list, then start a
    /// round. If puzzle generation ever breaks at launch, this fails here rather
    /// than showing an infinite "Loading words..." spinner on device.
    @Test func testGameViewModelStartsARoundFromLoadedWordList() async throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let list = WordList()
        let viewModel = GameViewModel(wordList: list, persistenceStore: store)

        #expect(viewModel.roundPhase == .loading)

        await list.load()
        #expect(list.isLoaded)

        viewModel.startNewRound()
        #expect(viewModel.roundPhase == .playing)
        #expect(viewModel.puzzle != nil)
        #expect(viewModel.outerLetters.count == 6)
        #expect(!viewModel.outerLetters.contains(viewModel.centerLetter))
        #expect(viewModel.totalWordCount >= 20)
        #expect(viewModel.maxPossibleScore > 0)
        #expect(viewModel.rank == .novice)
    }
}

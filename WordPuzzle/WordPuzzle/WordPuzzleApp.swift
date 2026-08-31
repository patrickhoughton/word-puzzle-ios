//
//  WordPuzzleApp.swift
//  WordPuzzle
//
//  Created by Patrick Houghton on 8/28/26.
//

import SwiftUI
import SwiftData

@main
struct WordPuzzleApp: App {

    // CONTEXT D-07: all services are @Observable and injected via .environment().
    // Views read them with @Environment(Type.self).
    @State private var persistenceStore: PersistenceStore
    @State private var entitlementStore = EntitlementStore()
    @State private var wordList: WordList
    @State private var gameViewModel: GameViewModel

    private let modelContainer: ModelContainer

    init() {
        // On-disk container for production. If the store file is corrupt or
        // unreadable, fall back to an in-memory container so the app still launches
        // rather than crashing on first run — history is lost, gameplay is not.
        let container: ModelContainer
        do {
            container = try PersistenceStore.makeContainer()
        } catch {
            assertionFailure("On-disk SwiftData container failed: \(error)")
            // swiftlint:disable:next force_try
            container = try! PersistenceStore.makeContainer(inMemory: true)
        }
        self.modelContainer = container

        let store = PersistenceStore(container: container)
        let list = WordList()
        _persistenceStore = State(initialValue: store)
        _wordList = State(initialValue: list)
        _gameViewModel = State(initialValue: GameViewModel(wordList: list, persistenceStore: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(persistenceStore)
                .environment(entitlementStore)
                .environment(wordList)
                .environment(gameViewModel)
                .task {
                    // CONTEXT D-08 / MON-04: the entitlement check runs on EVERY app
                    // launch, from Transaction.currentEntitlements — never from a
                    // cached UserDefaults flag.
                    //
                    // RESEARCH Pitfall 2: these steps are ONE sequential task, not two
                    // concurrent `.task` modifiers. SwiftUI gives no ordering guarantee
                    // between separate `.task` blocks, so a concurrent version could run
                    // the D-01 launch gate check while `isPremium` was still at its
                    // default `false` — paywalling a genuinely premium user on cold
                    // launch. Entitlement refresh is fast relative to parsing the
                    // ~173K-word list, so sequencing costs effectively nothing.
                    await entitlementStore.refreshEntitlements()
                    await entitlementStore.loadProduct()
                    await wordList.load()

                    // D-01 trigger 2: on relaunch, a free user already at the daily
                    // limit goes straight to .paywalled — never sees a puzzle screen
                    // they are not allowed to play.
                    gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium)
                }
        }
        .modelContainer(modelContainer)
    }
}

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
    @State private var tutorial: TutorialController

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
        _tutorial = State(initialValue: TutorialController(wordList: list))
        _gameViewModel = State(initialValue: GameViewModel(wordList: list, persistenceStore: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(persistenceStore)
                .environment(entitlementStore)
                .environment(wordList)
                .environment(gameViewModel)
                .environment(tutorial)
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

                    // Phase 11 D-10/D-11: Finish or Skip on a FIRST-LAUNCH tutorial starts the first real round
                    // through the normal gate. A replay (D-12) ends with nothing: the real round resumes untouched.
                    // The .loading guard means a real round is never started twice.
                    tutorial.onExit = { [gameViewModel, entitlementStore] mode in
                        guard mode == .firstLaunch, gameViewModel.roundPhase == .loading else { return }
                        gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium)
                    }
                    // Phase 11 D-08/D-09/D-13: new installs with no history see the practice tutorial (premium
                    // included). The real VM stays .loading until Finish/Skip, so no RoundStartRecord is written
                    // before the player chooses (D-07). Same sequential task: the word list is loaded (Pitfall 2).
                    if TutorialFlag.shouldShowOnLaunch(hasHistory: { persistenceStore.hasAnyHistory() }) {
                        tutorial.begin(mode: .firstLaunch)
                    } else {
                        // D-01 trigger 2: on relaunch, a free user already at the daily
                        // limit goes straight to .paywalled.
                        gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium)
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

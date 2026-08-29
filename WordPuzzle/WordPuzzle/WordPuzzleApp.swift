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

    // CONTEXT D-07: both services are @Observable and injected via .environment().
    // Views read them with @Environment(PersistenceStore.self) / @Environment(EntitlementStore.self).
    @State private var persistenceStore: PersistenceStore
    @State private var entitlementStore = EntitlementStore()

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
        _persistenceStore = State(initialValue: PersistenceStore(container: container))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(persistenceStore)
                .environment(entitlementStore)
                .task {
                    // CONTEXT D-08 / MON-04: the entitlement check runs on EVERY app
                    // launch, from Transaction.currentEntitlements — never from a
                    // cached UserDefaults flag.
                    await entitlementStore.refreshEntitlements()
                    await entitlementStore.loadProduct()
                }
        }
        .modelContainer(modelContainer)
    }
}

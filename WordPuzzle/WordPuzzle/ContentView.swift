//
//  ContentView.swift
//  WordPuzzle
//
//  Created by Patrick Houghton on 8/28/26.
//

import SwiftUI
#if DEBUG
import StoreKit
#endif

struct ContentView: View {
    var body: some View {
        #if DEBUG
        EntitlementDebugPanel()
        #else
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        #endif
    }
}

#if DEBUG
/// TEMPORARY — Phase 2 only. Exists solely so the manual sandbox purchase/restore
/// verification (CONTEXT D-06) has something to tap before the Phase 4 paywall exists.
/// Phase 3 replaces ContentView with the real game screen and this type is deleted.
struct EntitlementDebugPanel: View {
    @Environment(EntitlementStore.self) private var entitlementStore
    @Environment(PersistenceStore.self) private var persistenceStore
    @State private var lastMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Phase 2 Debug Panel")
                .font(.headline)

            LabeledContent("isPremium", value: entitlementStore.isPremium ? "true" : "false")
            LabeledContent("Product", value: entitlementStore.unlimitedProduct?.displayPrice ?? "not loaded")
            LabeledContent("Played today", value: "\(persistenceStore.puzzlesPlayedToday())")
            LabeledContent("Streak", value: "\(persistenceStore.currentStreak())")
            LabeledContent("Games / Best / Words", value: "\(persistenceStore.totalGamesPlayed()) / \(persistenceStore.bestScore()) / \(persistenceStore.totalWordsFound())")

            Divider()

            Button("Load Product") {
                Task { await entitlementStore.loadProduct(); lastMessage = "loaded" }
            }
            Button("Buy Unlimited") {
                Task {
                    do { try await entitlementStore.purchaseUnlimited(); lastMessage = "purchase finished" }
                    catch { lastMessage = "purchase error: \(error)" }
                }
            }
            Button("Restore Purchases") {
                Task {
                    do { try await entitlementStore.restore(); lastMessage = "restore finished" }
                    catch { lastMessage = "restore error: \(error)" }
                }
            }
            Button("Record Fake Session") {
                persistenceStore.record(score: 20, wordsFoundCount: 7)
                lastMessage = "recorded"
            }

            if !lastMessage.isEmpty {
                Text(lastMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }
}
#endif

#Preview {
    ContentView()
}

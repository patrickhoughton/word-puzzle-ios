//
//  ContentView.swift
//  WordPuzzle
//
//  Created by Patrick Houghton on 8/28/26.
//

import SwiftUI

/// Phase 3: the root view is now the real game screen. The Phase 2
/// EntitlementDebugPanel was deleted here — the Phase 4 paywall replaces
/// its purchase/restore affordances.
struct ContentView: View {
    var body: some View {
        GameView()
    }
}

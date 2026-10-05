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
///
/// Phase 11: while the tutorial is active the root is a GameView over the PRACTICE view-model
/// (`.environment(tutorial.practice)` overrides the app-level GameViewModel for this subtree),
/// so the real round's state survives untouched underneath (D-12).
struct ContentView: View {
    @Environment(TutorialController.self) private var tutorial

    var body: some View {
        Group {
            if tutorial.isActive {
                GameView(tutorial: tutorial, onHowToPlay: { tutorial.begin(mode: tutorial.mode) })
                    .environment(tutorial.practice)
            } else {
                GameView(onHowToPlay: { tutorial.begin(mode: .replay) })
            }
        }
        .animation(.easeInOut(duration: GameTheme.reduceMotionCrossfadeSeconds), value: tutorial.isActive)
    }
}

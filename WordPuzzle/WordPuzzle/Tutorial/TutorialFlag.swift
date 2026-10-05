import Foundation

/// Phase 11 D-08/D-09/D-13: the "has seen the tutorial" flag. A UserDefaults flag, per the
/// project's flags-in-UserDefaults / history-in-SwiftData split.
///
/// TRI-STATE on purpose: nil = never decided (fresh install OR an interrupted tutorial),
/// true = seen, false = forced show (UI tests pass `-hasSeenTutorial NO`).
/// `@AppStorage` cannot tell "absent" from its default, so the launch decision reads
/// `object(forKey:)` first.
enum TutorialFlag {
    static let seenKey = "hasSeenTutorial"

    /// Launch arguments land in the argument domain as STRINGS ("YES"/"NO"), and
    /// `object(forKey:) as? Bool` fails on an NSString. `bool(forKey:)` parses
    /// "YES"/"NO"/"1"/"0"/"true"/"false", so read presence first, then the Bool.
    static func state(in defaults: UserDefaults = .standard) -> Bool? {
        guard defaults.object(forKey: seenKey) != nil else { return nil }
        return defaults.bool(forKey: seenKey)
    }

    /// Only finishing (D-10) or skipping (D-11) calls this. Never called on interruption (D-13).
    static func markSeen(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: seenKey)
    }

    /// D-08/D-09: show only on a new install with no history. Existing/updating players with
    /// any GameRecord or RoundStartRecord get the flag set and never see it automatically.
    /// `hasHistory` is a closure so the SwiftData probe only runs when the key is absent.
    static func shouldShowOnLaunch(defaults: UserDefaults = .standard, hasHistory: () -> Bool) -> Bool {
        switch state(in: defaults) {
        case true?:  return false
        case false?: return true
        case nil:
            if hasHistory() {
                markSeen(in: defaults)
                return false
            }
            return true
        }
    }
}

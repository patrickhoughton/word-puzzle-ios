import Foundation

/// Minimal state needed to resume an unfinished round. Score, bonuses, pangram count and
/// completed lengths are NOT stored; they are derived by replaying `foundWords`.
struct RoundSnapshot: Codable, Equatable {
    static let currentVersion = 1
    var version: Int = RoundSnapshot.currentVersion
    let letters: String        // 7 letters, sorted
    let centerLetter: String   // 1 char
    let validWords: [String]
    let pangrams: [String]
    let foundWords: [String]   // most-recent-first, same as GameViewModel.foundWords
}

/// Persists the in-progress round as one small JSON blob.
///
/// UserDefaults rather than SwiftData: this is a single flag-like value with no queries,
/// matching the project's split (flags/seeds in UserDefaults, queryable history in SwiftData).
/// Deliberately not @Observable; no view reads it.
@MainActor
final class RoundSnapshotStore {
    static let key = "inProgressRound.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ snapshot: RoundSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.key)
    }

    /// nil on missing data, decode failure, or a version mismatch.
    func load() -> RoundSnapshot? {
        guard let data = defaults.data(forKey: Self.key),
              let snapshot = try? JSONDecoder().decode(RoundSnapshot.self, from: data),
              snapshot.version == RoundSnapshot.currentVersion else { return nil }
        return snapshot
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}

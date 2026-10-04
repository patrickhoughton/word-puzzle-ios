import Foundation

/// Phase 9: an immutable snapshot of every stat the Stats screen shows. Built ONLY by
/// GameView via PersistenceStore.playerStats(now:) (plan 09-03) so child views stay
/// value-in/closure-out. Every field has a default so tests and previews can build
/// partial snapshots with the memberwise init.
struct PlayerStats: Equatable, Sendable {
    // TODAY (D-06)
    var puzzlesToday: Int = 0        // STARTED rounds today (free-tier counter)
    var todayScore: Int = 0
    var todayWords: Int = 0
    // STREAK (D-07, D-21)
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var streakAtRisk: Bool = false   // alive only via the grace day (not yet played today)
    // LIFETIME (D-08, D-09, D-10)
    var gamesPlayed: Int = 0         // FINISHED rounds
    var bestScore: Int = 0
    var totalWords: Int = 0
    var averageScore: Int? = nil     // nil when gamesPlayed == 0 (D-20, D-23)
    var averageWords: Int? = nil
    var bestRank: RankTier? = nil    // nil when no record has a stored rank (D-12, D-14)
    var pangrams: Int = 0
    var sweeps: Int = 0

    static let empty = PlayerStats()
}

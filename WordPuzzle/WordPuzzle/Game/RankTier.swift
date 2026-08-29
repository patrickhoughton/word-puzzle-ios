import Foundation

/// CONTEXT D-09 (locked): an original 10-tier ladder — deliberately NOT NYT
/// Spelling Bee's own tier names (App Store 4.3 clone-risk avoidance) — using
/// the same percentage-of-max-score thresholds. Tier names are exact and must
/// not be reworded (03-UI-SPEC.md Copywriting Contract).
enum RankTier: Int, CaseIterable, Comparable, Sendable {
    case novice = 0
    case rookie
    case apprentice
    case wordsmith
    case adept
    case skilled
    case expert
    case virtuoso
    case master
    case legend

    /// Percentage of the puzzle's max possible score required to reach this tier.
    var thresholdPercent: Double {
        switch self {
        case .novice:     return 0
        case .rookie:     return 2
        case .apprentice: return 5
        case .wordsmith:  return 8
        case .adept:      return 15
        case .skilled:    return 25
        case .expert:     return 40
        case .virtuoso:   return 50
        case .master:     return 70
        case .legend:     return 100
        }
    }

    var displayName: String {
        switch self {
        case .novice:     return "Novice"
        case .rookie:     return "Rookie"
        case .apprentice: return "Apprentice"
        case .wordsmith:  return "Wordsmith"
        case .adept:      return "Adept"
        case .skilled:    return "Skilled"
        case .expert:     return "Expert"
        case .virtuoso:   return "Virtuoso"
        case .master:     return "Master"
        case .legend:     return "Legend"
        }
    }

    /// Points needed to reach this tier for a puzzle worth `maxScore`.
    /// Rounds DOWN, matching NYT behaviour.
    func requiredScore(maxScore: Int) -> Int {
        guard maxScore > 0 else { return 0 }
        return Int((thresholdPercent / 100 * Double(maxScore)).rounded(.down))
    }

    /// Highest tier whose requirement is met by `score`.
    static func tier(score: Int, maxScore: Int) -> RankTier {
        guard maxScore > 0 else { return .novice }
        var result = RankTier.novice
        for tier in RankTier.allCases where score >= tier.requiredScore(maxScore: maxScore) {
            result = tier
        }
        return result
    }

    static func < (lhs: RankTier, rhs: RankTier) -> Bool { lhs.rawValue < rhs.rawValue }
}

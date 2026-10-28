import Foundation
import SwiftData

// MARK: - Filter Model

public struct StatsFilter {
    public var timeRange: TimeRange = .allTime
    public var playerCount: Int? = nil // nil = any
    public var tag: String? = nil // nil = any
    public var requiredPlayerId: UUID? = nil // filter games where this player was present
    
    public init(
        timeRange: TimeRange = .allTime,
        playerCount: Int? = nil,
        tag: String? = nil,
        requiredPlayerId: UUID? = nil
    ) {
        self.timeRange = timeRange
        self.playerCount = playerCount
        self.tag = tag
        self.requiredPlayerId = requiredPlayerId
    }
    
    public enum TimeRange: String, CaseIterable, Identifiable {
        case allTime = "Tout l'historique"
        case lastMonth = "30 derniers jours"
        case lastThreeMonths = "3 derniers mois"
        case thisYear = "Cette année"
        
        public var id: String { rawValue }
        
        public func filter(games: [Game]) -> [Game] {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .allTime:
                return games
            case .lastMonth:
                guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return games }
                return games.filter { $0.startedAt >= start }
            case .lastThreeMonths:
                guard let start = calendar.date(byAdding: .month, value: -3, to: now) else { return games }
                return games.filter { $0.startedAt >= start }
            case .thisYear:
                guard let start = calendar.dateInterval(of: .year, for: now)?.start else { return games }
                return games.filter { $0.startedAt >= start }
            }
        }
    }
    
    public func apply(to games: [Game]) -> [Game] {
        var result = timeRange.filter(games: games.filter { $0.status == .finished })
        if let count = playerCount {
            result = result.filter { $0.participants.count == count }
        }
        if let t = tag, !t.isEmpty {
            result = result.filter { $0.tags.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) }
        }
        if let pid = requiredPlayerId {
            result = result.filter { $0.participants.contains(where: { $0.player?.id == pid }) }
        }
        return result
    }
}

// MARK: - Game Heatmap Cell

public struct GameHeatmapCell: Identifiable {
    public var id: String { "\(playerId.uuidString)_r\(roundNumber)" }
    public let playerId: UUID
    public let playerName: String
    public let playerColorHex: String
    public let roundNumber: Int
    public let cardsDealt: Int
    public let bid: Int
    public let tricks: Int
    public let points: Int
    public let isSuccess: Bool
    public let diff: Int // tricks - bid
}

// MARK: - Player Habit Item

public struct PlayerHabitItem: Identifiable {
    public var id: String { "\(cards)_\(bid)" }
    public let cards: Int
    public let mostFrequentBid: Int
    public let bidCount: Int
    public let totalRoundsWithCards: Int
    public var percentage: Double {
        totalRoundsWithCards > 0 ? (Double(bidCount) / Double(totalRoundsWithCards)) * 100.0 : 0
    }
    public var text: String {
        "À \(cards) carte\(cards > 1 ? "s" : ""), tu paries \(mostFrequentBid) dans \(Int(percentage))% des cas."
    }
}

// MARK: - Empirical Matrix Cell (Bid vs Tricks)

public struct BidTricksMatrixCell: Identifiable {
    public var id: String { "b\(bid)_t\(tricks)" }
    public let bid: Int
    public let tricks: Int
    public var count: Int
}

// MARK: - Empirical Table Probability Cell (Success rate for Bid X with Y Cards)

public struct EmpiricalProbCell: Identifiable {
    public var id: String { "c\(cards)_b\(bid)" }
    public let cards: Int
    public let bid: Int
    public var attempts: Int
    public var successes: Int
    public var successRate: Double {
        attempts > 0 ? (Double(successes) / Double(attempts)) * 100.0 : 0.0
    }
}

// MARK: - Table Position Effect

public struct TablePositionStats {
    public var gamesCount: Int = 0
    public var winRate: Double = 0.0
    public var avgScore: Double = 0.0
}

// MARK: - Head to Head Advanced Analysis

public struct AdvancedH2HStats {
    public var playerA: Player
    public var playerB: Player
    public var commonGamesCount: Int = 0
    public var aFinishedAheadCount: Int = 0
    public var bFinishedAheadCount: Int = 0
    public var aWinRateVsB: Double {
        commonGamesCount > 0 ? Double(aFinishedAheadCount) / Double(commonGamesCount) : 0
    }
    public var avgScoreDiffAminusB: Double = 0.0
    public var biggestWinA: Int = 0
    public var biggestWinB: Int = 0
    
    // Presence effect
    public var aWinRateWhenBPresent: Double = 0.0
    public var aWinRateWhenBAbsent: Double = 0.0
    public var aScoreWhenBPresent: Double = 0.0
    public var aScoreWhenBAbsent: Double = 0.0
    public var aSuccessRateWhenBPresent: Double = 0.0
    public var aSuccessRateWhenBAbsent: Double = 0.0
    
    // Table Relative Position Effect
    public var aJustBeforeBStats = TablePositionStats()
    public var aJustAfterBStats = TablePositionStats()
    
    // Pearson Score Correlation in common games
    public var scoreCorrelation: Double = 0.0 // -1.0 ... +1.0
}

// MARK: - Player Profile Comprehensive Stats

public struct PlayerExhaustiveStats {
    public var player: Player
    public var totalGames: Int = 0
    public var wins: Int = 0
    public var winRate: Double = 0.0
    public var podiums: Int = 0
    public var avgRank: Double = 0.0
    public var normalizedRank: Double = 0.0
    
    public var avgScore: Double = 0.0
    public var medianScore: Double = 0.0
    public var maxScore: Int = 0
    public var minScore: Int = 0
    public var scoreStandardDeviation: Double = 0.0
    public var avgPointsPerRound: Double = 0.0
    
    // Bidding
    public var totalBidsCount: Int = 0
    public var successBidsCount: Int = 0
    public var overallSuccessRate: Double = 0.0
    public var relativeBidAvg: Double = 0.0 // bid / cards
    public var avgBias: Double = 0.0 // tricks - bid
    public var biasLabel: String = "Neutre"
    public var missWithinOnePercent: Double = 0.0 // % missed by exactly +-1
    
    // Success rate breakdowns
    public var successRateByRoundNumber: [Int: Double] = [:] // 1...10 -> 0...1
    public var successRateByCardsDealt: [Int: Double] = [:]  // 1...10 -> 0...1
    public var successRateByBidValue: [Int: Double] = [:]    // 0...10 -> 0...1
    public var successRateByTurnPosition: [Int: Double] = [:] // 0 (1st to play) ... n-1
    public var successRateByPlayerCount: [Int: Double] = [:]  // 2...12
    
    // Bid frequency & Habits
    public var bidDistribution: [Int: Int] = [:] // bid -> count
    public var habits: [PlayerHabitItem] = []
    
    // Bid x Tricks Matrix (Heatmap)
    public var bidTricksMatrix: [BidTricksMatrixCell] = []
    
    // Zero bid specialist
    public var zeroBidsAttempts: Int = 0
    public var zeroBidsSuccess: Int = 0
    public var zeroBidsSuccessRate: Double = 0.0
    public var zeroPointsGained: Int = 0
    public var zeroPointsLost: Int = 0
    
    // Game Phases Performance
    public var earlyGameAvgPoints: Double = 0.0  // Rounds 1-3
    public var midGameAvgPoints: Double = 0.0    // Rounds 4-7
    public var lateGameAvgPoints: Double = 0.0   // Rounds 8-10
    
    // Points split & progression
    public var totalPositivePoints: Int = 0
    public var totalNegativePoints: Int = 0
    public var bonusPointsGained: Int = 0
    public var bonusPointsShare: Double = 0.0 // bonus / total positive
    public var rollingFiveGamesAvgScores: [(gameIndex: Int, avgScore: Double)] = []
    
    // Streaks
    public var currentStreak: Int = 0
    public var longestCareerSuccessStreak: Int = 0
    public var longestSingleGameSuccessStreak: Int = 0
    public var longestWinStreak: Int = 0
    public var longestLoseStreak: Int = 0
    public var recentForms: [Int] = [] // Last 5 games ranks
    
    // Nemesis & Favorite Victim
    public var nemesis: (player: Player, winRateAgainst: Double, games: Int)? = nil
    public var favoriteVictim: (player: Player, winRateAgainst: Double, games: Int)? = nil
}

// MARK: - Fun Table Aggregate Stats

public struct TableFunStats {
    public var totalFinishedGames: Int = 0
    public var totalRounds: Int = 0
    public var totalPlayTimeSeconds: TimeInterval = 0
    public var preferredDayOfWeek: String = ""
    public var preferredHourSpan: String = ""
    public var avgTableOverbidPerRound: [Int: Double] = [:] // round -> avg (bids - cards)
    public var deadliestRoundNumber: Int = 1 // lowest average points / player
    public var mostConsistentPlayer: (name: String, stdDev: Double)? = nil
    public var mostUnpredictablePlayer: (name: String, stdDev: Double)? = nil
    public var empiricalProbabilities: [EmpiricalProbCell] = []
}

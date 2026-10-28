import Foundation
import SwiftData

// MARK: - Game Highlights

public struct GameHighlights {
    public var biggestRoundPlayer: (name: String, points: Int, round: Int)?
    public var worstDropPlayer: (name: String, points: Int, round: Int)?
    public var largestComeback: (name: String, fromRank: Int, toRank: Int)?
    public var leadChangesCount: Int = 0
    public var longestSuccessStreak: (name: String, streak: Int)?
    public var heroicZeros: [(name: String, round: Int, cards: Int)] = []
    public var totalDurationFormatted: String = ""
    public var avgRoundDurationFormatted: String = ""
}

// MARK: - Player Profile Stats

public struct PlayerProfileStats {
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
    
    // Zero bids
    public var zeroBidsAttempts: Int = 0
    public var zeroBidsSuccess: Int = 0
    public var zeroBidsSuccessRate: Double = 0.0
    public var zeroPointsGained: Int = 0
    public var zeroPointsLost: Int = 0
    
    // Streaks
    public var currentStreak: Int = 0
    public var longestCareerSuccessStreak: Int = 0
    public var longestSingleGameSuccessStreak: Int = 0
    public var recentForms: [Int] = [] // Last 5 game ranks
    
    // Points split
    public var totalPositivePoints: Int = 0
    public var totalNegativePoints: Int = 0
    public var bonusPointsGained: Int = 0
}

// MARK: - Head to Head Stats

public struct HeadToHeadStats {
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
}

// MARK: - Stats Service Implementation

public final class StatsService {
    public static let shared = StatsService()
    
    // MARK: - Game Highlights Computation
    
    public static func computeGameHighlights(game: Game) -> GameHighlights {
        var highlights = GameHighlights()
        
        let sortedRounds = game.sortedRounds
        guard !sortedRounds.isEmpty else { return highlights }
        
        var maxRoundPts = Int.min
        var minRoundPts = Int.max
        var leaderSequence: [UUID] = []
        
        var playerCurrentStreaks: [UUID: Int] = [:]
        var playerMaxStreaks: [UUID: Int] = [:]
        
        for round in sortedRounds {
            // Check heroics zeros (0 bid success with >= 8 cards)
            for entry in round.entries {
                guard let p = entry.participant?.player else { continue }
                if entry.bid == 0 && entry.isSuccess && round.cardsDealt >= 8 {
                    highlights.heroicZeros.append((name: p.name, round: round.number, cards: round.cardsDealt))
                }
                
                if entry.points > maxRoundPts {
                    maxRoundPts = entry.points
                    highlights.biggestRoundPlayer = (name: p.name, points: entry.points, round: round.number)
                }
                if entry.points < minRoundPts {
                    minRoundPts = entry.points
                    highlights.worstDropPlayer = (name: p.name, points: entry.points, round: round.number)
                }
                
                // Streaks
                if entry.isSuccess {
                    playerCurrentStreaks[p.id, default: 0] += 1
                    let cur = playerCurrentStreaks[p.id, default: 0]
                    if cur > playerMaxStreaks[p.id, default: 0] {
                        playerMaxStreaks[p.id] = cur
                    }
                } else {
                    playerCurrentStreaks[p.id] = 0
                }
            }
            
            // Round leader
            let leaderEntry = round.entries.max { $0.cumulativeScore < $1.cumulativeScore }
            if let leaderPid = leaderEntry?.participant?.player?.id {
                leaderSequence.append(leaderPid)
            }
        }
        
        // Count leader changes
        var changes = 0
        for i in 1..<leaderSequence.count {
            if leaderSequence[i] != leaderSequence[i - 1] {
                changes += 1
            }
        }
        highlights.leadChangesCount = changes
        
        // Longest success streak in game
        if let maxStreakEntry = playerMaxStreaks.max(by: { $0.value < $1.value }) {
            let pName = game.participants.first { $0.player?.id == maxStreakEntry.key }?.player?.name ?? "Joueur"
            highlights.longestSuccessStreak = (name: pName, streak: maxStreakEntry.value)
        }
        
        // Comeback
        if sortedRounds.count >= 2 {
            let firstRoundEntries = sortedRounds.first!.entries.sorted { $0.cumulativeScore > $1.cumulativeScore }
            let finalParticipants = game.sortedParticipants.sorted { $0.finalRank < $1.finalRank }
            
            if let winner = finalParticipants.first, let winnerId = winner.player?.id {
                if let initialIndex = firstRoundEntries.firstIndex(where: { $0.participant?.player?.id == winnerId }) {
                    let initialRank = initialIndex + 1
                    if initialRank > 1 {
                        highlights.largestComeback = (name: winner.player?.name ?? "Vainqueur", fromRank: initialRank, toRank: 1)
                    }
                }
            }
        }
        
        // Durations
        if let dur = game.duration {
            let minutes = Int(dur) / 60
            let seconds = Int(dur) % 60
            highlights.totalDurationFormatted = "\(minutes) min \(seconds) s"
            
            let avgSec = Int(dur) / max(1, sortedRounds.count)
            highlights.avgRoundDurationFormatted = "\(avgSec / 60)m \(avgSec % 60)s"
        }
        
        return highlights
    }
    
    // MARK: - Detailed Player Profile Stats
    
    public static func computePlayerProfile(player: Player, games: [Game]) -> PlayerProfileStats {
        var stats = PlayerProfileStats(player: player)
        
        let finishedGames = games.filter { $0.status == .finished }
        var relevantParticipations: [(game: Game, part: GameParticipant)] = []
        
        for g in finishedGames {
            if let part = g.participants.first(where: { $0.player?.id == player.id }) {
                relevantParticipations.append((game: g, part: part))
            }
        }
        
        // Sort chronologically
        relevantParticipations.sort { $0.game.startedAt < $1.game.startedAt }
        stats.totalGames = relevantParticipations.count
        guard stats.totalGames > 0 else { return stats }
        
        var scores: [Int] = []
        var ranks: [Int] = []
        var normRanks: [Double] = []
        var roundPoints: [Int] = []
        
        var careerStreak = 0
        var maxCareerStreak = 0
        var biases: [Int] = []
        var relativeBids: [Double] = []
        var missWithin1Count = 0
        var totalMisses = 0
        
        for item in relevantParticipations {
            let p = item.part
            scores.append(p.finalScore)
            ranks.append(p.finalRank)
            
            if p.finalRank == 1 { stats.wins += 1 }
            if p.finalRank <= 3 { stats.podiums += 1 }
            
            let n = item.game.participants.count
            let normR = n > 1 ? Double(n - p.finalRank) / Double(n - 1) : 1.0
            normRanks.append(normR)
            
            // Entries
            var gameStreak = 0
            for entry in p.roundEntries.sorted(by: { ($0.round?.number ?? 0) < ($1.round?.number ?? 0) }) {
                guard let round = entry.round else { continue }
                stats.totalBidsCount += 1
                roundPoints.append(entry.points)
                
                if entry.points > 0 { stats.totalPositivePoints += entry.points }
                if entry.points < 0 { stats.totalNegativePoints += entry.points }
                
                let relBid = round.cardsDealt > 0 ? Double(entry.bid) / Double(round.cardsDealt) : 0
                relativeBids.append(relBid)
                
                let bias = entry.tricks - entry.bid
                biases.append(bias)
                
                if entry.bid == 0 {
                    stats.zeroBidsAttempts += 1
                    if entry.isSuccess {
                        stats.zeroBidsSuccess += 1
                        stats.zeroPointsGained += entry.points
                    } else {
                        stats.zeroPointsLost += entry.points
                    }
                }
                
                if entry.isSuccess {
                    stats.successBidsCount += 1
                    careerStreak += 1
                    gameStreak += 1
                    if careerStreak > maxCareerStreak { maxCareerStreak = careerStreak }
                    if gameStreak > stats.longestSingleGameSuccessStreak { stats.longestSingleGameSuccessStreak = gameStreak }
                } else {
                    careerStreak = 0
                    gameStreak = 0
                    totalMisses += 1
                    if abs(bias) == 1 {
                        missWithin1Count += 1
                    }
                }
            }
        }
        
        stats.winRate = Double(stats.wins) / Double(stats.totalGames)
        stats.avgRank = ranks.reduce(0, +) > 0 ? Double(ranks.reduce(0, +)) / Double(ranks.count) : 0
        stats.normalizedRank = normRanks.reduce(0, +) / Double(normRanks.count)
        stats.avgScore = Double(scores.reduce(0, +)) / Double(scores.count)
        stats.maxScore = scores.max() ?? 0
        stats.minScore = scores.min() ?? 0
        
        let sortedScores = scores.sorted()
        if sortedScores.count % 2 == 0 {
            stats.medianScore = Double(sortedScores[sortedScores.count / 2 - 1] + sortedScores[sortedScores.count / 2]) / 2.0
        } else {
            stats.medianScore = Double(sortedScores[sortedScores.count / 2])
        }
        
        // Standard deviation
        let mean = stats.avgScore
        let variance = scores.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(scores.count)
        stats.scoreStandardDeviation = sqrt(variance)
        
        if !roundPoints.isEmpty {
            stats.avgPointsPerRound = Double(roundPoints.reduce(0, +)) / Double(roundPoints.count)
        }
        
        stats.overallSuccessRate = stats.totalBidsCount > 0 ? Double(stats.successBidsCount) / Double(stats.totalBidsCount) : 0
        stats.relativeBidAvg = !relativeBids.isEmpty ? relativeBids.reduce(0, +) / Double(relativeBids.count) : 0
        
        if !biases.isEmpty {
            stats.avgBias = Double(biases.reduce(0, +)) / Double(biases.count)
            if stats.avgBias > 0.15 {
                stats.biasLabel = "Tu te sous-estimes (tu fais plus de plis que prévu)"
            } else if stats.avgBias < -0.15 {
                stats.biasLabel = "Tu te surestimes (tu fais moins de plis que prévu)"
            } else {
                stats.biasLabel = "Très équilibré"
            }
        }
        
        if totalMisses > 0 {
            stats.missWithinOnePercent = Double(missWithin1Count) / Double(totalMisses)
        }
        
        if stats.zeroBidsAttempts > 0 {
            stats.zeroBidsSuccessRate = Double(stats.zeroBidsSuccess) / Double(stats.zeroBidsAttempts)
        }
        
        stats.longestCareerSuccessStreak = maxCareerStreak
        stats.currentStreak = careerStreak
        
        // Recent form (last 5 games)
        let lastGames = relevantParticipations.suffix(5)
        stats.recentForms = lastGames.map { $0.part.finalRank }
        
        return stats
    }
    
    // MARK: - Head to Head Comparison
    
    public static func computeHeadToHead(playerA: Player, playerB: Player, games: [Game]) -> HeadToHeadStats {
        var h2h = HeadToHeadStats(playerA: playerA, playerB: playerB)
        
        let finishedGames = games.filter { $0.status == .finished }
        var aScoresWithB: [Int] = []
        var aScoresWithoutB: [Int] = []
        var aWinsWithB = 0
        var aWinsWithoutB = 0
        var aGamesWithoutB = 0
        
        for g in finishedGames {
            let partA = g.participants.first { $0.player?.id == playerA.id }
            let partB = g.participants.first { $0.player?.id == playerB.id }
            
            if let pA = partA, let pB = partB {
                h2h.commonGamesCount += 1
                if pA.finalRank < pB.finalRank {
                    h2h.aFinishedAheadCount += 1
                    let diff = pA.finalScore - pB.finalScore
                    if diff > h2h.biggestWinA { h2h.biggestWinA = diff }
                } else if pB.finalRank < pA.finalRank {
                    h2h.bFinishedAheadCount += 1
                    let diff = pB.finalScore - pA.finalScore
                    if diff > h2h.biggestWinB { h2h.biggestWinB = diff }
                }
                
                aScoresWithB.append(pA.finalScore)
                if pA.finalRank == 1 { aWinsWithB += 1 }
            } else if let pA = partA, partB == nil {
                aGamesWithoutB += 1
                aScoresWithoutB.append(pA.finalScore)
                if pA.finalRank == 1 { aWinsWithoutB += 1 }
            }
        }
        
        if h2h.commonGamesCount > 0 {
            let totalDiff = aScoresWithB.reduce(0, +)
            h2h.avgScoreDiffAminusB = Double(totalDiff) / Double(h2h.commonGamesCount)
            h2h.aWinRateWhenBPresent = Double(aWinsWithB) / Double(h2h.commonGamesCount)
            h2h.aScoreWhenBPresent = Double(aScoresWithB.reduce(0, +)) / Double(h2h.commonGamesCount)
        }
        
        if aGamesWithoutB > 0 {
            h2h.aWinRateWhenBAbsent = Double(aWinsWithoutB) / Double(aGamesWithoutB)
            h2h.aScoreWhenBAbsent = Double(aScoresWithoutB.reduce(0, +)) / Double(aGamesWithoutB)
        }
        
        return h2h
    }
}

import Foundation
import SwiftData

// MARK: - ELO Rating Structures

public struct PlayerEloPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let rating: Double
    public let gameId: UUID
}

public struct PlayerLeaderboardItem: Identifiable {
    public var id: UUID { player.id }
    public let player: Player
    public var currentElo: Double
    public var eloDeltaLastGame: Double
    public var totalGames: Int
    public var totalWins: Int
    public var winRate: Double { totalGames > 0 ? Double(totalWins) / Double(totalGames) : 0 }
    public var averageRank: Double
    public var normalizedRank: Double // (n - rank) / (n - 1)
    public var averageScore: Double
    public var bidSuccessRate: Double
    public var totalPoints: Int
}

public final class RatingService {
    public static let shared = RatingService()
    
    public static let initialElo: Double = 1000.0
    public static let defaultK: Double = 32.0
    
    /// Computes full ELO history and leaderboard across all finished games
    public static func computeLeaderboards(players: [Player], games: [Game]) -> [PlayerLeaderboardItem] {
        let finishedGames = games.filter { $0.status == .finished }.sorted { $0.startedAt < $1.startedAt }
        
        var ratings: [UUID: Double] = [:]
        var previousRatings: [UUID: Double] = [:]
        var gamesCount: [UUID: Int] = [:]
        var winsCount: [UUID: Int] = [:]
        var ranksSum: [UUID: Double] = [:]
        var normalizedRanksSum: [UUID: Double] = [:]
        var scoresSum: [UUID: Int] = [:]
        var successfulBids: [UUID: Int] = [:]
        var totalBids: [UUID: Int] = [:]
        
        for player in players {
            ratings[player.id] = initialElo
            previousRatings[player.id] = initialElo
            gamesCount[player.id] = 0
            winsCount[player.id] = 0
            ranksSum[player.id] = 0
            normalizedRanksSum[player.id] = 0
            scoresSum[player.id] = 0
            successfulBids[player.id] = 0
            totalBids[player.id] = 0
        }
        
        for game in finishedGames {
            let participants = game.sortedParticipants.filter { $0.player != nil }
            let n = participants.count
            guard n >= 2 else { continue }
            
            // Save state before this game to compute delta
            for p in participants {
                if let pid = p.player?.id {
                    previousRatings[pid] = ratings[pid] ?? initialElo
                }
            }
            
            // Stats aggregation
            for p in participants {
                guard let pid = p.player?.id else { continue }
                gamesCount[pid, default: 0] += 1
                ranksSum[pid, default: 0] += Double(p.finalRank)
                scoresSum[pid, default: 0] += p.finalScore
                if p.finalRank == 1 {
                    winsCount[pid, default: 0] += 1
                }
                let normRank = n > 1 ? Double(n - p.finalRank) / Double(n - 1) : 1.0
                normalizedRanksSum[pid, default: 0] += normRank
            }
            
            for round in game.rounds {
                for entry in round.entries {
                    if let pid = entry.participant?.player?.id {
                        totalBids[pid, default: 0] += 1
                        if entry.isSuccess {
                            successfulBids[pid, default: 0] += 1
                        }
                    }
                }
            }
            
            // Multiplayer ELO via pairwise matches
            // K is divided by (n - 1) so total update magnitude is scaled properly
            let effectiveK = defaultK / Double(n - 1)
            var deltaElo: [UUID: Double] = [:]
            
            for i in 0..<n {
                let pA = participants[i]
                guard let idA = pA.player?.id else { continue }
                let rA = ratings[idA, default: initialElo]
                
                for j in (i + 1)..<n {
                    let pB = participants[j]
                    guard let idB = pB.player?.id else { continue }
                    let rB = ratings[idB, default: initialElo]
                    
                    // Expected outcome for A vs B
                    let expA = 1.0 / (1.0 + pow(10.0, (rB - rA) / 400.0))
                    let expB = 1.0 - expA
                    
                    // Actual outcome (lower rank is better)
                    let actualA: Double
                    let actualB: Double
                    if pA.finalRank < pB.finalRank {
                        actualA = 1.0; actualB = 0.0
                    } else if pA.finalRank > pB.finalRank {
                        actualA = 0.0; actualB = 1.0
                    } else {
                        actualA = 0.5; actualB = 0.5
                    }
                    
                    deltaElo[idA, default: 0.0] += effectiveK * (actualA - expA)
                    deltaElo[idB, default: 0.0] += effectiveK * (actualB - expB)
                }
            }
            
            for (pid, delta) in deltaElo {
                ratings[pid, default: initialElo] += delta
            }
        }
        
        var items: [PlayerLeaderboardItem] = []
        for player in players {
            let pid = player.id
            let totalG = gamesCount[pid, default: 0]
            let curElo = ratings[pid, default: initialElo]
            let prevElo = previousRatings[pid, default: initialElo]
            let delta = curElo - prevElo
            let wins = winsCount[pid, default: 0]
            let avgR = totalG > 0 ? (ranksSum[pid, default: 0] / Double(totalG)) : 0
            let avgNormR = totalG > 0 ? (normalizedRanksSum[pid, default: 0] / Double(totalG)) : 0
            let avgSc = totalG > 0 ? Double(scoresSum[pid, default: 0]) / Double(totalG) : 0
            let tBids = totalBids[pid, default: 0]
            let sBids = successfulBids[pid, default: 0]
            let bidRate = tBids > 0 ? Double(sBids) / Double(tBids) : 0
            
            items.append(PlayerLeaderboardItem(
                player: player,
                currentElo: curElo,
                eloDeltaLastGame: delta,
                totalGames: totalG,
                totalWins: wins,
                averageRank: avgR,
                normalizedRank: avgNormR,
                averageScore: avgSc,
                bidSuccessRate: bidRate,
                totalPoints: scoresSum[pid, default: 0]
            ))
        }
        
        return items
    }
    
    /// Returns the current ELO rating for a specific player
    public static func computePlayerElo(for player: Player, allPlayers: [Player], games: [Game]) -> Double {
        let leaderboard = computeLeaderboards(players: allPlayers, games: games)
        return leaderboard.first(where: { $0.player.id == player.id })?.currentElo ?? initialElo
    }
}

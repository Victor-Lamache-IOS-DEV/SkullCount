import Foundation
import SwiftData

// MARK: - Record Item

public struct RecordItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let category: String
    public let valueDescription: String
    public let holderName: String
    public let date: Date
    public let gameId: UUID
    public let isShame: Bool
}

// MARK: - Badge Definition

public struct BadgeItem: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let unlockedCount: Int
    public let holders: [String]
}

// MARK: - Records Service Implementation

public final class RecordsService {
    public static let shared = RecordsService()
    
    public static func computeHallOfFameAndShame(games: [Game]) -> (fame: [RecordItem], shame: [RecordItem]) {
        let finishedGames = games.filter { $0.status == .finished }
        var fame: [RecordItem] = []
        var shame: [RecordItem] = []
        
        guard !finishedGames.isEmpty else { return (fame, shame) }
        
        // 1. Highest Game Score
        var highestScore = Int.min
        var highestScorePlayer: (name: String, date: Date, gameId: UUID)?
        
        // 2. Lowest Game Score (Shame)
        var lowestScore = Int.max
        var lowestScorePlayer: (name: String, date: Date, gameId: UUID)?
        
        // 3. Best Round Score
        var bestRoundScore = Int.min
        var bestRoundPlayer: (name: String, date: Date, gameId: UUID, round: Int)?
        
        // 4. Worst Round Score (Shame)
        var worstRoundScore = Int.max
        var worstRoundPlayer: (name: String, date: Date, gameId: UUID, round: Int)?
        
        // 5. Largest victory gap (1st vs 2nd)
        var largestGap = Int.min
        var largestGapGame: (winner: String, gap: Int, date: Date, gameId: UUID)?
        
        // 6. Closest victory (1st vs 2nd)
        var closestGap = Int.max
        var closestGapGame: (winner: String, gap: Int, date: Date, gameId: UUID)?
        
        // 7. Highest Table Score (sum of all scores in game)
        var highestTableScore = Int.min
        var highestTableGame: (score: Int, date: Date, gameId: UUID)?
        
        // 8. Longest & Shortest Game
        var longestDur: TimeInterval = 0
        var longestGame: (dur: TimeInterval, date: Date, gameId: UUID)?
        var shortestDur: TimeInterval = Double.infinity
        var shortestGame: (dur: TimeInterval, date: Date, gameId: UUID)?
        
        for g in finishedGames {
            let parts = g.sortedParticipants.sorted { $0.finalScore > $1.finalScore }
            
            let tableScore = parts.reduce(0) { $0 + $1.finalScore }
            if tableScore > highestTableScore {
                highestTableScore = tableScore
                highestTableGame = (score: tableScore, date: g.startedAt, gameId: g.id)
            }
            
            if parts.count >= 2 {
                let gap = parts[0].finalScore - parts[1].finalScore
                if gap > largestGap {
                    largestGap = gap
                    largestGapGame = (winner: parts[0].player?.name ?? "Capitaine", gap: gap, date: g.startedAt, gameId: g.id)
                }
                if gap >= 0 && gap < closestGap {
                    closestGap = gap
                    closestGapGame = (winner: parts[0].player?.name ?? "Capitaine", gap: gap, date: g.startedAt, gameId: g.id)
                }
            }
            
            for p in parts {
                guard let name = p.player?.name else { continue }
                if p.finalScore > highestScore {
                    highestScore = p.finalScore
                    highestScorePlayer = (name: name, date: g.startedAt, gameId: g.id)
                }
                if p.finalScore < lowestScore {
                    lowestScore = p.finalScore
                    lowestScorePlayer = (name: name, date: g.startedAt, gameId: g.id)
                }
            }
            
            for r in g.rounds {
                for e in r.entries {
                    guard let name = e.participant?.player?.name else { continue }
                    if e.points > bestRoundScore {
                        bestRoundScore = e.points
                        bestRoundPlayer = (name: name, date: g.startedAt, gameId: g.id, round: r.number)
                    }
                    if e.points < worstRoundScore {
                        worstRoundScore = e.points
                        worstRoundPlayer = (name: name, date: g.startedAt, gameId: g.id, round: r.number)
                    }
                }
            }
            
            if let dur = g.duration, dur > 60 {
                if dur > longestDur {
                    longestDur = dur
                    longestGame = (dur: dur, date: g.startedAt, gameId: g.id)
                }
                if dur < shortestDur {
                    shortestDur = dur
                    shortestGame = (dur: dur, date: g.startedAt, gameId: g.id)
                }
            }
        }
        
        // Build Hall of Fame
        if let h = highestScorePlayer {
            fame.append(RecordItem(title: "Plus gros trésor", category: "Partie", valueDescription: "\(highestScore) pts", holderName: h.name, date: h.date, gameId: h.gameId, isShame: false))
        }
        if let b = bestRoundPlayer {
            fame.append(RecordItem(title: "Manche légendaire", category: "Manche", valueDescription: "+\(bestRoundScore) pts (M\(b.round))", holderName: b.name, date: b.date, gameId: b.gameId, isShame: false))
        }
        if let lg = largestGapGame {
            fame.append(RecordItem(title: "Écrasante domination", category: "Écart", valueDescription: "+\(lg.gap) pts d'avance", holderName: lg.winner, date: lg.date, gameId: lg.gameId, isShame: false))
        }
        if let cg = closestGapGame {
            fame.append(RecordItem(title: "Victoire sur le fil", category: "Écart", valueDescription: "\(cg.gap) pt(s) d'écart", holderName: cg.winner, date: cg.date, gameId: cg.gameId, isShame: false))
        }
        if let ht = highestTableGame {
            fame.append(RecordItem(title: "Trésor de table record", category: "Collectif", valueDescription: "\(ht.score) pts cumulés", holderName: "Équipage", date: ht.date, gameId: ht.gameId, isShame: false))
        }
        if let lg = longestGame {
            let m = Int(lg.dur) / 60
            fame.append(RecordItem(title: "Plus longue épopée", category: "Temps", valueDescription: "\(m) minutes", holderName: "Équipage", date: lg.date, gameId: lg.gameId, isShame: false))
        }
        
        // Build Hall of Shame
        if let l = lowestScorePlayer {
            shame.append(RecordItem(title: "Pire naufrage", category: "Partie", valueDescription: "\(lowestScore) pts", holderName: l.name, date: l.date, gameId: l.gameId, isShame: true))
        }
        if let w = worstRoundPlayer {
            shame.append(RecordItem(title: "Pire manche", category: "Manche", valueDescription: "\(worstRoundScore) pts (M\(w.round))", holderName: w.name, date: w.date, gameId: w.gameId, isShame: true))
        }
        
        return (fame, shame)
    }
    
    // MARK: - Badges
    
    public static func computeBadges(players: [Player], games: [Game]) -> [BadgeItem] {
        let finishedGames = games.filter { $0.status == .finished }
        
        var perfectGameHolders = Set<String>()
        var zeroKingHolders = Set<String>()
        var shipwreckHolders = Set<String>()
        var mermaidHolders = Set<String>()
        var streakHolders = Set<String>()
        
        for g in finishedGames {
            // Perfect game check (all bids successful in a game)
            for p in g.participants {
                guard let name = p.player?.name else { continue }
                let entries = p.roundEntries
                if entries.count >= 5 && entries.allSatisfy({ $0.isSuccess }) {
                    perfectGameHolders.insert(name)
                }
                
                // Zero King (>= 3 zeros successfully bid in a single game)
                let zerosSuccess = entries.filter { $0.bid == 0 && $0.isSuccess }.count
                if zerosSuccess >= 3 {
                    zeroKingHolders.insert(name)
                }
                
                // Shipwreck: <= -100 in a single round
                if entries.contains(where: { $0.points <= -100 }) {
                    shipwreckHolders.insert(name)
                }
                
                // Mermaid: captured SK
                if entries.contains(where: { $0.skCapturedByMermaid && $0.isSuccess }) {
                    mermaidHolders.insert(name)
                }
            }
        }
        
        return [
            BadgeItem(
                id: "perfect_game",
                title: "Pari Parfait",
                description: "Réussir 100% de ses paris dans une partie complète (min. 5 manches)",
                icon: "crown.fill",
                unlockedCount: perfectGameHolders.count,
                holders: Array(perfectGameHolders).sorted()
            ),
            BadgeItem(
                id: "zero_king",
                title: "Roi du Zéro",
                description: "Réussir au moins 3 paris à 0 au cours d'une même partie",
                icon: "shield.checkered",
                unlockedCount: zeroKingHolders.count,
                holders: Array(zeroKingHolders).sorted()
            ),
            BadgeItem(
                id: "shipwreck",
                title: "Grand Naufrage",
                description: "Perdre -100 points ou pire en une seule manche",
                icon: "water.waves.and.arrow.down",
                unlockedCount: shipwreckHolders.count,
                holders: Array(shipwreckHolders).sorted()
            ),
            BadgeItem(
                id: "mermaid_captor",
                title: "Charmeuse des Abysses",
                description: "Capturer le Skull King avec une Sirène lors d'un pari réussi",
                icon: "sparkles",
                unlockedCount: mermaidHolders.count,
                holders: Array(mermaidHolders).sorted()
            )
        ]
    }
}

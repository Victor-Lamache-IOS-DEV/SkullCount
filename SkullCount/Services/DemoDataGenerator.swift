import Foundation
import SwiftData

public final class DemoDataGenerator {
    
    public static func generateDemoData(modelContext: ModelContext, gameCount: Int = 20) {
        let pirateNames = [
            ("Barbe Noire", "🏴‍☠️", "#E74C3C"),
            ("Anne Bonny", "🦜", "#E84393"),
            ("Jack Sparrow", "🧭", "#F39C12"),
            ("Mary Read", "🗡️", "#1ABC9C"),
            ("Capitaine Crochet", "⚓️", "#3498DB"),
            ("Barbe Rousse", "💣", "#C0392B"),
            ("Calico Jack", "👑", "#F1C40F"),
            ("Sirène Syrena", "🧜‍♀️", "#9B59B6")
        ]
        
        var players: [Player] = []
        for (name, emoji, color) in pirateNames {
            let p = Player(name: name, colorHex: color, emoji: emoji)
            modelContext.insert(p)
            players.append(p)
        }
        
        let calendar = Calendar.current
        var baseDate = calendar.date(byAdding: .day, value: -gameCount * 2, to: Date()) ?? Date()
        
        for gIndex in 0..<gameCount {
            let playerCount = Int.random(in: 3...6)
            let selectedPlayers = Array(players.shuffled().prefix(playerCount))
            
            let gameDate = calendar.date(byAdding: .hour, value: gIndex * 24 + Int.random(in: 1...10), to: baseDate) ?? Date()
            let durationSeconds = Double.random(in: 1200...2700)
            let endDate = gameDate.addingTimeInterval(durationSeconds)
            
            let game = Game(
                startedAt: gameDate,
                endedAt: endDate,
                status: .finished,
                bonusEnabled: true,
                roundMode: .reducedRounds,
                plannedRounds: 10,
                startingPlayerIndex: Int.random(in: 0..<playerCount),
                location: ["Taverne de l'Île", "Cale du Black Pearl", "Port Royal", "Tortuga"].randomElement()!,
                notes: "Partie de test générée automatiquement."
            )
            modelContext.insert(game)
            
            var participants: [GameParticipant] = []
            for (idx, p) in selectedPlayers.enumerated() {
                let part = GameParticipant(seatIndex: idx, player: p, game: game)
                modelContext.insert(part)
                game.participants.append(part)
                participants.append(part)
            }
            
            let plannedRounds = ScoringEngine.plannedRoundsCount(playerCount: playerCount, roundMode: .reducedRounds)
            var cumulativeScores = [UUID: Int]()
            for p in participants { cumulativeScores[p.id] = 0 }
            
            for rNum in 1...plannedRounds {
                let cards = ScoringEngine.cardsDealt(forRound: rNum, playerCount: playerCount, roundMode: .reducedRounds)
                let firstIdx = ScoringEngine.firstPlayerSeatIndex(roundNumber: rNum, startingPlayerSeatIndex: game.startingPlayerIndex, playerCount: playerCount)
                
                let round = Round(
                    number: rNum,
                    cardsDealt: cards,
                    firstPlayerIndex: firstIdx,
                    startedAt: gameDate.addingTimeInterval(Double(rNum * 150)),
                    endedAt: gameDate.addingTimeInterval(Double(rNum * 150 + 120)),
                    game: game
                )
                modelContext.insert(round)
                game.rounds.append(round)
                
                // Distribute tricks randomly summing to cards
                var tricksRemaining = cards
                var distributedTricks = [Int](repeating: 0, count: playerCount)
                while tricksRemaining > 0 {
                    let randP = Int.random(in: 0..<playerCount)
                    distributedTricks[randP] += 1
                    tricksRemaining -= 1
                }
                
                for (pIdx, part) in participants.enumerated() {
                    let tricks = distributedTricks[pIdx]
                    // 65% chance bid matches or is close
                    let bid: Int
                    if Double.random(in: 0...1) < 0.65 {
                        bid = tricks
                    } else {
                        bid = max(0, min(cards, tricks + (Bool.random() ? 1 : -1)))
                    }
                    
                    let skMermaid = (bid == tricks) && (Double.random(in: 0...1) < 0.08)
                    let pirates = (bid == tricks && !skMermaid) ? (Double.random(in: 0...1) < 0.15 ? Int.random(in: 1...2) : 0) : 0
                    
                    let calc = ScoringEngine.calculateScore(
                        bid: bid,
                        tricks: tricks,
                        cardsDealt: cards,
                        bonusEnabled: true,
                        piratesCapturedBySK: pirates,
                        skCapturedByMermaid: skMermaid
                    )
                    
                    let prevCum = cumulativeScores[part.id, default: 0]
                    let newCum = prevCum + calc.points
                    cumulativeScores[part.id] = newCum
                    
                    let entry = RoundEntry(
                        bid: bid,
                        tricks: tricks,
                        piratesCapturedBySK: pirates,
                        skCapturedByMermaid: skMermaid,
                        points: calc.points,
                        cumulativeScore: newCum,
                        round: round,
                        participant: part
                    )
                    modelContext.insert(entry)
                    round.entries.append(entry)
                    part.roundEntries.append(entry)
                }
            }
            
            // Assign final scores and ranks
            let sortedParts = participants.sorted {
                cumulativeScores[$0.id, default: 0] > cumulativeScores[$1.id, default: 0]
            }
            for (rankIdx, part) in sortedParts.enumerated() {
                part.finalScore = cumulativeScores[part.id, default: 0]
                part.finalRank = rankIdx + 1
            }
        }
        
        try? modelContext.save()
    }
}

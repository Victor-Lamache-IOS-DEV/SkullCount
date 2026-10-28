import SwiftUI
import SwiftData

@Observable
public final class GamePlayViewModel {
    public var game: Game
    public var currentRoundIndex: Int = 1
    public var isResultsPhase: Bool = false
    public var isScoresRevealed: Bool = false
    
    // Live round inputs keyed by participant ID
    public var bids: [UUID: Int] = [:]
    public var tricks: [UUID: Int] = [:]
    public var piratesBonus: [UUID: Int] = [:]
    public var mermaidBonus: [UUID: Bool] = [:]
    
    // Undo / Redo history
    private var historySnapshots: [[UUID: (bid: Int, trick: Int)]] = []
    
    public init(game: Game) {
        self.game = game
        // Find current round
        let sorted = game.sortedRounds
        if let lastRound = sorted.last, lastRound.endedAt != nil && sorted.count < game.plannedRounds {
            self.currentRoundIndex = sorted.count + 1
        } else if let lastRound = sorted.last, lastRound.endedAt == nil {
            self.currentRoundIndex = lastRound.number
            // Load existing round entries if any
            for e in lastRound.entries {
                if let pid = e.participant?.id {
                    bids[pid] = e.bid
                    tricks[pid] = e.tricks
                    piratesBonus[pid] = e.piratesCapturedBySK
                    mermaidBonus[pid] = e.skCapturedByMermaid
                }
            }
            if !bids.isEmpty && bids.count == game.participants.count {
                self.isResultsPhase = true
            }
        } else {
            self.currentRoundIndex = max(1, sorted.count)
        }
    }
    
    // MARK: - Current Round Helpers
    
    public var currentCardsDealt: Int {
        ScoringEngine.cardsDealt(forRound: currentRoundIndex, playerCount: game.participants.count, roundMode: game.roundMode, deckSize: game.deckSize)
    }
    
    public var currentFirstPlayerIndex: Int {
        ScoringEngine.firstPlayerSeatIndex(roundNumber: currentRoundIndex, startingPlayerSeatIndex: game.startingPlayerIndex, playerCount: game.participants.count)
    }
    
    /// Participants ordered by play order for this round
    public var participantsInTurnOrder: [GameParticipant] {
        let sorted = game.sortedParticipants
        let count = sorted.count
        guard count > 0 else { return [] }
        let leadIndex = currentFirstPlayerIndex
        var list: [GameParticipant] = []
        for i in 0..<count {
            let seat = (leadIndex + i) % count
            if let p = sorted.first(where: { $0.seatIndex == seat }) {
                list.append(p)
            }
        }
        return list
    }
    
    public var startingPlayerName: String {
        let leadIndex = currentFirstPlayerIndex
        return game.sortedParticipants.first(where: { $0.seatIndex == leadIndex })?.player?.name ?? "Capitaine"
    }
    
    // MARK: - Live Validations & Metrics
    
    public var totalBids: Int {
        bids.values.reduce(0, +)
    }
    
    public var totalTricks: Int {
        tricks.values.reduce(0, +)
    }
    
    public var isBiddingComplete: Bool {
        for p in game.participants {
            if bids[p.id] == nil { return false }
        }
        return true
    }
    
    public var isTricksComplete: Bool {
        for p in game.participants {
            if tricks[p.id] == nil { return false }
        }
        return true
    }
    
    public var isTricksSumValid: Bool {
        return totalTricks == currentCardsDealt
    }
    
    public var tricksMissingCount: Int {
        return currentCardsDealt - totalTricks
    }
    
    // MARK: - Fast 1-Tap Actions
    
    public func setBid(for participantId: UUID, bid: Int) {
        bids[participantId] = bid
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    public func setTrick(for participantId: UUID, trick: Int) {
        tricks[participantId] = trick
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Smart completion: If only 1 player is missing tricks, suggest/auto-set it if valid
        let remainingParticipants = game.participants.filter { tricks[$0.id] == nil }
        if remainingParticipants.count == 1 {
            let lastPid = remainingParticipants[0].id
            let needed = currentCardsDealt - totalTricks
            if needed >= 0 && needed <= currentCardsDealt {
                tricks[lastPid] = needed
            }
        }
    }
    
    public func markSuccess(for participantId: UUID) {
        if let bid = bids[participantId] {
            setTrick(for: participantId, trick: bid)
        }
    }
    
    public func markAllSuccess() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        for p in game.participants {
            if let bid = bids[p.id] {
                tricks[p.id] = bid
            }
        }
    }
    
    // MARK: - Round Lifecycle & Validation
    
    public func validateBidsPhase() {
        guard isBiddingComplete else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isResultsPhase = true
    }
    
    public func validateRound(modelContext: ModelContext) {
        guard isTricksComplete && isTricksSumValid else { return }
        
        // Ensure Round object exists
        var round = game.sortedRounds.first(where: { $0.number == currentRoundIndex })
        if round == nil {
            round = Round(
                number: currentRoundIndex,
                cardsDealt: currentCardsDealt,
                firstPlayerIndex: currentFirstPlayerIndex,
                startedAt: Date(),
                game: game
            )
            modelContext.insert(round!)
            game.rounds.append(round!)
        }
        
        round?.endedAt = Date()
        
        // Compute entries and update cumulative scores
        for p in game.participants {
            let bid = bids[p.id] ?? 0
            let trick = tricks[p.id] ?? 0
            let pBonus = piratesBonus[p.id] ?? 0
            let mBonus = mermaidBonus[p.id] ?? false
            
            let result = ScoringEngine.calculateScore(
                bid: bid,
                tricks: trick,
                cardsDealt: currentCardsDealt,
                bonusEnabled: game.bonusEnabled,
                piratesCapturedBySK: pBonus,
                skCapturedByMermaid: mBonus,
                bonusPirateBySKValue: game.bonusPirateBySK,
                bonusSKByMermaidValue: game.bonusSKByMermaid
            )
            
            // Previous cumulative score
            let previousCumulative = p.roundEntries
                .filter { ($0.round?.number ?? 0) < currentRoundIndex }
                .reduce(0) { $0 + $1.points }
            let newCumulative = previousCumulative + result.points
            
            var entry = round?.entries.first(where: { $0.participant?.id == p.id })
            if entry == nil {
                entry = RoundEntry(round: round, participant: p)
                modelContext.insert(entry!)
                round?.entries.append(entry!)
                p.roundEntries.append(entry!)
            }
            entry?.bid = bid
            entry?.tricks = trick
            entry?.piratesCapturedBySK = pBonus
            entry?.skCapturedByMermaid = mBonus
            entry?.points = result.points
            entry?.cumulativeScore = newCumulative
        }
        
        // Recalculate subsequent rounds if we are editing an earlier round
        recalculateSubsequentRounds()
        
        // Check if game is finished
        if currentRoundIndex >= game.plannedRounds {
            finishGame(modelContext: modelContext)
        } else {
            // Next round setup
            currentRoundIndex += 1
            isResultsPhase = false
            bids.removeAll()
            tricks.removeAll()
            piratesBonus.removeAll()
            mermaidBonus.removeAll()
        }
        
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    public func recalculateSubsequentRounds() {
        let sortedRounds = game.sortedRounds
        for p in game.participants {
            var cum = 0
            for r in sortedRounds {
                if let entry = r.entries.first(where: { $0.participant?.id == p.id }) {
                    cum += entry.points
                    entry.cumulativeScore = cum
                }
            }
            p.finalScore = cum
        }
    }
    
    public func finishGame(modelContext: ModelContext) {
        game.status = .finished
        game.endedAt = Date()
        recalculateSubsequentRounds()
        
        // Assign final ranks
        let ranked = game.participants.sorted { $0.finalScore > $1.finalScore }
        for (i, p) in ranked.enumerated() {
            p.finalRank = i + 1
        }
        try? modelContext.save()
    }
    
    public func getPreviewScore(for participantId: UUID) -> (points: Int, isSuccess: Bool)? {
        guard let bid = bids[participantId], let trick = tricks[participantId] else { return nil }
        let pBonus = piratesBonus[participantId] ?? 0
        let mBonus = mermaidBonus[participantId] ?? false
        let calc = ScoringEngine.calculateScore(
            bid: bid,
            tricks: trick,
            cardsDealt: currentCardsDealt,
            bonusEnabled: game.bonusEnabled,
            piratesCapturedBySK: pBonus,
            skCapturedByMermaid: mBonus
        )
        return (calc.points, calc.isSuccess)
    }
}

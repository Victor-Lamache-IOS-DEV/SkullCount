import Foundation

/// Pure struct calculation engine for Skull King Classic (66 cards, 1 to 13)
public struct ScoringEngine {
    
    // MARK: - Deck & Rounds Configuration
    
    public static let defaultDeckSize: Int = 66
    
    /// Calculate maximum number of cards possible per player given deck size and player count.
    /// Standard rule: min(10, floor(deckSize / playerCount))
    public static func maxCardsPossible(playerCount: Int, deckSize: Int = defaultDeckSize) -> Int {
        guard playerCount > 0 else { return 0 }
        let theoreticalMax = deckSize / playerCount
        return min(10, theoreticalMax)
    }
    
    /// Total rounds for a game based on game mode and player count
    public static func plannedRoundsCount(playerCount: Int, roundMode: RoundMode, deckSize: Int = defaultDeckSize) -> Int {
        let maxCards = maxCardsPossible(playerCount: playerCount, deckSize: deckSize)
        switch roundMode {
        case .reducedRounds:
            return max(1, maxCards)
        case .cappedTenRounds:
            return 10
        }
    }
    
    /// Cards dealt for a specific round index (1-based)
    public static func cardsDealt(forRound roundNumber: Int, playerCount: Int, roundMode: RoundMode, deckSize: Int = defaultDeckSize) -> Int {
        let maxCards = maxCardsPossible(playerCount: playerCount, deckSize: deckSize)
        switch roundMode {
        case .reducedRounds:
            return min(roundNumber, maxCards)
        case .cappedTenRounds:
            return min(roundNumber, maxCards)
        }
    }
    
    // MARK: - Rotation of First Player
    
    /// Rotation index around table (0 ..< playerCount) for a given round (1-based)
    public static func firstPlayerSeatIndex(roundNumber: Int, startingPlayerSeatIndex: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return (startingPlayerSeatIndex + (roundNumber - 1)) % playerCount
    }
    
    /// Reordered seat indices for play order in a round
    public static func seatOrder(forRound roundNumber: Int, startingPlayerSeatIndex: Int, playerCount: Int) -> [Int] {
        guard playerCount > 0 else { return [] }
        let leadIndex = firstPlayerSeatIndex(roundNumber: roundNumber, startingPlayerSeatIndex: startingPlayerSeatIndex, playerCount: playerCount)
        var order = [Int]()
        for i in 0..<playerCount {
            order.append((leadIndex + i) % playerCount)
        }
        return order
    }
    
    // MARK: - Score Calculation
    
    /// Calculate round points for a single entry
    ///
    /// Rules:
    /// If bid >= 1:
    ///   tricks == bid  -> +20 * bid (+ bonus)
    ///   tricks != bid  -> -10 * abs(tricks - bid) (no bonus)
    /// If bid == 0:
    ///   tricks == 0    -> +10 * cardsDealt (+ bonus)
    ///   tricks >= 1    -> -10 * cardsDealt (no bonus)
    ///
    /// Bonus: only if bid is successful!
    ///   piratesCapturedBySK * bonusPirateBySK (default +30)
    ///   + (skCapturedByMermaid ? bonusSKByMermaid : 0) (default +50)
    public static func calculateScore(
        bid: Int,
        tricks: Int,
        cardsDealt: Int,
        bonusEnabled: Bool = false,
        piratesCapturedBySK: Int = 0,
        skCapturedByMermaid: Bool = false,
        bonusPirateBySKValue: Int = 30,
        bonusSKByMermaidValue: Int = 50
    ) -> (points: Int, isSuccess: Bool, bonusPoints: Int) {
        
        let isSuccess = (bid == tricks)
        var baseScore = 0
        var bonusScore = 0
        
        if bid >= 1 {
            if isSuccess {
                baseScore = 20 * bid
            } else {
                baseScore = -10 * abs(tricks - bid)
            }
        } else {
            // bid == 0
            if isSuccess {
                baseScore = 10 * cardsDealt
            } else {
                baseScore = -10 * cardsDealt
            }
        }
        
        if isSuccess && bonusEnabled {
            if piratesCapturedBySK > 0 {
                bonusScore += piratesCapturedBySK * bonusPirateBySKValue
            }
            if skCapturedByMermaid {
                bonusScore += bonusSKByMermaidValue
            }
        }
        
        return (points: baseScore + bonusScore, isSuccess: isSuccess, bonusPoints: bonusScore)
    }
    
    // MARK: - Validation
    
    /// Checks whether the sum of tricks equals cardsDealt
    public static func validateTricksSum(tricks: [Int], cardsDealt: Int) -> Bool {
        return tricks.reduce(0, +) == cardsDealt
    }
}

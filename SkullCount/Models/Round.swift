import Foundation
import SwiftData

@Model
public final class Round {
    @Attribute(.unique) public var id: UUID
    public var number: Int
    public var cardsDealt: Int
    public var firstPlayerIndex: Int
    public var startedAt: Date
    public var endedAt: Date?
    
    public var game: Game?
    
    @Relationship(deleteRule: .cascade, inverse: \RoundEntry.round)
    public var entries: [RoundEntry] = []
    
    public init(
        id: UUID = UUID(),
        number: Int,
        cardsDealt: Int,
        firstPlayerIndex: Int,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        game: Game? = nil
    ) {
        self.id = id
        self.number = number
        self.cardsDealt = cardsDealt
        self.firstPlayerIndex = firstPlayerIndex
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.game = game
    }
    
    public var duration: TimeInterval? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }
}

import Foundation
import SwiftData

@Model
public final class GameParticipant {
    @Attribute(.unique) public var id: UUID
    public var seatIndex: Int
    public var finalScore: Int
    public var finalRank: Int
    
    public var player: Player?
    public var game: Game?
    
    @Relationship(deleteRule: .cascade, inverse: \RoundEntry.participant)
    public var roundEntries: [RoundEntry] = []
    
    public init(
        id: UUID = UUID(),
        seatIndex: Int,
        finalScore: Int = 0,
        finalRank: Int = 0,
        player: Player? = nil,
        game: Game? = nil
    ) {
        self.id = id
        self.seatIndex = seatIndex
        self.finalScore = finalScore
        self.finalRank = finalRank
        self.player = player
        self.game = game
    }
}

import Foundation
import SwiftData

@Model
public final class RoundEntry {
    @Attribute(.unique) public var id: UUID
    public var bid: Int
    public var tricks: Int
    public var piratesCapturedBySK: Int
    public var skCapturedByMermaid: Bool
    public var points: Int
    public var cumulativeScore: Int
    
    public var round: Round?
    public var participant: GameParticipant?
    
    public init(
        id: UUID = UUID(),
        bid: Int = 0,
        tricks: Int = 0,
        piratesCapturedBySK: Int = 0,
        skCapturedByMermaid: Bool = false,
        points: Int = 0,
        cumulativeScore: Int = 0,
        round: Round? = nil,
        participant: GameParticipant? = nil
    ) {
        self.id = id
        self.bid = bid
        self.tricks = tricks
        self.piratesCapturedBySK = piratesCapturedBySK
        self.skCapturedByMermaid = skCapturedByMermaid
        self.points = points
        self.cumulativeScore = cumulativeScore
        self.round = round
        self.participant = participant
    }
    
    public var isSuccess: Bool {
        return bid == tricks
    }
}

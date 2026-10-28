import Foundation
import SwiftData

@Model
public final class Game {
    @Attribute(.unique) public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var statusRaw: String
    
    public var bonusEnabled: Bool
    public var bonusPirateBySK: Int
    public var bonusSKByMermaid: Int
    public var deckSize: Int
    public var roundModeRaw: String
    public var plannedRounds: Int
    public var startingPlayerIndex: Int
    
    public var location: String
    public var notes: String
    public var tagsRaw: String
    
    @Relationship(deleteRule: .cascade, inverse: \GameParticipant.game)
    public var participants: [GameParticipant] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Round.game)
    public var rounds: [Round] = []
    
    public var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }
    
    public var roundMode: RoundMode {
        get { RoundMode(rawValue: roundModeRaw) ?? .reducedRounds }
        set { roundModeRaw = newValue.rawValue }
    }
    
    public var tags: [String] {
        get {
            guard !tagsRaw.isEmpty else { return [] }
            return tagsRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        set {
            tagsRaw = newValue.joined(separator: ",")
        }
    }
    
    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: GameStatus = .inProgress,
        bonusEnabled: Bool = false,
        bonusPirateBySK: Int = 30,
        bonusSKByMermaid: Int = 50,
        deckSize: Int = ScoringEngine.defaultDeckSize,
        roundMode: RoundMode = .reducedRounds,
        plannedRounds: Int = 10,
        startingPlayerIndex: Int = 0,
        location: String = "",
        notes: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = status.rawValue
        self.bonusEnabled = bonusEnabled
        self.bonusPirateBySK = bonusPirateBySK
        self.bonusSKByMermaid = bonusSKByMermaid
        self.deckSize = deckSize
        self.roundModeRaw = roundMode.rawValue
        self.plannedRounds = plannedRounds
        self.startingPlayerIndex = startingPlayerIndex
        self.location = location
        self.notes = notes
        self.tagsRaw = tags.joined(separator: ",")
    }
    
    public var sortedParticipants: [GameParticipant] {
        participants.sorted { $0.seatIndex < $1.seatIndex }
    }
    
    public var sortedRounds: [Round] {
        rounds.sorted { $0.number < $1.number }
    }
    
    public var duration: TimeInterval? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }
}

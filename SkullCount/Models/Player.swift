import Foundation
import SwiftData

@Model
public final class Player {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var colorHex: String
    public var emoji: String
    public var createdAt: Date
    public var isArchived: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \GameParticipant.player)
    public var gameParticipations: [GameParticipant] = []
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#E67E22",
        emoji: String = "🏴‍☠️",
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorHex = colorHex
        self.emoji = emoji
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}

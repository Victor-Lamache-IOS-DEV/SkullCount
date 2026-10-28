import Foundation

// MARK: - Export Container DTO

public struct SkullKingExportDTO: Codable {
    public let schemaVersion: Int
    public let exportedAt: Date
    public let edition: String
    public let players: [PlayerDTO]
    public let games: [GameDTO]
    
    public init(
        schemaVersion: Int = 1,
        exportedAt: Date = Date(),
        edition: String = "classic-66",
        players: [PlayerDTO],
        games: [GameDTO]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.edition = edition
        self.players = players
        self.games = games
    }
}

// MARK: - Player DTO

public struct PlayerDTO: Codable {
    public let id: UUID
    public let name: String
    public let colorHex: String
    public let emoji: String
    public let createdAt: Date
    public let isArchived: Bool
    
    public init(
        id: UUID,
        name: String,
        colorHex: String,
        emoji: String,
        createdAt: Date,
        isArchived: Bool
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
    
    public init(from player: Player) {
        self.id = player.id
        self.name = player.name
        self.colorHex = player.colorHex
        self.emoji = player.emoji
        self.createdAt = player.createdAt
        self.isArchived = player.isArchived
    }
}

// MARK: - Game DTO

public struct GameDTO: Codable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let status: String
    public let bonusEnabled: Bool
    public let bonusPirateBySK: Int
    public let bonusSKByMermaid: Int
    public let deckSize: Int
    public let roundMode: String
    public let plannedRounds: Int
    public let startingPlayerIndex: Int
    public let location: String
    public let notes: String
    public let tags: [String]
    public let participants: [GameParticipantDTO]
    public let rounds: [RoundDTO]
    
    public init(from game: Game) {
        self.id = game.id
        self.startedAt = game.startedAt
        self.endedAt = game.endedAt
        self.status = game.status.rawValue
        self.bonusEnabled = game.bonusEnabled
        self.bonusPirateBySK = game.bonusPirateBySK
        self.bonusSKByMermaid = game.bonusSKByMermaid
        self.deckSize = game.deckSize
        self.roundMode = game.roundMode.rawValue
        self.plannedRounds = game.plannedRounds
        self.startingPlayerIndex = game.startingPlayerIndex
        self.location = game.location
        self.notes = game.notes
        self.tags = game.tags
        self.participants = game.sortedParticipants.map { GameParticipantDTO(from: $0) }
        self.rounds = game.sortedRounds.map { RoundDTO(from: $0) }
    }
}

// MARK: - GameParticipant DTO

public struct GameParticipantDTO: Codable {
    public let id: UUID
    public let playerId: UUID?
    public let playerName: String?
    public let seatIndex: Int
    public let finalScore: Int
    public let finalRank: Int
    
    public init(from participant: GameParticipant) {
        self.id = participant.id
        self.playerId = participant.player?.id
        self.playerName = participant.player?.name
        self.seatIndex = participant.seatIndex
        self.finalScore = participant.finalScore
        self.finalRank = participant.finalRank
    }
}

// MARK: - Round DTO

public struct RoundDTO: Codable {
    public let id: UUID
    public let number: Int
    public let cardsDealt: Int
    public let firstPlayerIndex: Int
    public let startedAt: Date
    public let endedAt: Date?
    public let entries: [RoundEntryDTO]
    
    public init(from round: Round) {
        self.id = round.id
        self.number = round.number
        self.cardsDealt = round.cardsDealt
        self.firstPlayerIndex = round.firstPlayerIndex
        self.startedAt = round.startedAt
        self.endedAt = round.endedAt
        self.entries = round.entries.map { RoundEntryDTO(from: $0) }
    }
}

// MARK: - RoundEntry DTO

public struct RoundEntryDTO: Codable {
    public let id: UUID
    public let participantId: UUID?
    public let bid: Int
    public let tricks: Int
    public let piratesCapturedBySK: Int
    public let skCapturedByMermaid: Bool
    public let points: Int
    public let cumulativeScore: Int
    
    public init(from entry: RoundEntry) {
        self.id = entry.id
        self.participantId = entry.participant?.id
        self.bid = entry.bid
        self.tricks = entry.tricks
        self.piratesCapturedBySK = entry.piratesCapturedBySK
        self.skCapturedByMermaid = entry.skCapturedByMermaid
        self.points = entry.points
        self.cumulativeScore = entry.cumulativeScore
    }
}

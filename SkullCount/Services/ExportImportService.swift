import Foundation
import SwiftData

public final class ExportImportService {
    
    public static let shared = ExportImportService()
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Export Full History
    
    public func exportFullJSON(modelContext: ModelContext) throws -> Data {
        let playerDescriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.createdAt)])
        let players = try modelContext.fetch(playerDescriptor)
        
        let gameDescriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let games = try modelContext.fetch(gameDescriptor)
        
        let playerDTOs = players.map { PlayerDTO(from: $0) }
        let gameDTOs = games.map { GameDTO(from: $0) }
        
        let container = SkullKingExportDTO(
            schemaVersion: 1,
            exportedAt: Date(),
            edition: "classic-66",
            players: playerDTOs,
            games: gameDTOs
        )
        
        return try jsonEncoder.encode(container)
    }
    
    // MARK: - Export Single Game
    
    public func exportSingleGameJSON(game: Game) throws -> Data {
        let gameDTO = GameDTO(from: game)
        var playerDTOs: [PlayerDTO] = []
        for p in game.sortedParticipants {
            if let pl = p.player, !playerDTOs.contains(where: { $0.id == pl.id }) {
                playerDTOs.append(PlayerDTO(from: pl))
            }
        }
        
        let container = SkullKingExportDTO(
            schemaVersion: 1,
            exportedAt: Date(),
            edition: "classic-66",
            players: playerDTOs,
            games: [gameDTO]
        )
        return try jsonEncoder.encode(container)
    }
    
    // MARK: - Export CSV
    
    public func exportRoundEntriesCSV(modelContext: ModelContext) throws -> String {
        let gameDescriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.startedAt)])
        let games = try modelContext.fetch(gameDescriptor)
        
        var csv = "GameID,Date,Status,PlayerName,SeatIndex,RoundNumber,CardsDealt,Bid,Tricks,Success,Points,CumulativeScore,BonusSKPirates,BonusSKByMermaid\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for game in games {
            let gameId = game.id.uuidString
            let dateStr = dateFormatter.string(from: game.startedAt)
            let status = game.status.rawValue
            
            for round in game.sortedRounds {
                for entry in round.entries {
                    let playerName = entry.participant?.player?.name ?? "Inconnu"
                    let seatIndex = entry.participant?.seatIndex ?? 0
                    let roundNum = round.number
                    let cards = round.cardsDealt
                    let bid = entry.bid
                    let tricks = entry.tricks
                    let success = entry.isSuccess ? 1 : 0
                    let points = entry.points
                    let cumScore = entry.cumulativeScore
                    let pirates = entry.piratesCapturedBySK
                    let mermaid = entry.skCapturedByMermaid ? 1 : 0
                    
                    csv += "\(gameId),\(dateStr),\(status),\"\(playerName)\",\(seatIndex),\(roundNum),\(cards),\(bid),\(tricks),\(success),\(points),\(cumScore),\(pirates),\(mermaid)\n"
                }
            }
        }
        
        return csv
    }
    
    // MARK: - Import JSON
    
    public enum ImportMode {
        case mergeByUUID
        case fullReplace
    }
    
    public func importJSON(data: Data, mode: ImportMode, modelContext: ModelContext) throws -> (playersImported: Int, gamesImported: Int) {
        let container = try jsonDecoder.decode(SkullKingExportDTO.self, from: data)
        
        if mode == .fullReplace {
            let allGames = try modelContext.fetch(FetchDescriptor<Game>())
            for g in allGames { modelContext.delete(g) }
            
            let allParticipants = try modelContext.fetch(FetchDescriptor<GameParticipant>())
            for p in allParticipants { modelContext.delete(p) }
            
            let allRounds = try modelContext.fetch(FetchDescriptor<Round>())
            for r in allRounds { modelContext.delete(r) }
            
            let allEntries = try modelContext.fetch(FetchDescriptor<RoundEntry>())
            for e in allEntries { modelContext.delete(e) }
            
            let allPlayers = try modelContext.fetch(FetchDescriptor<Player>())
            for p in allPlayers { modelContext.delete(p) }
            
            try modelContext.save()
        }
        
        // Fetch existing players
        let existingPlayers = try modelContext.fetch(FetchDescriptor<Player>())
        var playerMap: [UUID: Player] = [:]
        for p in existingPlayers {
            playerMap[p.id] = p
        }
        
        var playersImportedCount = 0
        for pDTO in container.players {
            if let existing = playerMap[pDTO.id] {
                existing.name = pDTO.name
                existing.colorHex = pDTO.colorHex
                existing.emoji = pDTO.emoji
                existing.isArchived = pDTO.isArchived
            } else {
                let newPlayer = Player(
                    id: pDTO.id,
                    name: pDTO.name,
                    colorHex: pDTO.colorHex,
                    emoji: pDTO.emoji,
                    createdAt: pDTO.createdAt,
                    isArchived: pDTO.isArchived
                )
                modelContext.insert(newPlayer)
                playerMap[pDTO.id] = newPlayer
                playersImportedCount += 1
            }
        }
        
        // Fetch existing games
        let existingGames = try modelContext.fetch(FetchDescriptor<Game>())
        var gameMap: [UUID: Game] = [:]
        for g in existingGames {
            gameMap[g.id] = g
        }
        
        var gamesImportedCount = 0
        for gDTO in container.games {
            // If already exists and mode is merge, remove old game entity to cleanly rebuild its rounds
            if let oldGame = gameMap[gDTO.id] {
                modelContext.delete(oldGame)
            }
            
            let game = Game(
                id: gDTO.id,
                startedAt: gDTO.startedAt,
                endedAt: gDTO.endedAt,
                status: GameStatus(rawValue: gDTO.status) ?? .finished,
                bonusEnabled: gDTO.bonusEnabled,
                bonusPirateBySK: gDTO.bonusPirateBySK,
                bonusSKByMermaid: gDTO.bonusSKByMermaid,
                deckSize: gDTO.deckSize,
                roundMode: RoundMode(rawValue: gDTO.roundMode) ?? .reducedRounds,
                plannedRounds: gDTO.plannedRounds,
                startingPlayerIndex: gDTO.startingPlayerIndex,
                location: gDTO.location,
                notes: gDTO.notes,
                tags: gDTO.tags
            )
            modelContext.insert(game)
            gamesImportedCount += 1
            
            var participantMap: [UUID: GameParticipant] = [:]
            for partDTO in gDTO.participants {
                let player = partDTO.playerId != nil ? playerMap[partDTO.playerId!] : nil
                let participant = GameParticipant(
                    id: partDTO.id,
                    seatIndex: partDTO.seatIndex,
                    finalScore: partDTO.finalScore,
                    finalRank: partDTO.finalRank,
                    player: player,
                    game: game
                )
                modelContext.insert(participant)
                game.participants.append(participant)
                participantMap[partDTO.id] = participant
            }
            
            for rDTO in gDTO.rounds {
                let round = Round(
                    id: rDTO.id,
                    number: rDTO.number,
                    cardsDealt: rDTO.cardsDealt,
                    firstPlayerIndex: rDTO.firstPlayerIndex,
                    startedAt: rDTO.startedAt,
                    endedAt: rDTO.endedAt,
                    game: game
                )
                modelContext.insert(round)
                game.rounds.append(round)
                
                for eDTO in rDTO.entries {
                    let participant = eDTO.participantId != nil ? participantMap[eDTO.participantId!] : nil
                    let entry = RoundEntry(
                        id: eDTO.id,
                        bid: eDTO.bid,
                        tricks: eDTO.tricks,
                        piratesCapturedBySK: eDTO.piratesCapturedBySK,
                        skCapturedByMermaid: eDTO.skCapturedByMermaid,
                        points: eDTO.points,
                        cumulativeScore: eDTO.cumulativeScore,
                        round: round,
                        participant: participant
                    )
                    modelContext.insert(entry)
                    round.entries.append(entry)
                    participant?.roundEntries.append(entry)
                }
            }
        }
        
        try modelContext.save()
        return (playersImportedCount, gamesImportedCount)
    }
}

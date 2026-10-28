import Foundation

/// Available round count modes for a game
public enum RoundMode: String, Codable, CaseIterable, Identifiable {
    case reducedRounds = "reducedRounds"
    case cappedTenRounds = "cappedTenRounds"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .reducedRounds:
            return "Manches réduites (recommandé)"
        case .cappedTenRounds:
            return "10 manches plafonnées (variante)"
        }
    }
    
    public var description: String {
        switch self {
        case .reducedRounds:
            return "Nombre de manches = max de cartes possibles par joueur (ex: 8 joueurs → 8 manches de 1 à 8 cartes)."
        case .cappedTenRounds:
            return "Toujours 10 manches. Au-delà du maximum de cartes, le nombre de cartes est plafonné."
        }
    }
}

/// Game status
public enum GameStatus: String, Codable, CaseIterable {
    case inProgress = "inProgress"
    case finished = "finished"
    case abandoned = "abandoned"
    
    public var displayName: String {
        switch self {
        case .inProgress:
            return "En cours"
        case .finished:
            return "Terminée"
        case .abandoned:
            return "Abandonnée"
        }
    }
}

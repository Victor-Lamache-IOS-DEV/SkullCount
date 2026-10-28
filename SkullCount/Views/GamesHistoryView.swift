import SwiftUI
import SwiftData

public struct GamesHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \.startedAt, order: .reverse) private var allGames: [Game]
    
    @State private var selectedGameForDetails: Game? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                if allGames.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(PirateTheme.gold)
                        Text("Aucune partie dans le journal")
                            .font(.headline)
                            .foregroundColor(PirateTheme.parchment)
                        Text("Lance ta première partie depuis l'accueil !")
                            .font(.caption)
                            .foregroundColor(PirateTheme.parchment.opacity(0.6))
                    }
                } else {
                    List {
                        ForEach(allGames) { game in
                            Button(action: { selectedGameForDetails = game }) {
                                gameHistoryRow(game: game)
                            }
                            .listRowBackground(PirateTheme.cardSurface)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(game)
                                    try? modelContext.save()
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Journal des parties")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedGameForDetails) { game in
                if game.status == .inProgress {
                    RoundPlayView(game: game)
                } else {
                    GameResultView(game: game)
                }
            }
        }
    }
    
    private func gameHistoryRow(game: Game) -> some View {
        let sortedParticipants = game.sortedParticipants.sorted { $0.finalRank < $1.finalRank }
        let winner = sortedParticipants.first
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(game.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(PirateTheme.gold)
                
                Spacer()
                
                Text(game.status.displayName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(game.status == .finished ? PirateTheme.emerald : PirateTheme.crimson)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(PirateTheme.deepNavy))
            }
            
            HStack(spacing: 8) {
                if let w = winner, game.status == .finished {
                    Text("👑")
                    Text("\(w.player?.name ?? "Joueur") (\(w.finalScore) pts)")
                        .font(.headline)
                        .foregroundColor(PirateTheme.parchment)
                } else {
                    Text("En cours – Manche \(game.rounds.count)/\(game.plannedRounds)")
                        .font(.headline)
                        .foregroundColor(PirateTheme.gold)
                }
                Spacer()
            }
            
            HStack(spacing: 4) {
                Text("\(game.participants.count) pirates :")
                    .font(.caption2)
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
                
                ForEach(game.sortedParticipants) { p in
                    Text(p.player?.emoji ?? "🏴‍☠️")
                        .font(.caption2)
                }
                
                if !game.location.isEmpty {
                    Spacer()
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundColor(PirateTheme.gold)
                    Text(game.location)
                        .font(.caption2)
                        .foregroundColor(PirateTheme.parchment.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

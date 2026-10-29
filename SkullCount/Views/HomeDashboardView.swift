import SwiftUI
import SwiftData

public struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Game.startedAt, order: .reverse) private var games: [Game]
    @Query private var players: [Player]
    
    @State private var showingNewGameSetup: Bool = false
    @State private var gameToResume: Game? = nil
    
    public init() {}
    
    // Check if there's an unfinished game
    public var inProgressGame: Game? {
        games.first { $0.status == .inProgress }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Clean Title Banner
                        VStack(spacing: 6) {
                            Image(systemName: "flag.2.crossed.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                            
                            Text("SkullCount")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Compteur & Statistiques – Édition Classique")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // Primary Action : Nouvelle Partie
                        PirateButton(
                            title: "Nouvelle Partie",
                            icon: "plus.circle.fill"
                        ) {
                            showingNewGameSetup = true
                        }
                        
                        // Resume in progress game if exists
                        if let activeGame = inProgressGame {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(PirateTheme.emerald)
                                        .frame(width: 10, height: 10)
                                    Text("Partie en cours détectée")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(PirateTheme.emerald)
                                    Spacer()
                                    Text("Manche \(activeGame.rounds.count)/\(activeGame.plannedRounds)")
                                        .font(.caption2)
                                        .foregroundColor(PirateTheme.parchment.opacity(0.7))
                                }
                                
                                Button(action: {
                                    gameToResume = activeGame
                                }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                        VStack(alignment: .leading) {
                                            Text("Reprendre la partie")
                                                .font(.headline)
                                            Text("\(activeGame.participants.count) pirates à table")
                                                .font(.caption2)
                                                .opacity(0.8)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(PirateTheme.midnightNavy)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.gold))
                                }
                            }
                            .pirateCard(backgroundColor: PirateTheme.deepNavy, borderColor: PirateTheme.emerald)
                        }
                        
                        // Dashboard Navigation Hub Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            NavigationLink(destination: GamesHistoryView()) {
                                hubTile(icon: "clock.arrow.circlepath", title: "Historique", subtitle: "\(games.count) parties")
                            }
                            
                            NavigationLink(destination: StatsDashboardView()) {
                                hubTile(icon: "chart.bar.xaxis", title: "Statistiques", subtitle: "Records & ELO")
                            }
                            
                            NavigationLink(destination: PlayersListView()) {
                                hubTile(icon: "person.3.fill", title: "Équipage", subtitle: "\(players.count) pirates")
                            }
                            
                            NavigationLink(destination: RulesReferenceView()) {
                                hubTile(icon: "book.pages.fill", title: "Règles", subtitle: "66 cartes")
                            }
                        }
                        
                        // Bottom Settings Link
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Réglages & Sauvegarde JSON")
                            }
                            .font(.subheadline)
                            .foregroundColor(PirateTheme.parchment.opacity(0.7))
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNewGameSetup) {
                NewGameSetupView()
            }
            .navigationDestination(item: $gameToResume) { game in
                RoundPlayView(game: game)
            }
        }
    }
    
    private func hubTile(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(PirateTheme.gold)
            
            Text(title)
                .font(.headline)
                .foregroundColor(PirateTheme.parchment)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(PirateTheme.parchment.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .pirateCard()
    }
}

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
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Reprendre la partie")
                                                .font(.body.weight(.semibold))
                                            Text("Manche \(activeGame.rounds.count)/\(activeGame.plannedRounds) • \(activeGame.participants.count) joueurs")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.green.opacity(0.4), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Dashboard Navigation Hub Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            NavigationLink(destination: GamesHistoryView()) {
                                hubTile(icon: "clock.arrow.circlepath", title: "Historique", subtitle: "\(games.count) parties")
                            }
                            
                            NavigationLink(destination: StatsDashboardView()) {
                                hubTile(icon: "chart.bar.xaxis", title: "Statistiques", subtitle: "Classement & ELO")
                            }
                            
                            NavigationLink(destination: PlayersListView()) {
                                hubTile(icon: "person.2.fill", title: "Joueurs", subtitle: "\(players.count) joueurs")
                            }
                            
                            NavigationLink(destination: SettingsView()) {
                                hubTile(icon: "gearshape.fill", title: "Réglages", subtitle: "Sauvegarde & Données")
                            }
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 94)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
    }
}

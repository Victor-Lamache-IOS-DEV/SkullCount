import SwiftUI
import SwiftData

public struct GameResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let game: Game
    
    @State private var revealedCount: Int = 0
    @State private var showingFullTable: Bool = false
    @State private var locationText: String = ""
    @State private var notesText: String = ""
    @State private var tagsText: String = ""
    @State private var rematchReady: Bool = false
    
    public init(game: Game) {
        self.game = game
    }
    
    public var sortedFinalParticipants: [GameParticipant] {
        game.sortedParticipants.sorted { $0.finalRank < $1.finalRank }
    }
    
    public var winner: GameParticipant? {
        sortedFinalParticipants.first
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        Text("🏴‍☠️ Révélation du Trésor")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(PirateTheme.gold)
                        
                        // Winner Announcement Podium
                        if let w = winner {
                            winnerPodium(winner: w)
                        }
                        
                        // Suspense Rankings List
                        rankingsList
                        
                        // Game Highlights Card
                        highlightsCard
                        
                        // Charts Module
                        GameChartsView(game: game)
                        
                        // Optional Info (Location, Notes, Tags)
                        optionalDetailsCard
                        
                        // Share & Rematch Action Buttons
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Fin de partie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminer") {
                        saveDetails()
                        dismiss()
                    }
                    .foregroundColor(PirateTheme.gold)
                }
            }
            .sheet(isPresented: $showingFullTable) {
                ScoresTableView(game: game)
            }
            .onAppear {
                locationText = game.location
                notesText = game.notes
                tagsText = game.tags.joined(separator: ", ")
                
                // Suspense reveal animation from bottom to top
                let count = game.participants.count
                for i in 1...count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.35) {
                        revealedCount = i
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func winnerPodium(winner: GameParticipant) -> some View {
        VStack(spacing: 8) {
            Text("👑 Capitaine des Sept Mers")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(PirateTheme.gold)
            
            HStack(spacing: 12) {
                Text(winner.player?.emoji ?? "🏴‍☠️")
                    .font(.system(size: 48))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(winner.player?.name ?? "Capitaine")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(Color(hex: winner.player?.colorHex ?? "#FFFFFF"))
                    
                    Text("\(winner.finalScore) points")
                        .font(.headline)
                        .foregroundColor(PirateTheme.gold)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .pirateCard(backgroundColor: PirateTheme.deepNavy, borderColor: PirateTheme.gold)
    }
    
    private var rankingsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Classement Final")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            ForEach(Array(sortedFinalParticipants.enumerated()), id: \.element.id) { index, part in
                let rank = index + 1
                let isRevealed = revealedCount >= (sortedFinalParticipants.count - index)
                
                HStack(spacing: 12) {
                    Text(rankBadge(rank))
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(width: 32)
                    
                    Text(part.player?.emoji ?? "🏴‍☠️")
                        .font(.title3)
                    
                    Text(part.player?.name ?? "Joueur")
                        .font(.headline)
                        .foregroundColor(Color(hex: part.player?.colorHex ?? "#FFFFFF"))
                    
                    Spacer()
                    
                    if isRevealed {
                        Text("\(part.finalScore) pts")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(PirateTheme.parchment)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("???")
                            .font(.headline)
                            .foregroundColor(PirateTheme.parchment.opacity(0.3))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .pirateCard()
    }
    
    private var highlightsCard: some View {
        let hl = StatsService.computeGameHighlights(game: game)
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("Faits Marquants de la Traversée")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            if let big = hl.biggestRoundPlayer {
                highlightRow(icon: "flame.fill", color: PirateTheme.emerald, title: "Plus grosse manche", detail: "\(big.name) (+\(big.points) pts, M\(big.round))")
            }
            if let drop = hl.worstDropPlayer {
                highlightRow(icon: "drop.fill", color: PirateTheme.crimson, title: "Pire chute", detail: "\(drop.name) (\(drop.points) pts, M\(drop.round))")
            }
            if let streak = hl.longestSuccessStreak {
                highlightRow(icon: "bolt.fill", color: PirateTheme.gold, title: "Plus longue série de réussites", detail: "\(streak.name) (\(streak.streak) manches)")
            }
            if !hl.heroicZeros.isEmpty {
                ForEach(hl.heroicZeros, id: \.name) { hz in
                    highlightRow(icon: "shield.fill", color: PirateTheme.oceanBlue, title: "0 Héroïque réussi", detail: "\(hz.name) à la manche \(hz.round) (\(hz.cards) cartes)")
                }
            }
            if !hl.totalDurationFormatted.isEmpty {
                highlightRow(icon: "clock.fill", color: PirateTheme.parchment, title: "Durée de la partie", detail: "\(hl.totalDurationFormatted) (moy. \(hl.avgRoundDurationFormatted) / manche)")
            }
        }
        .pirateCard()
    }
    
    private func highlightRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
                Text(detail)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.parchment)
            }
            Spacer()
        }
    }
    
    private var optionalDetailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journal de bord (facultatif)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            TextField("Lieu (ex: Taverne de Tortuga)", text: $locationText)
                .textFieldStyle(.plain)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(PirateTheme.deepNavy))
                .foregroundColor(PirateTheme.parchment)
            
            TextField("Étiquettes (séparées par une virgule)", text: $tagsText)
                .textFieldStyle(.plain)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(PirateTheme.deepNavy))
                .foregroundColor(PirateTheme.parchment)
            
            TextField("Notes sur la partie...", text: $notesText)
                .textFieldStyle(.plain)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(PirateTheme.deepNavy))
                .foregroundColor(PirateTheme.parchment)
        }
        .pirateCard()
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingFullTable = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "tablecells")
                    Text("Consulter le tableau complet")
                }
                .font(.headline)
                .foregroundColor(PirateTheme.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.deepNavy))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(PirateTheme.gold, lineWidth: 1))
            }
            
            ShareLink(
                item: generateShareSummary(),
                subject: Text("Partie de Skull King"),
                message: Text("Résultat de notre partie de Skull King !")
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Partager les résultats")
                }
                .font(.headline)
                .foregroundColor(PirateTheme.midnightNavy)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.gold))
            }
            
            PirateButton(title: "Revanche immédiate", icon: "arrow.counterclockwise") {
                launchRematch()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func rankBadge(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)e"
        }
    }
    
    private func saveDetails() {
        game.location = locationText
        game.notes = notesText
        game.tags = tagsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        try? modelContext.save()
    }
    
    private func generateShareSummary() -> String {
        var str = "🏴‍☠️ Skull King – Résultat de la partie 🏴‍☠️\n"
        for p in sortedFinalParticipants {
            str += "\(p.finalRank). \(p.player?.name ?? "Joueur") : \(p.finalScore) pts\n"
        }
        return str
    }
    
    private func launchRematch() {
        saveDetails()
        
        let newGame = Game(
            startedAt: Date(),
            status: .inProgress,
            bonusEnabled: game.bonusEnabled,
            bonusPirateBySK: game.bonusPirateBySK,
            bonusSKByMermaid: game.bonusSKByMermaid,
            deckSize: game.deckSize,
            roundMode: game.roundMode,
            plannedRounds: game.plannedRounds,
            startingPlayerIndex: Int.random(in: 0..<game.participants.count),
            location: game.location
        )
        modelContext.insert(newGame)
        
        for part in game.sortedParticipants {
            let newPart = GameParticipant(
                seatIndex: part.seatIndex,
                player: part.player,
                game: newGame
            )
            modelContext.insert(newPart)
            newGame.participants.append(newPart)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

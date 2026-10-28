import SwiftUI
import SwiftData

public struct NewGameSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Player> { !$0.isArchived }, sort: \Player.name)
    private var allPlayers: [Player]
    
    // Ordered table seats
    @State private var selectedPlayers: [Player] = []
    @State private var newPlayerName: String = ""
    @State private var newPlayerEmoji: String = "🏴‍☠️"
    @State private var newPlayerColor: String = PirateTheme.playerPalette[0]
    
    // Game options
    @State private var bonusEnabled: Bool = false
    @State private var bonusPirateValue: Int = 30
    @State private var bonusMermaidValue: Int = 50
    @State private var roundMode: RoundMode = .reducedRounds
    @State private var deckSize: Int = ScoringEngine.defaultDeckSize
    @State private var showAdvancedOptions: Bool = false
    
    // Starting player selection
    @State private var startingPlayerIndex: Int = 0
    @State private var showWheel: Bool = false
    
    // Navigation to game
    @State private var createdGame: Game? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Player Count & Round announcement
                        roundAnnouncementCard
                        
                        // Registered Players Quick Selection Chips
                        savedPlayersChipsCard
                        
                        // Add New Player Field
                        addNewPlayerCard
                        
                        // Table Seating Order
                        tableOrderCard
                        
                        // Starting Player Section
                        startingPlayerCard
                        
                        // Collapsible Advanced Settings
                        advancedSettingsCard
                        
                        // Launch Game Button
                        PirateButton(
                            title: "Lever l'ancre",
                            icon: "sailboat.fill",
                            isEnabled: selectedPlayers.count >= 2 && selectedPlayers.count <= 12
                        ) {
                            launchGame()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Nouvelle Partie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(PirateTheme.gold)
                }
            }
            .sheet(isPresented: $showWheel) {
                StartingPlayerWheelView(players: selectedPlayers) { selectedIdx in
                    startingPlayerIndex = selectedIdx
                    showWheel = false
                }
            }
            .navigationDestination(item: $createdGame) { game in
                RoundPlayView(game: game)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var roundAnnouncementCard: some View {
        let count = selectedPlayers.count
        let plannedRounds = ScoringEngine.plannedRoundsCount(playerCount: count, roundMode: roundMode, deckSize: deckSize)
        let maxCards = ScoringEngine.maxCardsPossible(playerCount: count, deckSize: deckSize)
        
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: "flag.2.crossed.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("\(count) joueur\(count > 1 ? "s" : "") → \(plannedRounds) manche\(plannedRounds > 1 ? "s" : "")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.parchment)
                Spacer()
                Text("Max \(maxCards) c.")
                    .font(.caption)
                    .foregroundColor(PirateTheme.gold)
            }
            
            if count > 6 {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(PirateTheme.crimson)
                    Text("L'édition classique est officiellement conçue pour 2 à 6 joueurs. Au-delà, le nombre de cartes par manche est réduit.")
                        .font(.caption2)
                        .foregroundColor(PirateTheme.parchment.opacity(0.8))
                }
                .padding(.top, 4)
            }
        }
        .pirateCard()
    }
    
    private var savedPlayersChipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Matelots enregistrés (1 tap pour ajouter/retirer)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            if allPlayers.isEmpty {
                Text("Aucun joueur enregistré. Crée ton premier moussaillon ci-dessous !")
                    .font(.caption)
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(allPlayers) { player in
                        let isSelected = selectedPlayers.contains(where: { $0.id == player.id })
                        Button(action: {
                            togglePlayerSelection(player)
                        }) {
                            HStack(spacing: 4) {
                                Text(player.emoji)
                                    .font(.caption)
                                Text(player.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundColor(isSelected ? PirateTheme.midnightNavy : PirateTheme.parchment)
                            .background(
                                Capsule().fill(isSelected ? Color(hex: player.colorHex) : PirateTheme.deepNavy)
                            )
                            .overlay(
                                Capsule().stroke(Color(hex: player.colorHex), lineWidth: isSelected ? 2 : 1)
                            )
                        }
                    }
                }
            }
        }
        .pirateCard()
    }
    
    private var addNewPlayerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Créer un nouveau joueur")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            HStack(spacing: 8) {
                Menu {
                    ForEach(PirateTheme.defaultEmojis, id: \.self) { emoji in
                        Button(emoji) { newPlayerEmoji = emoji }
                    }
                } label: {
                    Text(newPlayerEmoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(PirateTheme.deepNavy))
                        .overlay(Circle().stroke(PirateTheme.cardBorder, lineWidth: 1))
                }
                
                TextField("Nom du pirate...", text: $newPlayerName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.deepNavy))
                    .foregroundColor(PirateTheme.parchment)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(PirateTheme.cardBorder, lineWidth: 1))
                
                Button(action: createNewPlayer) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(PirateTheme.midnightNavy)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.gold))
                }
                .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .pirateCard()
    }
    
    private var tableOrderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ordre autour de la table")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.gold)
                Spacer()
                
                if selectedPlayers.count >= 2 {
                    Button(action: reverseOrder) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Inverser")
                        }
                        .font(.caption2)
                        .foregroundColor(PirateTheme.gold)
                    }
                }
            }
            
            if selectedPlayers.isEmpty {
                Text("Sélectionne au moins 2 joueurs.")
                    .font(.caption)
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
            } else {
                ForEach(0..<selectedPlayers.count, id: \.self) { idx in
                    let player = selectedPlayers[idx]
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(PirateTheme.gold)
                            .frame(width: 22)
                        
                        Text(player.emoji)
                            .font(.title3)
                        
                        Text(player.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: player.colorHex))
                        
                        Spacer()
                        
                        if startingPlayerIndex == idx {
                            Text("1er joueur")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.midnightNavy)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(PirateTheme.gold))
                        }
                        
                        // Move buttons
                        if idx > 0 {
                            Button(action: { movePlayer(from: idx, to: idx - 1) }) {
                                Image(systemName: "chevron.up")
                                    .foregroundColor(PirateTheme.parchment.opacity(0.7))
                            }
                        }
                        if idx < selectedPlayers.count - 1 {
                            Button(action: { movePlayer(from: idx, to: idx + 1) }) {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(PirateTheme.parchment.opacity(0.7))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .pirateCard()
    }
    
    private var startingPlayerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premier joueur de la Manche 1")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            HStack(spacing: 12) {
                Button(action: { showWheel = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill")
                        Text("Tirer au sort (Boussole)")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.midnightNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.gold))
                }
                .disabled(selectedPlayers.count < 2)
                
                Menu {
                    ForEach(0..<selectedPlayers.count, id: \.self) { idx in
                        Button("\(selectedPlayers[idx].emoji) \(selectedPlayers[idx].name)") {
                            startingPlayerIndex = idx
                        }
                    }
                } label: {
                    Text("Choisir...")
                        .font(.subheadline)
                        .foregroundColor(PirateTheme.gold)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.deepNavy))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PirateTheme.gold.opacity(0.5), lineWidth: 1))
                }
                .disabled(selectedPlayers.count < 2)
            }
        }
        .pirateCard()
    }
    
    private var advancedSettingsCard: some View {
        DisclosureGroup(isExpanded: $showAdvancedOptions) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $bonusEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bonus de capture (Pirates / Sirène)")
                            .font(.subheadline)
                            .foregroundColor(PirateTheme.parchment)
                        Text("+30 par pirate capturé par le Skull King, +50 pour Sirène capturant Skull King.")
                            .font(.caption2)
                            .foregroundColor(PirateTheme.parchment.opacity(0.6))
                    }
                }
                .tint(PirateTheme.gold)
                
                Divider().background(PirateTheme.cardBorder)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mode des manches")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(PirateTheme.gold)
                    
                    Picker("Mode", selection: $roundMode) {
                        ForEach(RoundMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(roundMode.description)
                        .font(.caption2)
                        .foregroundColor(PirateTheme.parchment.opacity(0.7))
                }
                
                Divider().background(PirateTheme.cardBorder)
                
                HStack {
                    Text("Taille du paquet :")
                        .font(.subheadline)
                        .foregroundColor(PirateTheme.parchment)
                    Spacer()
                    Stepper("\(deckSize) cartes", value: $deckSize, in: 40...120)
                        .foregroundColor(PirateTheme.gold)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("Options de la partie")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.parchment)
            }
        }
        .pirateCard()
    }
    
    // MARK: - Actions
    
    private func togglePlayerSelection(_ player: Player) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let idx = selectedPlayers.firstIndex(where: { $0.id == player.id }) {
            selectedPlayers.remove(at: idx)
            if startingPlayerIndex >= selectedPlayers.count {
                startingPlayerIndex = max(0, selectedPlayers.count - 1)
            }
        } else {
            selectedPlayers.append(player)
        }
    }
    
    private func createNewPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Prevent duplicate (case insensitive)
        if let existing = allPlayers.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            if !selectedPlayers.contains(where: { $0.id == existing.id }) {
                selectedPlayers.append(existing)
            }
            newPlayerName = ""
            return
        }
        
        let randomColor = PirateTheme.playerPalette[selectedPlayers.count % PirateTheme.playerPalette.count]
        let player = Player(
            name: trimmed,
            colorHex: randomColor,
            emoji: newPlayerEmoji
        )
        modelContext.insert(player)
        selectedPlayers.append(player)
        newPlayerName = ""
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func reverseOrder() {
        selectedPlayers.reverse()
        startingPlayerIndex = (selectedPlayers.count - 1) - startingPlayerIndex
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func movePlayer(from: Int, to: Int) {
        let p = selectedPlayers.remove(at: from)
        selectedPlayers.insert(p, at: to)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func launchGame() {
        let plannedRounds = ScoringEngine.plannedRoundsCount(
            playerCount: selectedPlayers.count,
            roundMode: roundMode,
            deckSize: deckSize
        )
        
        let game = Game(
            startedAt: Date(),
            status: .inProgress,
            bonusEnabled: bonusEnabled,
            bonusPirateBySK: bonusPirateValue,
            bonusSKByMermaid: bonusMermaidValue,
            deckSize: deckSize,
            roundMode: roundMode,
            plannedRounds: plannedRounds,
            startingPlayerIndex: startingPlayerIndex
        )
        modelContext.insert(game)
        
        for (idx, p) in selectedPlayers.enumerated() {
            let part = GameParticipant(
                seatIndex: idx,
                player: p,
                game: game
            )
            modelContext.insert(part)
            game.participants.append(part)
        }
        
        try? modelContext.save()
        createdGame = game
    }
}

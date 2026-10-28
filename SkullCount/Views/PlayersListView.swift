import SwiftUI
import SwiftData

public struct PlayersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \.name) private var allPlayers: [Player]
    
    @State private var showingAddPlayerModal: Bool = false
    @State private var playerToEdit: Player? = nil
    @State private var playerToDelete: Player? = nil
    @State private var showingDeleteAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                List {
                    ForEach(allPlayers) { player in
                        HStack(spacing: 12) {
                            Text(player.emoji)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(player.name)
                                        .font(.headline)
                                        .foregroundColor(Color(hex: player.colorHex))
                                    
                                    if player.isArchived {
                                        Text("Archivé")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(PirateTheme.deepNavy))
                                    }
                                }
                                
                                Text("\(player.gameParticipations.count) partie(s) jouée(s)")
                                    .font(.caption)
                                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Button(action: { playerToEdit = player }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(PirateTheme.gold)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(PirateTheme.cardSurface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                playerToDelete = player
                                showingDeleteAlert = true
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                            
                            Button {
                                player.isArchived.toggle()
                                try? modelContext.save()
                            } label: {
                                Label(player.isArchived ? "Désarchiver" : "Archiver", systemImage: player.isArchived ? "tray.and.arrow.up" : "archivebox")
                            }
                            .tint(PirateTheme.oceanBlue)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Équipage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlayerModal = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(PirateTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayerModal) {
                PlayerEditSheet(player: nil)
            }
            .sheet(item: $playerToEdit) { p in
                PlayerEditSheet(player: p)
            }
            .alert("Supprimer ce joueur ?", isPresented: $showingDeleteAlert) {
                Button("Supprimer", role: .destructive) {
                    if let p = playerToDelete {
                        modelContext.delete(p)
                        try? modelContext.save()
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Si ce pirate a déjà joué des parties, son historique sera supprimé ou rattaché à Inconnu. Préfère l'archivage si tu souhaites conserver ses statistiques.")
            }
        }
    }
}

public struct PlayerEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let player: Player?
    
    @State private var name: String = ""
    @State private var emoji: String = "🏴‍☠️"
    @State private var colorHex: String = PirateTheme.playerPalette[0]
    
    public init(player: Player?) {
        self.player = player
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Emoji Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PirateTheme.defaultEmojis, id: \.self) { em in
                                Button(action: { emoji = em }) {
                                    Text(em)
                                        .font(.title)
                                        .padding(8)
                                        .background(Circle().fill(emoji == em ? PirateTheme.gold : PirateTheme.cardSurface))
                                }
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Name Field
                    TextField("Nom du pirate", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.deepNavy))
                        .foregroundColor(PirateTheme.parchment)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(PirateTheme.cardBorder, lineWidth: 1))
                    
                    // Color Palette Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Couleur de bannière")
                            .font(.caption)
                            .foregroundColor(PirateTheme.gold)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                            ForEach(PirateTheme.playerPalette, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        colorHex = hex
                                    }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    PirateButton(title: "Enregistrer", icon: "checkmark") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle(player == nil ? "Nouveau Pirate" : "Modifier Pirate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(PirateTheme.gold)
                }
            }
            .onAppear {
                if let p = player {
                    name = p.name
                    emoji = p.emoji
                    colorHex = p.colorHex
                }
            }
        }
    }
    
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let p = player {
            p.name = trimmed
            p.emoji = emoji
            p.colorHex = colorHex
        } else {
            let newP = Player(name: trimmed, colorHex: colorHex, emoji: emoji)
            modelContext.insert(newP)
        }
        try? modelContext.save()
        dismiss()
    }
}

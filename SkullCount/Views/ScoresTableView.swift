import SwiftUI

public struct ScoresTableView: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    var onSelectRoundToEdit: ((Int) -> Void)? = nil
    
    public init(game: Game, onSelectRoundToEdit: ((Int) -> Void)? = nil) {
        self.game = game
        self.onSelectRoundToEdit = onSelectRoundToEdit
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row (Players)
                        HStack(spacing: 0) {
                            Text("Manche")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.gold)
                                .frame(width: 70, height: 44)
                                .background(PirateTheme.deepNavy)
                            
                            ForEach(game.sortedParticipants) { part in
                                VStack(spacing: 2) {
                                    Text(part.player?.emoji ?? "🏴‍☠️")
                                        .font(.caption)
                                    Text(part.player?.name.prefix(7) ?? "")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: part.player?.colorHex ?? "#FFFFFF"))
                                }
                                .frame(width: 85, height: 44)
                                .background(PirateTheme.deepNavy)
                            }
                        }
                        .overlay(Rectangle().frame(height: 1).foregroundColor(PirateTheme.cardBorder), alignment: .bottom)
                        
                        // Rounds rows
                        ForEach(game.sortedRounds) { round in
                            HStack(spacing: 0) {
                                Button(action: {
                                    if let edit = onSelectRoundToEdit {
                                        edit(round.number)
                                    }
                                }) {
                                    HStack(spacing: 2) {
                                        Text("M\(round.number)")
                                            .fontWeight(.bold)
                                        Text("(\(round.cardsDealt)c)")
                                            .font(.caption2)
                                    }
                                    .font(.caption)
                                    .foregroundColor(PirateTheme.gold)
                                    .frame(width: 70, height: 44)
                                    .background(PirateTheme.cardSurface)
                                }
                                
                                ForEach(game.sortedParticipants) { part in
                                    let entry = round.entries.first(where: { $0.participant?.id == part.id })
                                    VStack(spacing: 2) {
                                        if let e = entry {
                                            HStack(spacing: 3) {
                                                Text("\(e.bid)/\(e.tricks)")
                                                    .font(.caption2)
                                                    .foregroundColor(e.isSuccess ? PirateTheme.emerald : PirateTheme.crimson)
                                                Text("\(e.points > 0 ? "+" : "")\(e.points)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(PirateTheme.parchment)
                                            }
                                            Text("∑ \(e.cumulativeScore)")
                                                .font(.system(size: 10))
                                                .foregroundColor(PirateTheme.gold.opacity(0.8))
                                        } else {
                                            Text("-")
                                                .font(.caption)
                                                .foregroundColor(PirateTheme.parchment.opacity(0.3))
                                        }
                                    }
                                    .frame(width: 85, height: 44)
                                    .background(PirateTheme.cardSurface.opacity(0.6))
                                }
                            }
                            .overlay(Rectangle().frame(height: 0.5).foregroundColor(PirateTheme.cardBorder.opacity(0.4)), alignment: .bottom)
                        }
                        
                        // Total / Final Score Row
                        HStack(spacing: 0) {
                            Text("Total")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(PirateTheme.gold)
                                .frame(width: 70, height: 44)
                                .background(PirateTheme.deepNavy)
                            
                            ForEach(game.sortedParticipants) { part in
                                Text("\(part.finalScore) pts")
                                    .font(.caption)
                                    .fontWeight(.heavy)
                                    .foregroundColor(PirateTheme.gold)
                                    .frame(width: 85, height: 44)
                                    .background(PirateTheme.deepNavy)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Tableau des scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(PirateTheme.gold)
                }
            }
        }
    }
}

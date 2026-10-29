import SwiftUI
import Charts
import SwiftData

public struct PlayerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let player: Player
    let allPlayers: [Player]
    let allGames: [Game]
    let filter: StatsFilter
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Profile Card
                    HStack(spacing: 16) {
                        Text(player.emoji)
                            .font(.system(size: 48))
                            .frame(width: 72, height: 72)
                            .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.name)
                                .font(.title2.weight(.bold))
                                .foregroundColor(Color(hex: player.colorHex))
                            
                            let elo = RatingService.computePlayerElo(for: player, allPlayers: allPlayers, games: allGames)
                            HStack(spacing: 8) {
                                Text("Score ELO")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(elo))")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
                    
                    let stats = StatsService.computeExhaustivePlayerProfile(player: player, allPlayers: allPlayers, games: allGames, filter: filter)
                    
                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        metricTile(title: "Parties jouées", value: "\(stats.totalGames)")
                        metricTile(title: "Victoires", value: "\(stats.wins) (\(Int(stats.winRate * 100))%)")
                        metricTile(title: "Rang normalisé", value: String(format: "%.2f", stats.normalizedRank))
                        metricTile(title: "Score moyen", value: "\(Int(stats.avgScore)) pts")
                        metricTile(title: "Régularité (Écart-type)", value: "±\(Int(stats.scoreStandardDeviation)) pts")
                        metricTile(title: "Points / manche", value: String(format: "%.1f", stats.avgPointsPerRound))
                    }
                    
                    // Psychology & Habits
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Psychologie des Paris & Biais")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Taux de réussite global")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(stats.overallSuccessRate * 100))% (\(stats.successBidsCount)/\(stats.totalBidsCount))")
                                .font(.caption.weight(.bold))
                        }
                        
                        HStack {
                            Text("Pari relatif moyen (Pari / Cartes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f", stats.relativeBidAvg))
                                .font(.caption.weight(.semibold))
                        }
                        
                        HStack {
                            Text("Biais moyen (Plis − Pari)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f", stats.avgBias))
                                .font(.caption.weight(.semibold))
                        }
                        
                        Text(stats.biasLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        
                        if !stats.habits.isEmpty {
                            Divider().padding(.vertical, 4)
                            Text("Habitudes observées :")
                                .font(.caption.weight(.semibold))
                            ForEach(stats.habits.prefix(4)) { h in
                                Text("• \(h.text)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
                    
                    // Success Rate by Cards Dealt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Taux de Réussite selon le Nombre de Cartes")
                            .font(.subheadline.weight(.bold))
                        
                        Chart {
                            ForEach(1...10, id: \.self) { c in
                                let rate = stats.successRateByCardsDealt[c] ?? 0
                                BarMark(
                                    x: .value("Cartes", "\(c)c"),
                                    y: .value("Réussite", Int(rate * 100))
                                )
                                .foregroundStyle(Color.accentColor)
                            }
                        }
                        .frame(height: 140)
                        
                        Text("Réussite par position dans le tour (1er → dernier)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        HStack(spacing: 6) {
                            ForEach(0..<6, id: \.self) { pos in
                                let rate = stats.successRateByTurnPosition[pos] ?? 0
                                VStack(spacing: 2) {
                                    Text("\(pos + 1)e")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(rate * 100))%")
                                        .font(.caption.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(uiColor: .tertiarySystemFill)))
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
                    
                    // Bid x Tricks Matrix
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Matrice Paris × Plis Réalisés")
                            .font(.subheadline.weight(.bold))
                        Text("La diagonale verte représente les paris exactement honorés.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                            ForEach(0..<6, id: \.self) { b in
                                ForEach(0..<6, id: \.self) { t in
                                    let count = stats.bidTricksMatrix.first(where: { $0.bid == b && $0.tricks == t })?.count ?? 0
                                    let isSuccess = b == t
                                    VStack(spacing: 1) {
                                        Text("\(b)p/\(t)t")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                        Text("\(count)")
                                            .font(.caption2.weight(.bold))
                                            .foregroundColor(count > 0 ? (isSuccess ? .green : .red) : Color(uiColor: .tertiaryLabel))
                                    }
                                    .frame(height: 32)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isSuccess ? Color.green.opacity(count > 0 ? 0.2 : 0.05) : Color(uiColor: .tertiarySystemFill))
                                    )
                                }
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
                    
                    // Progression over time
                    if stats.rollingFiveGamesAvgScores.count >= 2 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progression (Moyenne glissante sur 5 parties)")
                                .font(.subheadline.weight(.bold))
                            
                            Chart {
                                ForEach(stats.rollingFiveGamesAvgScores, id: \.gameIndex) { item in
                                    LineMark(
                                        x: .value("Partie", item.gameIndex),
                                        y: .value("Moyenne", item.avgScore)
                                    )
                                    .foregroundStyle(Color.accentColor)
                                    PointMark(
                                        x: .value("Partie", item.gameIndex),
                                        y: .value("Moyenne", item.avgScore)
                                    )
                                    .foregroundStyle(Color.orange)
                                }
                            }
                            .frame(height: 140)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
                    }
                    
                    // Rivalries (Nemesis & Victim)
                    if stats.nemesis != nil || stats.favoriteVictim != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rivalités & Affinités")
                                .font(.subheadline.weight(.bold))
                            
                            if let nem = stats.nemesis {
                                HStack {
                                    Text("🎯 Bête noire :")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text("\(nem.player.emoji) \(nem.player.name)")
                                        .font(.caption.weight(.bold))
                                    Spacer()
                                    Text("\(Int(nem.winRateAgainst * 100))% vict. (\(nem.games) duels)")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            if let fav = stats.favoriteVictim {
                                HStack {
                                    Text("⚔️ Victime favorite :")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("\(fav.player.emoji) \(fav.player.name)")
                                        .font(.caption.weight(.bold))
                                    Spacer()
                                    Text("\(Int(fav.winRateAgainst * 100))% vict. (\(fav.games) duels)")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Profil Joueur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
    
    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
    }
}

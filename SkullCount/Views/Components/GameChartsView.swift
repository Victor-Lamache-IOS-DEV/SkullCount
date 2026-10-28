import SwiftUI
import Charts
import SwiftData

public struct GameChartsView: View {
    let game: Game
    @State private var selectedMetric: ChartMetric = .cumulativeScore
    
    enum ChartMetric: String, CaseIterable, Identifiable {
        case cumulativeScore = "Scores"
        case rankEvolution = "Rang"
        case roundPoints = "Points / M."
        case tableBids = "Paris"
        case heatmap = "Heatmap"
        
        var id: String { rawValue }
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            Picker("Métrique", selection: $selectedMetric) {
                ForEach(ChartMetric.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            
            switch selectedMetric {
            case .cumulativeScore:
                cumulativeScoreChart
            case .rankEvolution:
                rankBumpChart
            case .roundPoints:
                roundPointsBarChart
            case .tableBids:
                tableBidsComparisonChart
            case .heatmap:
                gameHeatmapView
            }
        }
        .pirateCard()
    }
    
    // MARK: - Cumulative Score Chart
    
    private var cumulativeScoreChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Évolution du score cumulé")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            Chart {
                ForEach(game.sortedParticipants) { part in
                    let playerColor = Color(hex: part.player?.colorHex ?? "#FFFFFF")
                    let entries = part.roundEntries.sorted { ($0.round?.number ?? 0) < ($1.round?.number ?? 0) }
                    
                    LineMark(
                        x: .value("Manche", 0),
                        y: .value("Score", 0)
                    )
                    .foregroundStyle(playerColor)
                    
                    ForEach(entries) { entry in
                        let rNum = entry.round?.number ?? 0
                        LineMark(
                            x: .value("Manche", rNum),
                            y: .value("Score", entry.cumulativeScore)
                        )
                        .foregroundStyle(by: .value("Joueur", part.player?.name ?? ""))
                        
                        PointMark(
                            x: .value("Manche", rNum),
                            y: .value("Score", entry.cumulativeScore)
                        )
                        .foregroundStyle(playerColor)
                    }
                }
            }
            .chartLegend(.visible)
            .chartXScale(domain: 0...game.plannedRounds)
            .frame(height: 220)
        }
    }
    
    // MARK: - Rank Bump Chart
    
    private var rankBumpChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bump Chart – Évolution des rangs")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            let rounds = game.sortedRounds
            let n = game.participants.count
            
            Chart {
                ForEach(game.sortedParticipants) { part in
                    let playerColor = Color(hex: part.player?.colorHex ?? "#FFFFFF")
                    
                    ForEach(rounds) { round in
                        let roundEntries = round.entries.sorted { $0.cumulativeScore > $1.cumulativeScore }
                        if let rankIndex = roundEntries.firstIndex(where: { $0.participant?.id == part.id }) {
                            let rank = rankIndex + 1
                            LineMark(
                                x: .value("Manche", round.number),
                                y: .value("Rang", rank)
                            )
                            .foregroundStyle(by: .value("Joueur", part.player?.name ?? ""))
                            
                            PointMark(
                                x: .value("Manche", round.number),
                                y: .value("Rang", rank)
                            )
                            .foregroundStyle(playerColor)
                        }
                    }
                }
            }
            .chartYScale(domain: .automatic(reversed: true))
            .chartYAxis {
                AxisMarks(values: Array(1...max(2, n)))
            }
            .frame(height: 220)
        }
    }
    
    // MARK: - Round Points Bars
    
    private var roundPointsBarChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Points marqués / perdus par manche")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            Chart {
                ForEach(game.sortedRounds) { round in
                    ForEach(round.entries) { entry in
                        BarMark(
                            x: .value("Manche", "M\(round.number)"),
                            y: .value("Points", entry.points)
                        )
                        .foregroundStyle(by: .value("Joueur", entry.participant?.player?.name ?? ""))
                        .position(by: .value("Joueur", entry.participant?.player?.name ?? ""))
                    }
                }
            }
            .frame(height: 220)
        }
    }
    
    // MARK: - Table Bids Comparison
    
    private var tableBidsComparisonChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total des paris vs Cartes distribuées")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            Chart {
                ForEach(game.sortedRounds) { round in
                    let totalBids = round.entries.reduce(0) { $0 + $1.bid }
                    
                    BarMark(
                        x: .value("Manche", "M\(round.number)"),
                        y: .value("Paris", totalBids)
                    )
                    .foregroundStyle(PirateTheme.gold)
                    
                    LineMark(
                        x: .value("Manche", "M\(round.number)"),
                        y: .value("Cartes", round.cardsDealt)
                    )
                    .foregroundStyle(PirateTheme.oceanBlue)
                    .lineStyle(StrokeStyle(lineWidth: 3, dash: [4, 4]))
                }
            }
            .frame(height: 220)
        }
    }
    
    // MARK: - Carte de Chaleur Joueurs x Manches (Heatmap)
    
    private var gameHeatmapView: some View {
        let cells = StatsService.computeGameHeatmap(game: game)
        let participants = game.sortedParticipants
        let rounds = game.sortedRounds
        
        return VStack(alignment: .leading, spacing: 6) {
            Text("Carte de chaleur Joueurs × Manches")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            Text("Vert = réussi • Rouge = raté (avec l'écart de plis)")
                .font(.system(size: 10))
                .foregroundColor(PirateTheme.parchment.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // Header of rounds
                    HStack(spacing: 4) {
                        Text("")
                            .frame(width: 60, height: 26)
                        ForEach(rounds) { r in
                            Text("M\(r.number)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.gold)
                                .frame(width: 38, height: 26)
                        }
                    }
                    
                    // Each player row
                    ForEach(participants) { part in
                        HStack(spacing: 4) {
                            Text(part.player?.name.prefix(6) ?? "")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: part.player?.colorHex ?? "#FFFFFF"))
                                .frame(width: 60, height: 28, alignment: .leading)
                            
                            ForEach(rounds) { r in
                                let cell = cells.first(where: { $0.playerId == part.player?.id && $0.roundNumber == r.number })
                                if let c = cell {
                                    VStack(spacing: 1) {
                                        Text(c.isSuccess ? "✓" : "\(c.diff > 0 ? "+" : "")\(c.diff)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(c.isSuccess ? PirateTheme.midnightNavy : .white)
                                        Text("\(c.points)")
                                            .font(.system(size: 7))
                                            .foregroundColor(c.isSuccess ? PirateTheme.midnightNavy.opacity(0.8) : .white.opacity(0.8))
                                    }
                                    .frame(width: 38, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(c.isSuccess ? PirateTheme.emerald : PirateTheme.crimson.opacity(0.85))
                                    )
                                } else {
                                    Rectangle()
                                        .fill(PirateTheme.deepNavy)
                                        .frame(width: 38, height: 28)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import SwiftUI
import Charts
import SwiftData

// MARK: - Dedicated Chart Data Models (Precomputed to avoid Swift type-checker timeouts)

struct ScorePointData: Identifiable {
    let id = UUID()
    let playerName: String
    let colorHex: String
    let roundNumber: Int
    let score: Int
}

struct RankPointData: Identifiable {
    let id = UUID()
    let playerName: String
    let colorHex: String
    let roundNumber: Int
    let rank: Int
}

struct RoundBarData: Identifiable {
    let id = UUID()
    let playerName: String
    let roundLabel: String
    let points: Int
}

struct TableBidBarData: Identifiable {
    let id = UUID()
    let roundLabel: String
    let totalBids: Int
    let cardsDealt: Int
}

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
    
    public init(game: Game) {
        self.game = game
    }
    
    // MARK: - Precomputed Data
    
    private var scorePoints: [ScorePointData] {
        var points: [ScorePointData] = []
        for part in game.sortedParticipants {
            let name = part.player?.name ?? "Joueur"
            let color = part.player?.colorHex ?? "#FFFFFF"
            // Start at 0
            points.append(ScorePointData(playerName: name, colorHex: color, roundNumber: 0, score: 0))
            let sortedEntries = part.roundEntries.sorted { ($0.round?.number ?? 0) < ($1.round?.number ?? 0) }
            for e in sortedEntries {
                let rNum = e.round?.number ?? 0
                points.append(ScorePointData(playerName: name, colorHex: color, roundNumber: rNum, score: e.cumulativeScore))
            }
        }
        return points
    }
    
    private var rankPoints: [RankPointData] {
        var points: [RankPointData] = []
        let rounds = game.sortedRounds
        for part in game.sortedParticipants {
            let name = part.player?.name ?? "Joueur"
            let color = part.player?.colorHex ?? "#FFFFFF"
            for round in rounds {
                let roundEntries = round.entries.sorted { $0.cumulativeScore > $1.cumulativeScore }
                if let rankIndex = roundEntries.firstIndex(where: { $0.participant?.id == part.id }) {
                    points.append(RankPointData(playerName: name, colorHex: color, roundNumber: round.number, rank: rankIndex + 1))
                }
            }
        }
        return points
    }
    
    private var roundBars: [RoundBarData] {
        var bars: [RoundBarData] = []
        for round in game.sortedRounds {
            let label = "M\(round.number)"
            for entry in round.entries {
                let name = entry.participant?.player?.name ?? "Joueur"
                bars.append(RoundBarData(playerName: name, roundLabel: label, points: entry.points))
            }
        }
        return bars
    }
    
    private var tableBidsBars: [TableBidBarData] {
        var data: [TableBidBarData] = []
        for round in game.sortedRounds {
            let label = "M\(round.number)"
            let total = round.entries.reduce(0) { $0 + $1.bid }
            data.append(TableBidBarData(roundLabel: label, totalBids: total, cardsDealt: round.cardsDealt))
        }
        return data
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
            
            Chart(scorePoints) { item in
                LineMark(
                    x: .value("Manche", item.roundNumber),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(by: .value("Joueur", item.playerName))
                
                PointMark(
                    x: .value("Manche", item.roundNumber),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(Color(hex: item.colorHex))
            }
            .chartLegend(.visible)
            .chartXScale(domain: 0...game.plannedRounds)
            .frame(height: 220)
        }
    }
    
    // MARK: - Rank Bump Chart
    
    private var rankBumpChart: some View {
        let n = game.participants.count
        
        return VStack(alignment: .leading, spacing: 6) {
            Text("Bump Chart – Évolution des rangs")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            Chart(rankPoints) { item in
                LineMark(
                    x: .value("Manche", item.roundNumber),
                    y: .value("Rang", item.rank)
                )
                .foregroundStyle(by: .value("Joueur", item.playerName))
                
                PointMark(
                    x: .value("Manche", item.roundNumber),
                    y: .value("Rang", item.rank)
                )
                .foregroundStyle(Color(hex: item.colorHex))
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
            
            Chart(roundBars) { item in
                BarMark(
                    x: .value("Manche", item.roundLabel),
                    y: .value("Points", item.points)
                )
                .foregroundStyle(by: .value("Joueur", item.playerName))
                .position(by: .value("Joueur", item.playerName))
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
            
            Chart(tableBidsBars) { item in
                BarMark(
                    x: .value("Manche", item.roundLabel),
                    y: .value("Paris", item.totalBids)
                )
                .foregroundStyle(PirateTheme.gold)
                
                LineMark(
                    x: .value("Manche", item.roundLabel),
                    y: .value("Cartes", item.cardsDealt)
                )
                .foregroundStyle(PirateTheme.oceanBlue)
                .lineStyle(StrokeStyle(lineWidth: 3, dash: [4, 4]))
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
                    
                    ForEach(participants) { part in
                        HStack(spacing: 4) {
                            Text(part.player?.name.prefix(6) ?? "")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: part.player?.colorHex ?? "#FFFFFF"))
                                .frame(width: 60, height: 28, alignment: .leading)
                            
                            ForEach(rounds) { r in
                                heatmapCellView(for: part, round: r, cells: cells)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func heatmapCellView(for part: GameParticipant, round: Round, cells: [GameHeatmapCell]) -> some View {
        if let c = cells.first(where: { $0.playerId == part.player?.id && $0.roundNumber == round.number }) {
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

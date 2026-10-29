import SwiftUI
import Charts
import SwiftData

public struct StatsDashboardView: View {
    @Query private var allGames: [Game]
    @Query(filter: #Predicate<Player> { !$0.isArchived }, sort: \Player.name)
    private var allPlayers: [Player]
    
    @State private var selectedTab: StatsTab = .leaderboard
    @State private var filter = StatsFilter()
    @State private var showFilterSheet: Bool = false
    
    enum StatsTab: String, CaseIterable, Identifiable {
        case leaderboard = "Classement"
        case playerProfile = "Profils"
        case headToHead = "Duels"
        case confrontationMatrix = "Matrice"
        case hallOfFame = "Records"
        case tableFun = "Table & Fun"
        
        var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Summary Bar
                    filterBar
                    
                    // Tab Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(StatsTab.allCases) { tab in
                                let isSel = selectedTab == tab
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedTab = tab
                                }) {
                                    Text(tab.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(isSel ? .semibold : .regular)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .foregroundColor(isSel ? .white : Color(uiColor: .label))
                                        .background(
                                            Capsule().fill(isSel ? Color.primary : Color(uiColor: .tertiarySystemFill))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case .leaderboard:
                                leaderboardTabContent
                            case .playerProfile:
                                playerProfileTabContent
                            case .headToHead:
                                headToHeadTabContent
                            case .confrontationMatrix:
                                confrontationMatrixTabContent
                            case .hallOfFame:
                                hallOfFameTabContent
                            case .tableFun:
                                tableFunTabContent
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(filter.playerCount != nil || filter.timeRange != .allTime || filter.tag != nil ? PirateTheme.gold : PirateTheme.parchment.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
        }
    }
    
    // MARK: - Filter Bar & Sheet
    
    private var filterBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption2)
                Text(filter.timeRange.rawValue)
                if let p = filter.playerCount {
                    Text("• \(p) joueurs")
                }
                if let t = filter.tag {
                    Text("• Tag: \(t)")
                }
            }
            .font(.caption2)
            .foregroundColor(PirateTheme.gold)
            
            Spacer()
            
            Button("Modifier") {
                showFilterSheet = true
            }
            .font(.caption2)
            .foregroundColor(PirateTheme.parchment.opacity(0.8))
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(PirateTheme.deepNavy)
    }
    
    private var filterSheet: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                Form {
                    Section("Période") {
                        Picker("Période", selection: $filter.timeRange) {
                            ForEach(StatsFilter.TimeRange.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                    }
                    
                    Section("Nombre de joueurs autour de la table") {
                        Picker("Joueurs", selection: $filter.playerCount) {
                            Text("Tous").tag(nil as Int?)
                            ForEach(2...12, id: \.self) { c in
                                Text("\(c) joueurs").tag(c as Int?)
                            }
                        }
                    }
                    
                    Section("Joueur requis dans la partie") {
                        Picker("Présence", selection: $filter.requiredPlayerId) {
                            Text("Aucun en particulier").tag(nil as UUID?)
                            ForEach(allPlayers) { pl in
                                Text("\(pl.emoji) \(pl.name)").tag(pl.id as UUID?)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Appliquer") { showFilterSheet = false }
                        .foregroundColor(PirateTheme.gold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Réinitialiser") {
                        filter = StatsFilter()
                        showFilterSheet = false
                    }
                    .foregroundColor(PirateTheme.crimson)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - 1. General Leaderboard Tab
    
    @State private var leaderboardSort: LeaderboardSort = .elo
    @State private var minGamesFilter: Int = 5
    
    enum LeaderboardSort: String, CaseIterable, Identifiable {
        case elo = "ELO"
        case winRate = "% Victoires"
        case normRank = "Rang normalisé"
        case avgRank = "Rang brut"
        case avgScore = "Score moyen"
        case bidRate = "% Paris"
        case totalWins = "Victoires"
        case totalPoints = "Total points"
        
        var id: String { rawValue }
    }
    
    private var leaderboardTabContent: some View {
        let filteredGames = filter.apply(to: allGames)
        let rawItems = RatingService.computeLeaderboards(players: allPlayers, games: filteredGames)
        let qualifiedItems = rawItems.filter { $0.totalGames >= minGamesFilter }
        
        let sortedItems: [PlayerLeaderboardItem] = {
            switch leaderboardSort {
            case .elo: return qualifiedItems.sorted { $0.currentElo > $1.currentElo }
            case .winRate: return qualifiedItems.sorted { $0.winRate > $1.winRate }
            case .normRank: return qualifiedItems.sorted { $0.normalizedRank > $1.normalizedRank }
            case .avgRank: return qualifiedItems.sorted { $0.averageRank < $1.averageRank }
            case .avgScore: return qualifiedItems.sorted { $0.averageScore > $1.averageScore }
            case .bidRate: return qualifiedItems.sorted { $0.bidSuccessRate > $1.bidSuccessRate }
            case .totalWins: return qualifiedItems.sorted { $0.totalWins > $1.totalWins }
            case .totalPoints: return qualifiedItems.sorted { $0.totalPoints > $1.totalPoints }
            }
        }()
        
        return VStack(spacing: 12) {
            HStack {
                Text("Minimum \(minGamesFilter) parties")
                    .font(.caption2)
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
                Stepper("", value: $minGamesFilter, in: 0...20)
                    .labelsHidden()
                
                Spacer()
                
                Picker("Tri", selection: $leaderboardSort) {
                    ForEach(LeaderboardSort.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)
            }
            
            ForEach(Array(sortedItems.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 12) {
                    Text("\(idx + 1)")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(idx == 0 ? PirateTheme.gold : PirateTheme.parchment.opacity(0.6))
                        .frame(width: 26)
                    
                    Text(item.player.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.player.name)
                            .font(.headline)
                            .foregroundColor(Color(hex: item.player.colorHex))
                        
                        Text("\(item.totalGames) parties • \(item.totalWins) vict. (\(Int(item.winRate * 100))%) • Norm. \(String(format: "%.2f", item.normalizedRank))")
                            .font(.caption2)
                            .foregroundColor(PirateTheme.parchment.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(Int(item.currentElo))")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(PirateTheme.gold)
                            
                            if item.eloDeltaLastGame != 0 {
                                Text(item.eloDeltaLastGame > 0 ? "▲+\(Int(item.eloDeltaLastGame))" : "▼\(Int(item.eloDeltaLastGame))")
                                    .font(.caption2)
                                    .foregroundColor(item.eloDeltaLastGame > 0 ? PirateTheme.emerald : PirateTheme.crimson)
                            }
                        }
                        
                        Text("Moy. \(Int(item.averageScore)) pts • \(Int(item.bidSuccessRate * 100))% paris")
                            .font(.system(size: 10))
                            .foregroundColor(PirateTheme.parchment.opacity(0.7))
                    }
                }
                .pirateCard()
            }
        }
    }
    
    // MARK: - 2. Minimalist Player Profile Cards Tab
    
    @State private var playerForDetailSheet: Player? = nil
    
    private var playerProfileTabContent: some View {
        VStack(spacing: 10) {
            ForEach(allPlayers) { player in
                let elo = RatingService.computePlayerElo(for: player, allPlayers: allPlayers, games: allGames)
                let playerGames = allGames.filter { g in g.participants.contains(where: { $0.player?.id == player.id }) }
                let wins = playerGames.filter { g in g.participants.first(where: { $0.player?.id == player.id })?.finalRank == 1 }.count
                let winRate = playerGames.isEmpty ? 0 : Double(wins) / Double(playerGames.count)
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    playerForDetailSheet = player
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Text("\(playerGames.count) parties • \(wins) vict. (\(Int(winRate * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(elo))")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.orange)
                            
                            Text("ELO")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $playerForDetailSheet) { player in
            PlayerDetailView(
                player: player,
                allPlayers: allPlayers,
                allGames: allGames,
                filter: filter
            )
        }
    }
    
    private func phaseScoreBox(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(PirateTheme.parchment.opacity(0.6))
            Text("\(String(format: "%.1f", value)) pts")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(value >= 0 ? PirateTheme.emerald : PirateTheme.crimson)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(PirateTheme.deepNavy))
    }
    
    // MARK: - 3. Advanced Head to Head Tab
    
    @State private var h2hPlayerA: Player? = nil
    @State private var h2hPlayerB: Player? = nil
    
    private var headToHeadTabContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(allPlayers) { p in
                        Button("\(p.emoji) \(p.name)") { h2hPlayerA = p }
                    }
                } label: {
                    Text(h2hPlayerA?.name ?? "Joueur A")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(PirateTheme.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.deepNavy))
                }
                
                Text("VS")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(PirateTheme.crimson)
                
                Menu {
                    ForEach(allPlayers) { p in
                        Button("\(p.emoji) \(p.name)") { h2hPlayerB = p }
                    }
                } label: {
                    Text(h2hPlayerB?.name ?? "Joueur B")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(PirateTheme.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.deepNavy))
                }
            }
            .onAppear {
                if h2hPlayerA == nil && allPlayers.count >= 1 { h2hPlayerA = allPlayers[0] }
                if h2hPlayerB == nil && allPlayers.count >= 2 { h2hPlayerB = allPlayers[1] }
            }
            
            if let pA = h2hPlayerA, let pB = h2hPlayerB, pA.id != pB.id {
                let h2h = StatsService.computeAdvancedHeadToHead(playerA: pA, playerB: pB, games: filter.apply(to: allGames))
                
                VStack(spacing: 14) {
                    Text("\(h2h.commonGamesCount) parties en commun")
                        .font(.headline)
                        .foregroundColor(PirateTheme.gold)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text(pA.emoji).font(.title)
                            Text("\(h2h.aFinishedAheadCount) victoires")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.emerald)
                        }
                        
                        Text("–")
                            .font(.title)
                            .foregroundColor(PirateTheme.parchment.opacity(0.4))
                        
                        VStack {
                            Text(pB.emoji).font(.title)
                            Text("\(h2h.bFinishedAheadCount) victoires")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.crimson)
                        }
                    }
                    
                    Divider().background(PirateTheme.cardBorder)
                    
                    // Presence Effect
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Effet de Présence de \(pB.name) sur \(pA.name)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(PirateTheme.gold)
                        
                        HStack {
                            Text("Quand \(pB.name) est présent :")
                            Spacer()
                            Text("\(Int(h2h.aWinRateWhenBPresent * 100))% victoires • Moy. \(Int(h2h.aScoreWhenBPresent)) pts")
                                .fontWeight(.bold)
                        }
                        .font(.caption2)
                        .foregroundColor(PirateTheme.parchment)
                        
                        HStack {
                            Text("Quand \(pB.name) est absent :")
                            Spacer()
                            Text("\(Int(h2h.aWinRateWhenBAbsent * 100))% victoires • Moy. \(Int(h2h.aScoreWhenBAbsent)) pts")
                                .fontWeight(.bold)
                        }
                        .font(.caption2)
                        .foregroundColor(PirateTheme.parchment.opacity(0.8))
                    }
                    
                    Divider().background(PirateTheme.cardBorder)
                    
                    // Table Position Effect
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Effet de Position à Table")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(PirateTheme.gold)
                        
                        Text("• Quand \(pA.name) joue juste avant \(pB.name) : \(Int(h2h.aJustBeforeBStats.winRate * 100))% victoires (moy. \(Int(h2h.aJustBeforeBStats.avgScore)) pts)")
                            .font(.caption2)
                            .foregroundColor(PirateTheme.parchment)
                        
                        Text("• Quand \(pA.name) joue juste après \(pB.name) : \(Int(h2h.aJustAfterBStats.winRate * 100))% victoires (moy. \(Int(h2h.aJustAfterBStats.avgScore)) pts)")
                            .font(.caption2)
                            .foregroundColor(PirateTheme.parchment)
                    }
                    
                    Divider().background(PirateTheme.cardBorder)
                    
                    // Score Correlation
                    HStack {
                        Text("Corrélation de scores :")
                            .font(.caption)
                            .foregroundColor(PirateTheme.gold)
                        Spacer()
                        Text("\(String(format: "%.2f", h2h.scoreCorrelation))")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(h2h.scoreCorrelation < -0.2 ? PirateTheme.crimson : (h2h.scoreCorrelation > 0.2 ? PirateTheme.emerald : PirateTheme.parchment))
                    }
                }
                .pirateCard()
            }
        }
    }
    
    // MARK: - 4. Confrontation Matrix (Heatmap)
    
    private var confrontationMatrixTabContent: some View {
        let players = allPlayers.prefix(7)
        let filteredGames = filter.apply(to: allGames)
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("Matrice de Confrontation (% victoire ligne vs colonne)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            VStack(spacing: 4) {
                // Header
                HStack(spacing: 4) {
                    Text("")
                        .frame(width: 44, height: 26)
                    ForEach(players) { p in
                        Text(p.emoji)
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                ForEach(players) { pRow in
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Text(pRow.emoji)
                            Text(pRow.name.prefix(3))
                                .font(.system(size: 8))
                                .fontWeight(.bold)
                        }
                        .frame(width: 44, height: 26)
                        
                        ForEach(players) { pCol in
                            if pRow.id == pCol.id {
                                Rectangle()
                                    .fill(PirateTheme.midnightNavy)
                                    .frame(maxWidth: .infinity, maxHeight: 26)
                            } else {
                                let h2h = StatsService.computeAdvancedHeadToHead(playerA: pRow, playerB: pCol, games: filteredGames)
                                let rate = h2h.aWinRateVsB
                                Text(h2h.commonGamesCount > 0 ? "\(Int(rate * 100))" : "-")
                                    .font(.system(size: 9))
                                    .fontWeight(.bold)
                                    .foregroundColor(h2h.commonGamesCount > 0 ? (rate >= 0.5 ? PirateTheme.emerald : PirateTheme.crimson) : PirateTheme.parchment.opacity(0.3))
                                    .frame(maxWidth: .infinity, maxHeight: 26)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(h2h.commonGamesCount > 0 ? (rate >= 0.5 ? PirateTheme.emerald.opacity(0.2) : PirateTheme.crimson.opacity(0.2)) : PirateTheme.deepNavy))
                            }
                        }
                    }
                }
            }
            .pirateCard()
        }
    }
    
    // MARK: - 5. Hall of Fame / Shame & Badges Tab
    
    private var hallOfFameTabContent: some View {
        let (fame, shame) = RecordsService.computeHallOfFameAndShame(games: filter.apply(to: allGames))
        let badges = RecordsService.computeBadges(players: allPlayers, games: filter.apply(to: allGames))
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Insignes de Piraterie")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(badges) { badge in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: badge.icon)
                                .foregroundColor(badge.unlockedCount > 0 ? PirateTheme.gold : .gray)
                            Spacer()
                            Text("\(badge.unlockedCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.gold)
                        }
                        Text(badge.title)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(PirateTheme.parchment)
                        Text(badge.description)
                            .font(.system(size: 10))
                            .foregroundColor(PirateTheme.parchment.opacity(0.6))
                    }
                    .pirateCard()
                }
            }
            
            Text("Hall of Fame (Légendes)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.gold)
            
            ForEach(fame) { rec in
                recordRow(rec: rec)
            }
            
            Text("Hall of Shame (Pires Naufrages)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.crimson)
            
            ForEach(shame) { rec in
                recordRow(rec: rec)
            }
        }
    }
    
    private func recordRow(rec: RecordItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rec.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(rec.isShame ? PirateTheme.crimson : PirateTheme.gold)
                Text("\(rec.holderName) • \(rec.category)")
                    .font(.caption2)
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
            }
            Spacer()
            Text(rec.valueDescription)
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(PirateTheme.parchment)
        }
        .pirateCard()
    }
    
    // MARK: - 6. Table & Fun Tab (Empirical Probabilities)
    
    private var tableFunTabContent: some View {
        let stats = StatsService.computeTableFunStats(games: allGames, filter: filter)
        let hours = Int(stats.totalPlayTimeSeconds) / 3600
        let minutes = (Int(stats.totalPlayTimeSeconds) % 3600) / 60
        
        return VStack(spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricCard(title: "Parties terminées", value: "\(stats.totalFinishedGames)")
                metricCard(title: "Manches jouées", value: "\(stats.totalRounds)")
                metricCard(title: "Temps total en mer", value: "\(hours)h \(minutes)m")
                metricCard(title: "Jour préféré", value: stats.preferredDayOfWeek.isEmpty ? "Vendredi" : stats.preferredDayOfWeek)
                metricCard(title: "Créneau préféré", value: stats.preferredHourSpan.isEmpty ? "21h - 22h" : stats.preferredHourSpan)
                metricCard(title: "Manche la plus meurtrière", value: "Manche \(stats.deadliestRoundNumber)")
            }
            
            // Empirical Probability Table
            VStack(alignment: .leading, spacing: 8) {
                Text("Table de Probabilités Empiriques « Réussir un pari X avec Y cartes »")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.gold)
                
                Text("Calculée sur l'ensemble réel de toutes les manches enregistrées.")
                    .font(.system(size: 10))
                    .foregroundColor(PirateTheme.parchment.opacity(0.6))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Cartes").frame(width: 50, alignment: .leading).font(.caption2).foregroundColor(PirateTheme.gold)
                            Text("Pari").frame(width: 40, alignment: .center).font(.caption2).foregroundColor(PirateTheme.gold)
                            Text("Tentatives").frame(width: 65, alignment: .center).font(.caption2).foregroundColor(PirateTheme.gold)
                            Text("Taux Réussite").frame(width: 90, alignment: .trailing).font(.caption2).foregroundColor(PirateTheme.gold)
                        }
                        .padding(.vertical, 4)
                        
                        ForEach(stats.empiricalProbabilities.prefix(15)) { cell in
                            HStack(spacing: 6) {
                                Text("\(cell.cards) cartes").frame(width: 50, alignment: .leading).font(.caption2).foregroundColor(PirateTheme.parchment)
                                Text("\(cell.bid)").frame(width: 40, alignment: .center).font(.caption2).foregroundColor(PirateTheme.parchment)
                                Text("\(cell.attempts)").frame(width: 65, alignment: .center).font(.caption2).foregroundColor(PirateTheme.parchment.opacity(0.7))
                                Text("\(Int(cell.successRate))%").frame(width: 90, alignment: .trailing).font(.caption2).fontWeight(.bold).foregroundColor(cell.successRate >= 50 ? PirateTheme.emerald : PirateTheme.crimson)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .pirateCard()
        }
    }
    
    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(PirateTheme.parchment.opacity(0.6))
            Text(value)
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(PirateTheme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pirateCard()
    }
}

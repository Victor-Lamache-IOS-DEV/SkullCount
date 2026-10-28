import Foundation
import SwiftData

public extension StatsService {
    
    // MARK: - Game Heatmap Cells
    
    static func computeGameHeatmap(game: Game) -> [GameHeatmapCell] {
        var cells: [GameHeatmapCell] = []
        for round in game.sortedRounds {
            for entry in round.entries {
                guard let p = entry.participant?.player else { continue }
                cells.append(GameHeatmapCell(
                    playerId: p.id,
                    playerName: p.name,
                    playerColorHex: p.colorHex,
                    roundNumber: round.number,
                    cardsDealt: round.cardsDealt,
                    bid: entry.bid,
                    tricks: entry.tricks,
                    points: entry.points,
                    isSuccess: entry.isSuccess,
                    diff: entry.tricks - entry.bid
                ))
            }
        }
        return cells
    }
    
    // MARK: - Exhaustive Player Profile Computation
    
    static func computeExhaustivePlayerProfile(player: Player, allPlayers: [Player], games: [Game], filter: StatsFilter = StatsFilter()) -> PlayerExhaustiveStats {
        let filteredGames = filter.apply(to: games)
        var stats = PlayerExhaustiveStats(player: player)
        
        var relevantParticipations: [(game: Game, part: GameParticipant)] = []
        for g in filteredGames {
            if let part = g.participants.first(where: { $0.player?.id == player.id }) {
                relevantParticipations.append((game: g, part: part))
            }
        }
        
        relevantParticipations.sort { $0.game.startedAt < $1.game.startedAt }
        stats.totalGames = relevantParticipations.count
        guard stats.totalGames > 0 else { return stats }
        
        var scores: [Int] = []
        var ranks: [Int] = []
        var normRanks: [Double] = []
        var roundPoints: [Int] = []
        
        var careerStreak = 0
        var maxCareerStreak = 0
        var currentWinStreak = 0
        var maxWinStreak = 0
        var currentLoseStreak = 0
        var maxLoseStreak = 0
        
        var biases: [Int] = []
        var relativeBids: [Double] = []
        var missWithin1Count = 0
        var totalMisses = 0
        
        // Breakdown accumulators
        var roundSuccesses = [Int: (succ: Int, total: Int)]()
        var cardsSuccesses = [Int: (succ: Int, total: Int)]()
        var bidValSuccesses = [Int: (succ: Int, total: Int)]()
        var turnPosSuccesses = [Int: (succ: Int, total: Int)]()
        var playerCountSuccesses = [Int: (succ: Int, total: Int)]()
        
        // Habits: cards -> [bid: count]
        var cardsBidCounts = [Int: [Int: Int]]()
        
        // Matrix: (bid, tricks) -> count
        var matrixCounts = [String: Int]()
        
        // Game phases
        var earlyPoints: [Int] = []
        var midPoints: [Int] = []
        var latePoints: [Int] = []
        
        for item in relevantParticipations {
            let p = item.part
            let finalScore = p.finalScore
            scores.append(finalScore)
            ranks.append(p.finalRank)
            
            if p.finalRank == 1 {
                stats.wins += 1
                currentWinStreak += 1
                if currentWinStreak > maxWinStreak { maxWinStreak = currentWinStreak }
                currentLoseStreak = 0
            } else {
                currentLoseStreak += 1
                if currentLoseStreak > maxLoseStreak { maxLoseStreak = currentLoseStreak }
                currentWinStreak = 0
            }
            
            if p.finalRank <= 3 { stats.podiums += 1 }
            
            let n = item.game.participants.count
            let normR = n > 1 ? Double(n - p.finalRank) / Double(n - 1) : 1.0
            normRanks.append(normR)
            
            // Player seat
            let mySeat = p.seatIndex
            
            var gameStreak = 0
            for entry in p.roundEntries.sorted(by: { ($0.round?.number ?? 0) < ($1.round?.number ?? 0) }) {
                guard let round = entry.round else { continue }
                stats.totalBidsCount += 1
                roundPoints.append(entry.points)
                
                if entry.points > 0 { stats.totalPositivePoints += entry.points }
                if entry.points < 0 { stats.totalNegativePoints += entry.points }
                
                // Bonus share
                if entry.isSuccess && (entry.piratesCapturedBySK > 0 || entry.skCapturedByMermaid) {
                    let bVal = (entry.piratesCapturedBySK * item.game.bonusPirateBySK) + (entry.skCapturedByMermaid ? item.game.bonusSKByMermaid : 0)
                    stats.bonusPointsGained += bVal
                }
                
                let relBid = round.cardsDealt > 0 ? Double(entry.bid) / Double(round.cardsDealt) : 0
                relativeBids.append(relBid)
                
                let bias = entry.tricks - entry.bid
                biases.append(bias)
                
                // Bid distribution
                stats.bidDistribution[entry.bid, default: 0] += 1
                
                // Cards habit
                cardsBidCounts[round.cardsDealt, default: [:]][entry.bid, default: 0] += 1
                
                // Matrix
                let matrixKey = "\(entry.bid)_\(entry.tricks)"
                matrixCounts[matrixKey, default: 0] += 1
                
                // Turn position in this round
                let turnPosition = (mySeat - round.firstPlayerIndex + n) % n
                
                // Breakdown totals
                roundSuccesses[round.number, default: (0, 0)].total += 1
                cardsSuccesses[round.cardsDealt, default: (0, 0)].total += 1
                bidValSuccesses[entry.bid, default: (0, 0)].total += 1
                turnPosSuccesses[turnPosition, default: (0, 0)].total += 1
                playerCountSuccesses[n, default: (0, 0)].total += 1
                
                // Game phases
                if round.number <= 3 {
                    earlyPoints.append(entry.points)
                } else if round.number <= 7 {
                    midPoints.append(entry.points)
                } else {
                    latePoints.append(entry.points)
                }
                
                if entry.bid == 0 {
                    stats.zeroBidsAttempts += 1
                    if entry.isSuccess {
                        stats.zeroBidsSuccess += 1
                        stats.zeroPointsGained += entry.points
                    } else {
                        stats.zeroPointsLost += entry.points
                    }
                }
                
                if entry.isSuccess {
                    stats.successBidsCount += 1
                    careerStreak += 1
                    gameStreak += 1
                    if careerStreak > maxCareerStreak { maxCareerStreak = careerStreak }
                    if gameStreak > stats.longestSingleGameSuccessStreak { stats.longestSingleGameSuccessStreak = gameStreak }
                    
                    roundSuccesses[round.number, default: (0, 0)].succ += 1
                    cardsSuccesses[round.cardsDealt, default: (0, 0)].succ += 1
                    bidValSuccesses[entry.bid, default: (0, 0)].succ += 1
                    turnPosSuccesses[turnPosition, default: (0, 0)].succ += 1
                    playerCountSuccesses[n, default: (0, 0)].succ += 1
                } else {
                    careerStreak = 0
                    gameStreak = 0
                    totalMisses += 1
                    if abs(bias) == 1 {
                        missWithin1Count += 1
                    }
                }
            }
        }
        
        stats.winRate = Double(stats.wins) / Double(stats.totalGames)
        stats.avgRank = ranks.reduce(0, +) > 0 ? Double(ranks.reduce(0, +)) / Double(ranks.count) : 0
        stats.normalizedRank = normRanks.reduce(0, +) / Double(normRanks.count)
        stats.avgScore = Double(scores.reduce(0, +)) / Double(scores.count)
        stats.maxScore = scores.max() ?? 0
        stats.minScore = scores.min() ?? 0
        
        let sortedScores = scores.sorted()
        if sortedScores.count % 2 == 0 {
            stats.medianScore = Double(sortedScores[sortedScores.count / 2 - 1] + sortedScores[sortedScores.count / 2]) / 2.0
        } else {
            stats.medianScore = Double(sortedScores[sortedScores.count / 2])
        }
        
        let mean = stats.avgScore
        let variance = scores.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(scores.count)
        stats.scoreStandardDeviation = sqrt(variance)
        
        if !roundPoints.isEmpty {
            stats.avgPointsPerRound = Double(roundPoints.reduce(0, +)) / Double(roundPoints.count)
        }
        
        stats.overallSuccessRate = stats.totalBidsCount > 0 ? Double(stats.successBidsCount) / Double(stats.totalBidsCount) : 0
        stats.relativeBidAvg = !relativeBids.isEmpty ? relativeBids.reduce(0, +) / Double(relativeBids.count) : 0
        
        if !biases.isEmpty {
            stats.avgBias = Double(biases.reduce(0, +)) / Double(biases.count)
            if stats.avgBias > 0.15 {
                stats.biasLabel = "Tu te sous-estimes (tu fais plus de plis que prévu)"
            } else if stats.avgBias < -0.15 {
                stats.biasLabel = "Tu te surestimes (tu fais moins de plis que prévu)"
            } else {
                stats.biasLabel = "Très équilibré"
            }
        }
        
        if totalMisses > 0 {
            stats.missWithinOnePercent = Double(missWithin1Count) / Double(totalMisses)
        }
        
        if stats.zeroBidsAttempts > 0 {
            stats.zeroBidsSuccessRate = Double(stats.zeroBidsSuccess) / Double(stats.zeroBidsAttempts)
        }
        
        stats.longestCareerSuccessStreak = maxCareerStreak
        stats.currentStreak = careerStreak
        stats.longestWinStreak = maxWinStreak
        stats.longestLoseStreak = maxLoseStreak
        
        if stats.totalPositivePoints > 0 {
            stats.bonusPointsShare = Double(stats.bonusPointsGained) / Double(stats.totalPositivePoints)
        }
        
        // Rolling 5 games average
        if scores.count >= 5 {
            for i in 4..<scores.count {
                let slice = scores[(i - 4)...i]
                let avg = Double(slice.reduce(0, +)) / 5.0
                stats.rollingFiveGamesAvgScores.append((gameIndex: i + 1, avgScore: avg))
            }
        }
        
        // Game Phases
        if !earlyPoints.isEmpty { stats.earlyGameAvgPoints = Double(earlyPoints.reduce(0, +)) / Double(earlyPoints.count) }
        if !midPoints.isEmpty { stats.midGameAvgPoints = Double(midPoints.reduce(0, +)) / Double(midPoints.count) }
        if !latePoints.isEmpty { stats.lateGameAvgPoints = Double(latePoints.reduce(0, +)) / Double(latePoints.count) }
        
        // Breakdowns
        for (k, v) in roundSuccesses { stats.successRateByRoundNumber[k] = v.total > 0 ? Double(v.succ) / Double(v.total) : 0 }
        for (k, v) in cardsSuccesses { stats.successRateByCardsDealt[k] = v.total > 0 ? Double(v.succ) / Double(v.total) : 0 }
        for (k, v) in bidValSuccesses { stats.successRateByBidValue[k] = v.total > 0 ? Double(v.succ) / Double(v.total) : 0 }
        for (k, v) in turnPosSuccesses { stats.successRateByTurnPosition[k] = v.total > 0 ? Double(v.succ) / Double(v.total) : 0 }
        for (k, v) in playerCountSuccesses { stats.successRateByPlayerCount[k] = v.total > 0 ? Double(v.succ) / Double(v.total) : 0 }
        
        // Habits
        for (c, bMap) in cardsBidCounts {
            let totalCardsRounds = bMap.values.reduce(0, +)
            if let maxBidEntry = bMap.max(by: { $0.value < $1.value }) {
                stats.habits.append(PlayerHabitItem(
                    cards: c,
                    mostFrequentBid: maxBidEntry.key,
                    bidCount: maxBidEntry.value,
                    totalRoundsWithCards: totalCardsRounds
                ))
            }
        }
        stats.habits.sort { $0.cards < $1.cards }
        
        // Matrix Heatmap
        var matrixList: [BidTricksMatrixCell] = []
        for (k, count) in matrixCounts {
            let parts = k.components(separatedBy: "_")
            if parts.count == 2, let b = Int(parts[0]), let t = Int(parts[1]) {
                matrixList.append(BidTricksMatrixCell(bid: b, tricks: t, count: count))
            }
        }
        stats.bidTricksMatrix = matrixList
        
        // Recent form (last 5 games)
        let lastGames = relevantParticipations.suffix(5)
        stats.recentForms = lastGames.map { $0.part.finalRank }
        
        // Nemesis & Favorite Victim (min 3 common games)
        var opponentRecords: [UUID: (player: Player, ahead: Int, behind: Int, total: Int)] = [:]
        for opp in allPlayers where opp.id != player.id {
            let h2h = computeAdvancedHeadToHead(playerA: player, playerB: opp, games: filteredGames)
            if h2h.commonGamesCount >= 3 {
                opponentRecords[opp.id] = (player: opp, ahead: h2h.aFinishedAheadCount, behind: h2h.bFinishedAheadCount, total: h2h.commonGamesCount)
            }
        }
        
        if let worst = opponentRecords.values.min(by: { (Double($0.ahead) / Double($0.total)) < (Double($1.ahead) / Double($1.total)) }) {
            stats.nemesis = (player: worst.player, winRateAgainst: Double(worst.ahead) / Double(worst.total), games: worst.total)
        }
        if let best = opponentRecords.values.max(by: { (Double($0.ahead) / Double($0.total)) < (Double($1.ahead) / Double($1.total)) }) {
            stats.favoriteVictim = (player: best.player, winRateAgainst: Double(best.ahead) / Double(best.total), games: best.total)
        }
        
        return stats
    }
    
    // MARK: - Advanced Head to Head Computation
    
    static func computeAdvancedHeadToHead(playerA: Player, playerB: Player, games: [Game]) -> AdvancedH2HStats {
        var h2h = AdvancedH2HStats(playerA: playerA, playerB: playerB)
        let finishedGames = games.filter { $0.status == .finished }
        
        var aScoresWithB: [Double] = []
        var bScoresWithA: [Double] = []
        var aScoresWithoutB: [Double] = []
        
        var aWinsWithB = 0
        var aWinsWithoutB = 0
        var aGamesWithoutB = 0
        
        var aBidsWithB = 0
        var aSuccessWithB = 0
        var aBidsWithoutB = 0
        var aSuccessWithoutB = 0
        
        var aBeforeB_Games = 0
        var aBeforeB_Wins = 0
        var aBeforeB_Scores: [Int] = []
        
        var aAfterB_Games = 0
        var aAfterB_Wins = 0
        var aAfterB_Scores: [Int] = []
        
        for g in finishedGames {
            let partA = g.participants.first { $0.player?.id == playerA.id }
            let partB = g.participants.first { $0.player?.id == playerB.id }
            
            if let pA = partA, let pB = partB {
                h2h.commonGamesCount += 1
                let n = g.participants.count
                
                aScoresWithB.append(Double(pA.finalScore))
                bScoresWithA.append(Double(pB.finalScore))
                
                if pA.finalRank < pB.finalRank {
                    h2h.aFinishedAheadCount += 1
                    let diff = pA.finalScore - pB.finalScore
                    if diff > h2h.biggestWinA { h2h.biggestWinA = diff }
                } else if pB.finalRank < pA.finalRank {
                    h2h.bFinishedAheadCount += 1
                    let diff = pB.finalScore - pA.finalScore
                    if diff > h2h.biggestWinB { h2h.biggestWinB = diff }
                }
                
                if pA.finalRank == 1 { aWinsWithB += 1 }
                
                for r in g.rounds {
                    if let eA = r.entries.first(where: { $0.participant?.id == pA.id }) {
                        aBidsWithB += 1
                        if eA.isSuccess { aSuccessWithB += 1 }
                    }
                }
                
                // Table Relative Position Effect
                // Seat index distance
                let seatDiff = (pA.seatIndex - pB.seatIndex + n) % n
                if seatDiff == n - 1 {
                    // A is right before B
                    aBeforeB_Games += 1
                    if pA.finalRank == 1 { aBeforeB_Wins += 1 }
                    aBeforeB_Scores.append(pA.finalScore)
                } else if seatDiff == 1 {
                    // A is right after B
                    aAfterB_Games += 1
                    if pA.finalRank == 1 { aAfterB_Wins += 1 }
                    aAfterB_Scores.append(pA.finalScore)
                }
                
            } else if let pA = partA, partB == nil {
                aGamesWithoutB += 1
                aScoresWithoutB.append(Double(pA.finalScore))
                if pA.finalRank == 1 { aWinsWithoutB += 1 }
                for r in g.rounds {
                    if let eA = r.entries.first(where: { $0.participant?.id == pA.id }) {
                        aBidsWithoutB += 1
                        if eA.isSuccess { aSuccessWithoutB += 1 }
                    }
                }
            }
        }
        
        if h2h.commonGamesCount > 0 {
            let totalDiff = zip(aScoresWithB, bScoresWithA).map { $0 - $1 }.reduce(0, +)
            h2h.avgScoreDiffAminusB = totalDiff / Double(h2h.commonGamesCount)
            h2h.aWinRateWhenBPresent = Double(aWinsWithB) / Double(h2h.commonGamesCount)
            h2h.aScoreWhenBPresent = aScoresWithB.reduce(0, +) / Double(h2h.commonGamesCount)
            h2h.aSuccessRateWhenBPresent = aBidsWithB > 0 ? Double(aSuccessWithB) / Double(aBidsWithB) : 0
            
            // Pearson Correlation
            h2h.scoreCorrelation = computePearsonCorrelation(x: aScoresWithB, y: bScoresWithA)
        }
        
        if aGamesWithoutB > 0 {
            h2h.aWinRateWhenBAbsent = Double(aWinsWithoutB) / Double(aGamesWithoutB)
            h2h.aScoreWhenBAbsent = aScoresWithoutB.reduce(0, +) / Double(aGamesWithoutB)
            h2h.aSuccessRateWhenBAbsent = aBidsWithoutB > 0 ? Double(aSuccessWithoutB) / Double(aBidsWithoutB) : 0
        }
        
        // Relative position stats
        if aBeforeB_Games > 0 {
            h2h.aJustBeforeBStats = TablePositionStats(
                gamesCount: aBeforeB_Games,
                winRate: Double(aBeforeB_Wins) / Double(aBeforeB_Games),
                avgScore: Double(aBeforeB_Scores.reduce(0, +)) / Double(aBeforeB_Games)
            )
        }
        if aAfterB_Games > 0 {
            h2h.aJustAfterBStats = TablePositionStats(
                gamesCount: aAfterB_Games,
                winRate: Double(aAfterB_Wins) / Double(aAfterB_Games),
                avgScore: Double(aAfterB_Scores.reduce(0, +)) / Double(aAfterB_Games)
            )
        }
        
        return h2h
    }
    
    // MARK: - Fun Table & Empirical Probabilities
    
    static func computeTableFunStats(games: [Game], filter: StatsFilter = StatsFilter()) -> TableFunStats {
        let filteredGames = filter.apply(to: games)
        var stats = TableFunStats()
        stats.totalFinishedGames = filteredGames.count
        
        var dayCounts = [Int: Int]()
        var hourCounts = [Int: Int]()
        var roundPointsSum = [Int: (pts: Int, entries: Int)]()
        var roundOverbids = [Int: [Int]]()
        var empProbMap = [String: (attempts: Int, successes: Int)]()
        
        let calendar = Calendar.current
        
        for g in filteredGames {
            let roundCount = g.rounds.count
            stats.totalRounds += roundCount
            if let dur = g.duration {
                stats.totalPlayTimeSeconds += dur
            }
            
            let weekday = calendar.component(.weekday, from: g.startedAt)
            dayCounts[weekday, default: 0] += 1
            
            let hour = calendar.component(.hour, from: g.startedAt)
            hourCounts[hour, default: 0] += 1
            
            for r in g.rounds {
                let totalBidsInRound = r.entries.reduce(0) { $0 + $1.bid }
                let overbid = totalBidsInRound - r.cardsDealt
                roundOverbids[r.number, default: []].append(overbid)
                
                for e in r.entries {
                    roundPointsSum[r.number, default: (0, 0)].pts += e.points
                    roundPointsSum[r.number, default: (0, 0)].entries += 1
                    
                    let key = "\(r.cardsDealt)_\(e.bid)"
                    empProbMap[key, default: (0, 0)].attempts += 1
                    if e.isSuccess {
                        empProbMap[key, default: (0, 0)].successes += 1
                    }
                }
            }
        }
        
        // Preferred day
        let dayNames = ["", "Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
        if let topDay = dayCounts.max(by: { $0.value < $1.value }), topDay.key < dayNames.count {
            stats.preferredDayOfWeek = "\(dayNames[topDay.key]) (\(topDay.value) parties)"
        }
        
        // Preferred hour
        if let topHour = hourCounts.max(by: { $0.value < $1.value }) {
            stats.preferredHourSpan = "\(topHour.key)h - \(topHour.key + 1)h (\(topHour.value) parties)"
        }
        
        // Average table overbid
        for (rNum, list) in roundOverbids {
            stats.avgTableOverbidPerRound[rNum] = Double(list.reduce(0, +)) / Double(list.count)
        }
        
        // Deadliest round (lowest average points per player)
        var minAvgRoundPts = Double.infinity
        var deadliest = 1
        for (rNum, pair) in roundPointsSum {
            if pair.entries > 0 {
                let avg = Double(pair.pts) / Double(pair.entries)
                if avg < minAvgRoundPts {
                    minAvgRoundPts = avg
                    deadliest = rNum
                }
            }
        }
        stats.deadliestRoundNumber = deadliest
        
        // Empirical probabilities table
        var empList: [EmpiricalProbCell] = []
        for (key, val) in empProbMap {
            let parts = key.components(separatedBy: "_")
            if parts.count == 2, let c = Int(parts[0]), let b = Int(parts[1]) {
                empList.append(EmpiricalProbCell(cards: c, bid: b, attempts: val.attempts, successes: val.successes))
            }
        }
        empList.sort { ($0.cards != $1.cards) ? $0.cards < $1.cards : $0.bid < $1.bid }
        stats.empiricalProbabilities = empList
        
        return stats
    }
    
    // MARK: - Pearson Correlation Math
    
    private static func computePearsonCorrelation(x: [Double], y: [Double]) -> Double {
        let n = Double(x.count)
        guard n > 1 && x.count == y.count else { return 0.0 }
        
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let meanX = sumX / n
        let meanY = sumY / n
        
        var numerator = 0.0
        var denomX = 0.0
        var denomY = 0.0
        
        for i in 0..<x.count {
            let diffX = x[i] - meanX
            let diffY = y[i] - meanY
            numerator += diffX * diffY
            denomX += diffX * diffX
            denomY += diffY * diffY
        }
        
        let denominator = sqrt(denomX * denomY)
        guard denominator > 0 else { return 0.0 }
        return numerator / denominator
    }
}

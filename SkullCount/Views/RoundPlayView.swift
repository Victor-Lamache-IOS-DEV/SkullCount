import SwiftUI
import SwiftData

public struct RoundPlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: GamePlayViewModel
    @State private var showingScoresTable: Bool = false
    @State private var bonusParticipant: GameParticipant? = nil
    @State private var showingEndGameView: Bool = false
    @State private var navigateToGameDetails: Bool = false
    
    public init(game: Game) {
        _viewModel = State(initialValue: GamePlayViewModel(game: game))
    }
    
    public var body: some View {
        ZStack {
            PirateTheme.midnightNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Banner
                headerBanner
                
                // Bids comparison banner (Phase 1) or Tricks status (Phase 2)
                phaseStatusBanner
                
                // Players Grid (Turn Order)
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.participantsInTurnOrder) { participant in
                            playerRow(participant: participant)
                        }
                    }
                    .padding()
                }
                
                // Bottom Action Bar
                bottomActionBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Quitter")
                    }
                    .foregroundColor(PirateTheme.gold)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Peek scores (long press or tap)
                    Button(action: {
                        viewModel.isScoresRevealed.toggle()
                    }) {
                        Image(systemName: viewModel.isScoresRevealed ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(PirateTheme.gold)
                    }
                    
                    // Scores table
                    Button(action: { showingScoresTable = true }) {
                        Image(systemName: "tablecells")
                            .foregroundColor(PirateTheme.gold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingScoresTable) {
            ScoresTableView(game: viewModel.game, onSelectRoundToEdit: { roundNum in
                viewModel.currentRoundIndex = roundNum
                showingScoresTable = false
            })
        }
        .sheet(item: $bonusParticipant) { part in
            BonusCaptureSheet(
                playerName: part.player?.name ?? "Joueur",
                bonusPirateValue: viewModel.game.bonusPirateBySK,
                bonusMermaidValue: viewModel.game.bonusSKByMermaid,
                piratesCount: Binding(
                    get: { viewModel.piratesBonus[part.id] ?? 0 },
                    set: { viewModel.piratesBonus[part.id] = $0 }
                ),
                mermaidCapturedSK: Binding(
                    get: { viewModel.mermaidBonus[part.id] ?? false },
                    set: { viewModel.mermaidBonus[part.id] = $0 }
                )
            )
        }
        .sheet(isPresented: $showingEndGameView) {
            GameResultView(game: viewModel.game)
        }
        .onAppear {
            // Keep screen awake during game
            UIApplication.shared.isIdleTimerDisabled = true
            if viewModel.game.status == .finished {
                showingEndGameView = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - Subviews
    
    private var headerBanner: some View {
        VStack(spacing: 4) {
            HStack {
                Text("🏴‍☠️ Manche \(viewModel.currentRoundIndex)/\(viewModel.game.plannedRounds)")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(PirateTheme.gold)
                
                Spacer()
                
                Text("\(viewModel.currentCardsDealt) carte\(viewModel.currentCardsDealt > 1 ? "s" : "")")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.parchment)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(PirateTheme.deepNavy))
            }
            
            HStack {
                Text("Commence :")
                    .font(.subheadline)
                    .foregroundColor(PirateTheme.parchment.opacity(0.8))
                Text(viewModel.startingPlayerName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.gold)
                Spacer()
                
                if viewModel.isScoresRevealed {
                    Text("Scores visibles")
                        .font(.caption2)
                        .foregroundColor(PirateTheme.emerald)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(PirateTheme.deepNavy)
        .overlay(Rectangle().frame(height: 1).foregroundColor(PirateTheme.cardBorder), alignment: .bottom)
    }
    
    private var phaseStatusBanner: some View {
        HStack {
            if !viewModel.isResultsPhase {
                let totalBids = viewModel.totalBids
                let cards = viewModel.currentCardsDealt
                let diff = totalBids - cards
                
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("Paris : \(totalBids) / \(cards) plis")
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.parchment)
                
                Spacer()
                
                if viewModel.isBiddingComplete {
                    if diff > 0 {
                        Text("Surenchère +\(diff)")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(PirateTheme.crimson)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(PirateTheme.crimson.opacity(0.2)))
                    } else if diff < 0 {
                        Text("Sous-enchère \(diff)")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(PirateTheme.emerald)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(PirateTheme.emerald.opacity(0.2)))
                    } else {
                        Text("Équilibre parfait")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(PirateTheme.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(PirateTheme.gold.opacity(0.2)))
                    }
                }
            } else {
                let totalTricks = viewModel.totalTricks
                let cards = viewModel.currentCardsDealt
                let missing = viewModel.tricksMissingCount
                
                Image(systemName: "flag.checkered")
                    .foregroundColor(PirateTheme.gold)
                Text("Plis : \(totalTricks) / \(cards)")
                    .fontWeight(.bold)
                    .foregroundColor(PirateTheme.parchment)
                
                Spacer()
                
                if missing != 0 {
                    Text(missing > 0 ? "Manque \(missing) pli(s)" : "Trop de plis (\(abs(missing)))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(PirateTheme.crimson)
                } else {
                    Text("✓ Total exact")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(PirateTheme.emerald)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(PirateTheme.midnightNavy)
    }
    
    private func playerRow(participant: GameParticipant) -> some View {
        let isLead = participant.seatIndex == viewModel.currentFirstPlayerIndex
        let currentBid = viewModel.bids[participant.id]
        let currentTrick = viewModel.tricks[participant.id]
        
        return VStack(alignment: .leading, spacing: 8) {
            // Player info row
            HStack {
                if isLead {
                    Text("▶︎")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(PirateTheme.gold)
                }
                
                Text(participant.player?.emoji ?? "🏴‍☠️")
                    .font(.title3)
                
                Text(participant.player?.name ?? "Joueur")
                    .font(.headline)
                    .foregroundColor(Color(hex: participant.player?.colorHex ?? "#FFFFFF"))
                
                if viewModel.isScoresRevealed {
                    let totalScore = participant.roundEntries
                        .filter { ($0.round?.number ?? 0) < viewModel.currentRoundIndex }
                        .reduce(0) { $0 + $1.points }
                    Text("(\(totalScore) pts)")
                        .font(.caption)
                        .foregroundColor(PirateTheme.parchment.opacity(0.6))
                }
                
                Spacer()
                
                // Bonus Button if enabled
                if viewModel.game.bonusEnabled && viewModel.isResultsPhase {
                    Button(action: {
                        bonusParticipant = participant
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                            let pB = viewModel.piratesBonus[participant.id] ?? 0
                            let mB = viewModel.mermaidBonus[participant.id] ?? false
                            if pB > 0 || mB {
                                Text("Bonus!")
                                    .fontWeight(.bold)
                            } else {
                                Text("+ Bonus")
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(PirateTheme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(PirateTheme.deepNavy))
                        .overlay(Capsule().stroke(PirateTheme.gold.opacity(0.5), lineWidth: 1))
                    }
                }
                
                // Live Score Preview in Phase 2
                if viewModel.isResultsPhase, let preview = viewModel.getPreviewScore(for: participant.id) {
                    Text("\(preview.points > 0 ? "+" : "")\(preview.points)")
                        .font(.callout)
                        .fontWeight(.heavy)
                        .foregroundColor(preview.isSuccess ? PirateTheme.emerald : PirateTheme.crimson)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(preview.isSuccess ? PirateTheme.emerald.opacity(0.2) : PirateTheme.crimson.opacity(0.2)))
                }
            }
            
            // Phase 1 : Bids Buttons
            if !viewModel.isResultsPhase {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0...viewModel.currentCardsDealt, id: \.self) { num in
                            PirateNumberButton(
                                number: num,
                                isSelected: currentBid == num
                            ) {
                                viewModel.setBid(for: participant.id, bid: num)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                // Phase 2 : Results Buttons + Quick Success Button
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.markSuccess(for: participant.id)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("✓ Réussi (\(currentBid ?? 0))")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(currentTrick == currentBid && currentTrick != nil ? PirateTheme.midnightNavy : PirateTheme.emerald)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(currentTrick == currentBid && currentTrick != nil ? PirateTheme.emerald : PirateTheme.deepNavy)
                        )
                        .overlay(Capsule().stroke(PirateTheme.emerald, lineWidth: 1))
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0...viewModel.currentCardsDealt, id: \.self) { num in
                                PirateNumberButton(
                                    number: num,
                                    isSelected: currentTrick == num,
                                    diameter: 42
                                ) {
                                    viewModel.setTrick(for: participant.id, trick: num)
                                }
                            }
                        }
                    }
                }
            }
        }
        .pirateCard()
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            if !viewModel.isResultsPhase {
                PirateButton(
                    title: "Valider les paris",
                    icon: "arrow.right.circle.fill",
                    isEnabled: viewModel.isBiddingComplete
                ) {
                    viewModel.validateBidsPhase()
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.markAllSuccess()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Tous réussi")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(PirateTheme.emerald)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(PirateTheme.deepNavy))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(PirateTheme.emerald, lineWidth: 1.5))
                    }
                    
                    PirateButton(
                        title: viewModel.currentRoundIndex >= viewModel.game.plannedRounds ? "Terminer la partie" : "Valider la manche",
                        icon: "checkmark.seal.fill",
                        isEnabled: viewModel.isTricksComplete && viewModel.isTricksSumValid
                    ) {
                        viewModel.validateRound(modelContext: modelContext)
                        if viewModel.game.status == .finished {
                            showingEndGameView = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(PirateTheme.deepNavy)
    }
}

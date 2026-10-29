import SwiftUI
import SwiftData

public struct RoundPlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: GamePlayViewModel
    @State private var showingScoresTable: Bool = false
    @State private var bonusParticipant: GameParticipant? = nil
    @State private var showingEndGameView: Bool = false
    
    public init(game: Game) {
        _viewModel = State(initialValue: GamePlayViewModel(game: game))
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBanner
                
                // Fitted Players list: spacing adjusts depending on count so no scrolling occurs
                let players = viewModel.participantsInTurnOrder
                let spacing: CGFloat = players.count > 6 ? 4 : (players.count > 4 ? 6 : 8)
                
                VStack(spacing: spacing) {
                    ForEach(players) { participant in
                        playerRow(participant: participant, compact: players.count > 5)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                
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
                    .font(.body)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingScoresTable = true }) {
                    Image(systemName: "tablecells")
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
            UIApplication.shared.isIdleTimerDisabled = true
            if viewModel.game.status == .finished {
                showingEndGameView = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - Header Banner (Shows Round, Starter player, and Progress)
    
    private var headerBanner: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manche \(viewModel.currentRoundIndex)/\(viewModel.game.plannedRounds)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Text("Commence :")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.startingPlayerName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            if !viewModel.isResultsPhase {
                Text("\(viewModel.totalBids)/\(viewModel.currentCardsDealt) paris")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                let missing = viewModel.tricksMissingCount
                HStack(spacing: 4) {
                    Text("\(viewModel.totalTricks)/\(viewModel.currentCardsDealt) plis")
                        .font(.subheadline.weight(.semibold))
                    if missing == 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    // MARK: - Player Row (Pure High-Contrast Direct Number Buttons)
    
    private func playerRow(participant: GameParticipant, compact: Bool) -> some View {
        let isLead = participant.seatIndex == viewModel.currentFirstPlayerIndex
        let currentBid = viewModel.bid(for: participant.id)
        let currentTrick = viewModel.trick(for: participant.id)
        let maxCards = viewModel.currentCardsDealt
        
        return HStack(spacing: 8) {
            // Player Lead indicator & Name
            HStack(spacing: 6) {
                if isLead {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 6, height: 6)
                }
                
                Text(participant.player?.name ?? "Joueur")
                    .font(.system(size: compact ? 13 : 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                    .lineLimit(1)
            }
            .frame(width: compact ? 85 : 100, alignment: .leading)
            
            Spacer()
            
            // Interaction Area depending on Phase
            if !viewModel.isResultsPhase {
                // PHASE 1: DIRECT BID BUTTONS (All numbers 0...maxCards directly selectable)
                let btnSize: CGFloat = maxCards > 8 ? 24 : (maxCards > 5 ? 28 : 32)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0...maxCards, id: \.self) { num in
                            let isSel = currentBid == num
                            Button(action: { viewModel.setBid(for: participant.id, bid: num) }) {
                                Text("\(num)")
                                    .font(.system(size: maxCards > 8 ? 12 : 14, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .white : Color(uiColor: .label))
                                    .frame(width: btnSize, height: btnSize)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSel ? Color.blue : Color(uiColor: .systemFill))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(isSel ? Color.blue : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                // PHASE 2: TRICKS INPUT (Compact Bid Badge + Direct Trick Numbers 0...maxCards)
                HStack(spacing: 6) {
                    // Tap on Bid pill marks exact success
                    Button(action: { viewModel.markSuccess(for: participant.id) }) {
                        HStack(spacing: 2) {
                            Text("Pari")
                                .font(.system(size: 10))
                                .foregroundColor(currentTrick == currentBid ? .white : .secondary)
                            Text("\(currentBid)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(currentTrick == currentBid ? .white : Color(uiColor: .label))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(currentTrick == currentBid ? Color.green : Color(uiColor: .systemFill))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    let btnSize: CGFloat = maxCards > 8 ? 23 : (maxCards > 5 ? 26 : 30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 3) {
                            ForEach(0...maxCards, id: \.self) { num in
                                let isSel = currentTrick == num
                                Button(action: { viewModel.setTrick(for: participant.id, trick: num) }) {
                                    Text("\(num)")
                                        .font(.system(size: maxCards > 8 ? 11 : 13, weight: isSel ? .bold : .medium))
                                        .foregroundColor(isSel ? .white : Color(uiColor: .label))
                                        .frame(width: btnSize, height: btnSize)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(isSel ? Color.blue : Color(uiColor: .systemFill))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .stroke(isSel ? Color.blue : Color.clear, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Optional bonus button if enabled
                    if viewModel.game.bonusEnabled {
                        Button(action: { bonusParticipant = participant }) {
                            let pB = viewModel.piratesBonus[participant.id] ?? 0
                            let mB = viewModel.mermaidBonus[participant.id] ?? false
                            Image(systemName: (pB > 0 || mB) ? "gift.fill" : "gift")
                                .font(.system(size: 13))
                                .foregroundColor((pB > 0 || mB) ? .orange : .secondary)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 5 : 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            if !viewModel.isResultsPhase {
                PirateButton(
                    title: "Valider les paris",
                    icon: "arrow.right"
                ) {
                    viewModel.validateBidsPhase()
                }
            } else {
                HStack(spacing: 8) {
                    // Back button to modify bids
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.isResultsPhase = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Modifier paris")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color(uiColor: .label))
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .tertiarySystemFill))
                        )
                    }
                    
                    Button(action: { viewModel.markAllSuccess() }) {
                        Text("Tous réussi")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.green.opacity(0.12))
                            )
                    }
                    
                    PirateButton(
                        title: viewModel.currentRoundIndex >= viewModel.game.plannedRounds ? "Terminer" : "Valider",
                        icon: "checkmark",
                        isEnabled: viewModel.isTricksSumValid
                    ) {
                        viewModel.validateRound(modelContext: modelContext)
                        if viewModel.game.status == .finished {
                            showingEndGameView = true
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(Divider(), alignment: .top)
    }
}

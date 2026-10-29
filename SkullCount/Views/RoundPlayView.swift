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
    
    // MARK: - Minimalist Header Banner
    
    private var headerBanner: some View {
        HStack(alignment: .center) {
            Text("Manche \(viewModel.currentRoundIndex)/\(viewModel.game.plannedRounds)")
                .font(.headline)
                .fontWeight(.bold)
            
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
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    // MARK: - Player Row (Pure Minimalist, No extra text, No vertical breaks)
    
    private func playerRow(participant: GameParticipant, compact: Bool) -> some View {
        let isLead = participant.seatIndex == viewModel.currentFirstPlayerIndex
        let currentBid = viewModel.bid(for: participant.id)
        let currentTrick = viewModel.trick(for: participant.id)
        let maxCards = viewModel.currentCardsDealt
        
        return HStack(spacing: 8) {
            // Player Lead indicator & Name (Strictly single-line, clean)
            HStack(spacing: 6) {
                if isLead {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 6, height: 6)
                }
                
                Text(participant.player?.name ?? "Joueur")
                    .font(.system(size: compact ? 14 : 15, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(width: compact ? 90 : 105, alignment: .leading)
            
            Spacer()
            
            // Interaction Area depending on Phase
            if !viewModel.isResultsPhase {
                // PHASE 1: BIDS INPUT (Default 0, direct fast tap or stepper)
                if maxCards <= 5 {
                    HStack(spacing: 4) {
                        ForEach(0...maxCards, id: \.self) { num in
                            let isSel = currentBid == num
                            Button(action: { viewModel.setBid(for: participant.id, bid: num) }) {
                                Text("\(num)")
                                    .font(.system(size: compact ? 13 : 14, weight: isSel ? .bold : .regular))
                                    .foregroundColor(isSel ? .white : Color(uiColor: .label))
                                    .frame(width: compact ? 26 : 30, height: compact ? 26 : 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSel ? Color.primary : Color(uiColor: .tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        ForEach(0...min(4, maxCards), id: \.self) { num in
                            let isSel = currentBid == num
                            Button(action: { viewModel.setBid(for: participant.id, bid: num) }) {
                                Text("\(num)")
                                    .font(.system(size: compact ? 13 : 14, weight: isSel ? .bold : .regular))
                                    .foregroundColor(isSel ? .white : Color(uiColor: .label))
                                    .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSel ? Color.primary : Color(uiColor: .tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Compact Stepper for higher bids
                        HStack(spacing: 2) {
                            Button(action: { viewModel.decrementBid(for: participant.id) }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: compact ? 22 : 24, height: compact ? 24 : 28)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(currentBid)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(width: 22)
                            
                            Button(action: { viewModel.incrementBid(for: participant.id) }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: compact ? 22 : 24, height: compact ? 24 : 28)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                // PHASE 2: TRICKS INPUT (Bid indicator pill + Trick buttons / Stepper)
                HStack(spacing: 8) {
                    // Ultra-compact Bid indicator badge (1 tap marks success)
                    Button(action: { viewModel.markSuccess(for: participant.id) }) {
                        HStack(spacing: 2) {
                            Text("Pari")
                                .font(.system(size: 11))
                                .foregroundColor(currentTrick == currentBid ? .white : .secondary)
                            Text("\(currentBid)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(currentTrick == currentBid ? .white : .primary)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(currentTrick == currentBid ? Color.green : Color(uiColor: .tertiarySystemFill))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Tricks Input Buttons or Stepper
                    if maxCards <= 4 {
                        HStack(spacing: 3) {
                            ForEach(0...maxCards, id: \.self) { num in
                                let isSel = currentTrick == num
                                Button(action: { viewModel.setTrick(for: participant.id, trick: num) }) {
                                    Text("\(num)")
                                        .font(.system(size: compact ? 12 : 13, weight: isSel ? .bold : .regular))
                                        .foregroundColor(isSel ? .white : Color(uiColor: .label))
                                        .frame(width: compact ? 22 : 26, height: compact ? 22 : 26)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(isSel ? Color.primary : Color(uiColor: .tertiarySystemFill))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        // Compact Stepper (- [score] +)
                        HStack(spacing: 4) {
                            Button(action: { viewModel.decrementTrick(for: participant.id) }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 26, height: 26)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(currentTrick)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .frame(width: 24)
                            
                            Button(action: { viewModel.incrementTrick(for: participant.id) }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 26, height: 26)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
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
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, compact ? 6 : 8)
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
                HStack(spacing: 10) {
                    Button(action: { viewModel.markAllSuccess() }) {
                        Text("Tous réussi")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.green.opacity(0.12))
                            )
                    }
                    
                    PirateButton(
                        title: viewModel.currentRoundIndex >= viewModel.game.plannedRounds ? "Terminer" : "Valider la manche",
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

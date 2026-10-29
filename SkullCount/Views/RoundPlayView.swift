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
                phaseStatusBanner
                
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
                .padding(.top, 6)
                
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
                HStack(spacing: 16) {
                    Button(action: { viewModel.isScoresRevealed.toggle() }) {
                        Image(systemName: viewModel.isScoresRevealed ? "eye.fill" : "eye.slash.fill")
                    }
                    
                    Button(action: { showingScoresTable = true }) {
                        Image(systemName: "tablecells")
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
            UIApplication.shared.isIdleTimerDisabled = true
            if viewModel.game.status == .finished {
                showingEndGameView = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - Header
    
    private var headerBanner: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manche \(viewModel.currentRoundIndex) / \(viewModel.game.plannedRounds)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Text("Ouvreur :")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.startingPlayerName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if viewModel.isScoresRevealed {
                    Text("Scores visibles")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                        .foregroundColor(.green)
                }
                
                Text("\(viewModel.currentCardsDealt) carte\(viewModel.currentCardsDealt > 1 ? "s" : "")")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    // MARK: - Phase Banner
    
    private var phaseStatusBanner: some View {
        HStack {
            if !viewModel.isResultsPhase {
                let totalBids = viewModel.totalBids
                let cards = viewModel.currentCardsDealt
                let diff = totalBids - cards
                
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.accentColor)
                Text("Paris : \(totalBids) / \(cards) plis")
                    .font(.subheadline.weight(.semibold))
                
                Spacer()
                
                if diff > 0 {
                    Text("Surenchère +\(diff)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red.opacity(0.12)))
                } else if diff < 0 {
                    Text("Sous-enchère \(diff)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                } else {
                    Text("Équilibre")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                }
            } else {
                let totalTricks = viewModel.totalTricks
                let cards = viewModel.currentCardsDealt
                let missing = viewModel.tricksMissingCount
                
                Image(systemName: "flag.checkered")
                    .foregroundColor(.accentColor)
                Text("Plis : \(totalTricks) / \(cards)")
                    .font(.subheadline.weight(.semibold))
                
                Spacer()
                
                if missing != 0 {
                    Text(missing > 0 ? "Manque \(missing) pli(s)" : "Trop de plis (\(abs(missing)))")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.red)
                } else {
                    Text("✓ Total exact")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    // MARK: - Player Row (Ultra Compact, Zero Scroll)
    
    private func playerRow(participant: GameParticipant, compact: Bool) -> some View {
        let isLead = participant.seatIndex == viewModel.currentFirstPlayerIndex
        let currentBid = viewModel.bid(for: participant.id)
        let currentTrick = viewModel.trick(for: participant.id)
        let maxCards = viewModel.currentCardsDealt
        
        return HStack(spacing: 8) {
            // Player Avatar & Name
            HStack(spacing: 4) {
                if isLead {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.accentColor)
                }
                
                Text(participant.player?.emoji ?? "👤")
                    .font(.system(size: compact ? 16 : 18))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(participant.player?.name ?? "Joueur")
                        .font(.system(size: compact ? 13 : 14, weight: .semibold))
                        .lineLimit(1)
                    
                    if viewModel.isScoresRevealed {
                        let totalScore = participant.roundEntries
                            .filter { ($0.round?.number ?? 0) < viewModel.currentRoundIndex }
                            .reduce(0) { $0 + $1.points }
                        Text("\(totalScore) pts")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: compact ? 88 : 100, alignment: .leading)
            
            Spacer()
            
            // Interaction Area depending on Phase
            if !viewModel.isResultsPhase {
                // PHASE 1: BIDS INPUT (Default 0, direct fast tap or stepper)
                if maxCards <= 5 {
                    // All buttons fit side-by-side without scrolling
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
                                            .fill(isSel ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // Fast stepper + direct pills (0, 1, 2, 3...)
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
                                            .fill(isSel ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Stepper for higher bids
                        HStack(spacing: 2) {
                            Button(action: { viewModel.decrementBid(for: participant.id) }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.accentColor)
                                    .frame(width: compact ? 22 : 24, height: compact ? 24 : 28)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(currentBid)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(currentBid > 4 ? .accentColor : Color(uiColor: .label))
                                .frame(width: 22)
                            
                            Button(action: { viewModel.incrementBid(for: participant.id) }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.accentColor)
                                    .frame(width: compact ? 22 : 24, height: compact ? 24 : 28)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                // PHASE 2: TRICKS RESULTS (Default 0, direct 1-tap success, quick buttons, or compact stepper)
                HStack(spacing: 6) {
                    // Quick "Success" pill: 1-tap if they made their bid
                    Button(action: { viewModel.markSuccess(for: participant.id) }) {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Pari (\(currentBid))")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .foregroundColor(currentTrick == currentBid ? .white : .green)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(currentTrick == currentBid ? Color.green : Color.green.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Compact Stepper / Selector for Tricks
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
                                                .fill(isSel ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        // Compact Stepper (- [score] +)
                        HStack(spacing: 3) {
                            Button(action: { viewModel.decrementTrick(for: participant.id) }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 24, height: 24)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(currentTrick)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(width: 22)
                            
                            Button(action: { viewModel.incrementTrick(for: participant.id) }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 24, height: 24)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Bonus Capture Button
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
                    
                    // Preview Score Badge
                    if let preview = viewModel.getPreviewScore(for: participant.id) {
                        Text("\(preview.points > 0 ? "+" : "")\(preview.points)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(preview.isSuccess ? .green : .red)
                            .frame(minWidth: 32, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
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
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Tous réussi")
                        }
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
                        title: viewModel.currentRoundIndex >= viewModel.game.plannedRounds ? "Terminer la partie" : "Valider la manche",
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

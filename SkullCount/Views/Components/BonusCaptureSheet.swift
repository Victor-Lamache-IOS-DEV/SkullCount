import SwiftUI

public struct BonusCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let playerName: String
    let bonusPirateValue: Int
    let bonusMermaidValue: Int
    
    @Binding var piratesCount: Int
    @Binding var mermaidCapturedSK: Bool
    
    public init(
        playerName: String,
        bonusPirateValue: Int = 30,
        bonusMermaidValue: Int = 50,
        piratesCount: Binding<Int>,
        mermaidCapturedSK: Binding<Bool>
    ) {
        self.playerName = playerName
        self.bonusPirateValue = bonusPirateValue
        self.bonusMermaidValue = bonusMermaidValue
        self._piratesCount = piratesCount
        self._mermaidCapturedSK = mermaidCapturedSK
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Bonus de capture – \(playerName)")
                        .font(.headline)
                        .foregroundColor(PirateTheme.gold)
                        .padding(.top, 8)
                    
                    Text("Les bonus ne sont accordés que si le pari est réussi.")
                        .font(.caption)
                        .foregroundColor(PirateTheme.parchment.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // Skull King captured Pirates
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pirates capturés par le Skull King")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(PirateTheme.parchment)
                                Text("+\(bonusPirateValue) pts par pirate (Scary Mary compte)")
                                    .font(.caption2)
                                    .foregroundColor(PirateTheme.gold)
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                Button(action: {
                                    if piratesCount > 0 { piratesCount -= 1 }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(piratesCount > 0 ? PirateTheme.gold : .gray)
                                }
                                .disabled(piratesCount <= 0)
                                
                                Text("\(piratesCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(PirateTheme.parchment)
                                    .frame(minWidth: 28)
                                
                                Button(action: {
                                    if piratesCount < 6 { piratesCount += 1 }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(piratesCount < 6 ? PirateTheme.gold : .gray)
                                }
                                .disabled(piratesCount >= 6)
                            }
                        }
                        .pirateCard()
                        
                        // Mermaid captured Skull King
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sirène capture le Skull King")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(PirateTheme.parchment)
                                Text("+\(bonusMermaidValue) pts bonus")
                                    .font(.caption2)
                                    .foregroundColor(PirateTheme.gold)
                            }
                            Spacer()
                            Toggle("", isOn: $mermaidCapturedSK)
                                .labelsHidden()
                                .tint(PirateTheme.emerald)
                        }
                        .pirateCard()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    PirateButton(title: "Valider les bonus", icon: "checkmark") {
                        dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(PirateTheme.gold)
                }
            }
        }
        .presentationDetents([.height(380)])
    }
}

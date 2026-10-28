import SwiftUI

public struct StartingPlayerWheelView: View {
    let players: [Player]
    let onSelected: (Int) -> Void
    
    @State private var rotationAngle: Double = 0
    @State private var isSpinning: Bool = false
    @State private var selectedIndex: Int = 0
    @State private var hasSpun: Bool = false
    
    public init(players: [Player], onSelected: @escaping (Int) -> Void) {
        self.players = players
        self.onSelected = onSelected
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Text("Boussole du Destin")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(PirateTheme.gold)
            
            Text("Qui donnera le coup d'envoi de la manche 1 ?")
                .font(.subheadline)
                .foregroundColor(PirateTheme.parchment.opacity(0.8))
                .multilineTextAlignment(.center)
            
            ZStack {
                // Compass outer dial
                Circle()
                    .stroke(PirateTheme.gold, lineWidth: 6)
                    .frame(width: 260, height: 260)
                    .background(Circle().fill(PirateTheme.deepNavy))
                    .shadow(color: PirateTheme.gold.opacity(0.4), radius: 10)
                
                // Segment markers for players
                ForEach(0..<players.count, id: \.self) { idx in
                    let angle = Double(idx) * (360.0 / Double(players.count))
                    VStack {
                        HStack(spacing: 4) {
                            Text(players[idx].emoji)
                                .font(.system(size: 22))
                            Text(players[idx].name.prefix(8))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: players[idx].colorHex))
                        }
                        .padding(4)
                        .background(Capsule().fill(PirateTheme.midnightNavy.opacity(0.8)))
                        Spacer()
                    }
                    .frame(height: 240)
                    .rotationEffect(.degrees(angle))
                }
                
                // Compass needle
                VStack(spacing: 0) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 42))
                        .foregroundColor(PirateTheme.crimson)
                        .shadow(color: PirateTheme.crimson.opacity(0.6), radius: 5)
                    Circle()
                        .fill(PirateTheme.gold)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    Spacer()
                }
                .frame(height: 180)
                .rotationEffect(.degrees(rotationAngle))
            }
            .frame(width: 280, height: 280)
            
            if hasSpun {
                VStack(spacing: 6) {
                    Text("Capitaine désigné :")
                        .font(.subheadline)
                        .foregroundColor(PirateTheme.parchment.opacity(0.7))
                    HStack(spacing: 8) {
                        Text(players[selectedIndex].emoji)
                            .font(.title)
                        Text(players[selectedIndex].name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(PirateTheme.gold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(PirateTheme.cardSurface))
                    .overlay(Capsule().stroke(PirateTheme.gold, lineWidth: 1.5))
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            HStack(spacing: 16) {
                Button(action: spinWheel) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(hasSpun ? "Relancer" : "Tourner la boussole")
                    }
                    .font(.headline)
                    .foregroundColor(PirateTheme.midnightNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.gold))
                }
                .disabled(isSpinning)
                
                if hasSpun {
                    Button(action: {
                        onSelected(selectedIndex)
                    }) {
                        Text("Confirmer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.emerald))
                    }
                }
            }
        }
        .padding()
        .pirateCard()
    }
    
    private func spinWheel() {
        guard !players.isEmpty, !isSpinning else { return }
        isSpinning = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let targetIndex = Int.random(in: 0..<players.count)
        let sliceAngle = 360.0 / Double(players.count)
        let extraRotations = Double(Int.random(in: 4...7)) * 360.0
        let targetAngle = extraRotations + (Double(targetIndex) * sliceAngle)
        
        withAnimation(.easeOut(duration: 2.2)) {
            rotationAngle += targetAngle
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            self.selectedIndex = targetIndex
            self.hasSpun = true
            self.isSpinning = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

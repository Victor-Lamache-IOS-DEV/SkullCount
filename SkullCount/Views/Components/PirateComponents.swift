import SwiftUI

// MARK: - Pirate Glass Card Modifier

public struct PirateCardModifier: ViewModifier {
    var backgroundColor: Color = PirateTheme.cardSurface
    var borderColor: Color = PirateTheme.cardBorder
    var cornerRadius: CGFloat = 16
    
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}

public extension View {
    func pirateCard(
        backgroundColor: Color = PirateTheme.cardSurface,
        borderColor: Color = PirateTheme.cardBorder,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.modifier(PirateCardModifier(backgroundColor: backgroundColor, borderColor: borderColor, cornerRadius: cornerRadius))
    }
}

// MARK: - Pirate Primary Button

public struct PirateButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void
    
    public var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(isEnabled ? (isDestructive ? .white : PirateTheme.midnightNavy) : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled
                            ? (isDestructive ? PirateTheme.crimson : PirateTheme.gold)
                            : PirateTheme.deepNavy.opacity(0.8)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isEnabled ? (isDestructive ? PirateTheme.crimson : PirateTheme.lightGold) : PirateTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: isEnabled ? (isDestructive ? PirateTheme.crimson.opacity(0.4) : PirateTheme.gold.opacity(0.3)) : .clear, radius: 6, y: 3)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

// MARK: - Pirate Circular Number Button

public struct PirateNumberButton: View {
    let number: Int
    let isSelected: Bool
    var diameter: CGFloat = 48
    let action: () -> Void
    
    public var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text("\(number)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? PirateTheme.midnightNavy : PirateTheme.parchment)
                .frame(width: diameter, height: diameter)
                .background(
                    Circle()
                        .fill(isSelected ? PirateTheme.gold : PirateTheme.cardSurface)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? PirateTheme.lightGold : PirateTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? PirateTheme.gold.opacity(0.4) : Color.black.opacity(0.2), radius: isSelected ? 4 : 2, y: 1)
        }
        .accessibilityLabel("\(number)")
    }
}

import SwiftUI

// MARK: - Pirate Glass Card Modifier

public struct PirateCardModifier: ViewModifier {
    var backgroundColor: Color = PirateTheme.cardSurface
    var borderColor: Color = PirateTheme.cardBorder
    var cornerRadius: CGFloat = 14
    
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5)
            )
    }
}

public extension View {
    func pirateCard(
        backgroundColor: Color = PirateTheme.cardSurface,
        borderColor: Color = PirateTheme.cardBorder,
        cornerRadius: CGFloat = 14
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
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(isEnabled ? .white : Color(uiColor: .tertiaryLabel))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isEnabled
                            ? (isDestructive ? PirateTheme.crimson : Color.accentColor)
                            : Color(uiColor: .tertiarySystemFill)
                    )
            )
        }
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

// MARK: - Pirate Circular / Pill Number Button

public struct PirateNumberButton: View {
    let number: Int
    let isSelected: Bool
    var diameter: CGFloat = 40
    let action: () -> Void
    
    public var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text("\(number)")
                .font(.system(size: 17, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : Color(uiColor: .label))
                .frame(width: diameter, height: diameter)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color(uiColor: .separator).opacity(0.3), lineWidth: isSelected ? 1.5 : 0.5)
                )
        }
        .accessibilityLabel("\(number)")
    }
}

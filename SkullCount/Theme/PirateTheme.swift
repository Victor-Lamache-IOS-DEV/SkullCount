import Foundation
import SwiftUI

public enum PirateTheme {
    // Apple-styled Clean Colors (Adaptive to Light & Dark)
    public static let midnightNavy = Color(uiColor: .systemGroupedBackground)
    public static let deepNavy = Color(uiColor: .secondarySystemGroupedBackground)
    public static let cardSurface = Color(uiColor: .secondarySystemGroupedBackground)
    public static let cardBorder = Color(uiColor: .separator).opacity(0.35)
    
    // Refined Apple Accent Tints
    public static let gold = Color.orange
    public static let antiqueGold = Color.orange.opacity(0.85)
    public static let lightGold = Color.yellow.opacity(0.7)
    
    // Clean System Typography Colors
    public static let parchment = Color(uiColor: .label)
    public static let parchmentDark = Color(uiColor: .secondaryLabel)
    
    // Status Accents
    public static let crimson = Color.red
    public static let emerald = Color.green
    public static let oceanBlue = Color.blue
    public static let purple = Color.purple
    
    public static let playerPalette: [String] = [
        "#007AFF", // Apple Blue
        "#34C759", // Apple Green
        "#FF9500", // Apple Orange
        "#FF2D55", // Apple Pink
        "#AF52DE", // Apple Purple
        "#5856D6", // Apple Indigo
        "#FF3B30", // Apple Red
        "#30B0C7", // Apple Teal
        "#32ADE6", // Apple Cyan
        "#FFCC00", // Apple Yellow
        "#8E8E93", // Apple Gray
        "#A2845E"  // Apple Brown
    ]
    
    public static let defaultEmojis: [String] = [
        "🏴‍☠️", "⚓️", "🦜", "🗡️", "🧜‍♀️", "👑", "🧭", "🍺", "💣", "💎", "🗺️", "🐙"
    ]
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 230, 126, 34)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#E67E22"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

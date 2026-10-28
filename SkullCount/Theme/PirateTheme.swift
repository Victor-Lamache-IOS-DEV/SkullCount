import Foundation
import SwiftUI

public enum PirateTheme {
    // Colors
    public static let midnightNavy = Color(red: 10/255, green: 22/255, blue: 40/255)
    public static let deepNavy = Color(red: 18/255, green: 32/255, blue: 58/255)
    public static let cardSurface = Color(red: 26/255, green: 43/255, blue: 74/255)
    public static let cardBorder = Color(red: 45/255, green: 70/255, blue: 115/255)
    
    public static let gold = Color(red: 235/255, green: 178/255, blue: 58/255)
    public static let antiqueGold = Color(red: 198/255, green: 146/255, blue: 42/255)
    public static let lightGold = Color(red: 255/255, green: 220/255, blue: 120/255)
    
    public static let parchment = Color(red: 244/255, green: 236/255, blue: 215/255)
    public static let parchmentDark = Color(red: 216/255, green: 202/255, blue: 170/255)
    
    public static let crimson = Color(red: 214/255, green: 69/255, blue: 69/255)
    public static let emerald = Color(red: 46/255, green: 184/255, blue: 114/255)
    public static let oceanBlue = Color(red: 52/255, green: 152/255, blue: 219/255)
    
    public static let playerPalette: [String] = [
        "#E74C3C", // Pirate Red
        "#E67E22", // Gold Orange
        "#F1C40F", // Sun Gold
        "#2ECC71", // Emerald Green
        "#1ABC9C", // Turquoise
        "#3498DB", // Ocean Blue
        "#9B59B6", // Royal Purple
        "#E84393", // Siren Pink
        "#00CEC9", // Caribbean Cyan
        "#6C5CE7", // Deep Indigo
        "#F39C12", // Amber
        "#A29BFE"  // Lavender
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

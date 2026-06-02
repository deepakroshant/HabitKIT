import SwiftUI

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }

    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}

/// The 12 preset habit colors matching HabitKit's palette.
let habitColors: [Color] = [
    Color(hex: "#4FC14F")!, // green
    Color(hex: "#5B8DEE")!, // blue
    Color(hex: "#C46EFF")!, // purple
    Color(hex: "#FF6B6B")!, // red
    Color(hex: "#FFB347")!, // orange
    Color(hex: "#FFE066")!, // yellow
    Color(hex: "#5BC8EF")!, // teal
    Color(hex: "#FF80AB")!, // pink
    Color(hex: "#A8E063")!, // lime
    Color(hex: "#FF8C42")!, // deep orange
    Color(hex: "#B0BEC5")!, // grey
    Color(hex: "#80DEEA")!, // cyan
]

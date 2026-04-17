import SwiftUI

// Earthy ClayLab palette — works in light and dark.
enum Palette {
    static let bone       = Color("Bone")
    static let boneDeep   = Color("BoneDeep")
    static let paper      = Color("Paper")
    static let clay       = Color("Clay")
    static let clayMuted  = Color("ClayMuted")
    static let terracotta = Color("Terracotta")
    static let terracottaDeep = Color("TerracottaDeep")
    static let sage       = Color("Sage")
    static let slate      = Color("Slate")
    static let stone      = Color("Stone")
    static let bisque     = Color("Bisque")
}

struct StagePalette {
    let start: Color
    let end: Color
    let dot: Color
    let icon: String

    static func of(_ stage: Stage) -> StagePalette {
        switch stage {
        case .idea:      .init(start: Color(hex: "#D5CCBC"), end: Color(hex: "#9A8E7C"), dot: Color(hex: "#9A8E7C"), icon: "lightbulb")
        case .formed:    .init(start: Color(hex: "#D9744F"), end: Color(hex: "#7E2D14"), dot: Color(hex: "#C2502A"), icon: "circle.dotted")
        case .greenware: .init(start: Color(hex: "#C0CBB1"), end: Color(hex: "#6B7D58"), dot: Color(hex: "#8B9D77"), icon: "leaf")
        case .bisque:    .init(start: Color(hex: "#E8C8A0"), end: Color(hex: "#C8954E"), dot: Color(hex: "#C8954E"), icon: "sun.max")
        case .glazed:    .init(start: Color(hex: "#8FA8B8"), end: Color(hex: "#4D6E82"), dot: Color(hex: "#6B8B9E"), icon: "drop")
        case .finished:  .init(start: Color(hex: "#A33D1D"), end: Color(hex: "#3F2818"), dot: Color(hex: "#3F2818"), icon: "sparkles")
        case .archived:  .init(start: Color(hex: "#D5CCBC"), end: Color(hex: "#9A8E7C"), dot: Color(hex: "#B8AC9A"), icon: "archivebox")
        }
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&v)
        let r, g, b, a: UInt64
        switch cleaned.count {
        case 6: (r, g, b, a) = (v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF, 255)
        case 8: (r, g, b, a) = (v >> 24 & 0xFF, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    var hex: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

enum CoverSwatches {
    static let all: [(from: Color, to: Color)] = [
        (Color(hex: "#E8C8A0"), Color(hex: "#C8954E")),
        (Color(hex: "#D9744F"), Color(hex: "#7E2D14")),
        (Color(hex: "#C0CBB1"), Color(hex: "#6B7D58")),
        (Color(hex: "#8FA8B8"), Color(hex: "#4D6E82")),
        (Color(hex: "#D5CCBC"), Color(hex: "#9A8E7C")),
        (Color(hex: "#EDE3D2"), Color(hex: "#C2502A")),
        (Color(hex: "#A8B594"), Color(hex: "#3F2818")),
    ]
}

import UIKit

enum Haptics {
    static func tap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func advance() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    static func success() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func warning() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }
}

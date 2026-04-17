import SwiftUI

struct StageChip: View {
    let stage: Stage
    var size: Size = .medium
    var onAdvance: (() -> Void)? = nil

    enum Size { case small, medium, large }

    var body: some View {
        let canAdvance = stage != .archived && stage != .finished && onAdvance != nil
        Button {
            Haptics.advance()
            onAdvance?()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(StagePalette.of(stage).dot)
                    .frame(width: dotSize, height: dotSize)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.6), lineWidth: 1).blur(radius: 0.5)
                    )
                Text(stage.label.uppercased())
                    .font(.system(size: fontSize, weight: .semibold))
                    .tracking(0.8)
                if canAdvance {
                    Image(systemName: "chevron.right")
                        .font(.system(size: fontSize - 2, weight: .bold))
                        .opacity(0.45)
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .background(
                Capsule().fill(Color.primary.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(Palette.clay)
        }
        .buttonStyle(.plain)
        .disabled(!canAdvance)
    }

    private var dotSize: CGFloat {
        switch size { case .small: 7; case .medium: 9; case .large: 11 }
    }
    private var fontSize: CGFloat {
        switch size { case .small: 10; case .medium: 11; case .large: 13 }
    }
    private var hPad: CGFloat {
        switch size { case .small: 8; case .medium: 10; case .large: 14 }
    }
    private var vPad: CGFloat {
        switch size { case .small: 4; case .medium: 6; case .large: 8 }
    }
}

struct StageProgressBar: View {
    let stage: Stage
    var body: some View {
        let idx = Stage.progressOrder.firstIndex(of: stage) ?? -1
        HStack(spacing: 3) {
            ForEach(Array(Stage.progressOrder.enumerated()), id: \.offset) { i, s in
                Capsule()
                    .fill(i <= idx && stage != .archived ? StagePalette.of(s).dot : Color.primary.opacity(0.1))
                    .frame(height: 4)
            }
        }
    }
}

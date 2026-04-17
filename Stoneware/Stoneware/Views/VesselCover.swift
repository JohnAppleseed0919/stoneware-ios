import SwiftUI

// Procedural ceramic vessel silhouette — seeded by piece id.
struct VesselCover: View {
    let seed: UUID
    let coverIndex: Int
    let photoData: Data?
    var cornerRadius: CGFloat = 20

    var body: some View {
        ZStack {
            if let data = photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                GeometryReader { geo in
                    let h = geo.size.height
                    let w = geo.size.width
                    Path { path in
                        let cx = w * 0.5
                        let top = h * 0.18
                        let bottom = h * 0.92
                        let lipY = top + 4
                        let neckW = w * neckWidthRatio
                        let bellyW = w * bellyWidthRatio
                        let baseW = w * baseWidthRatio
                        path.move(to: CGPoint(x: cx - neckW / 2, y: top))
                        path.addLine(to: CGPoint(x: cx + neckW / 2, y: top))
                        path.addLine(to: CGPoint(x: cx + neckW / 2, y: lipY))
                        path.addQuadCurve(
                            to: CGPoint(x: cx + bellyW / 2, y: top + h * 0.35),
                            control: CGPoint(x: cx + neckW / 2 + 8, y: top + h * 0.12)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: cx + baseW / 2, y: bottom),
                            control: CGPoint(x: cx + bellyW / 2, y: bottom - h * 0.05)
                        )
                        path.addLine(to: CGPoint(x: cx - baseW / 2, y: bottom))
                        path.addQuadCurve(
                            to: CGPoint(x: cx - bellyW / 2, y: top + h * 0.35),
                            control: CGPoint(x: cx - bellyW / 2, y: bottom - h * 0.05)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: cx - neckW / 2, y: lipY),
                            control: CGPoint(x: cx - neckW / 2 - 8, y: top + h * 0.12)
                        )
                        path.closeSubpath()
                    }
                    .fill(Color.black.opacity(0.20))
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .mask(
                        Path { path in
                            let cx = w * 0.5
                            let top = h * 0.18
                            let bottom = h * 0.92
                            let lipY = top + 4
                            let neckW = w * neckWidthRatio
                            let bellyW = w * bellyWidthRatio
                            let baseW = w * baseWidthRatio
                            path.move(to: CGPoint(x: cx - neckW / 2, y: top))
                            path.addLine(to: CGPoint(x: cx + neckW / 2, y: top))
                            path.addLine(to: CGPoint(x: cx + neckW / 2, y: lipY))
                            path.addQuadCurve(to: CGPoint(x: cx + bellyW / 2, y: top + h * 0.35),
                                              control: CGPoint(x: cx + neckW / 2 + 8, y: top + h * 0.12))
                            path.addQuadCurve(to: CGPoint(x: cx + baseW / 2, y: bottom),
                                              control: CGPoint(x: cx + bellyW / 2, y: bottom - h * 0.05))
                            path.addLine(to: CGPoint(x: cx - baseW / 2, y: bottom))
                            path.addQuadCurve(to: CGPoint(x: cx - bellyW / 2, y: top + h * 0.35),
                                              control: CGPoint(x: cx - bellyW / 2, y: bottom - h * 0.05))
                            path.addQuadCurve(to: CGPoint(x: cx - neckW / 2, y: lipY),
                                              control: CGPoint(x: cx - neckW / 2 - 8, y: top + h * 0.12))
                            path.closeSubpath()
                        }
                    )
                }
                // Grain overlay
                Color.black.opacity(0.04)
                    .blendMode(.multiply)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // Deterministic shape parameters from UUID
    private var hash: Int {
        abs(seed.uuidString.hashValue)
    }
    private var neckWidthRatio: Double { 0.25 + Double(hash % 12) * 0.012 }
    private var bellyWidthRatio: Double { 0.52 + Double((hash >> 3) % 20) * 0.012 }
    private var baseWidthRatio: Double { 0.32 + Double((hash >> 6) % 12) * 0.012 }

    private var gradientColors: [Color] {
        let swatch = CoverSwatches.all[coverIndex % CoverSwatches.all.count]
        return [swatch.from, swatch.to]
    }
}

import SwiftUI

struct PieceCard: View {
    let piece: Piece
    let units: UnitsManager
    var onAdvance: () -> Void
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    VesselCover(seed: piece.id, coverIndex: piece.coverIndex, photoData: piece.photoData, cornerRadius: 0)
                        .frame(height: 160)
                    HStack(spacing: 6) {
                        Image(systemName: StagePalette.of(piece.stage).icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(piece.stage.label.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.2)
                        Spacer()
                        if let glazes = piece.glazeLayers, !glazes.isEmpty {
                            HStack(spacing: -4) {
                                ForEach(Array(glazes.prefix(4)), id: \.id) { g in
                                    Circle()
                                        .fill(Color(hex: g.colorHex))
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(Palette.bone, lineWidth: 1.5))
                                }
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .padding(12)
                }
                .clipShape(.rect(topLeadingRadius: 18, topTrailingRadius: 18))

                VStack(alignment: .leading, spacing: 8) {
                    Text(piece.name)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .lineLimit(1)
                        .foregroundStyle(Palette.clay)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.clayMuted)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        if piece.weightG != nil {
                            Label(units.displayWeight(piece.weightG), systemImage: "scalemass")
                                .labelStyle(.compactCaption)
                        }
                        if let glazes = piece.glazeLayers, !glazes.isEmpty {
                            Label("\(glazes.count)", systemImage: "drop")
                                .labelStyle(.compactCaption)
                        }
                        if let firings = piece.firings, !firings.isEmpty {
                            Label("\(firings.count)", systemImage: "flame")
                                .labelStyle(.compactCaption)
                        }
                        Spacer()
                        Text(relativeTime(piece.updatedAt))
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.clayMuted.opacity(0.7))
                    }

                    HStack {
                        StageChip(stage: piece.stage, size: .small, onAdvance: {
                            onAdvance()
                        })
                        Spacer()
                    }
                }
                .padding(14)
            }
            .background(Palette.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .opacity(piece.stage == .archived ? 0.7 : 1)
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        let clay = piece.clayBody.isEmpty ? "No clay body" : piece.clayBody
        let method = piece.formingMethod?.rawValue ?? "No method"
        return "\(clay) · \(method)"
    }
}

private struct CompactCaptionLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 10, weight: .semibold))
            configuration.title
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Palette.clayMuted)
    }
}

extension LabelStyle where Self == CompactCaptionLabelStyle {
    static var compactCaption: CompactCaptionLabelStyle { CompactCaptionLabelStyle() }
}

func relativeTime(_ date: Date) -> String {
    let diff = Date().timeIntervalSince(date)
    let day: TimeInterval = 86400
    if diff < day { return "today" }
    if diff < 2 * day { return "yesterday" }
    if diff < 7 * day { return "\(Int(diff / day))d ago" }
    if diff < 30 * day { return "\(Int(diff / (7 * day)))w ago" }
    return "\(Int(diff / (30 * day)))mo ago"
}

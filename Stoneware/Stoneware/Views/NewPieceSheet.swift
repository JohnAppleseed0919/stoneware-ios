import SwiftUI

struct NewPieceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UnitsManager.self) private var units

    let onCreate: (Piece) -> Void

    @State private var name = ""
    @State private var clayBody = ""
    @State private var formingMethod: FormingMethod? = nil
    @State private var weight = ""
    @State private var height = ""
    @State private var width = ""
    @State private var coverIndex = Int.random(in: 0..<CoverSwatches.all.count)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COVER")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Palette.clayMuted)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<CoverSwatches.all.count, id: \.self) { i in
                                    let s = CoverSwatches.all[i]
                                    Button {
                                        Haptics.tap()
                                        coverIndex = i
                                    } label: {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LinearGradient(colors: [s.from, s.to], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 54, height: 54)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(coverIndex == i ? Palette.clay : Color.clear, lineWidth: 3)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    LabeledField(label: "Piece name") {
                        TextField("e.g. Speckled morning mug", text: $name)
                            .inputChrome()
                    }
                    HStack(spacing: 10) {
                        LabeledField(label: "Clay body") {
                            Menu {
                                Button("None") { clayBody = "" }
                                ForEach(CommonClayBodies.all, id: \.self) { c in
                                    Button(c) { clayBody = c }
                                }
                            } label: {
                                MenuInputLabel(text: clayBody.isEmpty ? "Stoneware…" : clayBody)
                            }
                        }
                        LabeledField(label: "Method") {
                            Menu {
                                Button("None") { formingMethod = nil }
                                ForEach(FormingMethod.allCases) { m in
                                    Button(m.rawValue) { formingMethod = m }
                                }
                            } label: {
                                MenuInputLabel(text: formingMethod?.rawValue ?? "Wheel-thrown…")
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        LabeledField(label: "Weight (\(units.system.weightLabel))") {
                            TextField("—", text: $weight)
                                .keyboardType(.decimalPad)
                                .inputChrome()
                        }
                        LabeledField(label: "Height (\(units.system.lengthLabel))") {
                            TextField("—", text: $height)
                                .keyboardType(.decimalPad)
                                .inputChrome()
                        }
                        LabeledField(label: "Width (\(units.system.lengthLabel))") {
                            TextField("—", text: $width)
                                .keyboardType(.decimalPad)
                                .inputChrome()
                        }
                    }
                }
                .padding(18)
            }
            .background(Palette.bone.ignoresSafeArea())
            .navigationTitle("New piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.clayMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        submit()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.terracotta)
                }
            }
        }
    }

    private func submit() {
        let piece = Piece(
            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled piece" : name,
            coverIndex: coverIndex
        )
        piece.clayBody = clayBody
        piece.formingMethod = formingMethod
        piece.weightG = Double(weight).map { units.gramsFromInput($0) }
        piece.heightCm = Double(height).map { units.cmFromInput($0) }
        piece.widthCm = Double(width).map { units.cmFromInput($0) }
        Haptics.success()
        onCreate(piece)
        dismiss()
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Palette.clayMuted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuInputLabel: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .foregroundStyle(Palette.clay)
                .font(.system(size: 15))
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 11))
                .foregroundStyle(Palette.clayMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

extension View {
    func inputChrome() -> some View {
        self
            .font(.system(size: 15))
            .foregroundStyle(Palette.clay)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Palette.paper)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

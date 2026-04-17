import SwiftUI
import SwiftData
import PhotosUI

struct PieceDetailView: View {
    @Bindable var piece: Piece
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(UnitsManager.self) private var units

    @State private var showDeleteAlert = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var showShrinkage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeroRow(piece: piece, photoItem: $photoItem)

                LifecycleSection(piece: piece)

                StatsGrid(piece: piece, units: units, showShrinkage: $showShrinkage)

                GlazeSection(piece: piece)

                FiringSection(piece: piece)

                NotesSection(piece: piece)

                TimelineSection(piece: piece)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Palette.bone.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if piece.stage != .archived {
                        Button {
                            piece.stage = .archived
                            piece.log(.stage, "Stage → Archived")
                        } label: { Label("Archive", systemImage: "archivebox") }
                    } else {
                        Button {
                            piece.stage = .finished
                            piece.log(.stage, "Stage → Finished (restored)")
                        } label: { Label("Restore", systemImage: "arrow.uturn.backward") }
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: { Label("Delete piece", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Palette.clay)
                }
            }
        }
        .alert("Delete this piece?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                context.delete(piece)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("This action can't be undone.")
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        piece.photoData = data
                        piece.log(.photo, "Photo added")
                        try? context.save()
                    }
                }
            }
        }
        .sheet(isPresented: $showShrinkage) {
            ShrinkageCalculator(piece: piece)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct HeroRow: View {
    @Bindable var piece: Piece
    @Binding var photoItem: PhotosPickerItem?
    @State private var isEditingName = false
    @State private var nameDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                VesselCover(seed: piece.id, coverIndex: piece.coverIndex, photoData: piece.photoData, cornerRadius: 22)
                    .frame(height: 260)
                HStack(spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Image(systemName: piece.photoData == nil ? "camera" : "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    if piece.photoData != nil {
                        Button {
                            piece.photoData = nil
                            piece.log(.photo, "Photo removed")
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(12)
            }

            if isEditingName {
                HStack {
                    TextField("Piece name", text: $nameDraft)
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                        .foregroundStyle(Palette.clay)
                        .onSubmit {
                            commitName()
                        }
                    Button("Done") {
                        commitName()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.terracotta)
                }
            } else {
                Button {
                    nameDraft = piece.name
                    isEditingName = true
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(piece.name)
                            .font(.system(size: 32, weight: .semibold, design: .serif))
                            .foregroundStyle(Palette.clay)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Image(systemName: "pencil")
                            .foregroundStyle(Palette.clayMuted.opacity(0.5))
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func commitName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        piece.name = trimmed.isEmpty ? "Untitled piece" : trimmed
        piece.log(.note, "Renamed to \(piece.name)")
        isEditingName = false
    }
}

private struct LifecycleSection: View {
    @Bindable var piece: Piece

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIFECYCLE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.clayMuted)
                Spacer()
                if piece.stage != .archived && piece.stage != .finished {
                    Button {
                        Haptics.advance()
                        piece.stage = piece.stage.next
                        piece.log(.stage, "Stage → \(piece.stage.label)")
                    } label: {
                        HStack(spacing: 4) {
                            Text("Advance to \(piece.stage.next.label)")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Palette.terracotta)
                    }
                }
            }
            StageProgressBar(stage: piece.stage)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Stage.progressOrder, id: \.self) { s in
                        Button {
                            Haptics.tap()
                            if s != piece.stage {
                                piece.stage = s
                                piece.log(.stage, "Stage → \(s.label)")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle().fill(StagePalette.of(s).dot).frame(width: 6, height: 6)
                                Text(s.label.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(s == piece.stage ? Palette.clay : Palette.paper)
                            .foregroundStyle(s == piece.stage ? Palette.bone : Palette.clay)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: s == piece.stage ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct StatsGrid: View {
    @Bindable var piece: Piece
    let units: UnitsManager
    @Binding var showShrinkage: Bool

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            StatCell(label: "Clay body") {
                Menu {
                    Button("None") { piece.clayBody = "" }
                    ForEach(CommonClayBodies.all, id: \.self) { c in
                        Button(c) { piece.clayBody = c; piece.log(.note, "Clay: \(c)") }
                    }
                } label: {
                    MenuLabel(text: piece.clayBody.isEmpty ? "Choose…" : piece.clayBody)
                }
            }
            StatCell(label: "Method") {
                Menu {
                    Button("None") { piece.formingMethod = nil }
                    ForEach(FormingMethod.allCases) { m in
                        Button(m.rawValue) { piece.formingMethod = m; piece.log(.note, "Method: \(m.rawValue)") }
                    }
                } label: {
                    MenuLabel(text: piece.formingMethod?.rawValue ?? "Choose…")
                }
            }
            StatCell(label: "Weight (\(units.system.weightLabel))") {
                NumericInput(
                    value: piece.weightG,
                    display: { units.displayWeight($0).replacingOccurrences(of: " \(units.system.weightLabel)", with: "") },
                    parse: { units.gramsFromInput($0) },
                    commit: { piece.weightG = $0; piece.touch() }
                )
            }
            StatCell(label: "H × W (\(units.system.lengthLabel))") {
                HStack(spacing: 4) {
                    NumericInput(
                        value: piece.heightCm,
                        display: { units.displayLength($0).replacingOccurrences(of: " \(units.system.lengthLabel)", with: "") },
                        parse: { units.cmFromInput($0) },
                        commit: { piece.heightCm = $0; piece.touch() }
                    )
                    Text("×").foregroundStyle(Palette.clayMuted)
                    NumericInput(
                        value: piece.widthCm,
                        display: { units.displayLength($0).replacingOccurrences(of: " \(units.system.lengthLabel)", with: "") },
                        parse: { units.cmFromInput($0) },
                        commit: { piece.widthCm = $0; piece.touch() }
                    )
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showShrinkage = true } label: {
                Label("Shrinkage", systemImage: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.terracotta)
            .padding(.trailing, 4)
            .padding(.top, 4)
            .offset(y: 26)
            .opacity(0)
        }
    }
}

private struct StatCell<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Palette.clayMuted)
            content()
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(Palette.clay)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MenuLabel: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(Palette.clayMuted)
        }
        .foregroundStyle(Palette.clay)
    }
}

private struct NumericInput: View {
    let value: Double?
    let display: (Double) -> String
    let parse: (Double) -> Double
    let commit: (Double?) -> Void

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("—", text: $draft)
            .keyboardType(.decimalPad)
            .focused($focused)
            .onAppear { syncFromValue() }
            .onChange(of: value) { _, _ in if !focused { syncFromValue() } }
            .onChange(of: focused) { _, new in
                if !new { commitDraft() }
            }
            .submitLabel(.done)
            .font(.system(size: 17, weight: .medium, design: .serif))
            .foregroundStyle(Palette.clay)
    }

    private func syncFromValue() {
        if let v = value {
            draft = display(v)
        } else {
            draft = ""
        }
    }

    private func commitDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            commit(nil)
        } else if let d = Double(trimmed) {
            commit(parse(d))
        } else {
            syncFromValue()
        }
    }
}

private struct GlazeSection: View {
    @Bindable var piece: Piece

    var body: some View {
        SectionCard(title: "Glaze layers", icon: "drop") {
            Button {
                Haptics.tap()
                let layer = GlazeLayer()
                layer.piece = piece
                if piece.glazeLayers == nil { piece.glazeLayers = [] }
                piece.glazeLayers?.append(layer)
                piece.log(.glaze, "Added glaze layer")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add layer").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Palette.clay)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        } content: {
            let layers = piece.sortedGlazes
            if layers.isEmpty {
                EmptyRow(text: "No glazes yet — add a base or test layer.")
            } else {
                VStack(spacing: 8) {
                    ForEach(layers, id: \.id) { layer in
                        GlazeRow(layer: layer, onRemove: {
                            piece.glazeLayers?.removeAll { $0.id == layer.id }
                            piece.log(.glaze, "Removed: \(layer.name.isEmpty ? "Untitled" : layer.name)")
                        })
                    }
                }
            }
        }
    }
}

private struct GlazeRow: View {
    @Bindable var layer: GlazeLayer
    let onRemove: () -> Void
    @State private var showColorPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    showColorPicker = true
                } label: {
                    Circle()
                        .fill(Color(hex: layer.colorHex))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Palette.bone, lineWidth: 2))
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                }
                .popover(isPresented: $showColorPicker) {
                    ColorPickerPopover(colorHex: $layer.colorHex)
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Glaze name (e.g. Shino)", text: $layer.name)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(Palette.clay)
                    HStack(spacing: 6) {
                        PillMenu(value: layer.location.rawValue, options: GlazeLocation.allCases.map(\.rawValue)) { v in
                            layer.location = GlazeLocation(rawValue: v) ?? .outside
                        }
                        PillMenu(value: layer.application.rawValue, options: GlazeApplication.allCases.map(\.rawValue)) { v in
                            layer.application = GlazeApplication(rawValue: v) ?? .dipped
                        }
                        CoatsStepper(coats: $layer.coats)
                    }
                }
                Spacer(minLength: 0)
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.clayMuted)
                        .padding(8)
                        .background(Palette.bone)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            TextField("Application notes…", text: $layer.notes)
                .font(.system(size: 12))
                .foregroundStyle(Palette.clayMuted)
        }
        .padding(12)
        .background(Palette.bone.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

private struct ColorPickerPopover: View {
    @Binding var colorHex: String
    var body: some View {
        VStack(spacing: 12) {
            Text("Pick glaze color").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.clay)
            let swatches: [String] = [
                "#F5EFE6", "#E8C8A0", "#D9744F", "#C2502A", "#7E2D14",
                "#3F2818", "#2A1A0F", "#6B8B9E", "#4D6E82", "#8B9D77",
                "#6B7D58", "#A8B594", "#B8AC9A", "#FFFFFF", "#000000",
            ]
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 8), count: 5), spacing: 8) {
                ForEach(swatches, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle().fill(Color(hex: hex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(colorHex == hex ? Palette.terracotta : Color.primary.opacity(0.15), lineWidth: colorHex == hex ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            ColorPicker("Custom", selection: Binding(
                get: { Color(hex: colorHex) },
                set: { colorHex = $0.hex }
            ))
            .labelsHidden()
        }
        .padding(16)
        .frame(width: 220)
    }
}

private struct PillMenu: View {
    let value: String
    let options: [String]
    let onChange: (String) -> Void
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { o in
                Button(o) { onChange(o) }
            }
        } label: {
            Text(value.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Palette.clay)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Palette.paper)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }
}

private struct CoatsStepper: View {
    @Binding var coats: Int
    var body: some View {
        HStack(spacing: 0) {
            Button { coats = max(1, coats - 1) } label: {
                Image(systemName: "minus").font(.system(size: 12, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            Text("\(coats) \(coats == 1 ? "coat" : "coats")")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Palette.clay)
                .padding(.horizontal, 4)
            Button { coats = min(9, coats + 1) } label: {
                Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                    .frame(width: 24, height: 24)
            }
        }
        .background(Palette.paper)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .buttonStyle(.plain)
        .foregroundStyle(Palette.clay)
    }
}

private struct FiringSection: View {
    @Bindable var piece: Piece

    var body: some View {
        SectionCard(title: "Firing log", icon: "flame") {
            Button {
                Haptics.tap()
                let firing = Firing()
                firing.piece = piece
                if piece.firings == nil { piece.firings = [] }
                piece.firings?.append(firing)
                piece.log(.firing, "Logged \(firing.type.rawValue) firing · cone \(firing.cone)")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Log firing").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Palette.clay)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        } content: {
            let firings = piece.sortedFirings
            if firings.isEmpty {
                EmptyRow(text: "No firings logged yet.")
            } else {
                VStack(spacing: 8) {
                    ForEach(firings, id: \.id) { f in
                        FiringRow(firing: f, onRemove: {
                            piece.firings?.removeAll { $0.id == f.id }
                            piece.log(.firing, "Removed \(f.type.rawValue) firing")
                        })
                    }
                }
            }
        }
    }
}

private struct FiringRow: View {
    @Bindable var firing: Firing
    let onRemove: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                PillMenu(value: firing.type.rawValue, options: FiringType.allCases.map(\.rawValue)) { v in
                    firing.type = FiringType(rawValue: v) ?? .bisque
                }
                PillMenu(value: firing.cone, options: Cones.all) { v in firing.cone = v }
                DatePicker("", selection: $firing.date, displayedComponents: .date)
                    .labelsHidden()
                    .font(.system(size: 11))
                Spacer()
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.clayMuted)
                }
                .buttonStyle(.plain)
            }
            TextField("Kiln (e.g. Studio L&L)", text: $firing.kiln)
                .font(.system(size: 13))
                .foregroundStyle(Palette.clay)
            TextField("Schedule, ramp, hold, observations…", text: $firing.notes, axis: .vertical)
                .lineLimit(1...3)
                .font(.system(size: 12))
                .foregroundStyle(Palette.clayMuted)
        }
        .padding(12)
        .background(Palette.bone.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

private struct NotesSection: View {
    @Bindable var piece: Piece
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STUDIO NOTES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Palette.clayMuted)
            TextField("Trim depth, stamp location, what surprised you, what to try next time…", text: $piece.notes, axis: .vertical)
                .lineLimit(3...8)
                .font(.system(size: 14))
                .foregroundStyle(Palette.clay)
                .padding(14)
                .background(Palette.paper)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }
}

private struct TimelineSection: View {
    let piece: Piece

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HISTORY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Palette.clayMuted)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(piece.sortedHistory, id: \.id) { event in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Rectangle()
                                .fill(Color.primary.opacity(0.12))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.leading, 4)
                            Circle()
                                .fill(dotColor(event.kind))
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Palette.bone, lineWidth: 2))
                        }
                        .frame(width: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.text)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundStyle(Palette.clay)
                            Text(event.timestamp.formatted(.dateTime.month().day().hour().minute()))
                                .font(.system(size: 11))
                                .foregroundStyle(Palette.clayMuted.opacity(0.8))
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(14)
            .background(Palette.paper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }

    private func dotColor(_ kind: HistoryKind) -> Color {
        switch kind {
        case .created: Color(hex: "#3F2818")
        case .stage: Color(hex: "#C2502A")
        case .glaze: Color(hex: "#6B8B9E")
        case .firing: Color(hex: "#D9744F")
        case .note: Color(hex: "#8B9D77")
        case .photo: Color(hex: "#9A8E7C")
        }
    }
}

private struct SectionCard<Accessory: View, Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let accessory: () -> Accessory
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.terracotta)
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.clay)
                Spacer()
                accessory()
            }
            content()
        }
        .padding(14)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

private struct EmptyRow: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Palette.clayMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Palette.bone.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.primary.opacity(0.12))
            )
    }
}

// Shrinkage calculator — a practical bonus feature
struct ShrinkageCalculator: View {
    @Bindable var piece: Piece
    @Environment(UnitsManager.self) private var units
    @State private var wet: String = ""
    @State private var dry: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shrinkage calculator")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.clay)
                Text("Measure a reference mark wet and again after firing. Stoneware does the math.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.clayMuted)
            }
            HStack(spacing: 12) {
                CalcField(label: "Wet (\(units.system.lengthLabel))", value: $wet)
                CalcField(label: "After firing (\(units.system.lengthLabel))", value: $dry)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("SHRINKAGE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Palette.clayMuted)
                Text(result)
                    .font(.system(size: 40, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.terracotta)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.paper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Spacer()
        }
        .padding(20)
        .background(Palette.bone.ignoresSafeArea())
    }

    private var result: String {
        guard let w = Double(wet), let d = Double(dry), w > 0 else { return "—" }
        let pct = (w - d) / w * 100
        return String(format: "%.1f%%", pct)
    }
}

private struct CalcField: View {
    let label: String
    @Binding var value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Palette.clayMuted)
            TextField("—", text: $value)
                .keyboardType(.decimalPad)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(Palette.clay)
                .padding(10)
                .background(Palette.paper)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

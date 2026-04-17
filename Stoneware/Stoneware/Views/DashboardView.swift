import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(UnitsManager.self) private var units

    @Query(sort: \Piece.updatedAt, order: .reverse) private var pieces: [Piece]

    @State private var query = ""
    @State private var stageFilter: Stage? = nil
    @State private var clayFilter: String? = nil
    @State private var glazeFilter: String? = nil
    @State private var showArchived = false
    @State private var newSheet = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Hero(pieces: pieces)
                        StageRail(pieces: pieces, selection: $stageFilter, showArchived: $showArchived)
                        FilterBar(
                            query: $query,
                            clayFilter: $clayFilter,
                            glazeFilter: $glazeFilter,
                            clayOptions: clayOptions,
                            glazeOptions: glazeOptions
                        )

                        if filtered.isEmpty {
                            EmptyStateView(hasAny: !pieces.isEmpty, onNew: { newSheet = true }, onClear: clearFilters)
                                .padding(.top, 24)
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 14) {
                                ForEach(filtered, id: \.id) { piece in
                                    NavigationLink(value: piece.id) {
                                        PieceCard(
                                            piece: piece,
                                            units: units,
                                            onAdvance: { advance(piece) },
                                            onTap: {}
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        ContextActions(piece: piece, onDelete: { delete(piece) })
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .background(Palette.bone.ignoresSafeArea())
                .navigationDestination(for: UUID.self) { id in
                    if let piece = pieces.first(where: { $0.id == id }) {
                        PieceDetailView(piece: piece)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Branding() }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Palette.clay)
                        }
                    }
                }
                .sheet(isPresented: $newSheet) {
                    NewPieceSheet(onCreate: create)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsSheet()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }

                Button {
                    Haptics.tap()
                    newSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                        Text("New piece")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Palette.clay)
                    .clipShape(Capsule())
                    .shadow(color: Palette.clay.opacity(0.3), radius: 12, y: 6)
                }
                .padding(.trailing, 18)
                .padding(.bottom, 18)
            }
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 14)]
    }

    private var clayOptions: [String] {
        Array(Set(pieces.map(\.clayBody).filter { !$0.isEmpty })).sorted()
    }
    private var glazeOptions: [String] {
        Array(Set(pieces.flatMap { ($0.glazeLayers ?? []).map(\.name) }.filter { !$0.isEmpty })).sorted()
    }

    private var filtered: [Piece] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        return pieces.filter { p in
            if !showArchived && p.stage == .archived { return false }
            if let s = stageFilter, p.stage != s { return false }
            if let c = clayFilter, p.clayBody != c { return false }
            if let g = glazeFilter, !(p.glazeLayers ?? []).contains(where: { $0.name == g }) { return false }
            if !q.isEmpty {
                let hay = p.name + " " + p.clayBody + " " + p.notes + " " + ((p.glazeLayers ?? []).map(\.name).joined(separator: " "))
                if !hay.lowercased().contains(q) { return false }
            }
            return true
        }
    }

    private func advance(_ piece: Piece) {
        guard piece.stage != .archived else { return }
        let next = piece.stage.next
        guard next != piece.stage else { return }
        piece.stage = next
        piece.log(.stage, "Stage → \(next.label)")
        try? context.save()
    }

    private func create(_ piece: Piece) {
        context.insert(piece)
        piece.log(.created, "Piece created")
        try? context.save()
    }

    private func delete(_ piece: Piece) {
        context.delete(piece)
        try? context.save()
    }

    private func clearFilters() {
        query = ""
        stageFilter = nil
        clayFilter = nil
        glazeFilter = nil
    }
}

private struct Branding: View {
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "#D9744F"), Color(hex: "#7E2D14")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Capsule()
                    .fill(Color(hex: "#3F2818").opacity(0.6))
                    .frame(width: 14, height: 3)
                    .offset(y: 9)
            }
            Text("Stone")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.clay)
            + Text("ware")
                .font(.system(size: 20, weight: .semibold, design: .serif).italic())
                .foregroundStyle(Palette.terracotta)
        }
    }
}

private struct Hero: View {
    let pieces: [Piece]
    var body: some View {
        let inProgress = pieces.filter { ![Stage.idea, .finished, .archived].contains($0.stage) }.count
        let finished = pieces.filter { $0.stage == .finished }.count
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR STUDIO, RECORDED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Palette.clayMuted)
            Text("Track every vessel\nfrom wedge to finished.")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.clay)
                .lineSpacing(-4)

            HStack(spacing: 10) {
                FactCard(label: "Working", value: inProgress, hint: "across stages")
                FactCard(label: "Finished", value: finished, hint: "off the kiln")
            }
        }
        .padding(.top, 8)
    }
}

private struct FactCard: View {
    let label: String
    let value: Int
    let hint: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Palette.clayMuted)
            Text("\(value)")
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.clay)
                .padding(.top, 2)
            Text(hint)
                .font(.system(size: 11))
                .foregroundStyle(Palette.clayMuted.opacity(0.8))
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

private struct StageRail: View {
    let pieces: [Piece]
    @Binding var selection: Stage?
    @Binding var showArchived: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BY STAGE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.clayMuted)
                Spacer()
                Button(showArchived ? "Hide archived" : "Show archived") {
                    showArchived.toggle()
                }
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.clayMuted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    StagePill(label: "All active", count: pieces.filter { $0.stage != .archived }.count, selected: selection == nil, stage: nil) {
                        selection = nil
                    }
                    ForEach(Stage.allCases.filter { showArchived || $0 != .archived }, id: \.self) { s in
                        StagePill(
                            label: s.label,
                            count: pieces.filter { $0.stage == s }.count,
                            selected: selection == s,
                            stage: s
                        ) {
                            selection = selection == s ? nil : s
                        }
                    }
                }
            }
        }
    }
}

private struct StagePill: View {
    let label: String
    let count: Int
    let selected: Bool
    let stage: Stage?
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 6) {
                if let s = stage {
                    Image(systemName: StagePalette.of(s).icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selected ? Palette.bone.opacity(0.6) : Palette.clayMuted.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? Palette.clay : Palette.paper)
            .foregroundStyle(selected ? Palette.bone : Palette.clay)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

private struct FilterBar: View {
    @Binding var query: String
    @Binding var clayFilter: String?
    @Binding var glazeFilter: String?
    let clayOptions: [String]
    let glazeOptions: [String]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Palette.clayMuted)
                TextField("Search by name, clay, glaze…", text: $query)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(Palette.clay)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Palette.clayMuted.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Palette.paper)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))

            if !clayOptions.isEmpty || !glazeOptions.isEmpty {
                HStack(spacing: 8) {
                    if !clayOptions.isEmpty {
                        FilterMenu(title: "Clay", selection: $clayFilter, options: clayOptions)
                    }
                    if !glazeOptions.isEmpty {
                        FilterMenu(title: "Glaze", selection: $glazeFilter, options: glazeOptions)
                    }
                    Spacer()
                }
            }
        }
    }
}

private struct FilterMenu: View {
    let title: String
    @Binding var selection: String?
    let options: [String]

    var body: some View {
        Menu {
            Button {
                selection = nil
            } label: {
                Label("All", systemImage: selection == nil ? "checkmark" : "")
            }
            ForEach(options, id: \.self) { o in
                Button {
                    selection = o
                } label: {
                    Label(o, systemImage: selection == o ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.2)
                Text(selection ?? "All").font(.system(size: 13, weight: .medium))
                Image(systemName: "chevron.down").font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Palette.paper)
            .foregroundStyle(Palette.clay)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }
}

private struct EmptyStateView: View {
    let hasAny: Bool
    let onNew: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if hasAny {
                Text("Nothing matches.")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.clay)
                Button("Clear filters", action: onClear)
                    .foregroundStyle(Palette.terracotta)
                    .font(.system(size: 15, weight: .semibold))
            } else {
                ZStack {
                    Circle()
                        .stroke(Palette.clay.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [4, 6]))
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(Palette.clay.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [2, 4]))
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#D9744F"), Color(hex: "#7E2D14")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                }
                .padding(.vertical, 12)
                (Text("Add your ")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                 + Text("first masterpiece")
                    .font(.system(size: 28, weight: .semibold, design: .serif).italic())
                    .foregroundColor(Palette.terracotta)
                 + Text(".")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.clay)
                Text("Every mug, every test tile, every wonky bowl.\nTrack them from idea to glazed-and-fired so the next batch is even better.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.clayMuted)
                    .font(.system(size: 14))
                    .padding(.horizontal, 24)
                Button(action: {
                    Haptics.tap()
                    onNew()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Start a piece").font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(Palette.terracotta)
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct ContextActions: View {
    let piece: Piece
    let onDelete: () -> Void

    var body: some View {
        Group {
            if piece.stage != .archived {
                Button {
                    piece.stage = .archived
                    piece.log(.stage, "Stage → Archived")
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            } else {
                Button {
                    piece.stage = .finished
                    piece.log(.stage, "Stage → Finished (restored)")
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

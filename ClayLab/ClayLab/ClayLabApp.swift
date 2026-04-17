import SwiftUI
import SwiftData

@main
struct ClayLabApp: App {
    @State private var units = UnitsManager()
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Piece.self,
            GlazeLayer.self,
            Firing.self,
            HistoryEvent.self,
        ])
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            modelContainer = try! ModelContainer(for: schema, configurations: [fallback])
        }
        ClayLabApp.seedIfNeeded(container: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(units)
                .preferredColorScheme(.light)
                .tint(Color(hex: "#C2502A"))
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private static func seedIfNeeded(container: ModelContainer) {
        let context = container.mainContext
        let fd = FetchDescriptor<Piece>()
        let count = (try? context.fetchCount(fd)) ?? 0
        guard count == 0 else { return }

        let m1 = Piece(name: "Speckled morning mug", stage: .glazed, coverIndex: 0)
        m1.clayBody = "Speckled stoneware"
        m1.formingMethod = .wheelThrown
        m1.weightG = 480
        m1.heightCm = 10.2
        m1.widthCm = 8.5
        m1.notes = "Pulled handle at leather hard. Slight S-curve, kept it."
        context.insert(m1)

        let g1 = GlazeLayer(name: "Shino", location: .outside, application: .dipped, coats: 2, colorHex: "#B8704C")
        g1.notes = "5-second dip"
        g1.piece = m1
        context.insert(g1)

        let g2 = GlazeLayer(name: "Tenmoku", location: .inside, application: .poured, coats: 1, colorHex: "#2A1A0F")
        g2.notes = "Just enough to coat"
        g2.piece = m1
        context.insert(g2)

        let f1 = Firing(type: .bisque, cone: "04", date: Date().addingTimeInterval(-86400 * 2), kiln: "Studio L&L", notes: "Slow ramp overnight")
        f1.piece = m1
        context.insert(f1)

        m1.log(.created, "Piece created")
        m1.log(.stage, "Stage → Formed")
        m1.log(.stage, "Stage → Greenware")
        m1.log(.stage, "Stage → Bisque")
        m1.log(.glaze, "Added glaze: Shino (Outside, Dipped × 2)")
        m1.log(.glaze, "Added glaze: Tenmoku (Inside, Poured × 1)")
        m1.log(.stage, "Stage → Glazed")

        let m2 = Piece(name: "Wide salad bowl", stage: .greenware, coverIndex: 2)
        m2.clayBody = "B-Mix"
        m2.formingMethod = .wheelThrown
        m2.weightG = 1240
        m2.heightCm = 8.0
        m2.widthCm = 28.0
        m2.notes = "Trimmed foot ring deeper than usual — wanted lift."
        context.insert(m2)
        m2.log(.created, "Piece created")
        m2.log(.stage, "Stage → Formed")
        m2.log(.stage, "Stage → Greenware")

        let m3 = Piece(name: "Test tile — celadon", stage: .idea, coverIndex: 3)
        m3.clayBody = "Porcelain"
        m3.formingMethod = .handbuiltSlab
        m3.notes = "Want to compare 1 / 2 / 3 coat thickness on porcelain vs stoneware."
        context.insert(m3)
        m3.log(.created, "Piece created")

        try? context.save()
    }
}

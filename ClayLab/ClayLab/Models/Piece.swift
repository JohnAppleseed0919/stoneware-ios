import Foundation
import SwiftData

enum Stage: String, Codable, CaseIterable, Identifiable {
    case idea, formed, greenware, bisque, glazed, finished, archived
    var id: String { rawValue }

    var label: String {
        switch self {
        case .idea: "Idea"
        case .formed: "Formed"
        case .greenware: "Greenware"
        case .bisque: "Bisque"
        case .glazed: "Glazed"
        case .finished: "Finished"
        case .archived: "Archived"
        }
    }

    var next: Stage {
        switch self {
        case .idea: .formed
        case .formed: .greenware
        case .greenware: .bisque
        case .bisque: .glazed
        case .glazed: .finished
        case .finished: .archived
        case .archived: .archived
        }
    }

    static var progressOrder: [Stage] {
        [.idea, .formed, .greenware, .bisque, .glazed, .finished]
    }
}

enum FormingMethod: String, Codable, CaseIterable, Identifiable {
    case wheelThrown = "Wheel-thrown"
    case handbuiltSlab = "Handbuilt — Slab"
    case handbuiltCoil = "Handbuilt — Coil"
    case handbuiltPinch = "Handbuilt — Pinch"
    case slipCast = "Slip-cast"
    case mixed = "Mixed / Other"
    var id: String { rawValue }
}

enum GlazeLocation: String, Codable, CaseIterable, Identifiable {
    case inside = "Inside"
    case outside = "Outside"
    case both = "Inside + Outside"
    case rim = "Rim"
    case foot = "Foot / base"
    var id: String { rawValue }
}

enum GlazeApplication: String, Codable, CaseIterable, Identifiable {
    case dipped = "Dipped"
    case brushed = "Brushed"
    case poured = "Poured"
    case sprayed = "Sprayed"
    case sponged = "Sponged"
    case waxResist = "Wax-resist"
    var id: String { rawValue }
}

enum FiringType: String, Codable, CaseIterable, Identifiable {
    case bisque = "Bisque"
    case oxidation = "Glaze — oxidation"
    case reduction = "Glaze — reduction"
    case raku = "Raku"
    case pit = "Pit"
    case saltSoda = "Salt / Soda"
    var id: String { rawValue }
}

enum HistoryKind: String, Codable {
    case created, stage, glaze, firing, note, photo
}

@Model
final class Piece {
    var id: UUID = UUID()
    var name: String = "Untitled piece"
    var stageRaw: String = Stage.idea.rawValue
    var clayBody: String = ""
    var formingMethodRaw: String = ""
    var weightG: Double? = nil       // stored in grams
    var heightCm: Double? = nil      // stored in centimeters
    var widthCm: Double? = nil       // stored in centimeters
    var wetSizeCm: Double? = nil     // for shrinkage calc: wet dimension reference
    var notes: String = ""
    var coverIndex: Int = 0
    var photoData: Data? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \GlazeLayer.piece)
    var glazeLayers: [GlazeLayer]? = []

    @Relationship(deleteRule: .cascade, inverse: \Firing.piece)
    var firings: [Firing]? = []

    @Relationship(deleteRule: .cascade, inverse: \HistoryEvent.piece)
    var history: [HistoryEvent]? = []

    init(name: String = "Untitled piece", stage: Stage = .idea, coverIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.stageRaw = stage.rawValue
        self.coverIndex = coverIndex
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var stage: Stage {
        get { Stage(rawValue: stageRaw) ?? .idea }
        set {
            stageRaw = newValue.rawValue
            touch()
        }
    }

    var formingMethod: FormingMethod? {
        get { FormingMethod(rawValue: formingMethodRaw) }
        set {
            formingMethodRaw = newValue?.rawValue ?? ""
            touch()
        }
    }

    var sortedHistory: [HistoryEvent] {
        (history ?? []).sorted { $0.timestamp > $1.timestamp }
    }

    var sortedGlazes: [GlazeLayer] {
        (glazeLayers ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    var sortedFirings: [Firing] {
        (firings ?? []).sorted { $0.date > $1.date }
    }

    func touch() {
        updatedAt = Date()
    }

    func log(_ kind: HistoryKind, _ text: String) {
        let event = HistoryEvent(kind: kind, text: text)
        event.piece = self
        if history == nil { history = [] }
        history?.append(event)
        touch()
    }
}

@Model
final class GlazeLayer {
    var id: UUID = UUID()
    var name: String = ""
    var locationRaw: String = GlazeLocation.outside.rawValue
    var applicationRaw: String = GlazeApplication.dipped.rawValue
    var coats: Int = 1
    var colorHex: String = "#C2502A"
    var notes: String = ""
    var createdAt: Date = Date()
    var piece: Piece?

    init(name: String = "", location: GlazeLocation = .outside, application: GlazeApplication = .dipped, coats: Int = 1, colorHex: String = "#C2502A") {
        self.id = UUID()
        self.name = name
        self.locationRaw = location.rawValue
        self.applicationRaw = application.rawValue
        self.coats = coats
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    var location: GlazeLocation {
        get { GlazeLocation(rawValue: locationRaw) ?? .outside }
        set { locationRaw = newValue.rawValue }
    }

    var application: GlazeApplication {
        get { GlazeApplication(rawValue: applicationRaw) ?? .dipped }
        set { applicationRaw = newValue.rawValue }
    }
}

@Model
final class Firing {
    var id: UUID = UUID()
    var typeRaw: String = FiringType.bisque.rawValue
    var cone: String = "04"
    var date: Date = Date()
    var kiln: String = ""
    var notes: String = ""
    var piece: Piece?

    init(type: FiringType = .bisque, cone: String = "04", date: Date = Date(), kiln: String = "", notes: String = "") {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.cone = cone
        self.date = date
        self.kiln = kiln
        self.notes = notes
    }

    var type: FiringType {
        get { FiringType(rawValue: typeRaw) ?? .bisque }
        set { typeRaw = newValue.rawValue }
    }
}

@Model
final class HistoryEvent {
    var id: UUID = UUID()
    var kindRaw: String = HistoryKind.note.rawValue
    var text: String = ""
    var timestamp: Date = Date()
    var piece: Piece?

    init(kind: HistoryKind, text: String) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.text = text
        self.timestamp = Date()
    }

    var kind: HistoryKind {
        get { HistoryKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }
}

enum CommonClayBodies {
    static let all = ["Stoneware", "Porcelain", "Earthenware", "Raku body", "Terracotta", "B-Mix", "Speckled stoneware"]
}

enum Cones {
    static let all = ["010", "08", "06", "04", "02", "01", "1", "4", "6", "8", "10"]
}

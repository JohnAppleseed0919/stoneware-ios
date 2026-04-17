import Foundation
import SwiftUI

enum UnitSystem: String {
    case metric, imperial

    var weightLabel: String { self == .metric ? "g" : "oz" }
    var lengthLabel: String { self == .metric ? "cm" : "in" }
}

@Observable
final class UnitsManager {
    var system: UnitSystem {
        didSet { UserDefaults.standard.set(system.rawValue, forKey: "claylab.units") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "claylab.units") ?? UnitSystem.metric.rawValue
        self.system = UnitSystem(rawValue: raw) ?? .metric
    }

    // Display helpers — data is stored in metric.
    func displayWeight(_ grams: Double?) -> String {
        guard let g = grams else { return "—" }
        if system == .imperial {
            let oz = g * 0.035274
            return String(format: "%.2f oz", oz)
        } else {
            return String(format: "%.0f g", g)
        }
    }

    func displayLength(_ cm: Double?) -> String {
        guard let c = cm else { return "—" }
        if system == .imperial {
            return String(format: "%.1f in", c * 0.393701)
        } else {
            return String(format: "%.1f cm", c)
        }
    }

    func weightForInput(_ grams: Double?) -> Double? {
        guard let g = grams else { return nil }
        return system == .imperial ? g * 0.035274 : g
    }

    func lengthForInput(_ cm: Double?) -> Double? {
        guard let c = cm else { return nil }
        return system == .imperial ? c * 0.393701 : c
    }

    func gramsFromInput(_ value: Double) -> Double {
        system == .imperial ? value / 0.035274 : value
    }

    func cmFromInput(_ value: Double) -> Double {
        system == .imperial ? value / 0.393701 : value
    }
}

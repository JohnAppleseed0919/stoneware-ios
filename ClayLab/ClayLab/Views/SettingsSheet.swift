import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UnitsManager.self) private var units

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SettingsGroup(title: "Units") {
                        HStack(spacing: 10) {
                            ForEach([UnitSystem.metric, .imperial], id: \.rawValue) { u in
                                Button {
                                    Haptics.tap()
                                    units.system = u
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(u == .metric ? "Metric" : "Imperial")
                                            .font(.system(size: 18, weight: .semibold, design: .serif))
                                            .foregroundStyle(units.system == u ? Palette.bone : Palette.clay)
                                        Text(u == .metric ? "g · cm" : "oz · in")
                                            .font(.system(size: 12))
                                            .foregroundStyle(units.system == u ? Palette.bone.opacity(0.8) : Palette.clayMuted)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(units.system == u ? Palette.clay : Palette.paper)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: units.system == u ? 0 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    SettingsGroup(title: "About") {
                        InfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        InfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        InfoRow(label: "Storage", value: "On-device, SwiftData")
                    }

                    Text("ClayLab · Local-first · Your data lives on this device.")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Palette.clayMuted.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding(18)
            }
            .background(Palette.bone.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Palette.terracotta)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Palette.clayMuted)
            content()
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Palette.clayMuted)
            Spacer()
            Text(value).foregroundStyle(Palette.clay).fontWeight(.medium)
        }
        .font(.system(size: 14))
        .padding(14)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

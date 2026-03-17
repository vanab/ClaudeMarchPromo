//
//  SettingsView.swift
//  ClaudePromo
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("notifyStart30") var notifyStart30: Bool = true
    @AppStorage("notifyStart10") var notifyStart10: Bool = true
    @AppStorage("notifyEnd30") var notifyEnd30: Bool = true
    @AppStorage("notifyEnd10") var notifyEnd10: Bool = true

    var onBack: (() -> Void)?
    var onSettingsChanged: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    onBack?()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Text("Notifications")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("x2 Boost Start")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Toggle("30 minutes before", isOn: $notifyStart30)
                    .onChange(of: notifyStart30) { onSettingsChanged?() }
                Toggle("10 minutes before", isOn: $notifyStart10)
                    .onChange(of: notifyStart10) { onSettingsChanged?() }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("x2 Boost End")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Toggle("30 minutes before", isOn: $notifyEnd30)
                    .onChange(of: notifyEnd30) { onSettingsChanged?() }
                Toggle("10 minutes before", isOn: $notifyEnd10)
                    .onChange(of: notifyEnd10) { onSettingsChanged?() }
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .frame(width: 340)
}

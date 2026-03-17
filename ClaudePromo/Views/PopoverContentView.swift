//
//  PopoverContentView.swift
//  ClaudePromo
//

import SwiftUI

struct PopoverContentView: View {
    @Bindable var schedule: PromoSchedule

    @AppStorage("notifyStart30") private var notifyStart30: Bool = true
    @AppStorage("notifyStart10") private var notifyStart10: Bool = true
    @AppStorage("notifyEnd30") private var notifyEnd30: Bool = true
    @AppStorage("notifyEnd10") private var notifyEnd10: Bool = true

    @State private var showSettings = false
    @State private var windowAppeared = false
    @State private var blocksAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            if schedule.currentStatus == .promoEnded {
                PromoEndedView()
            } else {
                mainContent
            }

            Divider()

            footerBar
        }
        .frame(width: 340)
        .opacity(windowAppeared ? 1 : 0)
        .offset(y: windowAppeared ? 0 : -8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                windowAppeared = true
            }
        }
        .onDisappear {
            windowAppeared = false
            blocksAppeared = false
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 16) {
            if showSettings {
                SettingsView(
                    onBack: { showSettings = false },
                    onSettingsChanged: rescheduleNotifications
                )
                .transition(.move(edge: .trailing))
            } else {
                StatusSectionView(
                    schedule: schedule,
                    blocksAppeared: $blocksAppeared,
                    onSettingsTap: { showSettings = true }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .padding()
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Text("Claude x2 Limits Promo — March 2026")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func rescheduleNotifications() {
        NotificationManager.shared.scheduleNotifications(
            schedule: schedule,
            notifyStart30: notifyStart30,
            notifyStart10: notifyStart10,
            notifyEnd30: notifyEnd30,
            notifyEnd10: notifyEnd10
        )
    }
}

#Preview {
    PopoverContentView(schedule: PromoSchedule())
}

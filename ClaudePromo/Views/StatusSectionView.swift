//
//  StatusSectionView.swift
//  ClaudePromo
//

import SwiftUI

struct StatusSectionView: View {
    let schedule: PromoSchedule
    @Binding var blocksAppeared: Bool
    var onSettingsTap: () -> Void

    @State private var statusPulse = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(schedule.currentStatus == .doubled ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .shadow(
                                color: (schedule.currentStatus == .doubled ? Color.green : Color.orange)
                                    .opacity(statusPulse ? 0.8 : 0),
                                radius: statusPulse ? 6 : 0
                            )
                            .scaleEffect(statusPulse ? 1.2 : 1.0)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    statusPulse = true
                                }
                            }
                        Text(schedule.currentStatus == .doubled ? "x2 Active" : "Peak Hours (x1)")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    if let countdown = schedule.countdownString(from: schedule.currentDate) {
                        Text(countdown)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .animation(.default, value: countdown)
                    }
                }
                Spacer()
                Button {
                    onSettingsTap()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            PromoTimelineView(
                schedule: schedule,
                currentDate: schedule.currentDate,
                timelineStart: schedule.timelineStart(from: schedule.currentDate),
                blocksAppeared: $blocksAppeared
            )

            Text("Promo ends March 27, 2026")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    let schedule = PromoSchedule()
    StatusSectionView(
        schedule: schedule,
        blocksAppeared: .constant(true),
        onSettingsTap: {}
    )
    .padding()
    .frame(width: 340)
}

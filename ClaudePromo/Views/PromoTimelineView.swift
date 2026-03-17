//
//  PromoTimelineView.swift
//  ClaudePromo
//

import SwiftUI

struct PromoTimelineView: View {
    let schedule: PromoSchedule
    let currentDate: Date
    let timelineStart: Date
    @Binding var blocksAppeared: Bool

    @State private var glowPulse = false

    private let totalHours = 26
    private let blockHeight: CGFloat = 44
    private let blockSpacing: CGFloat = 2

    private var hourEntries: [HourEntry] {
        let cal = Calendar.current
        return (0..<totalHours).map { i in
            let date = cal.date(byAdding: .hour, value: i, to: timelineStart)!
            let promoActive = schedule.isPromoActive(at: date)
            let doubled = schedule.isDoubled(at: date)
            let nextHour = cal.date(byAdding: .hour, value: 1, to: date)!
            let isPast = nextHour <= currentDate
            let isCurrent = date <= currentDate && currentDate < nextHour
            return HourEntry(
                index: i,
                date: date,
                isPromoActive: promoActive,
                isDoubled: doubled,
                isPast: isPast,
                isCurrent: isCurrent
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            blocksRow
            labelsRow
            legend
        }
    }

    // MARK: - Blocks

    private var blocksRow: some View {
        HStack(spacing: blockSpacing) {
            ForEach(hourEntries, id: \.index) { entry in
                RoundedRectangle(cornerRadius: 3)
                    .fill(blockColor(for: entry))
                    .frame(height: blockHeight * (entry.isDoubled ? 1.0 : 0.4))
                    .opacity(entry.isPast && !entry.isCurrent ? 0.35 : 1.0)
                    .brightness(entry.isCurrent ? 0.15 : 0)
                    .overlay(
                        entry.isCurrent
                            ? RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                            : nil
                    )
                    .shadow(
                        color: entry.isCurrent
                            ? blockColor(for: entry).opacity(glowPulse ? 0.8 : 0.3)
                            : .clear,
                        radius: glowPulse ? 6 : 2
                    )
                    .frame(maxHeight: blockHeight, alignment: .bottom)
                    .scaleEffect(
                        x: 1,
                        y: blocksAppeared ? 1.0 : 0.0,
                        anchor: .bottom
                    )
                    .animation(
                        .spring(duration: 0.5, bounce: 0.3)
                            .delay(Double(entry.index) * 0.02),
                        value: blocksAppeared
                    )
            }
        }
        .frame(height: blockHeight)
        .onAppear {
            blocksAppeared = true
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = true
            }
        }
    }

    private func blockColor(for entry: HourEntry) -> Color {
        if !entry.isPromoActive {
            return Color.gray.opacity(0.3)
        }
        return entry.isDoubled ? .green : .red
    }

    // MARK: - Labels (transitions + now)

    private var labelsRow: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let entries = hourEntries
            let blockWidth = (width - CGFloat(totalHours - 1) * blockSpacing) / CGFloat(totalHours)

            ZStack(alignment: .topLeading) {
                // Now indicator
                if let currentIndex = entries.firstIndex(where: { $0.isCurrent }) {
                    let x = blockCenterX(index: currentIndex, blockWidth: blockWidth)
                    VStack(spacing: 0) {
                        Text("▲")
                            .font(.system(size: 7))
                            .foregroundStyle(.white)
                        Text("now")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .position(x: x, y: 12)
                }

                // Transition labels
                ForEach(transitionIndices(entries: entries), id: \.self) { i in
                    let x = blockCenterX(index: i, blockWidth: blockWidth)
                    Text(transitionLabel(for: entries[i], previous: entries[i - 1]))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .position(x: x, y: 12)
                }
            }
        }
        .frame(height: 26)
    }

    private func blockCenterX(index: Int, blockWidth: CGFloat) -> CGFloat {
        let x = CGFloat(index) * (blockWidth + blockSpacing) + blockWidth / 2
        return x
    }

    private func transitionIndices(entries: [HourEntry]) -> [Int] {
        let currentIndex = entries.firstIndex(where: { $0.isCurrent })
        var indices: [Int] = []

        for i in 1..<entries.count {
            let prev = entries[i - 1]
            let curr = entries[i]
            if visualCategory(for: curr) != visualCategory(for: prev) {
                // Skip if this is the current hour (now indicator takes priority)
                if i == currentIndex { continue }
                // Skip if too close to previous label (< 4 blocks)
                if let last = indices.last, i - last < 4 { continue }
                // Skip if too close to now indicator
                if let ci = currentIndex, abs(i - ci) < 3 { continue }
                indices.append(i)
            }
        }
        return indices
    }

    private enum VisualCategory {
        case green, red, gray
    }

    private func visualCategory(for entry: HourEntry) -> VisualCategory {
        if !entry.isPromoActive { return .gray }
        return entry.isDoubled ? .green : .red
    }

    private func transitionLabel(for entry: HourEntry, previous: HourEntry) -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: entry.date)
        let hourStr = hourString(hour)

        let prevDay = cal.startOfDay(for: previous.date)
        let currDay = cal.startOfDay(for: entry.date)

        if prevDay != currDay {
            return "\(dayPrefix(for: entry.date)) \(hourStr)"
        }
        return hourStr
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 10, height: 14)
                Text("x2 Off-peak")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 10, height: 8)
                Text("x1 Peak")
            }
            Spacer()
        }
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
    }

    // MARK: - Helpers

    private func hourString(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour < 12 { return "\(hour)am" }
        if hour == 12 { return "12pm" }
        return "\(hour - 12)pm"
    }

    private func dayPrefix(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tmrw" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - HourEntry

private struct HourEntry {
    let index: Int
    let date: Date
    let isPromoActive: Bool
    let isDoubled: Bool
    let isPast: Bool
    let isCurrent: Bool
}

#Preview {
    let schedule = PromoSchedule()
    PromoTimelineView(
        schedule: schedule,
        currentDate: schedule.currentDate,
        timelineStart: schedule.timelineStart(from: schedule.currentDate),
        blocksAppeared: .constant(true)
    )
    .padding()
    .frame(width: 340)
}

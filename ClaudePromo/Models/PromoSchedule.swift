//
//  PromoSchedule.swift
//  ClaudePromo
//

import Foundation
import Observation

enum PromoStatus: Equatable {
    case doubled
    case normal
    case promoEnded
}

struct TimelineSegment: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let isDoubled: Bool
}

@Observable
final class PromoSchedule {
    private static let etTimeZone = TimeZone(identifier: "America/New_York")!
    private static let promoStartDay = DateComponents(year: 2026, month: 3, day: 13)
    private static let promoEndDay = DateComponents(year: 2026, month: 3, day: 27)
    private static let peakStartHour = 8  // 8 AM ET
    private static let peakEndHour = 14   // 2 PM ET

    private(set) var currentStatus: PromoStatus = .normal
    private(set) var currentDate: Date = .now

    private var timer: Timer?

    init() {
        updateStatus()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    func updateStatus() {
        currentDate = .now
        currentStatus = status(at: currentDate)
    }

    // MARK: - Public API

    func status(at date: Date) -> PromoStatus {
        guard isPromoActive(at: date) else { return .promoEnded }
        return isDoubled(at: date) ? .doubled : .normal
    }

    func isPromoActive(at date: Date) -> Bool {
        let cal = Self.calendar()
        guard let start = cal.date(from: Self.promoStartDay),
              let endDay = cal.date(from: Self.promoEndDay),
              let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endDay)
        else { return false }
        return date >= start && date <= end
    }

    func isDoubled(at date: Date) -> Bool {
        guard isPromoActive(at: date) else { return false }
        let cal = Self.calendar()
        let weekday = cal.component(.weekday, from: date) // 1=Sun, 7=Sat
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend { return true }

        let hour = cal.component(.hour, from: date)
        return hour < Self.peakStartHour || hour >= Self.peakEndHour
    }

    func nextTransition(from date: Date) -> (date: Date, toDoubled: Bool)? {
        guard isPromoActive(at: date) else { return nil }

        let cal = Self.calendar()
        var searchDate = date

        // Search up to 8 days ahead
        for _ in 0..<(8 * 24) {
            let currentlyDoubled = isDoubled(at: searchDate)

            // Move forward 1 hour
            guard let next = cal.date(byAdding: .hour, value: 1, to: searchDate) else { break }
            let nextHour = cal.dateInterval(of: .hour, for: next)?.start ?? next

            if !isPromoActive(at: nextHour) { return nil }

            let nextDoubled = isDoubled(at: nextHour)
            if currentlyDoubled != nextDoubled {
                // Find the exact transition point
                let weekday = cal.component(.weekday, from: nextHour)
                let isWeekend = weekday == 1 || weekday == 7

                if !isWeekend {
                    let hour = cal.component(.hour, from: nextHour)
                    if hour == Self.peakStartHour {
                        // Transition to peak (x1) at 8 AM ET
                        let transition = cal.date(bySettingHour: Self.peakStartHour, minute: 0, second: 0, of: nextHour)!
                        return (transition, false)
                    } else if hour == Self.peakEndHour {
                        // Transition to off-peak (x2) at 2 PM ET
                        let transition = cal.date(bySettingHour: Self.peakEndHour, minute: 0, second: 0, of: nextHour)!
                        return (transition, true)
                    }
                }
            }
            searchDate = nextHour
        }
        return nil
    }

    func timelineStart(from now: Date) -> Date {
        let cal = Calendar.current
        let twoHoursAgo = cal.date(byAdding: .hour, value: -2, to: now)!
        return cal.dateInterval(of: .hour, for: twoHoursAgo)?.start ?? twoHoursAgo
    }

    func timelineSegments(from now: Date) -> [TimelineSegment] {
        let cal = Self.calendar()
        let start = timelineStart(from: now)
        guard let end = cal.date(byAdding: .hour, value: 24, to: start) else { return [] }

        var segments: [TimelineSegment] = []
        var cursor = start

        while cursor < end {
            let currentlyDoubled = isDoubled(at: cursor)
            var segmentEnd = cursor

            // Extend segment while status remains the same
            while segmentEnd < end {
                guard let nextHour = cal.date(byAdding: .hour, value: 1, to: segmentEnd) else { break }
                if nextHour > end { break }
                if isDoubled(at: nextHour) != currentlyDoubled && isPromoActive(at: nextHour) { break }
                if !isPromoActive(at: nextHour) { break }
                segmentEnd = nextHour
            }

            if segmentEnd == cursor {
                guard let nextHour = cal.date(byAdding: .hour, value: 1, to: cursor) else { break }
                segmentEnd = min(nextHour, end)
            }

            segments.append(TimelineSegment(
                startDate: cursor,
                endDate: segmentEnd,
                isDoubled: isPromoActive(at: cursor) ? currentlyDoubled : false
            ))
            cursor = segmentEnd
        }

        return segments
    }

    func upcomingTransitions(days: Int = 7) -> [(date: Date, toDoubled: Bool)] {
        var transitions: [(date: Date, toDoubled: Bool)] = []
        var searchDate = Date.now

        for _ in 0..<(days * 4) { // max ~4 transitions per day
            guard let transition = nextTransition(from: searchDate) else { break }
            transitions.append(transition)
            searchDate = transition.date.addingTimeInterval(60) // move past this transition
        }
        return transitions
    }

    // MARK: - Formatting

    func countdownString(from now: Date) -> String? {
        guard let transition = nextTransition(from: now) else { return nil }
        let diff = transition.date.timeIntervalSince(now)
        guard diff > 0 else { return nil }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        let action = transition.toDoubled ? "x2 starts" : "x2 ends"
        if hours > 0 {
            return "\(action) in \(hours)h \(minutes)m"
        } else {
            return "\(action) in \(minutes)m"
        }
    }

    var statusBarText: String {
        switch currentStatus {
        case .doubled:
            if let cd = shortCountdown(from: currentDate) { return "x2 \(cd)" }
            return "x2"
        case .normal:
            if let cd = shortCountdown(from: currentDate) { return "x1 \(cd)" }
            return "x1"
        case .promoEnded:
            return "—"
        }
    }

    private func shortCountdown(from now: Date) -> String? {
        guard let transition = nextTransition(from: now) else { return nil }
        let diff = transition.date.timeIntervalSince(now)
        guard diff > 0 else { return nil }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        return String(format: "%02d:%02d", hours, minutes)
    }

    // MARK: - Private

    private static func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etTimeZone
        return cal
    }
}

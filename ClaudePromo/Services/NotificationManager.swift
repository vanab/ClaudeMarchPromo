//
//  NotificationManager.swift
//  ClaudePromo
//

import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleNotifications(
        schedule: PromoSchedule,
        notifyStart30: Bool,
        notifyStart10: Bool,
        notifyEnd30: Bool,
        notifyEnd10: Bool
    ) {
        center.removeAllPendingNotificationRequests()

        guard notifyStart30 || notifyStart10 || notifyEnd30 || notifyEnd10 else { return }

        let transitions = schedule.upcomingTransitions(days: 7)

        for transition in transitions {
            if transition.toDoubled {
                if notifyStart30 { scheduleOne(before: transition.date, minutes: 30, toDoubled: true) }
                if notifyStart10 { scheduleOne(before: transition.date, minutes: 10, toDoubled: true) }
            } else {
                if notifyEnd30 { scheduleOne(before: transition.date, minutes: 30, toDoubled: false) }
                if notifyEnd10 { scheduleOne(before: transition.date, minutes: 10, toDoubled: false) }
            }
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Private

    private func scheduleOne(before transitionDate: Date, minutes: Int, toDoubled: Bool) {
        let fireDate = transitionDate.addingTimeInterval(-Double(minutes) * 60)
        guard fireDate > Date.now else { return }

        let content = UNMutableNotificationContent()
        if toDoubled {
            content.title = "x2 Boost Starting Soon"
            content.body = "Double usage limits begin in \(minutes) minutes"
        } else {
            content.title = "x2 Boost Ending Soon"
            content.body = "Double usage limits end in \(minutes) minutes"
        }
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let id = "promo-\(toDoubled ? "start" : "end")-\(minutes)m-\(Int(transitionDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

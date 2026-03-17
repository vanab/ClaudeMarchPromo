//
//  ClaudePromoApp.swift
//  ClaudePromo
//
//  Created by Dmitriy Kudrin on 16.03.2026.
//

import SwiftUI
import AppKit
import Combine

@main
struct ClaudePromoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var schedule = PromoSchedule()
    @State private var menuBarImage = NSImage()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(schedule: schedule)
                .task {
                    menuBarImage = generateMenuBarImage()
                    NotificationManager.shared.requestPermission()
                    let s30 = UserDefaults.standard.object(forKey: "notifyStart30") as? Bool ?? true
                    let s10 = UserDefaults.standard.object(forKey: "notifyStart10") as? Bool ?? true
                    let e30 = UserDefaults.standard.object(forKey: "notifyEnd30") as? Bool ?? true
                    let e10 = UserDefaults.standard.object(forKey: "notifyEnd10") as? Bool ?? true
                    NotificationManager.shared.scheduleNotifications(
                        schedule: schedule,
                        notifyStart30: s30,
                        notifyStart10: s10,
                        notifyEnd30: e30,
                        notifyEnd10: e10
                    )
                }
        } label: {
            Image(nsImage: menuBarImage)
                .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                    schedule.updateStatus()
                    menuBarImage = generateMenuBarImage()
                }
                .onAppear {
                    schedule.updateStatus()
                    menuBarImage = generateMenuBarImage()
                }
        }
        .menuBarExtraStyle(.window)
    }

    private func generateMenuBarImage() -> NSImage {
        let limitText: String
        let limitColor: NSColor
        switch schedule.currentStatus {
        case .doubled:
            limitText = "x2"
            limitColor = .systemGreen
        case .normal:
            limitText = "x1"
            limitColor = .systemRed
        case .promoEnded:
            limitText = "—"
            limitColor = .systemGray
        }

        var countdownText: String?
        if let transition = schedule.nextTransition(from: schedule.currentDate) {
            let diff = transition.date.timeIntervalSince(schedule.currentDate)
            if diff > 0 {
                let hours = Int(diff) / 3600
                let minutes = (Int(diff) % 3600) / 60
                if hours > 0 {
                    countdownText = "\(hours)h \(minutes)m"
                } else {
                    countdownText = "\(minutes)m"
                }
            }
        }

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let countdownColor: NSColor = isDark ? .white.withAlphaComponent(0.85) : .black.withAlphaComponent(0.75)

        let limitFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .heavy)
        let countdownFont = NSFont.monospacedDigitSystemFont(ofSize: 8, weight: .medium)

        let limitAttr = NSAttributedString(string: limitText, attributes: [
            .font: limitFont,
            .foregroundColor: limitColor
        ])
        let limitSize = limitAttr.size()

        var countdownAttr: NSAttributedString?
        var countdownSize = NSSize.zero
        if let countdown = countdownText {
            let attr = NSAttributedString(string: countdown, attributes: [
                .font: countdownFont,
                .foregroundColor: countdownColor
            ])
            countdownAttr = attr
            countdownSize = attr.size()
        }

        let imageWidth = ceil(max(limitSize.width, countdownSize.width)) + 2
        let imageHeight: CGFloat = 22

        let image = NSImage(size: NSSize(width: imageWidth, height: imageHeight), flipped: false) { rect in
            if let countdownAttr {
                let spacing: CGFloat = 0
                let totalHeight = limitSize.height + countdownSize.height + spacing
                let baseY = (rect.height - totalHeight) / 2
                let limitX = (rect.width - limitSize.width) / 2
                let countdownX = (rect.width - countdownSize.width) / 2

                limitAttr.draw(at: NSPoint(x: limitX, y: baseY + countdownSize.height + spacing))
                countdownAttr.draw(at: NSPoint(x: countdownX, y: baseY))
            } else {
                let x = (rect.width - limitSize.width) / 2
                let y = (rect.height - limitSize.height) / 2
                limitAttr.draw(at: NSPoint(x: x, y: y))
            }
            return true
        }

        image.isTemplate = false
        return image
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var retryCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        openMenuBarExtra()
    }

    private func openMenuBarExtra() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            for window in NSApp.windows {
                if let button = self.findStatusBarButton(in: window.contentView) {
                    button.performClick(nil)
                    return
                }
            }
            if retryCount < 10 {
                retryCount += 1
                openMenuBarExtra()
            }
        }
    }

    private func findStatusBarButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view else { return nil }
        if let button = view as? NSStatusBarButton { return button }
        for subview in view.subviews {
            if let found = findStatusBarButton(in: subview) { return found }
        }
        return nil
    }
}

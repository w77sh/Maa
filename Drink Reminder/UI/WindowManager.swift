//
//  WindowManager.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import AppKit
import SwiftUI

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var popupWindow: NSWindow?
    private var statisticsWindow: NSWindow?

    private init() {}

    func showPopup(reminderManager: ReminderManager) {
        if popupWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 250),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .popUpMenu
            panel.isFloatingPanel = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.isReleasedWhenClosed = false

            let rootView = ReminderPopupView(reminderManager: reminderManager)
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)

            let hostingView = NSHostingView(rootView: rootView)
            panel.contentView = hostingView
            panel.center()
            self.popupWindow = panel
        }
        
        popupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePopup() {
        popupWindow?.close()
        popupWindow = nil
    }

    func showStatistics(reminderManager: ReminderManager) {
        if statisticsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Statistics".localized(reminderManager.settings.language)
            window.center()
            window.isReleasedWhenClosed = false

            let rootView = StatisticsView(historyStore: DailyHistoryStore(), dailyGoalMilliliters: Int(reminderManager.settings.dailyGoalLiters * 1000))
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)

            window.contentView = NSHostingView(rootView: rootView)
            self.statisticsWindow = window
            
            // To be able to observe when it closes
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
                self?.statisticsWindow = nil
            }
        }

        statisticsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

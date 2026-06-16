//
//  MenuBarView.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import AppKit
import SwiftUI
import UserNotifications

struct MenuBarView: View {
    @Environment(ReminderManager.self) private var reminderManager
    @Environment(\.openSettings) private var openSettings
    @Environment(MaaUpdaterController.self) private var updaterController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status Section
            VStack(alignment: .leading) {
                Label(primaryStatusLine, systemImage: "cup.and.saucer.fill")
                    .font(.headline)
                
                if let secondaryStatusLine {
                    Text(secondaryStatusLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let notificationStatusLine {
                    Button(action: {
                        reminderManager.openSystemNotificationSettings()
                    }) {
                        Label(notificationStatusLine, systemImage: "bell.badge.fill")
                            .foregroundStyle(.yellow)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Actions Section
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    reminderManager.drinkNow()
                }) {
                    Label("Drink now".localized(reminderManager.settings.language), systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(reminderManager.state.isPausedToday)

                Button(action: {
                    reminderManager.snooze30Minutes()
                }) {
                    Label("Snooze 30 minutes".localized(reminderManager.settings.language), systemImage: "powersleep")
                }
                .buttonStyle(.plain)
                .disabled(reminderManager.state.isPausedToday)

                Button(action: reminderAction) {
                    Label(reminderActionTitle.localized(reminderManager.settings.language), systemImage: reminderManager.state.isPausedToday ? "play.circle.fill" : "pause.circle.fill")
                }
                .buttonStyle(.plain)
            }

            Divider()

            Button(action: {
                WindowManager.shared.showStatistics(reminderManager: reminderManager)
            }) {
                Label("Statistics".localized(reminderManager.settings.language), systemImage: "chart.bar.fill")
            }
            .buttonStyle(.plain)

            Button(action: {
                updaterController.checkForUpdates()
            }) {
                Label("Check for updates".localized(reminderManager.settings.language), systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)

            Divider()

            // App Management Section
            Button(action: {
                openSettings()
                NSApplication.shared.activate(ignoringOtherApps: true)
            }) {
                Label("Settings".localized(reminderManager.settings.language), systemImage: "gearshape.fill")
            }
            .buttonStyle(.plain)

            Divider()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit".localized(reminderManager.settings.language), systemImage: "power.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private var primaryStatusLine: String {
        let lang = reminderManager.settings.language
        return String(format: "Consumed: %d ml / %d ml".localized(lang), reminderManager.state.consumedMilliliters, Int(reminderManager.settings.dailyGoalLiters * 1000))
    }

    private var secondaryStatusLine: String? {
        let lang = reminderManager.settings.language
        if reminderManager.state.isPausedToday {
            return "Paused today".localized(lang)
        }

        if reminderManager.isOutsideReminderWindow {
            return "Outside reminder window".localized(lang)
        }

        if let nextReminderTime = reminderManager.state.nextReminderTime {
            return String(format: "Next reminder: %@".localized(lang), TimeUtils.menuDateTimeString(nextReminderTime, language: lang))
        }

        return "Next reminder unavailable".localized(lang)
    }

    private var notificationStatusLine: String? {
        let lang = reminderManager.settings.language
        if !reminderManager.settings.enableNotification {
            return "Notifications disabled".localized(lang)
        }

        if reminderManager.notificationAuthorizationStatus == .denied {
            return "Enable notifications in System Settings".localized(lang)
        }

        return nil
    }

    private var reminderActionTitle: String {
        reminderManager.state.isPausedToday ? "Resume reminders" : "Pause today"
    }

    private func reminderAction() {
        if reminderManager.state.isPausedToday {
            reminderManager.resumeReminders()
        } else {
            reminderManager.pauseToday()
        }
    }
}

#Preview {
    MenuBarView()
        .environment(ReminderManager())
}

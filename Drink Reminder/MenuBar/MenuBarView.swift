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
    @Environment(\.openWindow) private var openWindow
    @Environment(MaaUpdaterController.self) private var updaterController

    @State private var isHoveringDrink = false

    var body: some View {
        VStack(spacing: 12) {
            // Header: Progress & Info
            HStack(alignment: .center, spacing: 16) {
                // Animated Water Cup
                ZStack {
                    Image(systemName: "mug")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Image(systemName: "mug.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .mask(alignment: .bottom) {
                            GeometryReader { geo in
                                VStack(spacing: 0) {
                                    Spacer(minLength: 0)
                                    Rectangle()
                                        .frame(height: geo.size.height * CGFloat(min(max(reminderManager.progress, 0.0), 1.0)))
                                }
                            }
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: reminderManager.progress)
                }
                .frame(width: 80, height: 80)
                
                // Status Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryStatusLine)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    if let secondaryStatusLine {
                        Text(secondaryStatusLine)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    if let notificationStatusLine {
                        Button(action: {
                            reminderManager.openSystemNotificationSettings()
                        }) {
                            Label(notificationStatusLine, systemImage: "bell.badge.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Divider()

            // Main Actions Grid
            HStack(spacing: 12) {
                Button(action: {
                    reminderManager.drinkNow()
                }) {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Drink Now".localized(reminderManager.settings.language))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(isHoveringDrink ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                .cornerRadius(8)
                .disabled(reminderManager.state.isPausedToday)
                .onHover { hovering in
                    isHoveringDrink = hovering
                }
            }
            .padding(.horizontal, 16)

            Divider()

            // Secondary Actions
            VStack(spacing: 4) {
                MenuBarActionRow(
                    icon: reminderManager.state.isPausedToday ? "play.circle.fill" : "pause.circle.fill",
                    title: reminderActionTitle.localized(reminderManager.settings.language),
                    action: reminderAction
                )
                
                MenuBarActionRow(
                    icon: "chart.bar.fill",
                    title: "Statistics".localized(reminderManager.settings.language),
                    action: { 
                        openWindow(id: "statistics")
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                )
            }
            .padding(.horizontal, 8)

            Divider()

            // Footer Actions
            VStack(spacing: 4) {
                MenuBarActionRow(
                    icon: "gearshape.fill",
                    title: "Settings".localized(reminderManager.settings.language),
                    action: {
                        openSettings()
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                )
                
                MenuBarActionRow(
                    icon: "power.circle.fill",
                    title: "Quit".localized(reminderManager.settings.language),
                    action: { NSApplication.shared.terminate(nil) }
                )
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 320)
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

struct MenuBarActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MenuBarView()
        .environment(ReminderManager())
}

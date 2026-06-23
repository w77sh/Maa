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
    @State private var isHoveringUndo = false
    @State private var isMenuVisible = false

    var body: some View {
        VStack(spacing: 12) {
            // Header: Progress & Info
            HStack(alignment: .center, spacing: 16) {
                // Animated Water Cup
                ZStack {
                    Image(systemName: "mug")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(reminderManager.progress == 0 ? .red : .secondary.opacity(0.3))
                    
                    Image(systemName: "mug.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .mask(alignment: .bottom) {
                            GeometryReader { geo in
                                VStack(spacing: 0) {
                                    Spacer(minLength: 0)
                                    let progress = min(max(reminderManager.progress, 0.0), 1.0)
                                    if progress > 0 && progress < 1.0 {
                                        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: !isMenuVisible)) { context in
                                            let time = context.date.timeIntervalSinceReferenceDate
                                            let phase = Angle.degrees(time * 180)
                                            Wave(phase: phase)
                                                .frame(height: geo.size.height * CGFloat(progress))
                                        }
                                    } else {
                                        Rectangle()
                                            .frame(height: geo.size.height * CGFloat(progress))
                                    }
                                }
                            }
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: reminderManager.progress)
                }
                .frame(width: 80, height: 80)
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                    isMenuVisible = true
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
                    isMenuVisible = false
                }
                
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
                    reminderManager.undoDrink()
                }) {
                    VStack {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                        Text("Undo".localized(reminderManager.settings.language))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(isHoveringUndo ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                .cornerRadius(8)
                .disabled(reminderManager.state.consumedMilliliters == 0 || reminderManager.state.isPausedToday)
                .onHover { hovering in
                    isHoveringUndo = hovering
                }
                
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

struct Wave: Shape {
    var phase: Angle

    var animatableData: Double {
        get { phase.radians }
        set { phase = Angle(radians: newValue) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            // Combine multiple sine waves for a more realistic, organic effect
            let wave1 = sin(relativeX * .pi * 4 + phase.radians)
            let wave2 = sin(relativeX * .pi * 5.5 + phase.radians * 1.3) * 0.6
            let wave3 = sin(relativeX * .pi * 2.5 - phase.radians * 0.7) * 0.4
            
            let combinedSine = (wave1 + wave2 + wave3) / 2.0
            
            let y = 3 + combinedSine * 3 // Base y is 3, max amplitude variation
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    MenuBarView()
        .environment(ReminderManager())
}

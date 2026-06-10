//
//  SettingsView.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import SwiftUI
import UserNotifications
import ServiceManagement

struct SettingsView: View {
    @Environment(ReminderManager.self) private var reminderManager

    @State private var intervalChoice: IntervalChoice = .minutes60
    @State private var customIntervalText = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var enableNotification = true
    @State private var enablePopupWindow = true
    @State private var runAtLogin = false
    @State private var dailyGoalLiters: Double = 2.0
    @State private var drinkPortionMilliliters: Int = 250
    @State private var language: AppLanguage = .english
    @State private var validationMessage: String?

    private let calendar = Calendar.current

    var body: some View {
        let lang = reminderManager.settings.language
        Form {
            Section("General".localized(lang)) {
                Toggle("Run automatically at login".localized(lang), isOn: $runAtLogin)
            }
            
            Section("Goal".localized(lang)) {
                Stepper(value: $dailyGoalLiters, in: 0.5...10, step: 0.1) {
                    Text(String(format: "Daily Goal: %.1f liters".localized(lang), dailyGoalLiters))
                }
                
                Stepper(value: $drinkPortionMilliliters, in: 50...1000, step: 50) {
                    Text(String(format: "Drink Portion: %d ml".localized(lang), drinkPortionMilliliters))
                }
            }

            Section("Interval".localized(lang)) {
                Picker("Reminder Interval".localized(lang), selection: $intervalChoice) {
                    ForEach(IntervalChoice.allCases) { choice in
                        Text(choice.title(for: lang)).tag(choice)
                    }
                }

                if intervalChoice == .custom {
                    TextField("Custom interval (minutes)".localized(lang), text: $customIntervalText)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section("Reminder Time Range".localized(lang)) {
                DatePicker("Start Time".localized(lang), selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time".localized(lang), selection: $endTime, displayedComponents: .hourAndMinute)
            }

            Section("Reminder Mode".localized(lang)) {
                Toggle("System Notification".localized(lang), isOn: $enableNotification)
                Toggle("Popup Window".localized(lang), isOn: $enablePopupWindow)

                if enableNotification && reminderManager.notificationAuthorizationStatus == .denied {
                    Button("Enable notifications in System Settings".localized(lang)) {
                        reminderManager.openSystemNotificationSettings()
                    }
                    .buttonStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }

            Section("Language".localized(lang)) {
                Picker("Language".localized(lang), selection: $language) {
                    ForEach(AppLanguage.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
            }

            if let validationMessage {
                Section {
                    Text(validationMessage.localized(lang))
                        .foregroundStyle(.red)
                }
            }

        }
        .formStyle(.grouped)
        .padding()
        .task {
            sync(from: reminderManager.settings)
        }
        .onChange(of: reminderManager.settings) { _, newSettings in
            sync(from: newSettings)
        }
        .onChange(of: intervalChoice) { _, _ in updateSettings() }
        .onChange(of: customIntervalText) { _, _ in updateSettings() }
        .onChange(of: startTime) { _, _ in updateSettings() }
        .onChange(of: endTime) { _, _ in updateSettings() }
        .onChange(of: enableNotification) { _, _ in updateSettings() }
        .onChange(of: enablePopupWindow) { _, _ in updateSettings() }
        .onChange(of: runAtLogin) { _, newValue in
            updateSettings()
            updateLoginItem(enabled: newValue)
        }
        .onChange(of: dailyGoalLiters) { _, _ in updateSettings() }
        .onChange(of: drinkPortionMilliliters) { _, _ in updateSettings() }
        .onChange(of: language) { _, _ in updateSettings() }
    }

    private func updateSettings() {
        guard let intervalMinutes = resolvedIntervalMinutes else {
            validationMessage = "Enter a valid custom interval."
            return
        }

        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let updatedSettings = AppSettings(
            reminderIntervalMinutes: intervalMinutes,
            startHour: startComponents.hour ?? 9,
            startMinute: startComponents.minute ?? 0,
            endHour: endComponents.hour ?? 20,
            endMinute: endComponents.minute ?? 0,
            enableNotification: enableNotification,
            runAtLogin: runAtLogin,
            dailyGoalLiters: dailyGoalLiters,
            drinkPortionMilliliters: drinkPortionMilliliters,
            language: language,
            enablePopupWindow: enablePopupWindow
        )

        if updatedSettings != reminderManager.settings {
            let result = reminderManager.updateSettings(updatedSettings)
            switch result {
            case .valid:
                validationMessage = nil
            case .invalid(let error):
                validationMessage = error.errorDescription
            }
        }
    }

    private func sync(from settings: AppSettings) {
        if let choice = IntervalChoice.from(minutes: settings.reminderIntervalMinutes) {
            intervalChoice = choice
            if choice == .custom {
                customIntervalText = "\(settings.reminderIntervalMinutes)"
            }
        } else {
            intervalChoice = .custom
            customIntervalText = "\(settings.reminderIntervalMinutes)"
        }

        let now = Date()
        startTime = calendar.date(bySettingHour: settings.startHour, minute: settings.startMinute, second: 0, of: now) ?? now
        endTime = calendar.date(bySettingHour: settings.endHour, minute: settings.endMinute, second: 0, of: now) ?? now
        enableNotification = settings.enableNotification
        enablePopupWindow = settings.enablePopupWindow
        runAtLogin = settings.runAtLogin
        dailyGoalLiters = settings.dailyGoalLiters
        drinkPortionMilliliters = settings.drinkPortionMilliliters
        language = settings.language
    }

    private var resolvedIntervalMinutes: Int? {
        switch intervalChoice {
        case .minutes5:
            return 5
        case .minutes10:
            return 10
        case .minutes15:
            return 15
        case .minutes30:
            return 30
        case .minutes45:
            return 45
        case .minutes60:
            return 60
        case .custom:
            return Int(customIntervalText)
        }
    }
    
    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "register" : "unregister") login item: \(error.localizedDescription)")
            // Optionally, show an alert to the user
        }
    }
}

enum IntervalChoice: Int, CaseIterable, Identifiable {
    case minutes5 = 5
    case minutes10 = 10
    case minutes15 = 15
    case minutes30 = 30
    case minutes45 = 45
    case minutes60 = 60
    case custom = 0

    var id: Self { self }

    var title: String {
        switch self {
        case .minutes5: return "5 minutes"
        case .minutes10: return "10 minutes"
        case .minutes15: return "15 minutes"
        case .minutes30: return "30 minutes"
        case .minutes45: return "45 minutes"
        case .minutes60: return "1 hour"
        case .custom: return "Custom..."
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .minutes5: return language == .arabic ? "٥ دقائق" : "5 minutes"
        case .minutes10: return language == .arabic ? "١٠ دقائق" : "10 minutes"
        case .minutes15: return language == .arabic ? "١٥ دقيقة" : "15 minutes"
        case .minutes30: return language == .arabic ? "٣٠ دقيقة" : "30 minutes"
        case .minutes45: return language == .arabic ? "٤٥ دقيقة" : "45 minutes"
        case .minutes60: return language == .arabic ? "ساعة واحدة" : "1 hour"
        case .custom: return language == .arabic ? "مخصص..." : "Custom..."
        }
    }

    static func from(minutes: Int) -> IntervalChoice? {
        if let choice = IntervalChoice(rawValue: minutes) {
            return choice
        }
        return nil
    }
}

#Preview {
    SettingsView()
        .environment(ReminderManager())
}

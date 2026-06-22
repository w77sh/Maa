//
//  SettingsView.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import SwiftUI
import UserNotifications
import ServiceManagement
import UniformTypeIdentifiers
import Sparkle

struct SettingsView: View {
    @Environment(ReminderManager.self) private var reminderManager
    @Environment(MaaUpdaterController.self) private var updaterController

    @State private var intervalChoice: IntervalChoice = .minutes60
    @State private var customIntervalText = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var enableNotification = true
    @State private var runAtLogin = false
    @State private var dailyGoalLiters: Double = 2.0
    @State private var drinkPortionMilliliters: Int = 250
    @State private var language: AppLanguage = .english
    @State private var validationMessage: String?
    @State private var showingNotificationAlert = false
    @State private var coloredMenuBarIcon = true

    private let calendar = Calendar.current

    var body: some View {
        let lang = reminderManager.settings.language
        TabView {
            // General Tab
            Form {
                Section("General".localized(lang)) {
                    Toggle("Run automatically at login".localized(lang), isOn: $runAtLogin)
                    Toggle("Colored Menu Bar Icon".localized(lang), isOn: $coloredMenuBarIcon)
                }
                
                Section("Language".localized(lang)) {
                    Picker("Language".localized(lang), selection: $language) {
                        ForEach(AppLanguage.allCases) { choice in
                            Text(choice.title).tag(choice)
                        }
                    }
                }
                
                Section("Updates".localized(lang)) {
                    Button("Check for Updates".localized(lang)) {
                        updaterController.standardUpdaterController.checkForUpdates(nil)
                    }
                }
                
                Section("Data Management".localized(lang)) {
                    HStack {
                        Button("Export Data".localized(lang)) {
                            exportData()
                        }
                        Spacer()
                        Button("Import Data".localized(lang)) {
                            importData()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("General".localized(lang), systemImage: "gearshape") }
            .tag("general")
            
            // Goal Tab
            Form {
                Section("Goal".localized(lang)) {
                    Stepper(value: $dailyGoalLiters, in: 0.5...10, step: 0.1) {
                        Text(String(format: "Daily Goal: %.1f liters".localized(lang), dailyGoalLiters))
                    }
                    
                    Stepper(value: $drinkPortionMilliliters, in: 50...1000, step: 50) {
                        Text(String(format: "Drink Portion: %d ml".localized(lang), drinkPortionMilliliters))
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Goal".localized(lang), systemImage: "target") }
            .tag("goal")
            
            // Schedule Tab
            Form {
                Section("Interval".localized(lang)) {
                    Picker("Reminder Interval".localized(lang), selection: $intervalChoice) {
                        ForEach(IntervalChoice.allCases) { choice in
                            Text(choice.title(for: lang)).tag(choice)
                        }
                    }

                    if intervalChoice == .custom {
                        Stepper(value: Binding(
                            get: { Int(customIntervalText) ?? 60 },
                            set: { customIntervalText = String($0) }
                        ), in: 1...1440, step: 5) {
                            Text(String(format: "%d minutes".localized(lang), Int(customIntervalText) ?? 60))
                        }
                    }
                }

                Section("Reminder Time Range".localized(lang)) {
                    DatePicker("Start Time".localized(lang), selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                    DatePicker("End Time".localized(lang), selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                }

                Section("Reminder Mode".localized(lang)) {
                    Toggle("System Notification".localized(lang), isOn: $enableNotification)

                    Button("Test Notification".localized(lang)) {
                        Task {
                            await reminderManager.sendTestNotification()
                        }
                    }

                    if enableNotification && reminderManager.notificationAuthorizationStatus == .denied {
                        Button("Enable notifications in System Settings".localized(lang)) {
                            reminderManager.openSystemNotificationSettings()
                        }
                        .buttonStyle(.plain)
                        .font(.callout)
                        .foregroundStyle(.secondary)
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
            .tabItem { Label("Schedule".localized(lang), systemImage: "calendar") }
            .tag("schedule")
        }
        .padding()
        .frame(width: 450, height: 350)
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
        .onChange(of: runAtLogin) { _, newValue in
            updateSettings()
            updateLoginItem(enabled: newValue)
        }
        .onChange(of: dailyGoalLiters) { _, _ in updateSettings() }
        .onChange(of: drinkPortionMilliliters) { _, _ in updateSettings() }
        .onChange(of: language) { _, _ in updateSettings() }
        .onChange(of: coloredMenuBarIcon) { _, _ in updateSettings() }
        .onAppear {
            checkAndShowAlertIfNeeded()
        }
        .onChange(of: enableNotification) { _, newValue in
            updateSettings()
            if newValue {
                checkAndShowAlertIfNeeded()
            }
        }
        .alert("Notifications Disabled".localized(lang), isPresented: $showingNotificationAlert) {
            Button("Open System Settings".localized(lang)) {
                reminderManager.openSystemNotificationSettings()
            }
            Button("Cancel".localized(lang), role: .cancel) { }
        } message: {
            Text("Please enable notifications in System Settings to receive drink reminders.".localized(lang))
        }
    }

    private func checkAndShowAlertIfNeeded() {
        if enableNotification && reminderManager.notificationAuthorizationStatus == .denied {
            showingNotificationAlert = true
        }
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
            coloredMenuBarIcon: coloredMenuBarIcon
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
        runAtLogin = settings.runAtLogin
        dailyGoalLiters = settings.dailyGoalLiters
        drinkPortionMilliliters = settings.drinkPortionMilliliters
        language = settings.language
        coloredMenuBarIcon = settings.coloredMenuBarIcon
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
    
    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MaaBackup.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try reminderManager.exportData(to: url)
            } catch {
                print("Export failed: \(error)")
            }
        }
    }

    private func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try reminderManager.importData(from: url)
                sync(from: reminderManager.settings)
            } catch {
                print("Import failed: \(error)")
            }
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

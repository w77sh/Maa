//
//  ReminderManager.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import AppKit
import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class ReminderManager {
    var settings: AppSettings
    var state: ReminderState
    
    var progress: Double {
        let goal = settings.dailyGoalLiters * 1000
        guard goal > 0 else { return 0 }
        return Double(state.consumedMilliliters) / goal
    }
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    private let settingsStore: SettingsStore
    private let stateStore: ReminderStateStore
    let historyStore: DailyHistoryStore
    private let notificationManager: NotificationManager
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private let calendar: Calendar
    private var hasStarted = false

    init(
        settingsStore: SettingsStore? = nil,
        stateStore: ReminderStateStore? = nil,
        historyStore: DailyHistoryStore? = nil,
        notificationManager: NotificationManager? = nil,
        calendar: Calendar = .current
    ) {
        let resolvedSettingsStore = settingsStore ?? SettingsStore()
        let resolvedStateStore = stateStore ?? ReminderStateStore()
        let resolvedHistoryStore = historyStore ?? DailyHistoryStore()
        let resolvedNotificationManager = notificationManager ?? NotificationManager()

        self.settingsStore = resolvedSettingsStore
        self.stateStore = resolvedStateStore
        self.historyStore = resolvedHistoryStore
        self.notificationManager = resolvedNotificationManager
        self.calendar = calendar

        let loadedSettings = resolvedSettingsStore.load()
        switch ReminderScheduler.validate(settings: loadedSettings) {
        case .valid:
            settings = loadedSettings
        case .invalid:
            settings = .default
            resolvedSettingsStore.save(.default)
        }

        if let savedState = resolvedStateStore.load() {
            state = savedState
        } else {
            state = ReminderState(lastProcessedDay: TimeUtils.startOfDay(for: Date(), calendar: calendar))
        }
        
        start()
    }

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        observeNotificationActions()
        recalculateNextReminder(now: Date(), clearExistingSchedule: true)
        startTimer()
        observeWakeNotifications()

        Task {
            await refreshNotificationAuthorizationStatus(requestIfNeeded: false)
        }
    }

    func requestNotificationAuthorizationOnLaunchIfNeeded() async {
        guard settings.enableNotification && allowsAuthorizationPrompts else {
            await refreshNotificationAuthorizationStatus(requestIfNeeded: false)
            return
        }

        await refreshNotificationAuthorizationStatus(requestIfNeeded: true)
    }

    func openSystemNotificationSettings() {
        notificationManager.openSystemNotificationSettings()
    }

    func sendTestNotification() async {
        if notificationAuthorizationStatus != .authorized {
            await refreshNotificationAuthorizationStatus(requestIfNeeded: true)
        }
        guard notificationAuthorizationStatus == .authorized else { return }
        await notificationManager.sendReminder(language: settings.language)
    }

    func handleTimerTick() {
        handleTimerTick(now: Date())
    }

    func drinkNow() {
        drinkNow(now: Date())
    }

    func drinkNow(now: Date) {
        let oldConsumed = state.consumedMilliliters
        let goal = Int(settings.dailyGoalLiters * 1000)

        state.lastProcessedDay = TimeUtils.startOfDay(for: now, calendar: calendar)
        state.lastDrinkTime = now
        state.isPausedToday = false
        state.nextReminderTime = nil
        state.consumedMilliliters += settings.drinkPortionMilliliters
        saveStateAndHistory(now: now)
        recalculateNextReminder(now: now)

        if oldConsumed < goal && state.consumedMilliliters >= goal {
            Task {
                await notificationManager.sendGoalReached(language: settings.language)
            }
        }
    }

    func pauseToday() {
        pauseToday(now: Date())
    }

    func pauseToday(now: Date) {
        state.lastProcessedDay = TimeUtils.startOfDay(for: now, calendar: calendar)
        state.isPausedToday = true
        state.nextReminderTime = nil
        stateStore.save(state)
    }

    func resumeReminders() {
        resumeReminders(now: Date())
    }

    func resumeReminders(now: Date) {
        state.lastProcessedDay = TimeUtils.startOfDay(for: now, calendar: calendar)
        state.isPausedToday = false
        state.nextReminderTime = nil
        stateStore.save(state)
        recalculateNextReminder(now: now)
    }

    func updateSettings(_ newSettings: AppSettings) -> ValidationResult {
        let validation = ReminderScheduler.validate(settings: newSettings)
        guard case .valid = validation else {
            return validation
        }

        settings = newSettings
        settingsStore.save(newSettings)
        state.nextReminderTime = nil
        stateStore.save(state)
        recalculateNextReminder(now: Date(), clearExistingSchedule: true)

        Task {
            await refreshNotificationAuthorizationStatus(
                requestIfNeeded: newSettings.enableNotification && allowsAuthorizationPrompts
            )
        }

        return .valid
    }

    func update(settings: AppSettings) {
        self.settings = settings
        settingsStore.save(settings)
        recalculateNextReminder(now: Date())
    }

    func pauseOrResume() {
        pauseOrResume(now: Date())
    }

    func pauseOrResume(now: Date) {
        if state.isPausedToday {
            resumeReminders(now: now)
        } else {
            pauseToday(now: now)
        }
    }

    var isOutsideReminderWindow: Bool {
        !state.isPausedToday && !ReminderScheduler.isWithinReminderWindow(now: Date(), settings: settings, calendar: calendar)
    }

    var shouldUsePausedMenuBarIcon: Bool {
        state.isPausedToday
    }

    var nextReminderDescription: String? {
        guard let nextReminderTime = state.nextReminderTime else {
            return nil
        }

        return "Next reminder: \(TimeUtils.menuDateTimeString(nextReminderTime, calendar: calendar))"
    }

    private func handleTimerTick(now: Date) {
        resetDailyStateIfNeeded(now: now)
        // Timer is now only used for UI state freshness (e.g. un-pausing when snooze expires)
        // Notifications are handled natively by macOS.
        if let next = state.nextReminderTime, now >= next {
            // Re-calculate the next reminder if we've passed the previous one without user interaction.
            recalculateNextReminder(now: now)
        }
    }

    private func triggerReminder(now: Date) {
        // This is only called for the "Test Notification" button now,
        // or if we needed to trigger something manually.
        // The actual scheduling is handled by `scheduleNotificationsIfNeeded`.
        Task {
            if notificationAuthorizationStatus != .authorized {
                await refreshNotificationAuthorizationStatus(requestIfNeeded: true)
            }

            guard notificationAuthorizationStatus == .authorized else {
                return
            }

            await notificationManager.sendReminder(language: settings.language)
        }
    }

    private func recalculateNextReminder(now: Date, clearExistingSchedule: Bool = false) {
        resetDailyStateIfNeeded(now: now)

        if clearExistingSchedule {
            state.nextReminderTime = nil
        }

        let goal = Int(settings.dailyGoalLiters * 1000)
        if goal > 0 && state.consumedMilliliters >= goal {
            state.nextReminderTime = nil
        } else {
            state.nextReminderTime = ReminderScheduler.calculateNextReminder(
                now: now,
                state: state,
                settings: settings,
                calendar: calendar
            )
        }
        stateStore.save(state)
        
        Task {
            await scheduleNotificationsIfNeeded()
        }
    }

    private func scheduleNotificationsIfNeeded() async {
        notificationManager.cancelAllReminders()
        
        guard settings.enableNotification, let nextReminderTime = state.nextReminderTime else {
            return
        }
        
        if nextReminderTime > Date() {
            await notificationManager.scheduleReminder(at: nextReminderTime, language: settings.language)
        }
    }

    private func saveStateAndHistory(now: Date) {
        stateStore.save(state)
        historyStore.addOrUpdateRecord(for: now, consumedMilliliters: state.consumedMilliliters, calendar: calendar)
    }

    private func resetDailyStateIfNeeded(now: Date) {
        let currentDay = TimeUtils.startOfDay(for: now, calendar: calendar)

        guard let lastProcessedDay = state.lastProcessedDay else {
            state.lastProcessedDay = currentDay
            return
        }

        guard !calendar.isDate(lastProcessedDay, inSameDayAs: currentDay) else {
            return
        }

        state.lastDrinkTime = nil
        state.nextReminderTime = nil
        state.isPausedToday = false
        state.lastProcessedDay = currentDay
        state.consumedMilliliters = 0
        stateStore.save(state)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTimerTick()
            }
        }
        timer?.tolerance = 5
    }

    private func observeWakeNotifications() {
        guard wakeObserver == nil else {
            return
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recalculateNextReminder(now: Date())
            }
        }
    }

    private func observeNotificationActions() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DrinkActionTriggered"), object: nil, queue: .main) { [weak self] _ in
            self?.drinkNow()
        }
    }

    private func refreshNotificationAuthorizationStatus(requestIfNeeded: Bool) async {
        let status: UNAuthorizationStatus
        if requestIfNeeded {
            status = await notificationManager.requestAuthorizationIfNeeded()
        } else {
            status = await notificationManager.authorizationStatus()
        }

        notificationAuthorizationStatus = status
    }

    private var allowsAuthorizationPrompts: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] == nil
            && environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
    }

    // MARK: - Data Management (Backup / Restore)
    
    struct AppDataBackup: Codable {
        let settings: AppSettings
        let state: ReminderState?
        let history: [DailyRecord]
    }
    
    func exportData(to url: URL) throws {
        let backup = AppDataBackup(
            settings: settings,
            state: state,
            history: historyStore.load()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)
        try data.write(to: url)
    }

    func importData(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let backup = try decoder.decode(AppDataBackup.self, from: data)
        
        // Save to respective stores
        settingsStore.save(backup.settings)
        if let importedState = backup.state {
            stateStore.save(importedState)
        }
        historyStore.save(backup.history)
        
        // Update in-memory state
        self.settings = backup.settings
        if let importedState = backup.state {
            self.state = importedState
        }
        
        recalculateNextReminder(now: Date(), clearExistingSchedule: true)
        
        Task {
            await refreshNotificationAuthorizationStatus(
                requestIfNeeded: settings.enableNotification && allowsAuthorizationPrompts
            )
        }
    }
}

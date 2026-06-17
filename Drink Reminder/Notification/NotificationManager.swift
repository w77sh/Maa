import AppKit
import UserNotifications

struct NotificationManager {
    private static let systemNotificationSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
    )

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        setupCategories()
    }

    private func setupCategories() {
        let drinkAction = UNNotificationAction(identifier: "DRINK_ACTION", title: "Drink Now".localized(.english), options: .foreground)

        let category = UNNotificationCategory(
            identifier: "REMINDER_CATEGORY",
            actions: [drinkAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([category])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }

    func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        let currentStatus = await authorizationStatus()
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])
        return await authorizationStatus()
    }

    func sendReminder(language: AppLanguage = .english) async {
        let content = UNMutableNotificationContent()
        content.title = "It's time to drink".localized(language)
        content.body = "water or whatever".localized(language)
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"

        let request = UNNotificationRequest(
            identifier: "DrinkReminder",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    func scheduleReminder(at date: Date, language: AppLanguage = .english) async {
        let content = UNMutableNotificationContent()
        content.title = "It's time to drink".localized(language)
        content.body = "water or whatever".localized(language)
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "DrinkReminder",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func sendGoalReached(language: AppLanguage = .english) async {
        let content = UNMutableNotificationContent()
        content.title = "Goal Reached! 🎉".localized(language)
        content.body = "Congratulations! You have completed your daily water goal today. Keep up the healthy habit! 💧".localized(language)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "GoalReachedReminder",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    func cancelAllReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["DrinkReminder"])
    }

    func openSystemNotificationSettings() {
        guard let url = Self.systemNotificationSettingsURL else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

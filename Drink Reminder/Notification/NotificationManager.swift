import AppKit
import UserNotifications

struct NotificationManager {
    private static let systemNotificationSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
    )

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
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

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    func openSystemNotificationSettings() {
        guard let url = Self.systemNotificationSettingsURL else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

import AppKit
import SwiftUI

@main
struct Drink_ReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate


    private static let menuBarIconAssetName = "StatusBarIcon"
    private static let menuBarPausedIconAssetName = "StatusBarIconPaused"
    private static let menuBarFallbackSymbolName = "waterbottle.fill"
    private static let menuBarPausedFallbackSymbolName = "pause.fill"

    @State private var reminderManager: ReminderManager

    init() {
        let reminderManager = ReminderManager()
        _reminderManager = State(initialValue: reminderManager)

        NSApplication.shared.setActivationPolicy(.accessory)

        Task { @MainActor in
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didFinishLaunchingNotification).prefix(1) {
                await reminderManager.requestNotificationAuthorizationOnLaunchIfNeeded()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(reminderManager)
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)
        } label: {
            menuBarIcon
                .accessibilityLabel("Drink Reminder".localized(reminderManager.settings.language))
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(reminderManager)
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)
                .frame(minWidth: 380, minHeight: 320)
        }
    }

    private var menuBarIcon: Image {
        if let image = templatedMenuBarIcon {
            Image(nsImage: image)
        } else {
            Image(systemName: fallbackSystemSymbolName)
        }
    }

    private var templatedMenuBarIcon: NSImage? {
        guard let image = NSImage(named: currentMenuBarIconAssetName)?.copy() as? NSImage else {
            return nil
        }

        image.isTemplate = true
        return image
    }

    private var currentMenuBarIconAssetName: String {
        reminderManager.shouldUsePausedMenuBarIcon
            ? Self.menuBarPausedIconAssetName
            : Self.menuBarIconAssetName
    }

    private var fallbackSystemSymbolName: String {
        reminderManager.shouldUsePausedMenuBarIcon
            ? Self.menuBarPausedFallbackSymbolName
            : Self.menuBarFallbackSymbolName
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

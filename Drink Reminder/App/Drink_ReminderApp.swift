import AppKit
import SwiftUI
import Sparkle
import UserNotifications

@main
struct Drink_ReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate


    private static let menuBarIconAssetName = "StatusBarIcon"
    private static let menuBarPausedIconAssetName = "StatusBarIconPaused"
    private static let menuBarFallbackSymbolName = "waterbottle.fill"
    private static let menuBarPausedFallbackSymbolName = "pause.fill"

    @State private var reminderManager: ReminderManager
    @State private var updaterController = MaaUpdaterController()

    init() {
        let reminderManager = ReminderManager()
        _reminderManager = State(initialValue: reminderManager)

        NSApplication.shared.setActivationPolicy(.accessory)

        Task { @MainActor in
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didFinishLaunchingNotification).prefix(1) {
                await reminderManager.requestNotificationAuthorizationOnLaunchIfNeeded()
                
                if reminderManager.settings.enableNotification && reminderManager.notificationAuthorizationStatus == .denied {
                    let alert = NSAlert()
                    alert.messageText = "Notifications Disabled".localized(reminderManager.settings.language)
                    alert.informativeText = "Please enable notifications in System Settings to receive drink reminders.".localized(reminderManager.settings.language)
                    alert.addButton(withTitle: "Open System Settings".localized(reminderManager.settings.language))
                    alert.addButton(withTitle: "Cancel".localized(reminderManager.settings.language))
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        reminderManager.openSystemNotificationSettings()
                    }
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(reminderManager)
                .environment(updaterController)
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)
        } label: {
            menuBarIcon
                .accessibilityLabel("Maa".localized(reminderManager.settings.language))
                .id("\(reminderManager.state.consumedMilliliters)_\(reminderManager.shouldUsePausedMenuBarIcon)_\(reminderManager.settings.coloredMenuBarIcon)")
        }
        .menuBarExtraStyle(.window)

        Window("Drinking Statistics".localized(reminderManager.settings.language), id: "statistics") {
            StatisticsView(
                historyStore: reminderManager.historyStore,
                dailyGoalMilliliters: Int(reminderManager.settings.dailyGoalLiters * 1000)
            )
                .environment(reminderManager)
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)
                .frame(minWidth: 400, minHeight: 300)
        }

        Settings {
            SettingsView()
                .environment(reminderManager)
                .environment(updaterController)
                .environment(\.locale, Locale(identifier: reminderManager.settings.language.rawValue))
                .environment(\.layoutDirection, reminderManager.settings.language == .arabic ? .rightToLeft : .leftToRight)
                .frame(minWidth: 380, minHeight: 320)
        }
    }

    private var menuBarIcon: Image {
        if let image = templatedMenuBarIcon {
            return Image(nsImage: image)
        } else {
            return Image(systemName: "mug")
        }
    }

    private var templatedMenuBarIcon: NSImage? {
        if reminderManager.shouldUsePausedMenuBarIcon {
            guard let image = NSImage(named: Self.menuBarPausedIconAssetName)?.copy() as? NSImage else { return nil }
            image.isTemplate = true
            return image
        }

        let consumed = reminderManager.state.consumedMilliliters
        let goal = Int(reminderManager.settings.dailyGoalLiters * 1000)
        let progress = goal > 0 ? min(Double(consumed) / Double(goal), 1.0) : 0.0

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            guard let outline = NSImage(systemSymbolName: "mug", accessibilityDescription: nil)?.withSymbolConfiguration(config),
                  let fill = NSImage(systemSymbolName: "mug.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) else {
                return false
            }

            let drawRect = NSRect(x: (18 - outline.size.width) / 2,
                                  y: (18 - outline.size.height) / 2,
                                  width: outline.size.width,
                                  height: outline.size.height)

            let tintedOutline = outline.copy() as! NSImage
            tintedOutline.lockFocus()
            NSColor.labelColor.set()
            NSRect(origin: .zero, size: tintedOutline.size).fill(using: .sourceAtop)
            tintedOutline.unlockFocus()
            
            tintedOutline.draw(in: drawRect)

            if progress <= 0 {
                let redLine = NSBezierPath()
                redLine.move(to: NSPoint(x: drawRect.minX + 3, y: drawRect.minY + 2))
                redLine.line(to: NSPoint(x: drawRect.maxX - 3, y: drawRect.minY + 2))
                NSColor.systemRed.setStroke()
                redLine.lineWidth = 1.5
                redLine.lineCapStyle = .round
                redLine.stroke()
            } else {
                NSGraphicsContext.current?.saveGraphicsState()
                
                let fillHeight = drawRect.height * progress
                let clipRect = NSRect(x: 0, y: 0, width: 18, height: drawRect.minY + fillHeight)
                NSBezierPath(rect: clipRect).addClip()
                
                let tintedFill = fill.copy() as! NSImage
                tintedFill.lockFocus()
                if reminderManager.settings.coloredMenuBarIcon {
                    NSColor.systemBlue.set()
                } else {
                    NSColor.labelColor.set()
                }
                NSRect(origin: .zero, size: tintedFill.size).fill(using: .sourceAtop)
                tintedFill.unlockFocus()
                
                tintedFill.draw(in: drawRect)
                
                NSGraphicsContext.current?.restoreGraphicsState()
            }

            if progress >= 1.0 {
                let badgeSize: CGFloat = 8.5
                let badgeRect = NSRect(x: drawRect.maxX - badgeSize + 2,
                                       y: drawRect.minY - 2,
                                       width: badgeSize,
                                       height: badgeSize)
                
                let greenCircle = NSBezierPath(ovalIn: badgeRect)
                NSColor.systemGreen.set()
                greenCircle.fill()
                
                let checkConfig = NSImage.SymbolConfiguration(pointSize: 6, weight: .bold)
                if let checkSymbol = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
                    .withSymbolConfiguration(checkConfig) {
                    
                    let checkRect = NSRect(x: badgeRect.midX - checkSymbol.size.width / 2,
                                           y: badgeRect.midY - checkSymbol.size.height / 2,
                                           width: checkSymbol.size.width,
                                           height: checkSymbol.size.height)
                    
                    let tintedCheck = checkSymbol.copy() as! NSImage
                    tintedCheck.lockFocus()
                    NSColor.white.set()
                    NSRect(origin: .zero, size: tintedCheck.size).fill(using: .sourceAtop)
                    tintedCheck.unlockFocus()
                    
                    tintedCheck.draw(in: checkRect)
                }
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // App is injected with ReminderManager as environment, but AppDelegate needs access to it.
        // I can broadcast a notification or access it via a shared instance if available.
        // Wait, ReminderManager is @State in App. I should observe NotificationCenter.
        switch response.actionIdentifier {
        case "DRINK_ACTION":
            NotificationCenter.default.post(name: NSNotification.Name("DrinkActionTriggered"), object: nil)
        default:
            break
        }
        completionHandler()
    }
}

@Observable
class MaaUpdaterController {
    let standardUpdaterController: SPUStandardUpdaterController

    private let delegate = UpdaterDelegate()

    init() {
        standardUpdaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: delegate, userDriverDelegate: nil)
    }

    func checkForUpdates() {
        standardUpdaterController.checkForUpdates(nil)
    }
}

class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? {
        return "https://github.com/w77sh/Maa/releases/latest/download/appcast.xml"
    }
}

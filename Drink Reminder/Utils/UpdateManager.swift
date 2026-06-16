//
//  UpdateManager.swift
//  Drink Reminder
//

import Foundation
import AppKit

class UpdateManager {
    static let shared = UpdateManager()
    
    func checkForUpdates(language: AppLanguage) {
        let url = URL(string: "https://api.github.com/repos/w77sh/Maa/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("Maa-DrinkReminder", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    self.showAlert(title: "Update Check Failed".localized(language),
                                   message: "Could not connect to GitHub.".localized(language),
                                   language: language)
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tagName = json["tag_name"] as? String,
                       let htmlUrlStr = json["html_url"] as? String,
                       let htmlUrl = URL(string: htmlUrlStr) {
                       
                        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                        let normalizedTag = tagName.replacingOccurrences(of: "v", with: "")
                        
                        if normalizedTag.compare(currentVersion, options: .numeric) == .orderedDescending {
                            self.showUpdateAvailableAlert(tagName: tagName, url: htmlUrl, language: language)
                        } else {
                            self.showAlert(title: "Up to Date".localized(language),
                                           message: "You have the latest version.".localized(language),
                                           language: language)
                        }
                    } else {
                        self.showAlert(title: "Update Check Failed".localized(language),
                                       message: "Invalid response from GitHub.".localized(language),
                                       language: language)
                    }
                } catch {
                    self.showAlert(title: "Update Check Failed".localized(language),
                                   message: "Error parsing response.".localized(language),
                                   language: language)
                }
            }
        }
        task.resume()
    }
    
    private func showUpdateAvailableAlert(tagName: String, url: URL, language: AppLanguage) {
        let alert = NSAlert()
        alert.messageText = "Update Available".localized(language)
        alert.informativeText = String(format: "A new version (%@) is available!".localized(language), tagName)
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: "Download".localized(language))
        alert.addButton(withTitle: "Cancel".localized(language))
        
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showAlert(title: String, message: String, language: AppLanguage) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK".localized(language))
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

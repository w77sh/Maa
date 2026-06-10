//
//  ReminderPopupView.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import SwiftUI

struct ReminderPopupView: View {
    var reminderManager: ReminderManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)

            Text("It's time to drink water!".localized(reminderManager.settings.language))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(String(format: "Consumed: %d ml / %d ml".localized(reminderManager.settings.language), reminderManager.state.consumedMilliliters, Int(reminderManager.settings.dailyGoalLiters * 1000)))
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                Button("Drink Now".localized(reminderManager.settings.language)) {
                    reminderManager.drinkNow()
                    WindowManager.shared.closePopup()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Snooze".localized(reminderManager.settings.language)) {
                    reminderManager.snooze30Minutes()
                    WindowManager.shared.closePopup()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Close".localized(reminderManager.settings.language)) {
                    WindowManager.shared.closePopup()
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
            }
        }
        .padding(30)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow).ignoresSafeArea())
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

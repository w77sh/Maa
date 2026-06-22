//
//  OnboardingView.swift
//  Drink Reminder
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(ReminderManager.self) private var reminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var dailyGoalLiters: Double = 2.0
    @State private var intervalChoice: IntervalChoice = .minutes60
    @State private var customIntervalText = "60"
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var enableNotification = true
    @State private var language: AppLanguage = .english
    
    var closeAction: (() -> Void)? = nil
    
    var body: some View {
        let lang = language
        
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(
                        .linearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("Welcome to Maa".localized(lang))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Let's set up your daily hydration goal.".localized(lang))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Goal Section
                    OnboardingSection(title: "Daily Goal".localized(lang), icon: "target") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(format: "Daily Goal: %.1f liters".localized(lang), dailyGoalLiters))
                                .font(.headline)
                            Slider(value: $dailyGoalLiters, in: 0.5...10, step: 0.1)
                                .tint(.cyan)
                        }
                    }
                    
                    // Time Range Section
                    OnboardingSection(title: "Active Hours".localized(lang), icon: "clock") {
                        HStack(spacing: 20) {
                            DatePicker("Start Time".localized(lang), selection: $startTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            
                            Text("to".localized(lang))
                                .foregroundStyle(.secondary)
                            
                            DatePicker("End Time".localized(lang), selection: $endTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    
                    // Interval Section
                    OnboardingSection(title: "Reminder Frequency".localized(lang), icon: "bell.badge") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("", selection: $intervalChoice) {
                                ForEach(IntervalChoice.allCases) { choice in
                                    Text(choice.title(for: lang)).tag(choice)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            
                            if intervalChoice == .custom {
                                Stepper(value: Binding(
                                    get: { Int(customIntervalText) ?? 60 },
                                    set: { customIntervalText = String($0) }
                                ), in: 1...1440, step: 5) {
                                    Text(String(format: "%d minutes".localized(lang), Int(customIntervalText) ?? 60))
                                }
                            }
                        }
                    }
                    
                    // Notification Section
                    OnboardingSection(title: "Notifications".localized(lang), icon: "message") {
                        Toggle("Enable Notifications".localized(lang), isOn: $enableNotification)
                            .toggleStyle(.switch)
                            .tint(.cyan)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // Footer
            VStack {
                Button(action: finishOnboarding) {
                    Text("Get Started".localized(lang))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            .linearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(40)
        }
        .frame(width: 480, height: 640)
        .background(
            ZStack {
                Color.clear
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            }
        )
        .ignoresSafeArea()
        .onAppear {
            self.language = reminderManager.settings.language
            self.dailyGoalLiters = reminderManager.settings.dailyGoalLiters
            self.enableNotification = reminderManager.settings.enableNotification
        }
    }
    
    private func finishOnboarding() {
        var newSettings = reminderManager.settings
        newSettings.dailyGoalLiters = dailyGoalLiters
        newSettings.enableNotification = enableNotification
        
        let calendar = Calendar.current
        newSettings.startHour = calendar.component(.hour, from: startTime)
        newSettings.startMinute = calendar.component(.minute, from: startTime)
        newSettings.endHour = calendar.component(.hour, from: endTime)
        newSettings.endMinute = calendar.component(.minute, from: endTime)
        
        if intervalChoice == .custom {
            newSettings.reminderIntervalMinutes = Int(customIntervalText) ?? 60
        } else {
            newSettings.reminderIntervalMinutes = intervalChoice.rawValue
        }
        
        newSettings.hasSeenOnboarding = true
        
        // Save and apply settings
        _ = reminderManager.updateSettings(newSettings)
        
        if enableNotification {
            Task {
                await reminderManager.requestNotificationAuthorizationOnLaunchIfNeeded()
            }
        }
        
        closeAction?()
        dismiss()
    }
}

struct OnboardingSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.cyan)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// Helper for native macos frosted glass
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

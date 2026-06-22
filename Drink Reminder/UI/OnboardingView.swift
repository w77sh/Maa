//
//  OnboardingView.swift
//  Drink Reminder
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(ReminderManager.self) private var reminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    @State private var dailyGoalLiters: Double = 2.0
    @State private var intervalChoice: IntervalChoice = .minutes60
    @State private var customIntervalText = "60"
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var enableNotification = true
    @State private var language: AppLanguage = .english
    
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
                
                Text(headerTitle(for: lang))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(headerSubtitle(for: lang))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Content
            ZStack {
                switch currentPage {
                case 0:
                    goalPage(lang: lang)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 1:
                    schedulePage(lang: lang)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 2:
                    notificationPage(lang: lang)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: currentPage)
            .padding(.horizontal, 40)
            
            Spacer(minLength: 0)
            
            // Footer Navigation
            HStack(spacing: 20) {
                if currentPage > 0 {
                    Button(action: {
                        withAnimation { currentPage -= 1 }
                    }) {
                        Text("Back".localized(lang))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        finishOnboarding()
                    }
                }) {
                    Text(currentPage < 2 ? "Next".localized(lang) : "Get Started".localized(lang))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            .linearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(40)
        }
        .frame(width: 480, height: 500)
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
    
    private func headerTitle(for lang: AppLanguage) -> String {
        switch currentPage {
        case 0: return "Welcome to Maa".localized(lang)
        case 1: return "Your Schedule".localized(lang)
        case 2: return "Stay Updated".localized(lang)
        default: return ""
        }
    }
    
    private func headerSubtitle(for lang: AppLanguage) -> String {
        switch currentPage {
        case 0: return "Let's set up your daily hydration goal.".localized(lang)
        case 1: return "When should we remind you to drink water?".localized(lang)
        case 2: return "Allow notifications so we can remind you.".localized(lang)
        default: return ""
        }
    }
    
    @ViewBuilder
    private func goalPage(lang: AppLanguage) -> some View {
        OnboardingSection(title: "Daily Goal".localized(lang), icon: "target") {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(format: "Daily Goal: %.1f liters".localized(lang), dailyGoalLiters))
                    .font(.headline)
                Slider(value: $dailyGoalLiters, in: 0.5...10, step: 0.1)
                    .tint(.cyan)
            }
        }
    }
    
    @ViewBuilder
    private func schedulePage(lang: AppLanguage) -> some View {
        VStack(spacing: 24) {
            OnboardingSection(title: "Active Hours".localized(lang), icon: "clock") {
                HStack(spacing: 20) {
                    DatePicker("Start Time".localized(lang), selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.stepperField)
                        .labelsHidden()
                        .colorMultiply(.white.opacity(0.8)) // Dim the solid background
                    
                    Text("to".localized(lang))
                        .foregroundStyle(.secondary)
                    
                    DatePicker("End Time".localized(lang), selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.stepperField)
                        .labelsHidden()
                        .colorMultiply(.white.opacity(0.8)) // Dim the solid background
                }
            }
            
            OnboardingSection(title: "Reminder Frequency".localized(lang), icon: "bell.badge") {
                VStack(alignment: .leading, spacing: 12) {
                    Menu {
                        ForEach(IntervalChoice.allCases) { choice in
                            Button(choice.title(for: lang)) {
                                intervalChoice = choice
                            }
                        }
                    } label: {
                        HStack {
                            Text(intervalChoice.title(for: lang))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
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
        }
    }
    
    @ViewBuilder
    private func notificationPage(lang: AppLanguage) -> some View {
        OnboardingSection(title: "Notifications".localized(lang), icon: "message") {
            Toggle("Enable Notifications".localized(lang), isOn: $enableNotification)
                .toggleStyle(.switch)
                .tint(.cyan)
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
        
        NotificationCenter.default.post(name: Notification.Name("OnboardingFinished"), object: nil)
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
                .background(Color.clear) // Completely transparent
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1) // Very subtle border
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

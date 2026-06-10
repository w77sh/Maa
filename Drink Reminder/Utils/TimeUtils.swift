//
//  TimeUtils.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import Foundation

enum TimeUtils {
    nonisolated static func time(
        onSameDayAs referenceDate: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar = .current
    ) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = components.day
        newComponents.hour = hour
        newComponents.minute = minute

        return calendar.date(from: newComponents) ?? referenceDate
    }

    nonisolated static func date(
        byAddingMinutes minutes: Int,
        to date: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: date) ?? date
    }

    nonisolated static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    nonisolated static func menuDateTimeString(_ date: Date, calendar: Calendar = .current, language: AppLanguage = .english) -> String {
        let locale = Locale(identifier: language.rawValue)
        let formattedTime = date.formatted(.dateTime.hour().minute().locale(locale))
        
        if calendar.isDateInToday(date) {
            return formattedTime
        }

        if calendar.isDateInTomorrow(date) {
            let tomorrow = language == .arabic ? "غداً" : "Tomorrow"
            return "\(tomorrow) \(formattedTime)"
        }

        return date.formatted(.dateTime.month().day().hour().minute().locale(locale))
    }
}

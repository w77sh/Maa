//
//  ReminderScheduler.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import Foundation

enum SettingsValidationError: LocalizedError, Equatable {
    case intervalTooShort
    case endTimeMustBeAfterStartTime

    nonisolated var errorDescription: String? {
        switch self {
        case .intervalTooShort:
            return "Interval must be at least 5 minutes."
        case .endTimeMustBeAfterStartTime:
            return "End time must be later than start time."
        }
    }
}

enum ValidationResult: Equatable {
    case valid
    case invalid(SettingsValidationError)
}

enum ReminderScheduler {
    nonisolated static let minimumIntervalMinutes = 5

    nonisolated static func calculateNextReminder(
        now: Date,
        state: ReminderState,
        settings: AppSettings,
        calendar: Calendar = .current
    ) -> Date? {
        guard case .valid = validate(settings: settings) else {
            return nil
        }

        if state.isPausedToday {
            return nil
        }



        if !isWithinReminderWindow(now: now, settings: settings, calendar: calendar) {
            return nextStartTime(after: now, settings: settings, calendar: calendar)
        }

        if let explicitNextReminder = state.nextReminderTime, explicitNextReminder > now {
            return normalizedUpcomingReminder(explicitNextReminder, settings: settings, calendar: calendar)
        }

        if let lastDrinkTime = state.lastDrinkTime {
            let candidate = TimeUtils.date(
                byAddingMinutes: settings.reminderIntervalMinutes,
                to: lastDrinkTime,
                calendar: calendar
            )

            if candidate > now {
                return normalizedUpcomingReminder(candidate, settings: settings, calendar: calendar)
            }
        }

        let fallback = TimeUtils.date(
            byAddingMinutes: settings.reminderIntervalMinutes,
            to: now,
            calendar: calendar
        )
        return normalizedUpcomingReminder(fallback, settings: settings, calendar: calendar)
    }

    nonisolated static func nextReminderAfterTrigger(
        now: Date,
        settings: AppSettings,
        calendar: Calendar = .current
    ) -> Date? {
        guard case .valid = validate(settings: settings) else {
            return nil
        }

        let candidate = TimeUtils.date(
            byAddingMinutes: settings.reminderIntervalMinutes,
            to: now,
            calendar: calendar
        )
        return normalizedUpcomingReminder(candidate, settings: settings, calendar: calendar)
    }

    nonisolated static func isWithinReminderWindow(
        now: Date,
        settings: AppSettings,
        calendar: Calendar = .current
    ) -> Bool {
        guard case .valid = validate(settings: settings) else {
            return false
        }

        let window = reminderWindow(containing: now, settings: settings, calendar: calendar)
        return now >= window.start && now <= window.end
    }

    nonisolated static func nextStartTime(
        after now: Date,
        settings: AppSettings,
        calendar: Calendar = .current
    ) -> Date {
        let todayStart = TimeUtils.time(
            onSameDayAs: now,
            hour: settings.startHour,
            minute: settings.startMinute,
            calendar: calendar
        )

        if now < todayStart {
            return todayStart
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return TimeUtils.time(
            onSameDayAs: tomorrow,
            hour: settings.startHour,
            minute: settings.startMinute,
            calendar: calendar
        )
    }

    nonisolated static func validate(settings: AppSettings) -> ValidationResult {
        if settings.reminderIntervalMinutes < minimumIntervalMinutes {
            return .invalid(.intervalTooShort)
        }

        let startTotalMinutes = (settings.startHour * 60) + settings.startMinute
        let endTotalMinutes = (settings.endHour * 60) + settings.endMinute

        if endTotalMinutes <= startTotalMinutes {
            return .invalid(.endTimeMustBeAfterStartTime)
        }

        return .valid
    }

    private nonisolated static func reminderWindow(
        containing now: Date,
        settings: AppSettings,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let start = TimeUtils.time(
            onSameDayAs: now,
            hour: settings.startHour,
            minute: settings.startMinute,
            calendar: calendar
        )
        let end = TimeUtils.time(
            onSameDayAs: now,
            hour: settings.endHour,
            minute: settings.endMinute,
            calendar: calendar
        )
        return (start, end)
    }

    private nonisolated static func normalizedUpcomingReminder(
        _ candidate: Date,
        settings: AppSettings,
        calendar: Calendar
    ) -> Date {
        if isWithinReminderWindow(now: candidate, settings: settings, calendar: calendar) {
            return candidate
        }

        return nextStartTime(after: candidate, settings: settings, calendar: calendar)
    }
}

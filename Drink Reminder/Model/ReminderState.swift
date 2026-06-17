//
//  ReminderState.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import Foundation

struct ReminderState: Codable {
    var lastDrinkTime: Date?
    var nextReminderTime: Date?
    var isPausedToday: Bool
    var lastProcessedDay: Date?
    var consumedMilliliters: Int

    init(
        lastDrinkTime: Date? = nil,
        nextReminderTime: Date? = nil,
        isPausedToday: Bool = false,
        lastProcessedDay: Date? = nil,
        consumedMilliliters: Int = 0
    ) {
        self.lastDrinkTime = lastDrinkTime
        self.nextReminderTime = nextReminderTime
        self.isPausedToday = isPausedToday
        self.lastProcessedDay = lastProcessedDay
        self.consumedMilliliters = consumedMilliliters
    }
}

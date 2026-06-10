//
//  AppSettings.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import Foundation

struct AppSettings: Codable, Equatable {
    var reminderIntervalMinutes: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var enableNotification: Bool
    var runAtLogin: Bool
    var dailyGoalLiters: Double
    var drinkPortionMilliliters: Int
    var language: AppLanguage
    var enablePopupWindow: Bool

    static let `default` = AppSettings(
        reminderIntervalMinutes: 60,
        startHour: 9,
        startMinute: 0,
        endHour: 20,
        endMinute: 0,
        enableNotification: true,
        runAtLogin: false,
        dailyGoalLiters: 2.0,
        drinkPortionMilliliters: 250,
        language: .english,
        enablePopupWindow: true
    )

    enum CodingKeys: String, CodingKey {
        case reminderIntervalMinutes
        case startHour
        case startMinute
        case endHour
        case endMinute
        case enableNotification
        case runAtLogin
        case dailyGoalLiters
        case drinkPortionMilliliters
        case language
        case enablePopupWindow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reminderIntervalMinutes = try container.decode(Int.self, forKey: .reminderIntervalMinutes)
        startHour = try container.decode(Int.self, forKey: .startHour)
        startMinute = try container.decode(Int.self, forKey: .startMinute)
        endHour = try container.decode(Int.self, forKey: .endHour)
        endMinute = try container.decode(Int.self, forKey: .endMinute)
        enableNotification = try container.decode(Bool.self, forKey: .enableNotification)
        runAtLogin = try container.decodeIfPresent(Bool.self, forKey: .runAtLogin) ?? AppSettings.default.runAtLogin
        dailyGoalLiters = try container.decodeIfPresent(Double.self, forKey: .dailyGoalLiters) ?? AppSettings.default.dailyGoalLiters
        drinkPortionMilliliters = try container.decodeIfPresent(Int.self, forKey: .drinkPortionMilliliters) ?? AppSettings.default.drinkPortionMilliliters
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        enablePopupWindow = try container.decodeIfPresent(Bool.self, forKey: .enablePopupWindow) ?? AppSettings.default.enablePopupWindow
    }
    
    // Add a custom initializer to be used by the default static property and tests
    init(reminderIntervalMinutes: Int, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, enableNotification: Bool, runAtLogin: Bool = false, dailyGoalLiters: Double = 2.0, drinkPortionMilliliters: Int = 250, language: AppLanguage = .english, enablePopupWindow: Bool = true) {
        self.reminderIntervalMinutes = reminderIntervalMinutes
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.enableNotification = enableNotification
        self.runAtLogin = runAtLogin
        self.dailyGoalLiters = dailyGoalLiters
        self.drinkPortionMilliliters = drinkPortionMilliliters
        self.language = language
        self.enablePopupWindow = enablePopupWindow
    }
}

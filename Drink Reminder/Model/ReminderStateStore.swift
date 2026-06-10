//
//  ReminderStateStore.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import Foundation

struct ReminderStateStore {
    private let userDefaults: UserDefaults
    private let key: String

    init(userDefaults: UserDefaults = .standard, key: String = "reminderState") {
        self.userDefaults = userDefaults
        self.key = key
    }

    func load() -> ReminderState? {
        guard
            let data = userDefaults.data(forKey: key),
            let state = try? JSONDecoder().decode(ReminderState.self, from: data)
        else {
            return nil
        }
        return state
    }

    func save(_ state: ReminderState) {
        guard let data = try? JSONEncoder().encode(state) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }
}

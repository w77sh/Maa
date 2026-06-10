//
//  DailyHistoryStore.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import Foundation

struct DailyRecord: Codable, Identifiable, Equatable {
    var id: String { dateString }
    let dateString: String // format "yyyy-MM-dd"
    var consumedMilliliters: Int
}

struct DailyHistoryStore {
    private let userDefaults: UserDefaults
    private let key: String

    init(userDefaults: UserDefaults = .standard, key: String = "dailyHistory") {
        self.userDefaults = userDefaults
        self.key = key
    }

    func load() -> [DailyRecord] {
        guard
            let data = userDefaults.data(forKey: key),
            let records = try? JSONDecoder().decode([DailyRecord].self, from: data)
        else {
            return []
        }
        return records
    }

    func save(_ records: [DailyRecord]) {
        guard let data = try? JSONEncoder().encode(records) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }
    
    func addOrUpdateRecord(for date: Date, consumedMilliliters: Int, calendar: Calendar = .current) {
        var records = load()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        let dateString = formatter.string(from: date)
        
        if let index = records.firstIndex(where: { $0.dateString == dateString }) {
            records[index].consumedMilliliters = consumedMilliliters
        } else {
            records.append(DailyRecord(dateString: dateString, consumedMilliliters: consumedMilliliters))
        }
        
        // Keep only last 30 days
        if records.count > 30 {
            records = Array(records.suffix(30))
        }
        
        save(records)
    }
}

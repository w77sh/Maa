//
//  StatisticsView.swift
//  Drink Reminder
//
//  Created by Codex on 2026/3/9.
//

import SwiftUI
import Charts

enum TimeRangeFilter: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case allTime = "All Time"
    
    var id: String { self.rawValue }
    
    func title(for lang: AppLanguage) -> String {
        return self.rawValue.localized(lang)
    }
}

struct StatisticsView: View {
    let historyStore: DailyHistoryStore
    let dailyGoalMilliliters: Int
    
    @State private var allRecords: [DailyRecord] = []
    @State private var selectedTimeRange: TimeRangeFilter = .last7Days
    
    @Environment(\.locale) var locale

    private var filteredRecords: [DailyRecord] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let sorted = allRecords.sorted { 
            guard let d1 = formatter.date(from: $0.dateString),
                  let d2 = formatter.date(from: $1.dateString) else { return false }
            return d1 < d2
        }
        
        switch selectedTimeRange {
        case .last7Days:
            return Array(sorted.suffix(7))
        case .last30Days:
            return Array(sorted.suffix(30))
        case .allTime:
            return sorted
        }
    }
    
    private var averageIntake: Int {
        guard !filteredRecords.isEmpty else { return 0 }
        let total = filteredRecords.reduce(0) { $0 + $1.consumedMilliliters }
        return total / filteredRecords.count
    }
    
    private var totalConsumed: Int {
        filteredRecords.reduce(0) { $0 + $1.consumedMilliliters }
    }
    
    private var bestDayIntake: Int {
        filteredRecords.map { $0.consumedMilliliters }.max() ?? 0
    }
    
    private var lang: AppLanguage {
        AppLanguage(rawValue: locale.identifier) ?? .english
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Drinking Statistics".localized(lang))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Picker("Time Range".localized(lang), selection: $selectedTimeRange) {
                    ForEach(TimeRangeFilter.allCases) { range in
                        Text(range.title(for: lang)).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 150)
            }
            .padding(.horizontal)

            HStack(spacing: 15) {
                SummaryCard(title: "Average Daily Intake".localized(lang), value: "\(averageIntake) ml", icon: "chart.bar.doc.horizontal")
                SummaryCard(title: "Total Consumed".localized(lang), value: "\(totalConsumed) ml", icon: "drop.fill")
                SummaryCard(title: "Best Day".localized(lang), value: "\(bestDayIntake) ml", icon: "star.fill")
            }
            .padding(.horizontal)

            if filteredRecords.isEmpty {
                Text("No data available yet.".localized(lang))
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                Chart(filteredRecords) { record in
                    BarMark(
                        x: .value("Date", formatDateString(record.dateString)),
                        y: .value("Milliliters", record.consumedMilliliters)
                    )
                    .foregroundStyle(record.consumedMilliliters >= dailyGoalMilliliters ? Color.green.gradient : Color.blue.gradient)
                    .annotation(position: .top) {
                        Text("\(record.consumedMilliliters)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    RuleMark(y: .value("Goal", dailyGoalMilliliters))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(Color.orange)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("Goal".localized(lang))
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .onAppear {
            allRecords = historyStore.load()
        }
        .frame(minWidth: 550, minHeight: 450)
        .padding(.vertical)
    }
    
    private func formatDateString(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.setLocalizedDateFormatFromTemplate("MMM d")
            displayFormatter.locale = locale
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

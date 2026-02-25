import Foundation
import SwiftUI

final class CountdownManager: ObservableObject {
    static let shared = CountdownManager()

    private static let labelKey = "countdown-label"
    private static let yearKey = "countdown-target-year"
    private static let monthKey = "countdown-target-month"
    private static let dayKey = "countdown-target-day"

    @Published var label: String {
        didSet { UserDefaults.standard.set(label, forKey: Self.labelKey) }
    }
    @Published var targetYear: Int {
        didSet { UserDefaults.standard.set(targetYear, forKey: Self.yearKey) }
    }
    @Published var targetMonth: Int {
        didSet { UserDefaults.standard.set(targetMonth, forKey: Self.monthKey) }
    }
    @Published var targetDay: Int {
        didSet { UserDefaults.standard.set(targetDay, forKey: Self.dayKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.label = defaults.string(forKey: Self.labelKey) ?? "Christmas"
        self.targetYear = defaults.object(forKey: Self.yearKey) as? Int ?? 2026
        self.targetMonth = defaults.object(forKey: Self.monthKey) as? Int ?? 12
        self.targetDay = defaults.object(forKey: Self.dayKey) as? Int ?? 25
    }

    var targetDate: Date {
        var components = DateComponents()
        components.year = targetYear
        components.month = targetMonth
        components.day = targetDay
        return Calendar.current.startOfDay(for: Calendar.current.date(from: components)!)
    }

    var daysRemaining: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let components = Calendar.current.dateComponents([.day], from: today, to: targetDate)
        return max(components.day ?? 0, 0)
    }
}

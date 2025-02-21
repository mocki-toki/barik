import EventKit
import SwiftUI

struct CalendarPopup: View {
    let calendarManager: CalendarManager

    @ObservedObject var configProvider: ConfigProvider
    @State private var selectedVariant: MenuBarPopupVariant = .box

    var body: some View {
        MenuBarPopupVariantView(
            selectedVariant: selectedVariant,
            onVariantSelected: { variant in
                selectedVariant = variant
                ConfigManager.shared.updateConfigValue(
                    key: "widgets.default.time.popup.view-variant",
                    newValue: variant.rawValue
                )
            },
            box: { CalendarBoxPopup(calendarManager) },
            vertical: { CalendarVerticalPopup(calendarManager) },
            horizontal: { CalendarHorizontalPopup(calendarManager) }
        )
        .onAppear {
            if let variantString = configProvider.config["popup"]?
                .dictionaryValue?["view-variant"]?.stringValue,
                let variant = MenuBarPopupVariant(rawValue: variantString)
            {
                selectedVariant = variant
            } else {
                selectedVariant = .box
            }
        }
        .onReceive(configProvider.$config) { newConfig in
            if let variantString = newConfig["popup"]?.dictionaryValue?[
                "view-variant"]?.stringValue,
                let variant = MenuBarPopupVariant(rawValue: variantString)
            {
                selectedVariant = variant
            }
        }
    }
}

struct CalendarBoxPopup: View {
    let calendarManager: CalendarManager

    init(_ calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(currentMonthYear)
                .font(.title2)
                .padding(.bottom, 25)
            WeekdayHeaderView()
            CalendarDaysView(
                weeks: weeks,
                currentYear: currentYear,
                currentMonth: currentMonth
            )
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
    }
}

struct CalendarVerticalPopup: View {
    let calendarManager: CalendarManager

    init(_ calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(currentMonthYear)
                .font(.title2)
                .padding(.bottom, 25)
            WeekdayHeaderView()
            CalendarDaysView(
                weeks: weeks,
                currentYear: currentYear,
                currentMonth: currentMonth
            )
            EventListView(
                todaysEvents: calendarManager.todaysEvents,
                tomorrowsEvents: calendarManager.tomorrowsEvents
            )
            .frame(width: 255)
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
    }
}

struct CalendarHorizontalPopup: View {
    let calendarManager: CalendarManager

    init(_ calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(currentMonthYear)
                    .font(.title2)
                    .padding(.bottom, 25)
                    .fixedSize(horizontal: true, vertical: false)
                WeekdayHeaderView()
                CalendarDaysView(
                    weeks: weeks,
                    currentYear: currentYear,
                    currentMonth: currentMonth
                )
            }
            EventListView(
                todaysEvents: calendarManager.todaysEvents,
                tomorrowsEvents: calendarManager.tomorrowsEvents
            )
            .frame(width: 255)
            .padding(.leading, 30)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
    }
}

private var currentMonthYear: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "LLLL yyyy"
    return formatter.string(from: Date()).capitalized
}

private var currentMonth: Int {
    Calendar.current.component(.month, from: Date())
}

private var currentYear: Int {
    Calendar.current.component(.year, from: Date())
}

private var calendarDays: [Int?] {
    let calendar = Calendar.current
    let date = Date()
    guard
        let range = calendar.range(of: .day, in: .month, for: date),
        let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        )
    else {
        return []
    }
    let startOfMonthWeekday = calendar.component(.weekday, from: firstOfMonth)
    let blanks = (startOfMonthWeekday - calendar.firstWeekday + 7) % 7
    var days: [Int?] = Array(repeating: nil, count: blanks)
    days.append(contentsOf: range.map { $0 })
    return days
}

private var weeks: [[Int?]] {
    var days = calendarDays
    let remainder = days.count % 7
    if remainder != 0 {
        days.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
    }
    return stride(from: 0, to: days.count, by: 7).map {
        Array(days[$0..<min($0 + 7, days.count)])
    }
}

private struct WeekdayHeaderView: View {
    var body: some View {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        let reordered = Array(
            weekdaySymbols[firstWeekdayIndex...]
                + weekdaySymbols[..<firstWeekdayIndex]
        )
        let referenceDate = DateComponents(
            calendar: calendar, year: 2020, month: 12, day: 13
        ).date!
        let referenceDays = (0..<7).map { i in
            calendar.date(byAdding: .day, value: i, to: referenceDate)!
        }

        HStack {
            ForEach(reordered.indices, id: \.self) { i in
                let originalIndex = (i + firstWeekdayIndex) % 7
                let isWeekend = calendar.isDateInWeekend(
                    referenceDays[originalIndex]
                )
                let color = isWeekend ? Color.gray : Color.white

                Text(reordered[i])
                    .frame(width: 30)
                    .foregroundColor(color)
            }
        }
        .padding(.bottom, 10)
    }
}

private struct CalendarDaysView: View {
    let weeks: [[Int?]]
    let currentYear: Int
    let currentMonth: Int

    var body: some View {
        let calendar = Calendar.current
        VStack(spacing: 10) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                HStack(spacing: 8) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        if let day = weeks[weekIndex][dayIndex] {
                            let date = calendar.date(
                                from: DateComponents(
                                    year: currentYear,
                                    month: currentMonth,
                                    day: day
                                )
                            )!
                            let isWeekend = calendar.isDateInWeekend(date)
                            let color =
                                isToday(day: day)
                                ? Color.black
                                : (isWeekend ? Color.gray : Color.white)

                            ZStack {
                                if isToday(day: day) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 30, height: 30)
                                }
                                Text("\(day)")
                                    .foregroundColor(color)
                                    .frame(width: 30, height: 30)
                            }
                        } else {
                            Color.clear.frame(width: 30, height: 30)
                        }
                    }
                }
            }
        }
    }

    func isToday(day: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let dateFromDay = calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: day
            )
        ) {
            return calendar.isDateInToday(dateFromDay)
        }
        return false
    }
}

private struct EventListView: View {
    let todaysEvents: [EKEvent]
    let tomorrowsEvents: [EKEvent]

    var body: some View {
        if todaysEvents.isEmpty && tomorrowsEvents.isEmpty {
            Text(NSLocalizedString("EMPTY_EVENTS", comment: ""))
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.callout)
        } else {
            VStack(spacing: 10) {
                eventSection(
                    title: NSLocalizedString("TODAY", comment: "").uppercased(),
                    events: todaysEvents)
                eventSection(
                    title: NSLocalizedString("TOMORROW", comment: "")
                        .uppercased(), events: tomorrowsEvents)
            }
        }
    }

    @ViewBuilder
    func eventSection(title: String, events: [EKEvent]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.gray)
            ForEach(events, id: \.eventIdentifier) { event in
                EventRow(event: event)
            }
        }
    }
}

private struct EventRow: View {
    let event: EKEvent

    var body: some View {
        let eventTime = getEventTime(event)
        HStack(spacing: 4) {
            Rectangle()
                .fill(Color(event.calendar.cgColor))
                .frame(width: 3, height: 30)
                .clipShape(Capsule())
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(eventTime)
                    .font(.caption)
                    .fontWeight(.regular)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(5)
        .padding(.trailing, 5)
        .foregroundStyle(Color(event.calendar.cgColor))
        .background(Color(event.calendar.cgColor).opacity(0.2))
        .cornerRadius(6)
        .frame(maxWidth: .infinity)
    }

    func getEventTime(_ event: EKEvent) -> String {
        var text = event.title ?? ""
        if !event.isAllDay {
            text += " ("
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("j:mm")
            text += formatter.string(from: event.startDate)
            text += ")"
        } else {
            return NSLocalizedString("ALL_DAY", comment: "")
        }
        return text
    }
}

struct CalendarPopup_Previews: PreviewProvider {
    var configProvider: ConfigProvider = ConfigProvider(config: ConfigData())
    var calendarManager: CalendarManager

    init() {
        self.calendarManager = CalendarManager(configProvider: configProvider)
    }

    static var previews: some View {
        let configProvider = ConfigProvider(config: ConfigData())
        let calendarManager = CalendarManager(configProvider: configProvider)

        CalendarBoxPopup(calendarManager)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Box")
        CalendarVerticalPopup(calendarManager)
            .background(Color.black)
            .frame(height: 600)
            .previewDisplayName("Vertical")
        CalendarHorizontalPopup(calendarManager)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Horizontal")
    }
}

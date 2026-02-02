import AppKit
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
                // If clicking settings while already in settings, go back to dayView
                let newVariant = (variant == .settings && selectedVariant == .settings) ? .dayView : variant
                selectedVariant = newVariant
                ConfigManager.shared.updateConfigValue(
                    key: "widgets.default.time.popup.view-variant",
                    newValue: newVariant.rawValue
                )
            },
            box: { CalendarBoxPopup() },
            vertical: { CalendarVerticalPopup(calendarManager) },
            horizontal: { CalendarHorizontalPopup(calendarManager) },
            dayView: { CalendarDayViewPopup(calendarManager) },
            settings: {
                CalendarSettingsView(calendarManager, onBack: {
                    selectedVariant = .dayView
                    ConfigManager.shared.updateConfigValue(
                        key: "widgets.default.time.popup.view-variant",
                        newValue: "dayView"
                    )
                })
            }
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
        .padding(30)
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
            
            Group {
                if calendarManager.todaysEvents.isEmpty && calendarManager.tomorrowsEvents.isEmpty {
                    Text(NSLocalizedString("EMPTY_EVENTS", comment: ""))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.callout)
                        .padding(.top, 3)
                }
                EventListView(
                    todaysEvents: calendarManager.todaysEvents,
                    tomorrowsEvents: calendarManager.tomorrowsEvents
                )
            }
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
            
            Group {
                if calendarManager.todaysEvents.isEmpty && calendarManager.tomorrowsEvents.isEmpty {
                    Text(NSLocalizedString("EMPTY_EVENTS", comment: ""))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.callout)
                }
                EventListView(
                    todaysEvents: calendarManager.todaysEvents,
                    tomorrowsEvents: calendarManager.tomorrowsEvents
                )
            }
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
        }.compositingGroup()
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
        if !todaysEvents.isEmpty || !tomorrowsEvents.isEmpty {
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
        if !events.isEmpty {
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
}

private struct EventRow: View {
    let event: EKEvent
    @State private var showDetail = false

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
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail.toggle()
        }
        .popover(isPresented: $showDetail, arrowEdge: .leading) {
            EventDetailView(event: event) {
                showDetail = false
            }
        }
    }

    func getEventTime(_ event: EKEvent) -> String {
        var text = ""
        if !event.isAllDay {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("j:mm")
            text += formatter.string(from: event.startDate).replacing(":00", with: "")
            text += " — "
            text += formatter.string(from: event.endDate).replacing(":00", with: "")
        } else {
            return NSLocalizedString("ALL_DAY", comment: "")
        }
        return text
    }
}

// MARK: - Event Detail View

private struct EventDetailView: View {
    let event: EKEvent
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with close button
            HStack {
                Circle()
                    .fill(Color(event.calendar.cgColor))
                    .frame(width: 10, height: 10)
                Text(event.calendar.title)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            // Event title
            Text(event.title ?? "Untitled Event")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Time
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(formatEventTime())
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Location (if available)
            if let location = event.location, !location.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(location)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }

            // Notes (if available)
            if let notes = event.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(3)
                }
            }

            // Open in Calendar button
            Button {
                openInCalendar()
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("Open in Calendar")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(event.calendar.cgColor).opacity(0.5))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(event.calendar.cgColor).opacity(0.4), lineWidth: 1)
                )
        )
        .frame(width: 220)
    }

    private func formatEventTime() -> String {
        if event.isAllDay {
            return NSLocalizedString("ALL_DAY", comment: "")
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) — \(end)"
    }

    private func openInCalendar() {
        if let url = URL(string: "x-apple-calendar://") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Day View Popup (Mac Sidebar Style)

struct CalendarDayViewPopup: View {
    let calendarManager: CalendarManager
    @State private var selectedEvent: EKEvent?

    init(_ calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
    }

    private let hourHeight: CGFloat = 24
    private let startHour: Int = 9
    private let endHour: Int = 24  // Extend to midnight
    private let visibleHours: Int = 8  // Show 8 hours at a time (same as original 9-17)

    private var scrollableHeight: CGFloat {
        CGFloat(visibleHours) * hourHeight
    }

    var body: some View {
        Group {
            if let event = selectedEvent {
                // Show expanded event detail view
                ExpandedEventView(event: event) {
                    withAnimation(.smooth(duration: 0.2)) {
                        selectedEvent = nil
                    }
                }
            } else {
                // Show normal day view
                HStack(alignment: .top, spacing: 0) {
                    // Left side: Today
                    TodayColumnView(
                        startHour: startHour,
                        endHour: endHour,
                        hourHeight: hourHeight,
                        scrollableHeight: scrollableHeight,
                        events: calendarManager.todaysEvents,
                        onEventSelected: { event in
                            withAnimation(.smooth(duration: 0.2)) {
                                selectedEvent = event
                            }
                        }
                    )

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1)

                    // Right side: Tomorrow
                    TomorrowColumnView(
                        startHour: startHour,
                        endHour: endHour,
                        hourHeight: hourHeight,
                        scrollableHeight: scrollableHeight,
                        events: calendarManager.tomorrowsEvents,
                        onEventSelected: { event in
                            withAnimation(.smooth(duration: 0.2)) {
                                selectedEvent = event
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Expanded Event View (fills popup space)

private struct ExpandedEventView: View {
    let event: EKEvent
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with back button
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Spacer()

                // Calendar indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(event.calendar.cgColor))
                        .frame(width: 10, height: 10)
                    Text(event.calendar.title)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            // Event title
            Text(event.title ?? "Untitled Event")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Time
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(Color(event.calendar.cgColor))
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatEventDate())
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                    Text(formatEventTime())
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Location (if available)
            if let location = event.location, !location.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "location")
                        .font(.system(size: 14))
                        .foregroundColor(Color(event.calendar.cgColor))
                    Text(location)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Notes (if available)
            if let notes = event.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14))
                        .foregroundColor(Color(event.calendar.cgColor))
                    ScrollView {
                        Text(notes)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxHeight: 100)
                }
            }

            Spacer()

            // Open in Calendar button
            Button {
                openInCalendar()
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text("Open in Calendar")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(event.calendar.cgColor).opacity(0.5))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 380)  // Match the width of the day view (180 + 1 + 220 - some padding)
    }

    private func formatEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: event.startDate)
    }

    private func formatEventTime() -> String {
        if event.isAllDay {
            return NSLocalizedString("ALL_DAY", comment: "")
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) — \(end)"
    }

    private func openInCalendar() {
        if let url = URL(string: "x-apple-calendar://") {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct TodayColumnView: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat
    let scrollableHeight: CGFloat
    let events: [EKEvent]
    let onEventSelected: (EKEvent) -> Void

    @State private var currentTime = Date()
    @State private var showAllDayEvents = false
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var allDayEvents: [EKEvent] {
        events.filter { $0.isAllDay }
    }

    private var timedEvents: [EKEvent] {
        events.filter { !$0.isAllDay }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Day of week + date
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    Text(dayNumber)
                        .font(.system(size: 34, weight: .light))
                }

                // All-day events badge (clickable)
                if !allDayEvents.isEmpty {
                    allDayEventsBadge
                        .onTapGesture {
                            withAnimation(.smooth(duration: 0.2)) {
                                showAllDayEvents.toggle()
                            }
                        }

                    // Expanded all-day events list
                    if showAllDayEvents {
                        allDayEventsList
                    }
                }
            }
            .padding(.bottom, 15)

            // Time slots with current time indicator (scrollable)
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour labels and lines
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            HStack(alignment: .top, spacing: 8) {
                                Text(formatHour(hour))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .frame(width: 24, alignment: .trailing)

                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(height: hourHeight)
                        }
                    }

                    // Events overlay
                    eventsOverlay

                    // Current time indicator
                    currentTimeIndicator
                }
            }
            .frame(height: scrollableHeight)
        }
        .frame(width: 180)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        let hourOffset = hour - startHour
        let minuteOffset = CGFloat(minute) / 60.0
        let yPosition = CGFloat(hourOffset) * hourHeight + minuteOffset * hourHeight

        return Group {
            if hour >= startHour && hour < endHour {
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 1)
                }
                .offset(x: 28, y: yPosition - 4)
            }
        }
    }

    private var eventsOverlay: some View {
        let calendar = Calendar.current
        let visibleEvents = timedEvents.filter { event in
            let hour = calendar.component(.hour, from: event.startDate)
            return hour >= startHour && hour < endHour
        }

        // Group overlapping events
        let groupedEvents = groupOverlappingEvents(visibleEvents)

        return ZStack(alignment: .topLeading) {
            ForEach(groupedEvents, id: \.0.eventIdentifier) { event, column, totalColumns in
                eventBlock(event: event, column: column, totalColumns: totalColumns)
            }
        }
    }

    private func eventBlock(event: EKEvent, column: Int, totalColumns: Int) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        let hourOffset = hour - startHour
        let minuteOffset = CGFloat(minute) / 60.0
        let yPosition = CGFloat(hourOffset) * hourHeight + minuteOffset * hourHeight

        // Calculate duration for height
        let duration = event.endDate.timeIntervalSince(event.startDate) / 3600.0
        let height = max(CGFloat(duration) * hourHeight - 2, 20)

        // Calculate width based on overlapping events
        let availableWidth: CGFloat = 120  // Slightly smaller for today column
        let eventWidth = (availableWidth / CGFloat(totalColumns)) - 2
        let xOffset: CGFloat = 36 + CGFloat(column) * (eventWidth + 2)

        return Button {
            onEventSelected(event)
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(event.calendar.cgColor))
                    .frame(width: 3)

                Text(event.title ?? "")
                    .font(.system(size: 11))
                    .lineLimit(height > 30 ? 2 : 1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
            }
            .frame(width: eventWidth, height: height, alignment: .leading)
            .background(Color(event.calendar.cgColor).opacity(0.25))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .offset(x: xOffset, y: yPosition)
    }

    private func groupOverlappingEvents(_ events: [EKEvent]) -> [(EKEvent, Int, Int)] {
        guard !events.isEmpty else { return [] }

        var result: [(EKEvent, Int, Int)] = []
        var groups: [[EKEvent]] = []

        let sortedEvents = events.sorted { $0.startDate < $1.startDate }

        for event in sortedEvents {
            var placed = false
            for i in groups.indices {
                let groupEnd = groups[i].map { $0.endDate }.max() ?? Date.distantPast
                if event.startDate >= groupEnd {
                    groups[i].append(event)
                    placed = true
                    break
                }
            }
            if !placed {
                groups.append([event])
            }
        }

        // Flatten with column info
        for event in sortedEvents {
            var column = 0
            var overlappingCount = 1

            for (idx, group) in groups.enumerated() {
                if group.contains(where: { $0.eventIdentifier == event.eventIdentifier }) {
                    column = idx
                    // Count how many groups overlap with this event
                    overlappingCount = groups.filter { group in
                        group.contains { otherEvent in
                            !(event.endDate <= otherEvent.startDate || event.startDate >= otherEvent.endDate)
                        }
                    }.count
                    break
                }
            }

            result.append((event, column, overlappingCount))
        }

        return result
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour > 12 ? hour - 12 : hour
        return "\(h)"
    }

    private var allDayEventsBadge: some View {
        HStack(spacing: 4) {
            // Show colored dots for first 3 calendars
            HStack(spacing: -4) {
                ForEach(Array(allDayEvents.prefix(3).enumerated()), id: \.offset) { _, event in
                    Circle()
                        .fill(Color(event.calendar.cgColor))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
            }

            Text("\(allDayEvents.count) all-day")
                .font(.system(size: 12))
                .foregroundColor(.white)

            Image(systemName: showAllDayEvents ? "chevron.up" : "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
        .contentShape(Rectangle())
    }

    private var allDayEventsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(allDayEvents, id: \.eventIdentifier) { event in
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color(event.calendar.cgColor))
                        .frame(width: 3, height: 16)
                        .cornerRadius(1.5)

                    Text(event.title ?? "Untitled")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 6)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct TomorrowColumnView: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat
    let scrollableHeight: CGFloat
    let events: [EKEvent]
    let onEventSelected: (EKEvent) -> Void

    @State private var showAllDayEvents = false

    private var allDayEvents: [EKEvent] {
        events.filter { $0.isAllDay }
    }

    private var timedEvents: [EKEvent] {
        events.filter { !$0.isAllDay }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: TOMORROW
            VStack(alignment: .leading, spacing: 6) {
                Text("TOMORROW")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)

                // All-day events badge (clickable)
                if !allDayEvents.isEmpty {
                    allDayEventsBadge
                        .onTapGesture {
                            withAnimation(.smooth(duration: 0.2)) {
                                showAllDayEvents.toggle()
                            }
                        }

                    // Expanded all-day events list
                    if showAllDayEvents {
                        allDayEventsList
                    }
                }
            }
            .padding(.bottom, 15)

            // Time slots with events (scrollable)
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour labels
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            HStack(alignment: .top, spacing: 8) {
                                Text(formatHour(hour))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .frame(width: 24, alignment: .trailing)

                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(height: hourHeight)
                        }
                    }

                    // Events overlay
                    eventsOverlay
                }
            }
            .frame(height: scrollableHeight)
        }
        .frame(width: 220)
    }

    private var allDayEventsBadge: some View {
        HStack(spacing: 4) {
            // Show colored dots for first 3 calendars
            HStack(spacing: -4) {
                ForEach(Array(allDayEvents.prefix(3).enumerated()), id: \.offset) { _, event in
                    Circle()
                        .fill(Color(event.calendar.cgColor))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
            }

            Text("\(allDayEvents.count) all-day event\(allDayEvents.count == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundColor(.white)

            Image(systemName: showAllDayEvents ? "chevron.up" : "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
        .contentShape(Rectangle())
    }

    private var allDayEventsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(allDayEvents, id: \.eventIdentifier) { event in
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color(event.calendar.cgColor))
                        .frame(width: 3, height: 16)
                        .cornerRadius(1.5)

                    Text(event.title ?? "Untitled")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 6)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var eventsOverlay: some View {
        let calendar = Calendar.current
        let visibleEvents = timedEvents.filter { event in
            let hour = calendar.component(.hour, from: event.startDate)
            return hour >= startHour && hour < endHour
        }

        // Group overlapping events
        let groupedEvents = groupOverlappingEvents(visibleEvents)

        return ZStack(alignment: .topLeading) {
            ForEach(groupedEvents, id: \.0.eventIdentifier) { event, column, totalColumns in
                eventBlock(event: event, column: column, totalColumns: totalColumns)
            }
        }
    }

    private func eventBlock(event: EKEvent, column: Int, totalColumns: Int) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        let hourOffset = hour - startHour
        let minuteOffset = CGFloat(minute) / 60.0
        let yPosition = CGFloat(hourOffset) * hourHeight + minuteOffset * hourHeight

        // Calculate duration for height
        let duration = event.endDate.timeIntervalSince(event.startDate) / 3600.0
        let height = max(CGFloat(duration) * hourHeight - 2, 20)

        // Calculate width based on overlapping events
        let availableWidth: CGFloat = 160
        let eventWidth = (availableWidth / CGFloat(totalColumns)) - 2
        let xOffset: CGFloat = 36 + CGFloat(column) * (eventWidth + 2)

        return Button {
            onEventSelected(event)
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(event.calendar.cgColor))
                    .frame(width: 3)

                Text(event.title ?? "")
                    .font(.system(size: 11))
                    .lineLimit(height > 30 ? 2 : 1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
            }
            .frame(width: eventWidth, height: height, alignment: .leading)
            .background(Color(event.calendar.cgColor).opacity(0.25))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .offset(x: xOffset, y: yPosition)
    }

    private func groupOverlappingEvents(_ events: [EKEvent]) -> [(EKEvent, Int, Int)] {
        guard !events.isEmpty else { return [] }

        var result: [(EKEvent, Int, Int)] = []
        var groups: [[EKEvent]] = []

        let sortedEvents = events.sorted { $0.startDate < $1.startDate }

        for event in sortedEvents {
            var placed = false
            for i in groups.indices {
                let groupEnd = groups[i].map { $0.endDate }.max() ?? Date.distantPast
                if event.startDate >= groupEnd {
                    groups[i].append(event)
                    placed = true
                    break
                }
            }
            if !placed {
                groups.append([event])
            }
        }

        // Flatten with column info
        for event in sortedEvents {
            var column = 0
            var overlappingCount = 1

            for (idx, group) in groups.enumerated() {
                if group.contains(where: { $0.eventIdentifier == event.eventIdentifier }) {
                    column = idx
                    // Count how many groups overlap with this event
                    overlappingCount = groups.filter { group in
                        group.contains { otherEvent in
                            !(event.endDate <= otherEvent.startDate || event.startDate >= otherEvent.endDate)
                        }
                    }.count
                    break
                }
            }

            result.append((event, column, overlappingCount))
        }

        return result
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour > 12 ? hour - 12 : hour
        return "\(h)"
    }
}

// MARK: - Calendar Settings View

struct CalendarSettingsView: View {
    @ObservedObject var calendarManager: CalendarManager
    @State private var denyListState: Set<String> = []
    var onBack: (() -> Void)?

    init(_ calendarManager: CalendarManager, onBack: (() -> Void)? = nil) {
        self.calendarManager = calendarManager
        self.onBack = onBack
    }

    private var maxHeight: CGFloat {
        (NSScreen.main?.frame.height ?? 800) / 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with back button and title
            HStack {
                Button {
                    onBack?()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("CALENDARS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 15)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(calendarManager.allCalendars, id: \.calendarIdentifier) { calendar in
                        CalendarToggleRow(
                            calendar: calendar,
                            isEnabled: !denyListState.contains(calendar.calendarIdentifier),
                            onToggle: { enabled in
                                toggleCalendar(calendar, enabled: enabled)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: maxHeight - 80)  // Account for header and padding
        }
        .frame(width: 250)
        .padding(20)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
        .onAppear {
            loadDenyListFromConfig()
        }
    }

    private func loadDenyListFromConfig() {
        // Read deny-list directly from ConfigManager to ensure we have the latest persisted values
        let widgetConfig = ConfigManager.shared.globalWidgetConfig(for: "default.time")
        if let calendarConfig = widgetConfig["calendar"]?.dictionaryValue,
           let denyListArray = calendarConfig["deny-list"]?.arrayValue {
            denyListState = Set(denyListArray.compactMap { $0.stringValue }.filter { !$0.isEmpty })
        } else {
            denyListState = []
        }
    }

    private func toggleCalendar(_ calendar: EKCalendar, enabled: Bool) {
        // Update local state immediately for responsive UI
        if enabled {
            denyListState.remove(calendar.calendarIdentifier)
        } else {
            denyListState.insert(calendar.calendarIdentifier)
        }

        // Format as TOML array string and save
        let tomlArray = "[" + denyListState.sorted().map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        ConfigManager.shared.updateConfigValueRaw(
            key: "widgets.default.time.calendar.deny-list",
            newValue: tomlArray
        )
    }
}

private struct CalendarToggleRow: View {
    let calendar: EKCalendar
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Calendar color indicator
            Circle()
                .fill(Color(calendar.cgColor))
                .frame(width: 12, height: 12)

            // Calendar name
            Text(calendar.title)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // Toggle checkbox
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(isEnabled ? Color(calendar.cgColor) : .gray.opacity(0.5))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle(!isEnabled)
        }
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

        CalendarBoxPopup()
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
        CalendarDayViewPopup(calendarManager)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Day View")
    }
}

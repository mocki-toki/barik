import Combine
import EventKit
import Foundation

class CalendarManager: ObservableObject {
    let configProvider: ConfigProvider
    var config: ConfigData? {
        configProvider.config["calendar"]?.dictionaryValue
    }
    var allowList: [String] {
        Array(
            (config?["allow-list"]?.arrayValue?.map { $0.stringValue ?? "" }
                .drop(while: { $0 == "" })) ?? [])
    }
    var denyList: [String] {
        Array(
            (config?["deny-list"]?.arrayValue?.map { $0.stringValue ?? "" }
                .drop(while: { $0 == "" })) ?? [])
    }

    @Published var nextEvent: EKEvent?
    @Published var todaysEvents: [EKEvent] = []
    @Published var tomorrowsEvents: [EKEvent] = []
    private let eventStore = EKEventStore()
    private var timer: Timer?

    init(configProvider: ConfigProvider) {
        self.configProvider = configProvider
        requestAccess()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            [weak self] _ in
            self?.fetchTodaysEvents()
            self?.fetchTomorrowsEvents()
            self?.fetchNextEvent()
        }
        fetchTodaysEvents()
        fetchTomorrowsEvents()
        fetchNextEvent()
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            if granted && error == nil {
                self?.fetchTodaysEvents()
                self?.fetchTomorrowsEvents()
                self?.fetchNextEvent()
            } else {
                print(
                    "Calendar access not granted: \(String(describing: error))")
            }
        }
    }

    private func filterEvents(_ events: [EKEvent]) -> [EKEvent] {
        var filtered = events
        if !allowList.isEmpty {
            filtered = filtered.filter { allowList.contains($0.calendar.title) }
        }
        if !denyList.isEmpty {
            filtered = filtered.filter { !denyList.contains($0.calendar.title) }
        }
        return filtered
    }

    func fetchNextEvent() {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let calendar = Calendar.current
        guard
            let endOfDay = calendar.date(
                bySettingHour: 23, minute: 59, second: 59, of: now)
        else {
            print("Failed to get end of day.")
            return
        }
        let predicate = eventStore.predicateForEvents(
            withStart: now, end: endOfDay, calendars: calendars)
        let events = eventStore.events(matching: predicate).sorted {
            $0.startDate < $1.startDate
        }
        let filteredEvents = filterEvents(events)
        let regularEvents = filteredEvents.filter { !$0.isAllDay }
        let next = regularEvents.first ?? filteredEvents.first
        DispatchQueue.main.async {
            self.nextEvent = next
        }
    }

    func fetchTodaysEvents() {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        guard
            let endOfDay = calendar.date(
                bySettingHour: 23, minute: 59, second: 59, of: now)
        else {
            print("Failed to get end of day.")
            return
        }
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay, end: endOfDay, calendars: calendars)
        let events = eventStore.events(matching: predicate)
            .filter { $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }
        let filteredEvents = filterEvents(events)
        DispatchQueue.main.async {
            self.todaysEvents = filteredEvents
        }
    }

    func fetchTomorrowsEvents() {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard
            let startOfTomorrow = calendar.date(
                byAdding: .day, value: 1, to: startOfToday),
            let endOfTomorrow = calendar.date(
                bySettingHour: 23, minute: 59, second: 59, of: startOfTomorrow)
        else {
            print("Failed to get tomorrow's date range.")
            return
        }
        let predicate = eventStore.predicateForEvents(
            withStart: startOfTomorrow, end: endOfTomorrow, calendars: calendars
        )
        let events = eventStore.events(matching: predicate).sorted {
            $0.startDate < $1.startDate
        }
        let filteredEvents = filterEvents(events)
        DispatchQueue.main.async {
            self.tomorrowsEvents = filteredEvents
        }
    }
}

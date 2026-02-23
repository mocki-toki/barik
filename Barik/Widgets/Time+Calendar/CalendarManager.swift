import Combine
import EventKit
import Foundation

class CalendarManager: ObservableObject {
    let configProvider: ConfigProvider

    // Read config directly from ConfigManager.shared to get latest values
    private var calendarConfig: ConfigData? {
        let widgetConfig = ConfigManager.shared.globalWidgetConfig(for: "default.time")
        return widgetConfig["calendar"]?.dictionaryValue
    }
    var allowList: [String] {
        Array(
            (calendarConfig?["allow-list"]?.arrayValue?.map { $0.stringValue ?? "" }
                .drop(while: { $0 == "" })) ?? [])
    }
    var denyList: [String] {
        Array(
            (calendarConfig?["deny-list"]?.arrayValue?.map { $0.stringValue ?? "" }
                .drop(while: { $0 == "" })) ?? [])
    }

    @Published var nextEvent: EKEvent?
    @Published var todaysEvents: [EKEvent] = []
    @Published var tomorrowsEvents: [EKEvent] = []
    @Published var allCalendars: [EKCalendar] = []
    let eventStore = EKEventStore()
    private var debounceTimer: Timer?
    private var configCancellable: AnyCancellable?

    init(configProvider: ConfigProvider) {
        self.configProvider = configProvider
        requestAccess()
        startMonitoring()

        // Subscribe to ConfigManager.shared config changes to re-fetch events when deny-list changes
        configCancellable = ConfigManager.shared.$config
            .dropFirst()  // Skip initial value
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchTodaysEvents()
                self?.fetchTomorrowsEvents()
                self?.fetchNextEvent()
            }
    }

    deinit {
        stopMonitoring()
        configCancellable?.cancel()
    }

    private func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCalendarStoreChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
        fetchAllCalendars()
        fetchTodaysEvents()
        fetchTomorrowsEvents()
        fetchNextEvent()
    }

    func fetchAllCalendars() {
        let calendars = eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        DispatchQueue.main.async {
            self.allCalendars = calendars
        }
    }

    private func stopMonitoring() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        NotificationCenter.default.removeObserver(
            self,
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }

    @objc private func handleCalendarStoreChanged() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            [weak self] _ in
            self?.fetchAllCalendars()
            self?.fetchTodaysEvents()
            self?.fetchTomorrowsEvents()
            self?.fetchNextEvent()
        }
    }

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            if granted && error == nil {
                self?.fetchAllCalendars()
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
            filtered = filtered.filter { allowList.contains($0.calendar.calendarIdentifier) }
        }
        if !denyList.isEmpty {
            filtered = filtered.filter { !denyList.contains($0.calendar.calendarIdentifier) }
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

import Combine
import EventKit
import Foundation

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    private var config: ConfigData? {
        ConfigManager.shared.config.rootToml.widgets
            .config(for: "default.time")?["calendar"]?.dictionaryValue
    }

    private var showEvents: Bool {
        config?["show-events"]?.boolValue ?? true
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
    private var hasAccess = false

    private init() {
        // Listen for config changes to enable/disable monitoring
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: Notification.Name("ConfigDidChange"),
            object: nil)

        // Only start if enabled
        if showEvents {
            requestAccess()
            startMonitoring()
        }
    }

    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func configDidChange() {
        if showEvents && timer == nil {
            requestAccess()
            startMonitoring()
        } else if !showEvents && timer != nil {
            stopMonitoring()
            // Clear events when disabled
            DispatchQueue.main.async {
                self.nextEvent = nil
                self.todaysEvents = []
                self.tomorrowsEvents = []
            }
        }
    }

    private func startMonitoring() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            [weak self] _ in
            guard let self = self, self.hasAccess else { return }
            self.fetchTodaysEvents()
            self.fetchTomorrowsEvents()
            self.fetchNextEvent()
        }
        if hasAccess {
            fetchTodaysEvents()
            fetchTomorrowsEvents()
            fetchNextEvent()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            guard let self = self else { return }
            self.hasAccess = granted && error == nil
            if self.hasAccess {
                self.fetchTodaysEvents()
                self.fetchTomorrowsEvents()
                self.fetchNextEvent()
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
        guard hasAccess else { return }
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let calendar = Calendar.current
        guard
            let endOfDay = calendar.date(
                bySettingHour: 23, minute: 59, second: 59, of: now)
        else {
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
        guard hasAccess else { return }
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        guard
            let endOfDay = calendar.date(
                bySettingHour: 23, minute: 59, second: 59, of: now)
        else {
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
        guard hasAccess else { return }
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

import Combine
import Foundation
import UserNotifications

enum PomodoroPhase: String {
    case idle
    case working = "Working"
    case onBreak = "Break"
    case onLongBreak = "Long Break"
}

private class PomodoroNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()

    private let notificationDelegate = PomodoroNotificationDelegate()

    @Published var phase: PomodoroPhase = .idle
    @Published var timeRemaining: Int = 0
    @Published var completedSessions: Int = 0
    @Published var isPaused: Bool = false

    @Published var workDuration: Int = 25
    @Published var breakDuration: Int = 5
    @Published var longBreakDuration: Int = 15
    @Published var sessionsBeforeLongBreak: Int = 4

    var isActive: Bool { phase != .idle }

    var totalDuration: Int {
        switch phase {
        case .idle: return workDuration * 60
        case .working: return workDuration * 60
        case .onBreak: return breakDuration * 60
        case .onLongBreak: return longBreakDuration * 60
        }
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }

    private var timerCancellable: AnyCancellable?

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        requestNotificationPermission()
    }

    func start() {
        phase = .working
        timeRemaining = workDuration * 60
        isPaused = false
        startTimer()
    }

    func pause() {
        isPaused = true
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func resume() {
        isPaused = false
        startTimer()
    }

    func reset() {
        timerCancellable?.cancel()
        timerCancellable = nil
        phase = .idle
        timeRemaining = 0
        completedSessions = 0
        isPaused = false
    }

    func skip() {
        timerCancellable?.cancel()
        timerCancellable = nil
        transitionToNextPhase()
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard timeRemaining > 0 else { return }
        timeRemaining -= 1
        if timeRemaining == 0 {
            timerCancellable?.cancel()
            timerCancellable = nil
            sendNotification()
            transitionToNextPhase()
        }
    }

    private func transitionToNextPhase() {
        switch phase {
        case .idle:
            break
        case .working:
            completedSessions += 1
            if completedSessions >= sessionsBeforeLongBreak {
                phase = .onLongBreak
                timeRemaining = longBreakDuration * 60
                completedSessions = 0
            } else {
                phase = .onBreak
                timeRemaining = breakDuration * 60
            }
            isPaused = false
            startTimer()
        case .onBreak, .onLongBreak:
            phase = .working
            timeRemaining = workDuration * 60
            isPaused = false
            startTimer()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        switch phase {
        case .working:
            content.title = "Pomodoro Complete"
            content.body = "Time for a break!"
        case .onBreak, .onLongBreak:
            content.title = "Break Over"
            content.body = "Ready to focus?"
        case .idle:
            return
        }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

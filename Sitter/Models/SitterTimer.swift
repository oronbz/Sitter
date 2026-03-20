import Foundation
import Observation

enum TimerState {
    case running
    case paused
    case expired
}

extension Notification.Name {
    static let timerSwitchAction = Notification.Name("SitterTimerSwitchAction")
    static let timerDismissAction = Notification.Name("SitterTimerDismissAction")
}

@Observable
class SitterTimer {
    var currentPosition: Position = .standing
    var remainingSeconds: Int
    var state: TimerState = .paused

    var sittingDurationMinutes: Int {
        didSet { UserDefaults.standard.set(sittingDurationMinutes, forKey: "sittingDuration") }
    }
    var standingDurationMinutes: Int {
        didSet { UserDefaults.standard.set(standingDurationMinutes, forKey: "standingDuration") }
    }

    private var timer: Timer?
    private var systemEventMonitor: SystemEventMonitor?
    private var wasRunningBeforeSystemEvent = false
    private var switchObserver: Any?
    private var dismissObserver: Any?

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var currentDurationSeconds: Int {
        switch currentPosition {
        case .sitting: sittingDurationMinutes * 60
        case .standing: standingDurationMinutes * 60
        }
    }

    init() {
        UserDefaults.standard.register(defaults: [
            "sittingDuration": 30,
            "standingDuration": 30,
        ])

        let sitting = UserDefaults.standard.integer(forKey: "sittingDuration")
        let standing = UserDefaults.standard.integer(forKey: "standingDuration")
        self.sittingDurationMinutes = sitting > 0 ? sitting : 30
        self.standingDurationMinutes = standing > 0 ? standing : 30
        self.remainingSeconds = (standing > 0 ? standing : 30) * 60

        systemEventMonitor = SystemEventMonitor(
            onSleep: { [weak self] in self?.handleSystemSleep() },
            onWake: { [weak self] in self?.handleSystemWake() }
        )

        switchObserver = NotificationCenter.default.addObserver(
            forName: .timerSwitchAction, object: nil, queue: .main
        ) { [weak self] _ in
            self?.switchPosition()
        }

        dismissObserver = NotificationCenter.default.addObserver(
            forName: .timerDismissAction, object: nil, queue: .main
        ) { _ in
            // Timer is already expired/paused — nothing to do
        }
    }

    func start() {
        guard state != .running else { return }
        if state == .expired {
            remainingSeconds = currentDurationSeconds
        }
        state = .running
        startTickTimer()
    }

    func pause() {
        state = .paused
        stopTickTimer()
    }

    func togglePauseResume() {
        if state == .running { pause() } else { start() }
    }

    func switchPosition() {
        stopTickTimer()
        currentPosition = currentPosition.next
        remainingSeconds = currentDurationSeconds
        state = .running
        startTickTimer()
    }

    func restart() {
        stopTickTimer()
        remainingSeconds = currentDurationSeconds
        state = .running
        startTickTimer()
    }

    // MARK: - System Events

    private func handleSystemSleep() {
        print("[Sitter] handleSystemSleep — state=\(state), wasRunning=\(wasRunningBeforeSystemEvent)")
        if state == .running {
            wasRunningBeforeSystemEvent = true
            pause()
            print("[Sitter] → paused timer, wasRunning=true")
        } else {
            print("[Sitter] → ignored (not running)")
        }
    }

    private func handleSystemWake() {
        print("[Sitter] handleSystemWake — state=\(state), wasRunning=\(wasRunningBeforeSystemEvent)")
        if wasRunningBeforeSystemEvent {
            wasRunningBeforeSystemEvent = false
            start()
            print("[Sitter] → resumed timer")
        } else {
            print("[Sitter] → ignored (wasn't running before)")
        }
    }

    // MARK: - Private

    private func startTickTimer() {
        stopTickTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTickTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            state = .expired
            stopTickTimer()
            NotificationManager.shared.sendTimerExpiredNotification(position: currentPosition)
        }
    }
}

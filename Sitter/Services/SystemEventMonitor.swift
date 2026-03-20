import AppKit
import Foundation

class SystemEventMonitor {
    private let onSleep: () -> Void
    private let onWake: () -> Void

    init(onSleep: @escaping () -> Void, onWake: @escaping () -> Void) {
        self.onSleep = onSleep
        self.onWake = onWake

        let workspace = NSWorkspace.shared.notificationCenter

        // System sleep / wake (lid close, idle sleep)
        workspace.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[Sitter] 🔔 willSleepNotification")
            self?.onSleep()
        }

        workspace.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[Sitter] 🔔 didWakeNotification")
            self?.onWake()
        }

        // Display sleep / wake (often coincides with screen lock)
        workspace.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[Sitter] 🔔 screensDidSleepNotification")
            self?.onSleep()
        }

        workspace.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[Sitter] 🔔 screensDidWakeNotification")
            self?.onWake()
        }

        // Explicit screen lock / unlock (Cmd+Ctrl+Q, screensaver)
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[Sitter] 🔔 screenIsLocked")
            self?.onSleep()
        }

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            print("[Sitter] 🔔 screenIsUnlocked")
            self?.onWake()
        }
    }
}

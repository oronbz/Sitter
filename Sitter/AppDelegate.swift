import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let switchAction = UNNotificationAction(
            identifier: "SWITCH_ACTION",
            title: "Switch",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "TIMER_EXPIRED",
            actions: [switchAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("[Sitter] Notification permission error: \(error)")
            } else {
                print("[Sitter] Notification permission granted: \(granted)")
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let name = switch response.actionIdentifier {
        case "SWITCH_ACTION": Notification.Name("SitterTimerSwitchAction")
        default: Notification.Name("SitterTimerDismissAction")
        }
        await MainActor.run {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
}

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
        let content = response.notification.request.content

        switch response.actionIdentifier {
        case "SWITCH_ACTION":
            let userInfo: [String: Any]
            if let raw = content.userInfo["targetPosition"] as? String,
               let target = Position(rawValue: raw) {
                userInfo = ["targetPosition": target]
            } else {
                userInfo = [:]
            }
            await MainActor.run {
                NotificationCenter.default.post(name: .timerSwitchAction, object: nil, userInfo: userInfo)
            }
        default:
            await MainActor.run {
                NotificationCenter.default.post(name: .timerDismissAction, object: nil)
            }
        }
    }
}

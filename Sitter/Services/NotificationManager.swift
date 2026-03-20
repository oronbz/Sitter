import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func sendTimerExpiredNotification(position: Position) {
        let center = UNUserNotificationCenter.current()
        let nextVerb = position.next.verb

        // Update category with dynamic action title, then send
        let switchAction = UNNotificationAction(
            identifier: "SWITCH_ACTION",
            title: nextVerb,
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "TIMER_EXPIRED",
            actions: [switchAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])

        let content = UNMutableNotificationContent()
        content.title = "Time to \(nextVerb.lowercased())!"
        content.body = "Your \(position.label.lowercased()) session is complete."
        content.sound = .default
        content.categoryIdentifier = "TIMER_EXPIRED"

        let request = UNNotificationRequest(
            identifier: "timer-expired-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        print("[Sitter] Sending notification: \(content.title) — button: \(nextVerb)")
        center.add(request) { error in
            if let error {
                print("[Sitter] ❌ Notification error: \(error)")
            } else {
                print("[Sitter] ✅ Notification sent")
            }
        }
    }
}

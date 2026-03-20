import SwiftUI

@main
struct SitterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var timer = SitterTimer()

    var body: some Scene {
        MenuBarExtra {
            TimerPopoverView(timer: timer)
                .frame(width: 320)
        } label: {
            Image(systemName: timer.currentPosition.sfSymbol)
            Text(timer.state == .expired ? "\(timer.currentPosition.next.verb)!" : timer.formattedTime)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(timer: timer)
        }
    }
}

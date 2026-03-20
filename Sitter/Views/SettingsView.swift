import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var timer: SitterTimer
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            TextField(
                "Sitting (min):",
                value: $timer.sittingDurationMinutes,
                format: .number
            )
            TextField(
                "Standing (min):",
                value: $timer.standingDurationMinutes,
                format: .number
            )
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to update login item: \(error)")
                        launchAtLogin = !newValue
                    }
                }
        }
        .padding()
        .frame(width: 300)
        .fixedSize()
        .onAppear {
            NSApplication.shared.activate()
            for window in NSApplication.shared.windows where window.title.contains("Settings") {
                window.level = .floating
            }
        }
    }
}

#Preview {
    SettingsView(timer: SitterTimer())
}

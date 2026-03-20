import SwiftUI

struct TimerPopoverView: View {
    @Bindable var timer: SitterTimer

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: timer.currentPosition.sfSymbol)
                    .font(.title)
                Text(timer.currentPosition.label)
                    .font(.title2.bold())
            }

            Text(timer.formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(timer.state == .expired ? .red : .primary)

            if timer.state == .expired {
                Text("Session complete!")
                    .foregroundStyle(.secondary)
            } else if timer.state == .paused {
                Text("Paused")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if timer.state != .expired {
                    Button(action: timer.togglePauseResume) {
                        Label(
                            timer.state == .running ? "Pause" : "Resume",
                            systemImage: timer.state == .running ? "pause.fill" : "play.fill"
                        )
                    }
                }

                Button(action: timer.switchPosition) {
                    Label(
                        timer.currentPosition.next.verb,
                        systemImage: timer.currentPosition.next.sfSymbol
                    )
                }

                Button(action: timer.restart) {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
            }
            .fixedSize()
            .buttonStyle(.bordered)

            Divider()

            HStack {
                SettingsLink {
                    Text("Settings...")
                }
                .simultaneousGesture(TapGesture().onEnded {
                    NSApplication.shared.activate()
                })
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .font(.caption)
        }
        .padding()
    }
}

#Preview {
    TimerPopoverView(timer: SitterTimer())
        .frame(width: 320)
}

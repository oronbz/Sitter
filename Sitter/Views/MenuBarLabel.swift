import SwiftUI

struct MenuBarLabel: View {
    let timer: SitterTimer

    var body: some View {
        let displayText = timer.state == .expired ? "Done" : timer.formattedTime
        Label(displayText, systemImage: timer.currentPosition.sfSymbol)
    }
}

#Preview {
    MenuBarLabel(timer: SitterTimer())
}

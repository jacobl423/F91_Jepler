import SwiftUI

@main
struct F91JeplerEmulatorApp: App {
    var body: some Scene {
        WindowGroup("F-91 Jepler Emulator & Debugger") {
            ContentView()
                .frame(minWidth: 900, minHeight: 650)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}

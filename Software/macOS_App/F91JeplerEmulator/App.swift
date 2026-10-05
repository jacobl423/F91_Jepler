import SwiftUI

@main
struct F91JeplerEmulatorApp: App {
    var body: some Scene {
        WindowGroup("Jepler Dev") {
            ContentView()
                .frame(minWidth: 860, minHeight: 620)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}

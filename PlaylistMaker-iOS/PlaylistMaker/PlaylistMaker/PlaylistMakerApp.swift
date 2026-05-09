import SwiftUI
@main
struct PlaylistMakerApp: App {
    @StateObject private var state = PlaylistAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
        }
    }
}

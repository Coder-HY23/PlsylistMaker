import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            switch state.step {
            case .input:
                InputView()
            case .results:
                RecommendationsView()
            case .confirm:
                ConfirmView()
            case .done:
                ResultView()
            }
        }
        .onOpenURL { url in
            if url.scheme == "playlistmaker" {
                Task { await state.handleSpotifyCallback(url) }
            }
        }
    }
}

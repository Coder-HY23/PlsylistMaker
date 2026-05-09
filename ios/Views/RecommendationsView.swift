import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        List {
            Section("Recommendations") {
                ForEach(state.tracks) { track in
                    VStack(alignment: .leading) {
                        Text(track.title).font(.headline)
                        Text(track.artist).font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Review")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    state.step = .confirm
                }
                .disabled(state.tracks.isEmpty)
            }
        }
    }
}

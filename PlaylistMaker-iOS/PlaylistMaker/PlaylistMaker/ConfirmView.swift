import SwiftUI

struct ConfirmView: View {
    @EnvironmentObject private var state: PlaylistAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create playlist?")
                .font(.title2)
                .bold()

            Picker("Provider", selection: $state.provider) {
                ForEach(Provider.enabledProviders, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .disabled(true)

            Text("Spotify is temporarily disabled for this build.")
                .font(.footnote)
                .foregroundColor(.orange)

            Text("Apple Music will be created on-device via MusicKit.")
                .foregroundColor(.secondary)

            Button {
                Task { await createPlaylist() }
            } label: {
                HStack {
                    if state.isLoading { ProgressView() }
                    Text("Create Playlist")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.isLoading || state.tracks.isEmpty)

            Spacer()
        }
        .padding()
        .navigationTitle("Confirm")
        .onAppear {
            if !Provider.enabledProviders.contains(state.provider) {
                state.provider = .appleMusic
            }
        }
    }

    @MainActor
    private func createPlaylist() async {
        state.isLoading = true
        defer { state.isLoading = false }

        if state.provider == .spotify {
            state.result = CreateResult(
                success: false,
                message: "Spotify is temporarily disabled for this build.",
                url: nil
            )
        } else {
            state.result = CreateResult(success: true, message: "Apple Music flow not wired yet", url: nil)
        }
        state.step = .done
    }
}

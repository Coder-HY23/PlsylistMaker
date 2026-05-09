import SwiftUI

struct ConfirmView: View {
    @EnvironmentObject private var state: PlaylistAppState
    @State private var showSpotifyAuth = false
    @State private var spotifyAuthURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create playlist?")
                .font(.title2)
                .bold()

            Picker("Provider", selection: $state.provider) {
                ForEach(Provider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)

            if state.provider == .spotify {
                if let token = state.spotifyAccessToken, !token.isEmpty {
                    Text("Spotify connected")
                        .foregroundColor(.green)
                } else {
                    Button("Connect Spotify") {
                        Task { await startSpotifyAuth() }
                    }
                    .buttonStyle(.bordered)

                    if let error = state.spotifyAuthError {
                        Text(error).foregroundColor(.red)
                    }
                }
            } else {
                Text("Apple Music will be created on-device via MusicKit.")
                    .foregroundColor(.secondary)
            }

            Button {
                Task { await createPlaylist() }
            } label: {
                HStack {
                    if state.isLoading { ProgressView() }
                    Text("Create Playlist")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.isLoading || state.tracks.isEmpty || (state.provider == .spotify && state.spotifyAccessToken == nil))

            Spacer()
        }
        .padding()
        .navigationTitle("Confirm")
        .sheet(isPresented: $showSpotifyAuth) {
            if let url = spotifyAuthURL {
                SafariView(url: url)
            }
        }
        .onChange(of: state.spotifyAccessToken) { _ in
            showSpotifyAuth = false
        }
    }

    @MainActor
    private func createPlaylist() async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            if state.provider == .spotify {
                guard let token = state.spotifyAccessToken else {
                    state.result = CreateResult(success: false, message: "Spotify not connected", url: nil)
                    state.step = .done
                    return
                }
                let result = try await state.api.createSpotifyPlaylist(
                    accessToken: token,
                    name: "PlaylistMaker",
                    tracks: state.tracks
                )
                state.result = result
            } else {
                state.result = CreateResult(success: true, message: "Apple Music flow not wired yet", url: nil)
            }
            state.step = .done
        } catch {
            state.result = CreateResult(
                success: false,
                message: "Failed to create: \(error.localizedDescription)",
                url: nil
            )
            state.step = .done
        }
    }

    @MainActor
    private func startSpotifyAuth() async {
        state.spotifyAuthError = nil
        do {
            let url = try await state.api.spotifyAuthorizeURL()
            spotifyAuthURL = url
            showSpotifyAuth = true
        } catch {
            state.spotifyAuthError = "Failed to start Spotify auth: \(error.localizedDescription)"
        }
    }
}

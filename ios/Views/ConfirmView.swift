import SwiftUI

struct ConfirmView: View {
    @EnvironmentObject private var state: AppState

    private var palette: MessengerPalette {
        state.interfaceTheme.palette
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create playlist?")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.textPrimary)

                        Text("Name: \(state.resolvedPlaylistName)")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .messengerCard(palette, padding: 18)

                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Provider", selection: $state.provider) {
                            ForEach(Provider.enabledProviders, id: \.self) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(true)
                        .tint(palette.primary)

                        Text("Spotify is temporarily disabled for this build.")
                            .font(.footnote)
                            .foregroundStyle(palette.warning)

                        Text("Apple Music will be created on-device via MusicKit.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .messengerCard(palette)

                    Button {
                        Task { await createPlaylist() }
                    } label: {
                        HStack(spacing: 8) {
                            if state.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Create Playlist")
                        }
                    }
                    .buttonStyle(MessengerPrimaryButtonStyle(palette: palette))
                    .disabled(state.isLoading || state.tracks.isEmpty)
                    .opacity((state.isLoading || state.tracks.isEmpty) ? 0.6 : 1.0)
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Confirm")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    state.step = .results
                }
                .foregroundStyle(palette.primary)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(palette.surface, for: .navigationBar)
        .toolbarColorScheme(palette.isDark ? .dark : .light, for: .navigationBar)
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

        do {
            if state.provider == .spotify {
                state.result = CreateResult(
                    success: false,
                    message: "Spotify is temporarily disabled for this build.",
                    url: nil
                )
            } else {
                state.result = try await state.api.createAppleMusicPlaylist(
                    name: state.resolvedPlaylistName,
                    tracks: state.tracks
                )
            }
        } catch {
            state.result = CreateResult(
                success: false,
                message: "Failed to create: \(error.localizedDescription)",
                url: nil
            )
        }
        state.step = .done
    }
}

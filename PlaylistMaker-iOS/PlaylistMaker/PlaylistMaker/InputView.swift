import SwiftUI

struct InputView: View {
    @EnvironmentObject private var state: PlaylistAppState

    private var palette: MessengerPalette {
        state.interfaceTheme.palette
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    playlistSection
                    settingsSection
                    generateButton
                }
                .padding(16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playlist Details")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Playlist name")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)

                TextField("PlaylistMaker", text: $state.playlistName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(palette.inputBackground)
                    )
                    .foregroundStyle(palette.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)

                TextEditor(text: $state.prompt)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(palette.inputBackground)
                    )
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(palette.textPrimary)
            }
        }
        .messengerCard(palette)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Track Settings")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Stepper(value: $state.count, in: 5...50, step: 5) {
                Text("Tracks: \(state.count)")
                    .foregroundStyle(palette.textPrimary)
            }
            .tint(palette.primary)

            Toggle("Limit tracks per same artist", isOn: $state.limitTracksPerArtist)
                .foregroundStyle(palette.textPrimary)
                .tint(palette.primary)

            if state.limitTracksPerArtist {
                Stepper(value: $state.maxTracksPerArtist, in: 1...10) {
                    Text("Max per artist: \(state.maxTracksPerArtist)")
                        .foregroundStyle(palette.textPrimary)
                }
                .tint(palette.primary)
            }
        }
        .messengerCard(palette)
    }

    private var generateButton: some View {
        Button {
            Task {
                await generate()
            }
        } label: {
            HStack(spacing: 8) {
                if state.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text("Generate Playlist")
            }
        }
        .buttonStyle(MessengerPrimaryButtonStyle(palette: palette))
        .disabled(state.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isLoading)
        .opacity((state.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isLoading) ? 0.6 : 1.0)
    }

    @MainActor
    private func generate() async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let tracks = try await state.api.recommend(
                prompt: state.prompt,
                count: state.count,
                maxTracksPerArtist: state.maxTracksPerArtistLimit
            )
            state.tracks = tracks
            state.step = .results
        } catch {
            state.result = CreateResult(
                success: false,
                message: "Failed to generate: \(error.localizedDescription)",
                url: nil
            )
            state.step = .done
        }
    }
}

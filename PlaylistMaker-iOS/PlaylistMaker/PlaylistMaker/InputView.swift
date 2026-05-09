import SwiftUI

struct InputView: View {
    @EnvironmentObject private var state: PlaylistAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PlaylistMaker")
                .font(.largeTitle)
                .bold()

            Text("Describe the playlist you want")
                .font(.headline)

            TextEditor(text: $state.prompt)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            Stepper(value: $state.count, in: 5...50, step: 5) {
                Text("Tracks: \(state.count)")
            }

            Button {
                Task {
                    await generate()
                }
            } label: {
                HStack {
                    if state.isLoading { ProgressView() }
                    Text("Generate")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isLoading)

            Spacer()
        }
        .padding()
    }

    @MainActor
    private func generate() async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let tracks = try await state.api.recommend(prompt: state.prompt, count: state.count)
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

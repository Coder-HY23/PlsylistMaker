import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var state: PlaylistAppState

    var body: some View {
        VStack(spacing: 16) {
            Text(state.result?.success == true ? "Done" : "Error")
                .font(.largeTitle)
                .bold()

            Text(state.result?.message ?? "")

            if let url = state.result?.url {
                Text(url.absoluteString)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            Button("Back to Input") {
                state.backToInput()
            }
            .buttonStyle(.borderedProminent)

            Button("Start Over") {
                state.reset()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

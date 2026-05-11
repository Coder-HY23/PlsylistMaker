import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var state: AppState

    private var palette: MessengerPalette {
        state.interfaceTheme.palette
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Image(systemName: state.result?.success == true ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(state.result?.success == true ? palette.success : palette.danger)

                    Text(state.result?.success == true ? "Done" : "Error")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)

                    Text(state.result?.message ?? "")
                        .font(.body)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)

                    if let url = state.result?.url {
                        Text(url.absoluteString)
                            .font(.footnote)
                            .foregroundStyle(palette.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                .messengerCard(palette, padding: 20)

                Button("Back to Input") {
                    state.backToInput()
                }
                .buttonStyle(MessengerPrimaryButtonStyle(palette: palette))

                Button("Start Over") {
                    state.reset()
                }
                .buttonStyle(MessengerSecondaryButtonStyle(palette: palette))
            }
            .padding(16)
        }
    }
}

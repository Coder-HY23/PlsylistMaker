import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var state: AppState

    private var palette: MessengerPalette {
        state.interfaceTheme.palette
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    summaryCard

                    ForEach(Array(state.tracks.enumerated()), id: \.element.id) { index, track in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(palette.primary)
                                    .frame(width: 28, height: 28)
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.headline)
                                    .foregroundStyle(palette.textPrimary)
                                Text(track.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(palette.textSecondary)
                            }
                        }
                        .messengerCard(palette, padding: 14)
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Review")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    state.step = .input
                }
                .foregroundStyle(palette.primary)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    state.step = .confirm
                }
                .foregroundStyle(palette.primary)
                .disabled(state.tracks.isEmpty)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(palette.surface, for: .navigationBar)
        .toolbarColorScheme(palette.isDark ? .dark : .light, for: .navigationBar)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Tracks")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Text("\(state.tracks.count) songs are ready for playlist creation.")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .messengerCard(palette, padding: 18)
    }
}

import Foundation

enum FlowStep {
    case input
    case results
    case confirm
    case done
}

enum Provider: String, CaseIterable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"

    static var enabledProviders: [Provider] {
        [.appleMusic]
    }
}

struct Track: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var artist: String
}

struct CreateResult {
    var success: Bool
    var message: String
    var url: URL?
}

@MainActor
final class AppState: ObservableObject {
    @Published var step: FlowStep = .input
    @Published var playlistName: String = "PlaylistMaker"
    @Published var prompt: String = ""
    @Published var count: Int = 20
    @Published var limitTracksPerArtist: Bool = false
    @Published var maxTracksPerArtist: Int = 2
    @Published var tracks: [Track] = []
    @Published var provider: Provider = .appleMusic
    @Published var isLoading: Bool = false
    @Published var result: CreateResult? = nil
    @Published var spotifyAccessToken: String? = nil
    @Published var spotifyAuthError: String? = nil

    let api = APIService()

    func reset() {
        step = .input
        playlistName = "PlaylistMaker"
        prompt = ""
        count = 20
        limitTracksPerArtist = false
        maxTracksPerArtist = 2
        tracks = []
        provider = .appleMusic
        isLoading = false
        result = nil
        spotifyAccessToken = nil
        spotifyAuthError = nil
    }

    func handleSpotifyCallback(_ url: URL) async {
        guard let code = url.queryParameters?["code"], !code.isEmpty else {
            spotifyAuthError = "Missing auth code"
            return
        }

        do {
            let token = try await api.exchangeSpotifyCode(code: code)
            spotifyAccessToken = token
            spotifyAuthError = nil
        } catch {
            spotifyAuthError = "Spotify auth failed"
        }
    }

    var resolvedPlaylistName: String {
        let trimmed = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "PlaylistMaker" : trimmed
    }

    var maxTracksPerArtistLimit: Int? {
        limitTracksPerArtist ? max(1, maxTracksPerArtist) : nil
    }
}

private extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return nil
        }
        var dict: [String: String] = [:]
        for item in items {
            dict[item.name] = item.value ?? ""
        }
        return dict
    }
}

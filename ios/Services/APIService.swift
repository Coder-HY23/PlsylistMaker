import Foundation
import MusicKit

final class APIService {
    private let baseURL = URL(string: "https://your-vercel-app.vercel.app")!

    func recommend(prompt: String, count: Int, maxTracksPerArtist: Int? = nil) async throws -> [Track] {
        let url = baseURL.appendingPathComponent("/api/recommend")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: Any] = [
            "prompt": prompt,
            "count": count
        ]
        if let maxTracksPerArtist {
            payload["maxTracksPerArtist"] = maxTracksPerArtist
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = decoded?["tracks"] as? [[String: String]] ?? []
        return items.compactMap { item in
            if let title = item["title"], let artist = item["artist"] {
                return Track(title: title, artist: artist)
            }
            return nil
        }
    }

    func createSpotifyPlaylist(accessToken: String, name: String, tracks: [Track]) async throws -> CreateResult {
        let url = baseURL.appendingPathComponent("/api/spotify/create-playlist")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let trackPayload = tracks.map { ["title": $0.title, "artist": $0.artist] }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "access_token": accessToken,
            "name": name,
            "tracks": trackPayload
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let urlString = decoded?["playlist_url"] as? String
        return CreateResult(
            success: true,
            message: "Created successfully",
            url: urlString != nil ? URL(string: urlString!) : nil
        )
    }

    func spotifyAuthorizeURL() async throws -> URL {
        let url = baseURL.appendingPathComponent("/api/spotify/authorize-url")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let urlString = decoded?["url"] as? String, let authURL = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        return authURL
    }

    func exchangeSpotifyCode(code: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/spotify/callback")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = decoded?["access_token"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        return token
    }

    func createAppleMusicPlaylist(name: String, tracks: [Track]) async throws -> CreateResult {
        guard !tracks.isEmpty else {
            throw AppleMusicError.noTracksProvided
        }

        let currentStatus = MusicAuthorization.currentStatus
        let authorization = currentStatus == .notDetermined
            ? await MusicAuthorization.request()
            : currentStatus

        guard authorization == .authorized else {
            throw AppleMusicError.authorizationDenied
        }

        let subscription = try await MusicSubscription.current
        guard subscription.canPlayCatalogContent else {
            throw AppleMusicError.subscriptionRequired
        }
        guard subscription.hasCloudLibraryEnabled else {
            throw AppleMusicError.cloudLibraryDisabled
        }

        var matchedSongs: [Song] = []
        var missingCount = 0

        for track in tracks {
            if let song = try await findCatalogSong(title: track.title, artist: track.artist) {
                matchedSongs.append(song)
            } else {
                missingCount += 1
            }
        }

        guard !matchedSongs.isEmpty else {
            throw AppleMusicError.noTracksMatched
        }

        let playlist = try await MusicLibrary.shared.createPlaylist(
            name: name,
            description: "Generated by PlaylistMaker",
            authorDisplayName: nil
        )
        try await MusicLibrary.shared.edit(playlist, items: matchedSongs)

        var message = "Created in Apple Music: added \(matchedSongs.count), missing \(missingCount)"
        if missingCount > 0 {
            message += "\nSome recommendations were not found in Apple Music catalog."
        }
        return CreateResult(success: true, message: message, url: nil)
    }

    private func findCatalogSong(title: String, artist: String) async throws -> Song? {
        let term = "\(title) \(artist)".trimmingCharacters(in: .whitespacesAndNewlines)
        var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
        request.limit = 10
        let response = try await request.response()

        let normalizedTitle = normalize(title)
        let normalizedArtist = normalize(artist)

        if let exact = response.songs.first(where: { song in
            normalize(song.title) == normalizedTitle &&
            normalize(song.artistName) == normalizedArtist
        }) {
            return exact
        }

        if let close = response.songs.first(where: { song in
            normalize(song.title).contains(normalizedTitle) ||
            normalize(song.artistName).contains(normalizedArtist)
        }) {
            return close
        }

        return response.songs.first
    }

    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
    }
}

private enum AppleMusicError: LocalizedError {
    case authorizationDenied
    case subscriptionRequired
    case cloudLibraryDisabled
    case noTracksProvided
    case noTracksMatched

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Apple Music access was denied."
        case .subscriptionRequired:
            return "An active Apple Music subscription is required."
        case .cloudLibraryDisabled:
            return "Sync Library is disabled in Apple Music settings."
        case .noTracksProvided:
            return "No tracks were provided to create a playlist."
        case .noTracksMatched:
            return "No matching tracks were found in Apple Music catalog."
        }
    }
}

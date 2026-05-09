import Foundation

final class APIService {
    private let baseURL = URL(string: "https://your-vercel-app.vercel.app")!

    func recommend(prompt: String, count: Int) async throws -> [Track] {
        let url = baseURL.appendingPathComponent("/api/recommend")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "prompt": prompt,
            "count": count
        ])

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
}

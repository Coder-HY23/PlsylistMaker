import Foundation

final class APIService {
    private let baseURL = URL(string: "https://playlistmaker-backend.vercel.app")!

    func recommend(prompt: String, count: Int) async throws -> [Track] {
        let url = endpoint(["api", "recommend"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "prompt": prompt,
            "count": count
        ])

        let decoded = try await sendJSON(request)
        let items = decoded?["tracks"] as? [[String: String]] ?? []
        return items.compactMap { item in
            if let title = item["title"], let artist = item["artist"] {
                return Track(title: title, artist: artist)
            }
            return nil
        }
    }

    func createSpotifyPlaylist(accessToken: String, name: String, tracks: [Track]) async throws -> CreateResult {
        let url = endpoint(["api", "spotify", "create-playlist"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let trackPayload = tracks.map { ["title": $0.title, "artist": $0.artist] }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "access_token": accessToken,
            "name": name,
            "tracks": trackPayload
        ])

        let decoded = try await sendJSON(request)
        let urlString = decoded?["playlist_url"] as? String
        let added = decoded?["added_count"] as? Int ?? 0
        let missing = decoded?["missing_count"] as? Int ?? 0
        let skipped = decoded?["skipped_count"] as? Int ?? 0
        let note = decoded?["note"] as? String ?? ""
        var message = "Created: added \(added), missing \(missing)"
        if skipped > 0 {
            message += ", skipped \(skipped)"
        }
        if !note.isEmpty {
            message += "\n\(note)"
        }
        return CreateResult(
            success: true,
            message: message,
            url: urlString != nil ? URL(string: urlString!) : nil
        )
    }

    func spotifyAuthorizeURL() async throws -> URL {
        let url = endpoint(["api", "spotify", "authorize-url"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let decoded = try await sendJSON(request)
        guard let urlString = decoded?["url"] as? String, let authURL = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        return authURL
    }

    func exchangeSpotifyCode(code: String) async throws -> String {
        let url = endpoint(["api", "spotify", "callback"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code
        ])

        let decoded = try await sendJSON(request)
        guard let token = decoded?["access_token"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        return token
    }

    private func endpoint(_ parts: [String]) -> URL {
        parts.reduce(baseURL) { partial, part in
            partial.appendingPathComponent(part)
        }
    }

    private func sendJSON(_ request: URLRequest) async throws -> [String: Any]? {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(
                domain: "APIService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: detail]
            )
        }

        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

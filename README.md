# PlaylistMaker

iOS-first MVP for generating AI-recommended playlists and creating them in Spotify or Apple Music.

## Structure
- `backend/` Vercel serverless API (OpenAI + Spotify)
- `ios/` SwiftUI sample screens and state model

## Backend setup (local)
1. Copy env template:
   - `backend/.env.example` -> `backend/.env.local`
2. Fill in keys.
3. Run locally (one of):
   - `vercel dev` (recommended)

## iOS setup
Create a new Xcode project (App, SwiftUI, iOS) named `PlaylistMaker` and add the Swift files under `ios/` into the project.

## Notes
- Apple Music playlist creation is handled on-device via MusicKit in iOS.
- Spotify playlist creation is via backend to protect client secret.

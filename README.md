# PlaylistMaker

AIでプレイリスト候補を作り、Spotify/Apple Musicへ保存するiOS向けMVPです。

## Repository Structure
- `backend/`: Vercel Serverless API (OpenAI + Spotify)
- `ios/`: SwiftUIのサンプル実装
- `PlaylistMaker/`, `PlaylistMaker-iOS/`: Xcodeプロジェクト

## Prerequisites
- Node.js 18以上
- Vercel CLI
  - `npm i -g vercel`
- Xcode

## Backend Local Setup
`backend/` で実行します。

```bash
cd /Users/yuyahirama/Documents/EasyPFC/PlsylistMaker/backend
cp .env.example .env.local
```

`backend/.env.local` を開き、以下を実値で設定してください。

- `OPENAI_API_KEY`
- `OPENAI_MODEL` (例: `gpt-4.1-mini`)
- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `SPOTIFY_REDIRECT_URI` (例: `playlistmaker://spotify/callback`)
- `APP_URL` (例: `http://localhost:3000`)

次にVercelへログインしてローカル起動します。

```bash
vercel login
vercel dev --listen 127.0.0.1:3100
```

起動後、`http://127.0.0.1:3100` でAPIが待ち受けます。

## Backend Smoke Test
別ターミナルで以下を実行します。

```bash
curl -i http://127.0.0.1:3100/api/recommend
curl -i -X POST http://127.0.0.1:3100/api/recommend -H 'content-type: application/json' -d '{}'
curl -i -X POST http://127.0.0.1:3100/api/spotify/authorize-url -H 'content-type: application/json' -d '{}'
```

期待される代表レスポンス:

- `GET /api/recommend` -> `405 Method not allowed`
- `POST /api/recommend {}` -> `400 prompt is required`
- `POST /api/spotify/authorize-url {}` -> `200` (Spotify認可URLを返す)

## iOS Setup
次のいずれかで進めてください。

1. 既存プロジェクトを開く  
   - `PlaylistMaker/PlaylistMaker.xcodeproj`
   - `PlaylistMaker-iOS/PlaylistMaker/PlaylistMaker.xcodeproj`
2. 新規プロジェクトを作成し、`ios/` 配下のSwiftファイルを追加する

## Troubleshooting
- `No existing credentials found` が出る  
  - `vercel login` を再実行
- `Spotify env not set` が出る  
  - `backend/.env.local` のSpotify関連キーを確認
- `OPENAI_API_KEY is not set` が出る  
  - `backend/.env.local` のOpenAI関連キーを確認

## Security Notes
- `backend/.env.local` は機密情報を含むためコミットしないでください（`.gitignore` 済み）。
- SpotifyクライアントシークレットはiOS側に置かず、`backend/` 側でのみ扱ってください。

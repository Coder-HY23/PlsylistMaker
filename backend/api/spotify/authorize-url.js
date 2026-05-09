const {
  SPOTIFY_CLIENT_ID,
  SPOTIFY_REDIRECT_URI
} = process.env;

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  if (!SPOTIFY_CLIENT_ID || !SPOTIFY_REDIRECT_URI) {
    res.status(500).json({ error: "Spotify env not set" });
    return;
  }

  const scopes = [
    "playlist-modify-public",
    "playlist-modify-private"
  ].join(" ");

  const params = new URLSearchParams({
    response_type: "code",
    client_id: SPOTIFY_CLIENT_ID,
    scope: scopes,
    redirect_uri: SPOTIFY_REDIRECT_URI,
    state: Math.random().toString(36).slice(2)
  });

  const url = `https://accounts.spotify.com/authorize?${params.toString()}`;
  res.status(200).json({ url });
};

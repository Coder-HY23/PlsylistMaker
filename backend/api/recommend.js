const { OPENAI_API_KEY, OPENAI_MODEL } = process.env;

function getJsonBody(req) {
  if (req.body && typeof req.body === "object") return req.body;
  if (typeof req.body === "string") {
    try {
      return JSON.parse(req.body);
    } catch {
      return null;
    }
  }
  return null;
}

function extractOutputText(data) {
  if (data && typeof data.output_text === "string") return data.output_text;
  if (!data || !Array.isArray(data.output)) return "";
  for (const item of data.output) {
    if (item && item.type === "message" && Array.isArray(item.content)) {
      for (const c of item.content) {
        if (c.type === "output_text" && typeof c.text === "string") {
          return c.text;
        }
      }
    }
  }
  return "";
}

function parseModelJson(text) {
  if (typeof text !== "string") return null;

  const candidates = [];
  const trimmed = text.trim();
  if (trimmed) candidates.push(trimmed);

  // Handle ```json ... ``` blocks.
  const fenceMatch = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  if (fenceMatch && fenceMatch[1]) {
    candidates.push(fenceMatch[1].trim());
  }

  // Fallback: extract first JSON object-like region.
  const firstBrace = trimmed.indexOf("{");
  const lastBrace = trimmed.lastIndexOf("}");
  if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
    candidates.push(trimmed.slice(firstBrace, lastBrace + 1));
  }

  const unique = [...new Set(candidates)];
  for (const candidate of unique) {
    try {
      return JSON.parse(candidate);
    } catch {
      // try next candidate
    }
  }

  return null;
}

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  if (!OPENAI_API_KEY) {
    res.status(500).json({ error: "OPENAI_API_KEY is not set" });
    return;
  }

  const body = getJsonBody(req);
  const prompt = body?.prompt;
  const count = Math.max(1, Math.min(100, Number(body?.count || 20)));

  if (!prompt || typeof prompt !== "string") {
    res.status(400).json({ error: "prompt is required" });
    return;
  }

  const systemText =
    "You are a music recommendation engine. Return strict JSON only.";
  const userText =
    `User request: ${prompt}\n` +
    `Return JSON: {"tracks":[{"title":"...","artist":"..."}]}\n` +
    `Provide at least ${count} tracks.`;

  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: OPENAI_MODEL || "gpt-4.1-mini",
        input: [
          { role: "system", content: [{ type: "input_text", text: systemText }] },
          { role: "user", content: [{ type: "input_text", text: userText }] }
        ]
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      res.status(500).json({ error: "OpenAI request failed", details: errText });
      return;
    }

    const data = await response.json();
    const outputText = extractOutputText(data);

    const parsed = parseModelJson(outputText);
    if (!parsed) {
      res.status(500).json({
        error: "Failed to parse model output as JSON",
        raw: outputText
      });
      return;
    }

    const tracks = Array.isArray(parsed?.tracks) ? parsed.tracks : [];
    const normalized = tracks
      .filter((t) => t && typeof t.title === "string" && typeof t.artist === "string")
      .map((t) => ({ title: t.title.trim(), artist: t.artist.trim() }))
      .filter((t) => t.title && t.artist)
      .slice(0, count);

    res.status(200).json({ tracks: normalized });
  } catch (err) {
    res.status(500).json({ error: "Unexpected error", details: String(err) });
  }
};

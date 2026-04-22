export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, DELETE, OPTIONS",
};

export function authenticate(req: Request): Response | null {
  const authHeader = req.headers.get("authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  const validKey = Deno.env.get("PM_KNOWLEDGE_KEY");

  if (!validKey || token !== validKey) {
    return errorResponse("Unauthorized", 401);
  }
  return null;
}

export function errorResponse(message: string, status = 400): Response {
  return new Response(
    JSON.stringify({ error: message }),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(
    JSON.stringify(data),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}

/**
 * Chunk markdown by headers, with size limits.
 * Returns array of { section_header, content, chunk_index }
 */
export function chunkMarkdown(
  text: string,
  maxChunkChars = 2000,
  overlapChars = 200
): Array<{ section_header: string; content: string; chunk_index: number }> {
  const lines = text.split("\n");
  const sections: Array<{ header: string; lines: string[] }> = [];
  let currentHeader = "(document start)";
  let currentLines: string[] = [];

  for (const line of lines) {
    if (/^#{1,3}\s+/.test(line)) {
      if (currentLines.length > 0) {
        sections.push({ header: currentHeader, lines: [...currentLines] });
      }
      currentHeader = line.replace(/^#+\s+/, "").trim();
      currentLines = [line];
    } else {
      currentLines.push(line);
    }
  }

  if (currentLines.length > 0) {
    sections.push({ header: currentHeader, lines: [...currentLines] });
  }

  const chunks: Array<{ section_header: string; content: string; chunk_index: number }> = [];
  let chunkIndex = 0;
  let buffer = "";
  let bufferHeader = "";

  for (const section of sections) {
    const sectionText = section.lines.join("\n").trim();

    if (sectionText.length < 200 && buffer.length + sectionText.length < maxChunkChars) {
      buffer += (buffer ? "\n\n" : "") + sectionText;
      if (!bufferHeader) bufferHeader = section.header;
      continue;
    }

    if (buffer) {
      chunks.push({ section_header: bufferHeader, content: buffer, chunk_index: chunkIndex++ });
      buffer = "";
      bufferHeader = "";
    }

    if (sectionText.length <= maxChunkChars) {
      chunks.push({ section_header: section.header, content: sectionText, chunk_index: chunkIndex++ });
      continue;
    }

    const paragraphs = sectionText.split(/\n\n+/);
    let subChunk = "";

    for (const para of paragraphs) {
      if (subChunk.length + para.length + 2 > maxChunkChars) {
        if (subChunk) {
          chunks.push({ section_header: section.header, content: subChunk, chunk_index: chunkIndex++ });
          const overlapStart = Math.max(0, subChunk.length - overlapChars);
          subChunk = subChunk.substring(overlapStart) + "\n\n" + para;
        } else {
          chunks.push({ section_header: section.header, content: para, chunk_index: chunkIndex++ });
          subChunk = "";
        }
      } else {
        subChunk += (subChunk ? "\n\n" : "") + para;
      }
    }

    if (subChunk) {
      chunks.push({ section_header: section.header, content: subChunk, chunk_index: chunkIndex++ });
    }
  }

  if (buffer) {
    chunks.push({ section_header: bufferHeader, content: buffer, chunk_index: chunkIndex++ });
  }

  return chunks;
}

/**
 * Estimate token count (rough: 1 token ≈ 4 chars for multilingual)
 */
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

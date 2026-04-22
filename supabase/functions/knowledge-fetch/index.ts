import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { corsHeaders, authenticate, errorResponse, jsonResponse } from "../_shared/utils.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authError = authenticate(req);
    if (authError) return authError;

    const { document_id, filename } = await req.json();
    if (!document_id && !filename) {
      return errorResponse("Provide either 'document_id' or 'filename'", 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    let query = supabase
      .from("knowledge_documents")
      .select("*");

    if (document_id) {
      query = query.eq("id", document_id);
    } else {
      query = query.eq("filename", filename);
    }

    const { data: doc, error: docErr } = await query.maybeSingle();
    if (docErr) {
      return errorResponse(`Document lookup failed: ${docErr.message}`, 500);
    }
    if (!doc) {
      return errorResponse("Document not found", 404);
    }

    const { data: chunks = [], error: chunkErr } = await supabase
      .from("knowledge_chunks")
      .select("chunk_index, section_header, content, token_count")
      .eq("document_id", doc.id);

    if (chunkErr) {
      return errorResponse(`Chunk lookup failed: ${chunkErr.message}`, 500);
    }

    chunks.sort((a, b) => {
      if (a.chunk_index != null && b.chunk_index != null) {
        return a.chunk_index - b.chunk_index;
      }
      return 0;
    });

    return jsonResponse({
      filename: doc.filename,
      document: doc,
      total_chunks: chunks.length,
      content: chunks.map((chunk) => chunk.content || "").join("\n"),
      chunks: chunks.map((chunk) => ({
        chunk_index: chunk.chunk_index ?? null,
        section_header: chunk.section_header ?? null,
        token_count: chunk.token_count ?? null,
        content: chunk.content ?? "",
      })),
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(`Unexpected error: ${message}`, 500);
  }
});

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { corsHeaders, authenticate, errorResponse, jsonResponse, chunkMarkdown, estimateTokens } from "../_shared/utils.ts";

const MAX_CONTENT_SIZE = 512_000; // 500KB
const EMBEDDING_BATCH_SIZE = 50;  // OpenAI max per request

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authError = authenticate(req);
    if (authError) return authError;

    const body = await req.json();
    const { filename, doc_type, content, metadata = {} } = body;

    // Validate required fields
    if (!filename || !doc_type || !content) {
      return errorResponse("Missing required fields: filename, doc_type, content", 400);
    }
    if (content.length > MAX_CONTENT_SIZE) {
      return errorResponse(`Content too large: ${content.length} bytes (max ${MAX_CONTENT_SIZE})`, 400);
    }

    const validTypes = ["triaj", "re-triaj", "referinta", "spec", "consolidare", "draft", "registru", "codex", "arsenal", "briefuri", "cercetare", "exercitii", "matrice", "prompt", "status", "extragere", "alt"];
    if (!validTypes.includes(doc_type)) {
      return errorResponse(`Invalid doc_type. Valid: ${validTypes.join(", ")}`, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Check if document already exists
    const { data: existing } = await supabase
      .from("knowledge_documents")
      .select("id")
      .eq("filename", filename)
      .maybeSingle();

    if (existing) {
      // Delete old version (cascade deletes chunks too)
      await supabase.from("knowledge_documents").delete().eq("id", existing.id);
    }

    // 1. Chunk the markdown
    const chunks = chunkMarkdown(content);

    // 2. Get embeddings from OpenAI in batches
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) return errorResponse("OPENAI_API_KEY not configured", 500);

    const allEmbeddings: number[][] = [];
    for (let i = 0; i < chunks.length; i += EMBEDDING_BATCH_SIZE) {
      const batch = chunks.slice(i, i + EMBEDDING_BATCH_SIZE);
      const embeddingRes = await fetch("https://api.openai.com/v1/embeddings", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${openaiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "text-embedding-3-small",
          input: batch.map((c) => c.content),
        }),
      });

      if (!embeddingRes.ok) {
        const err = await embeddingRes.text();
        return errorResponse(`OpenAI embedding failed: ${err}`, 502);
      }

      const embData = await embeddingRes.json();
      for (const item of embData.data) {
        allEmbeddings.push(item.embedding);
      }
    }

    // 3. Insert document
    const lineCount = content.split("\n").length;
    const { data: doc, error: docError } = await supabase
      .from("knowledge_documents")
      .insert({
        filename,
        doc_type,
        title: metadata.title || null,
        author: metadata.author || null,
        year: metadata.year || null,
        verdict: metadata.verdict || null,
        version: metadata.version || null,
        axes_relevant: metadata.axes_relevant || null,
        line_count: lineCount,
        source_date: metadata.source_date || null,
        full_text: content,
        metadata: metadata.extra || {},
      })
      .select("id")
      .single();

    if (docError) return errorResponse(`Insert document failed: ${docError.message}`, 500);

    // 4. Insert chunks with embeddings
    const chunkRows = chunks.map((c, i) => ({
      document_id: doc.id,
      chunk_index: c.chunk_index,
      content: c.content,
      section_header: c.section_header,
      token_count: estimateTokens(c.content),
      embedding: allEmbeddings[i],
    }));

    // Insert in batches of 20 to avoid payload limits
    let chunksInserted = 0;
    for (let i = 0; i < chunkRows.length; i += 20) {
      const batch = chunkRows.slice(i, i + 20);
      const { error: chunkError } = await supabase
        .from("knowledge_chunks")
        .insert(batch);

      if (chunkError) {
        // Rollback: delete the document
        await supabase.from("knowledge_documents").delete().eq("id", doc.id);
        return errorResponse(`Insert chunks failed at batch ${i}: ${chunkError.message}`, 500);
      }
      chunksInserted += batch.length;
    }

    const totalTokens = chunkRows.reduce((sum, c) => sum + (c.token_count || 0), 0);

    return jsonResponse({
      document_id: doc.id,
      filename,
      doc_type,
      replaced_existing: !!existing,
      chunks_created: chunksInserted,
      tokens_embedded: totalTokens,
    });
  } catch (e) {
    return errorResponse(`Unexpected error: ${e.message}`, 500);
  }
});

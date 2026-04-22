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

    // Find the document
    let query = supabase.from("knowledge_documents").select("id, filename");
    if (document_id) {
      query = query.eq("id", document_id);
    } else {
      query = query.eq("filename", filename);
    }

    const { data: doc, error: findError } = await query.maybeSingle();
    if (findError) return errorResponse(`Find failed: ${findError.message}`, 500);
    if (!doc) return errorResponse("Document not found", 404);

    // Count chunks before delete
    const { count } = await supabase
      .from("knowledge_chunks")
      .select("id", { count: "exact", head: true })
      .eq("document_id", doc.id);

    // Delete (cascade removes chunks)
    const { error: delError } = await supabase
      .from("knowledge_documents")
      .delete()
      .eq("id", doc.id);

    if (delError) return errorResponse(`Delete failed: ${delError.message}`, 500);

    return jsonResponse({
      deleted: true,
      filename: doc.filename,
      chunks_removed: count || 0,
    });
  } catch (e) {
    return errorResponse(`Unexpected error: ${e.message}`, 500);
  }
});

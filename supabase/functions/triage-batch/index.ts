import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { corsHeaders, authenticate, errorResponse, jsonResponse } from "../_shared/utils.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const AUTH_TOKEN = Deno.env.get("PM_KNOWLEDGE_KEY") ?? "pm_knowledge_2026_secure";

type IngestItem = {
  filename: string;
  doc_type: string;
  content: string;
  metadata?: Record<string, unknown>;
};

type CommitItem = {
  prefix: string; // N | C | T | B | S | IND
  assigned_ids: string[];
};

type BatchInput = {
  ingests: IngestItem[];
  deletes?: string[]; // filenames to delete
  commits?: CommitItem[]; // ID-uri de commit după rezervare
  source_label?: string; // ex: "Chen_Attachment_Workbook_2019" — pentru log
};

type StepResult = {
  step: string;
  target: string;
  success: boolean;
  detail?: unknown;
  error?: string;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const authError = authenticate(req);
    if (authError) return authError;

    const body: BatchInput = await req.json();
    const { ingests = [], deletes = [], commits = [], source_label = "unnamed" } = body;

    if (ingests.length === 0 && deletes.length === 0 && commits.length === 0) {
      return errorResponse("Empty batch: provide at least one of ingests/deletes/commits", 400);
    }

    const results: StepResult[] = [];
    const createdDocuments: { filename: string; document_id?: string }[] = [];

    // ===== STEP 1: INGESTS =====
    // Call knowledge-ingest Edge Function for each document
    for (const item of ingests) {
      try {
        const res = await fetch(
          `${SUPABASE_URL}/functions/v1/knowledge-ingest`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${AUTH_TOKEN}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(item),
          }
        );
        const data = await res.json();
        if (!res.ok) {
          results.push({
            step: "ingest",
            target: item.filename,
            success: false,
            error: data.error || `HTTP ${res.status}`,
          });
          // Rollback: delete any docs we already created in this batch
          for (const created of createdDocuments) {
            await fetch(`${SUPABASE_URL}/functions/v1/knowledge-delete`, {
              method: "POST",
              headers: {
                "Authorization": `Bearer ${AUTH_TOKEN}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({ filename: created.filename }),
            });
          }
          return jsonResponse({
            success: false,
            source_label,
            aborted_at: "ingest",
            failed_filename: item.filename,
            error: data.error || `HTTP ${res.status}`,
            rolled_back: createdDocuments.length,
            results,
          }, 500);
        }
        createdDocuments.push({ filename: item.filename, document_id: data.document_id });
        results.push({
          step: "ingest",
          target: item.filename,
          success: true,
          detail: {
            document_id: data.document_id,
            chunks_created: data.chunks_created,
            tokens_embedded: data.tokens_embedded,
            replaced_existing: data.replaced_existing,
          },
        });
      } catch (e) {
        results.push({
          step: "ingest",
          target: item.filename,
          success: false,
          error: String(e),
        });
        return jsonResponse({
          success: false,
          source_label,
          aborted_at: "ingest",
          failed_filename: item.filename,
          error: String(e),
          rolled_back: createdDocuments.length,
          results,
        }, 500);
      }
    }

    // ===== STEP 2: COMMITS =====
    // Call triage-commit for each prefix batch
    const supabase = createClient(
      SUPABASE_URL,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    for (const commit of commits) {
      try {
        const { data, error } = await supabase.rpc("triage_commit", {
          p_assigned_ids: commit.assigned_ids,
          p_doc_id: null,
        });
        if (error) {
          results.push({
            step: "commit",
            target: `${commit.prefix}[${commit.assigned_ids.length}]`,
            success: false,
            error: error.message,
          });
          // Note: we don't rollback ingests here — commits are idempotent-ish
          // and rolling back 6 successful ingests for a commit failure is too aggressive
        } else {
          results.push({
            step: "commit",
            target: `${commit.prefix}[${commit.assigned_ids.length}]`,
            success: true,
            detail: data,
          });
        }
      } catch (e) {
        results.push({
          step: "commit",
          target: `${commit.prefix}[${commit.assigned_ids.length}]`,
          success: false,
          error: String(e),
        });
      }
    }

    // ===== STEP 3: DELETES =====
    // Delete replaced master documents (e.g. old STATUS, old Registru part)
    for (const filename of deletes) {
      try {
        const res = await fetch(`${SUPABASE_URL}/functions/v1/knowledge-delete`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${AUTH_TOKEN}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ filename }),
        });
        const data = await res.json();
        if (!res.ok) {
          results.push({
            step: "delete",
            target: filename,
            success: false,
            error: data.error || `HTTP ${res.status}`,
          });
        } else {
          results.push({
            step: "delete",
            target: filename,
            success: true,
            detail: data,
          });
        }
      } catch (e) {
        results.push({
          step: "delete",
          target: filename,
          success: false,
          error: String(e),
        });
      }
    }

    // ===== FINAL REPORT =====
    const summary = {
      ingests: {
        total: ingests.length,
        succeeded: results.filter((r) => r.step === "ingest" && r.success).length,
        failed: results.filter((r) => r.step === "ingest" && !r.success).length,
      },
      commits: {
        total: commits.length,
        succeeded: results.filter((r) => r.step === "commit" && r.success).length,
        failed: results.filter((r) => r.step === "commit" && !r.success).length,
      },
      deletes: {
        total: deletes.length,
        succeeded: results.filter((r) => r.step === "delete" && r.success).length,
        failed: results.filter((r) => r.step === "delete" && !r.success).length,
      },
    };

    const allSucceeded =
      summary.ingests.failed === 0 &&
      summary.commits.failed === 0 &&
      summary.deletes.failed === 0;

    return jsonResponse({
      success: allSucceeded,
      source_label,
      summary,
      created_documents: createdDocuments,
      results,
    });
  } catch (e) {
    return errorResponse(`Unexpected error: ${String(e)}`, 500);
  }
});

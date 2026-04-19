// Shared utilities for Edge Functions — PM Knowledge / Triage
// Used by: triage-batch (and any future function that needs auth + CORS helpers)

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS, GET",
};

/**
 * Bearer token authentication against PM_KNOWLEDGE_KEY secret.
 * Returns a 401 Response if invalid, or null if valid (continue).
 */
export function authenticate(req: Request): Response | null {
  const expected = Deno.env.get("PM_KNOWLEDGE_KEY") ?? "pm_knowledge_2026_secure";
  const token = (req.headers.get("Authorization") ?? "")
    .replace(/^Bearer\s+/i, "")
    .trim();

  if (token !== expected) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  return null;
}

/** Helper for JSON error responses with proper CORS. */
export function errorResponse(message: string, status = 400): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Helper for JSON success responses with proper CORS. */
export function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

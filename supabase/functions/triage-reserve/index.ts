import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PM_KNOWLEDGE_KEY = Deno.env.get("PM_KNOWLEDGE_KEY") ?? "pm_knowledge_2026_secure";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (token !== PM_KNOWLEDGE_KEY) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const { prefix, count = 1, chat_label, source_name, source_year, item_type } = await req.json();

    if (!prefix || typeof prefix !== "string") {
      return new Response(JSON.stringify({ error: "Field prefix required (N|C|T|B|S|IND)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    if (typeof count !== "number" || count < 1 || count > 50) {
      return new Response(JSON.stringify({ error: "Field count must be integer 1-50" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data, error } = await supabase.rpc("triage_reserve", {
      p_prefix: prefix, p_count: count,
      p_chat_label: chat_label ?? null,
      p_source_name: source_name ?? null,
      p_source_year: source_year ?? null,
      p_item_type: item_type ?? null,
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const ids = (data ?? []).map((r) => r.assigned_id);
    return new Response(JSON.stringify({
      success: true, prefix, count: data?.length ?? 0,
      reservations: data, ids,
      first_id: ids[0] ?? null, last_id: ids[ids.length - 1] ?? null,
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});

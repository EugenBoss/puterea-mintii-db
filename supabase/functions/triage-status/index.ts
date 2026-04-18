import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PM_KNOWLEDGE_KEY = Deno.env.get("PM_KNOWLEDGE_KEY") ?? "pm_knowledge_2026_secure";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
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
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: statusData, error: statusErr } = await supabase.rpc("triage_status");
    if (statusErr) {
      return new Response(JSON.stringify({ error: statusErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const { data: activeRes } = await supabase
      .from("triage_reservations")
      .select("assigned_id, chat_label, source_name, source_year, item_type, reserved_at, expires_at")
      .eq("status", "reserved")
      .gt("expires_at", new Date().toISOString())
      .order("reserved_at", { ascending: false })
      .limit(50);

    return new Response(JSON.stringify({
      success: true,
      counters: statusData,
      active_reservations: activeRes,
      active_count: activeRes?.length ?? 0,
      server_time: new Date().toISOString(),
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});

-- ============================================================
-- LOCK DOWN PUBLIC KNOWLEDGE + TRIAGE TABLES
-- Date: 22 April 2026
-- Goal:
--   1. Eliminate direct Data API access from anon/authenticated
--   2. Keep access only through backend Edge Functions / service_role
-- ============================================================

-- ----------------------------
-- 1. Enable and force RLS
-- ----------------------------
ALTER TABLE IF EXISTS public.knowledge_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.knowledge_documents FORCE ROW LEVEL SECURITY;

ALTER TABLE IF EXISTS public.knowledge_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.knowledge_chunks FORCE ROW LEVEL SECURITY;

ALTER TABLE IF EXISTS public.triage_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.triage_counters FORCE ROW LEVEL SECURITY;

ALTER TABLE IF EXISTS public.triage_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.triage_reservations FORCE ROW LEVEL SECURITY;

-- No anon/authenticated policies are created on purpose.
-- These tables are backend-only and should be accessed via service_role
-- inside secured Edge Functions.

-- ----------------------------
-- 2. Revoke direct table access
-- ----------------------------
REVOKE ALL ON TABLE public.knowledge_documents FROM anon, authenticated;
REVOKE ALL ON TABLE public.knowledge_chunks FROM anon, authenticated;
REVOKE ALL ON TABLE public.triage_counters FROM anon, authenticated;
REVOKE ALL ON TABLE public.triage_reservations FROM anon, authenticated;

-- Also remove broad PUBLIC grants if present.
REVOKE ALL ON TABLE public.knowledge_documents FROM PUBLIC;
REVOKE ALL ON TABLE public.knowledge_chunks FROM PUBLIC;
REVOKE ALL ON TABLE public.triage_counters FROM PUBLIC;
REVOKE ALL ON TABLE public.triage_reservations FROM PUBLIC;

-- ----------------------------
-- 3. Revoke sequence access
-- ----------------------------
REVOKE ALL ON SEQUENCE public.triage_reservations_id_seq FROM anon, authenticated, PUBLIC;

-- ----------------------------
-- 4. Lock down RPC functions
-- ----------------------------
REVOKE ALL ON FUNCTION public.triage_reserve(TEXT, INT, TEXT, TEXT, INT, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION public.triage_commit(TEXT[], UUID) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION public.triage_status() FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION public.triage_cleanup_expired() FROM anon, authenticated, PUBLIC;

GRANT EXECUTE ON FUNCTION public.triage_reserve(TEXT, INT, TEXT, TEXT, INT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.triage_commit(TEXT[], UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.triage_status() TO service_role;
GRANT EXECUTE ON FUNCTION public.triage_cleanup_expired() TO service_role;

-- ----------------------------
-- 5. Documentation marker
-- ----------------------------
COMMENT ON TABLE public.knowledge_documents IS
  'Backend-only RAG document store. Direct anon/authenticated access is intentionally blocked.';

COMMENT ON TABLE public.knowledge_chunks IS
  'Backend-only RAG chunk store. Direct anon/authenticated access is intentionally blocked.';

COMMENT ON TABLE public.triage_counters IS
  'Backend-only triage sequencing table. Direct anon/authenticated access is intentionally blocked.';

COMMENT ON TABLE public.triage_reservations IS
  'Backend-only triage reservation table. Direct anon/authenticated access is intentionally blocked.';

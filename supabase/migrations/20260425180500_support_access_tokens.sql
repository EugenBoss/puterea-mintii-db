-- ============================================================
-- SUPPORT ACCESS TOKENS
-- Date: 25 April 2026
-- Goal:
--   Store hashed, expiring, read-only support-view tokens.
--   Raw tokens are never stored.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.support_access_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash text NOT NULL UNIQUE,
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text NOT NULL,
  expires_at timestamptz NOT NULL,
  first_used_at timestamptz,
  last_used_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS support_access_tokens_target_created_idx
  ON public.support_access_tokens (target_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS support_access_tokens_expires_idx
  ON public.support_access_tokens (expires_at)
  WHERE revoked_at IS NULL;

ALTER TABLE public.support_access_tokens ENABLE ROW LEVEL SECURITY;

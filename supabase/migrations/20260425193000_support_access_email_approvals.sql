-- ============================================================
-- SUPPORT ACCESS EMAIL APPROVALS
-- Date: 25 April 2026
-- Goal:
--   Let users approve temporary support access from an emailed button.
--   Raw approval tokens are never stored.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.support_access_approval_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash text NOT NULL UNIQUE,
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text NOT NULL,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS support_access_approval_target_created_idx
  ON public.support_access_approval_tokens (target_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS support_access_approval_expires_idx
  ON public.support_access_approval_tokens (expires_at)
  WHERE used_at IS NULL;

ALTER TABLE public.support_access_approval_tokens ENABLE ROW LEVEL SECURITY;

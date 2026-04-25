-- ============================================================
-- PROFILE COMPLIANCE CONTROLS
-- Date: 25 April 2026
-- Goal:
--   Store profile photo/social fields, public profile opt-in,
--   privacy consents, support-access consent, and support audit trail.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS public_slug text,
  ADD COLUMN IF NOT EXISTS public_profile_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS public_bio text,
  ADD COLUMN IF NOT EXISTS social_links jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS consent_terms_privacy_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_terms_privacy_version text,
  ADD COLUMN IF NOT EXISTS consent_data_improvement boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_data_improvement_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_marketing boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_marketing_at timestamptz,
  ADD COLUMN IF NOT EXISTS support_access_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS support_access_until timestamptz,
  ADD COLUMN IF NOT EXISTS support_access_note text;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_public_slug_key
  ON public.profiles (public_slug)
  WHERE public_slug IS NOT NULL;

CREATE INDEX IF NOT EXISTS profiles_public_enabled_idx
  ON public.profiles (public_profile_enabled)
  WHERE public_profile_enabled = true;

CREATE TABLE IF NOT EXISTS public.support_access_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text NOT NULL,
  action text NOT NULL,
  ip_address text,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS support_access_audit_target_created_idx
  ON public.support_access_audit (target_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS support_access_audit_admin_created_idx
  ON public.support_access_audit (admin_user_id, created_at DESC);

ALTER TABLE public.support_access_audit ENABLE ROW LEVEL SECURITY;

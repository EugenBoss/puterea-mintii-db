-- ============================================================
-- USER FEEDBACK + REFERRALS
-- Date: 25 April 2026
-- Goal:
--   Track thumbs up/down and copy actions for generated content.
--   Support referral links that grant one month of Transformare access
--   to both users after a referred user signs in.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS referral_code text,
  ADD COLUMN IF NOT EXISTS referred_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS referral_bonus_until timestamptz,
  ADD COLUMN IF NOT EXISTS referral_bonus_plan text;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_referral_code_key
  ON public.profiles (referral_code)
  WHERE referral_code IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.content_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  content_type text NOT NULL,
  content_id text,
  source text,
  rating text NOT NULL,
  content_text text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'content_feedback_rating_check'
  ) THEN
    ALTER TABLE public.content_feedback
      ADD CONSTRAINT content_feedback_rating_check
      CHECK (rating IN ('up', 'down', 'copy'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS content_feedback_user_created_idx
  ON public.content_feedback (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS content_feedback_type_created_idx
  ON public.content_feedback (content_type, created_at DESC);

ALTER TABLE public.content_feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "content_feedback_insert_own" ON public.content_feedback;
DROP POLICY IF EXISTS "content_feedback_select_own" ON public.content_feedback;

CREATE POLICY "content_feedback_insert_own"
ON public.content_feedback
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "content_feedback_select_own"
ON public.content_feedback
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE TABLE IF NOT EXISTS public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referred_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referral_code text NOT NULL,
  bonus_months integer NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'granted',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (referred_user_id),
  UNIQUE (referrer_user_id, referred_user_id)
);

CREATE INDEX IF NOT EXISTS referrals_referrer_created_idx
  ON public.referrals (referrer_user_id, created_at DESC);

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "referrals_select_own" ON public.referrals;

CREATE POLICY "referrals_select_own"
ON public.referrals
FOR SELECT
TO authenticated
USING (
  (SELECT auth.uid()) = referrer_user_id
  OR (SELECT auth.uid()) = referred_user_id
);

-- ============================================================
-- PROFILE REWARD EMAIL TRACKING
-- Date: 25 April 2026
-- Goal:
--   Track the profile reward email so the bonus meditation credit
--   announcement is sent only once.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS profile_reward_email_sent_at timestamptz;

CREATE INDEX IF NOT EXISTS profiles_profile_reward_email_pending_idx
  ON public.profiles (updated_at DESC)
  WHERE profile_reward_meditation_unlocked = true
    AND profile_reward_email_sent_at IS NULL;

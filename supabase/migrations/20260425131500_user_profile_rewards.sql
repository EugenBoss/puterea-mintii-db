-- ============================================================
-- USER PROFILE REWARDS
-- Date: 25 April 2026
-- Goal:
--   Store optional personal profile fields, profile completion points,
--   and one meditation bonus credit when the profile reaches threshold.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS main_goal text,
  ADD COLUMN IF NOT EXISTS meditation_focus text,
  ADD COLUMN IF NOT EXISTS experience_level text,
  ADD COLUMN IF NOT EXISTS reminder_time text,
  ADD COLUMN IF NOT EXISTS profile_points integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_reward_meditation_unlocked boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS profile_reward_meditation_claimed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS meditation_bonus_credits integer NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS profiles_profile_points_idx
  ON public.profiles (profile_points DESC);

CREATE INDEX IF NOT EXISTS profiles_meditation_bonus_credits_idx
  ON public.profiles (meditation_bonus_credits)
  WHERE meditation_bonus_credits > 0;

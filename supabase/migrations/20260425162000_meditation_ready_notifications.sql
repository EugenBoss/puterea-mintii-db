-- ============================================================
-- MEDITATION READY NOTIFICATIONS
-- Date: 25 April 2026
-- Goal:
--   Allow users to disable meditation-ready notifications and
--   prevent duplicate completion emails for generated audio.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS meditation_audio_notify_enabled boolean NOT NULL DEFAULT true;

ALTER TABLE public.generations
  ADD COLUMN IF NOT EXISTS audio_ready_email_sent_at timestamptz;

CREATE INDEX IF NOT EXISTS generations_audio_ready_email_pending_idx
  ON public.generations (audio_completed_at DESC)
  WHERE audio_status = 'ready'
    AND audio_ready_email_sent_at IS NULL;

-- ============================================================
-- REAL AUDIO PIPELINE FOR GENERATIONS
-- Date: 23 April 2026
-- Goal:
--   Store meditation audio generation state on public.generations
--   and create a private Storage bucket for generated MP3 files.
-- ============================================================

ALTER TABLE public.generations
  ADD COLUMN IF NOT EXISTS audio_status text,
  ADD COLUMN IF NOT EXISTS audio_provider text,
  ADD COLUMN IF NOT EXISTS audio_voice text,
  ADD COLUMN IF NOT EXISTS audio_path text,
  ADD COLUMN IF NOT EXISTS audio_duration_sec integer,
  ADD COLUMN IF NOT EXISTS audio_error text,
  ADD COLUMN IF NOT EXISTS audio_requested_at timestamptz,
  ADD COLUMN IF NOT EXISTS audio_completed_at timestamptz;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'generations_audio_status_check'
  ) THEN
    ALTER TABLE public.generations
      ADD CONSTRAINT generations_audio_status_check
      CHECK (
        audio_status IS NULL
        OR audio_status IN ('pending', 'generating', 'ready', 'failed')
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS generations_user_audio_requested_idx
  ON public.generations (user_id, audio_requested_at DESC);

UPDATE public.generations
SET audio_status = 'pending'
WHERE audio_status IS NULL
  AND COALESCE(script_text, '') <> '';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'meditation-audio',
  'meditation-audio',
  false,
  52428800,
  ARRAY['audio/mpeg']
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Align rd_sources with the approved R&D Intelligence source schema.
-- This migration intentionally uses ALTER TABLE only and does not rewrite data.

ALTER TABLE public.rd_sources
  DROP CONSTRAINT IF EXISTS rd_sources_source_type_check,
  DROP CONSTRAINT IF EXISTS rd_sources_status_check,
  DROP CONSTRAINT IF EXISTS rd_sources_trust_level_check;

ALTER TABLE public.rd_sources
  ALTER COLUMN source_type DROP DEFAULT;

ALTER TABLE public.rd_sources
  RENAME COLUMN source_url TO url;

ALTER TABLE public.rd_sources
  RENAME COLUMN author_or_publisher TO author;

ALTER TABLE public.rd_sources
  RENAME COLUMN publication_date TO source_date;

ALTER TABLE public.rd_sources
  RENAME COLUMN captured_at TO ingested_at;

ALTER TABLE public.rd_sources
  RENAME COLUMN summary TO raw_summary;

ALTER TABLE public.rd_sources
  DROP COLUMN IF EXISTS source_key,
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS trust_level,
  ADD COLUMN IF NOT EXISTS source_quality text,
  ADD COLUMN IF NOT EXISTS created_by text;

ALTER TABLE public.rd_sources
  ADD CONSTRAINT rd_sources_source_type_check
  CHECK (
    source_type IN (
      'internal_doc',
      'user_signal',
      'market_research',
      'academic_paper',
      'product_metric',
      'manual_note'
    )
  ) NOT VALID;

ALTER TABLE public.rd_sources
  ADD CONSTRAINT rd_sources_source_quality_check
  CHECK (
    source_quality IN ('low', 'medium', 'high', 'canonical')
    OR source_quality IS NULL
  ) NOT VALID;

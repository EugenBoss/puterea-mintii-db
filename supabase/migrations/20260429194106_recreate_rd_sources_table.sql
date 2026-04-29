-- Hard reset rd_sources to the approved R&D Intelligence source schema.
-- The previous table is retained as public.rd_sources_old.
-- Old source rows are intentionally not migrated in this migration.

ALTER TABLE public.rd_findings
  DROP CONSTRAINT IF EXISTS rd_findings_source_id_fkey;

ALTER TABLE public.rd_sources RENAME TO rd_sources_old;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_pkey'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_pkey TO rd_sources_old_pkey;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_source_key_key'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_source_key_key TO rd_sources_old_source_key_key;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_source_type_check'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_source_type_check TO rd_sources_old_source_type_check;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_source_quality_check'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_source_quality_check TO rd_sources_old_source_quality_check;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_trust_level_check'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_trust_level_check TO rd_sources_old_trust_level_check;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_status_check'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_status_check TO rd_sources_old_status_check;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.rd_sources_old'::regclass
      AND conname = 'rd_sources_metadata_object_check'
  ) THEN
    ALTER TABLE public.rd_sources_old
      RENAME CONSTRAINT rd_sources_metadata_object_check TO rd_sources_old_metadata_object_check;
  END IF;
END $$;

CREATE TABLE public.rd_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type text NOT NULL,
  title text NOT NULL,
  url text,
  author text,
  source_date date,
  ingested_at timestamptz DEFAULT now(),
  source_quality text,
  raw_summary text,
  created_by text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

ALTER TABLE public.rd_sources
ADD CONSTRAINT rd_sources_source_type_check
CHECK (source_type IN (
  'internal_doc',
  'user_signal',
  'market_research',
  'academic_paper',
  'product_metric',
  'manual_note'
));

ALTER TABLE public.rd_sources
ADD CONSTRAINT rd_sources_source_quality_check
CHECK (
  source_quality IN ('low','medium','high','canonical')
  OR source_quality IS NULL
);

ALTER TABLE public.rd_findings
  ADD CONSTRAINT rd_findings_source_id_fkey
  FOREIGN KEY (source_id)
  REFERENCES public.rd_sources(id)
  ON DELETE SET NULL
  NOT VALID;

ALTER TABLE public.rd_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_sources FORCE ROW LEVEL SECURITY;

CREATE POLICY "deny all rd_sources"
ON public.rd_sources
FOR ALL
USING (false)
WITH CHECK (false);

REVOKE ALL ON TABLE public.rd_sources FROM anon, authenticated, PUBLIC;
GRANT ALL ON TABLE public.rd_sources TO service_role;

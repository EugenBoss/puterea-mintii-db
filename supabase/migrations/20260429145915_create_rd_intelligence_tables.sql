-- ============================================================
-- PsyMind R&D Intelligence Agent MVP schema
-- Date: 29 April 2026
-- Scope: internal-only R&D intelligence tables.
--
-- Security:
-- - These tables are service/admin-only.
-- - RLS is enabled and forced.
-- - Direct anon/authenticated browser access is explicitly denied.
-- - rd_user_signal_rollups stores aggregate signals only; no raw user text,
--   user IDs, session IDs, anonymous IDs, emails, names, phone numbers, or
--   other PII columns are included.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.rd_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_key text NOT NULL,
  source_type text NOT NULL DEFAULT 'other',
  title text NOT NULL,
  author_or_publisher text NULL,
  source_url text NULL,
  publication_date date NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  last_reviewed_at timestamptz NULL,
  trust_level text NOT NULL DEFAULT 'medium',
  status text NOT NULL DEFAULT 'candidate',
  summary text NULL,
  tags text[] NOT NULL DEFAULT '{}'::text[],
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT rd_sources_source_key_key UNIQUE (source_key),
  CONSTRAINT rd_sources_source_type_check CHECK (
    source_type IN (
      'paper',
      'article',
      'book',
      'dataset',
      'internal_metric',
      'competitor',
      'expert_note',
      'other'
    )
  ),
  CONSTRAINT rd_sources_trust_level_check CHECK (
    trust_level IN ('low', 'medium', 'high', 'primary')
  ),
  CONSTRAINT rd_sources_status_check CHECK (
    status IN ('candidate', 'active', 'archived', 'blocked')
  ),
  CONSTRAINT rd_sources_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

CREATE TABLE IF NOT EXISTS public.rd_findings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id uuid NULL REFERENCES public.rd_sources(id) ON DELETE SET NULL,
  parent_finding_id uuid NULL REFERENCES public.rd_findings(id) ON DELETE SET NULL,
  finding_type text NOT NULL DEFAULT 'insight',
  title text NOT NULL,
  summary text NOT NULL,
  evidence_summary text NULL,
  implication text NULL,
  evidence_level text NOT NULL DEFAULT 'medium',
  status text NOT NULL DEFAULT 'new',
  impact_score numeric(4,2) NOT NULL DEFAULT 3.00,
  confidence_score numeric(4,2) NOT NULL DEFAULT 3.00,
  effort_score numeric(4,2) NOT NULL DEFAULT 1.00,
  risk_score numeric(4,2) NOT NULL DEFAULT 1.00,
  priority_score numeric(10,4) GENERATED ALWAYS AS (
    round(
      ((impact_score * confidence_score)::numeric / greatest((effort_score * risk_score)::numeric, 1::numeric)),
      4
    )
  ) STORED,
  tags text[] NOT NULL DEFAULT '{}'::text[],
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT rd_findings_finding_type_check CHECK (
    finding_type IN (
      'evidence',
      'insight',
      'risk',
      'pattern',
      'contradiction',
      'opportunity'
    )
  ),
  CONSTRAINT rd_findings_evidence_level_check CHECK (
    evidence_level IN ('low', 'medium', 'high')
  ),
  CONSTRAINT rd_findings_status_check CHECK (
    status IN ('new', 'reviewed', 'accepted', 'rejected', 'archived')
  ),
  CONSTRAINT rd_findings_scores_check CHECK (
    impact_score BETWEEN 1 AND 10
    AND confidence_score BETWEEN 1 AND 10
    AND effort_score BETWEEN 1 AND 10
    AND risk_score BETWEEN 1 AND 10
  ),
  CONSTRAINT rd_findings_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

CREATE TABLE IF NOT EXISTS public.rd_hypotheses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_finding_id uuid NULL REFERENCES public.rd_findings(id) ON DELETE SET NULL,
  hypothesis_type text NOT NULL DEFAULT 'product',
  title text NOT NULL,
  hypothesis text NOT NULL,
  rationale text NULL,
  expected_impact text NULL,
  status text NOT NULL DEFAULT 'draft',
  owner text NULL,
  impact_score numeric(4,2) NOT NULL DEFAULT 3.00,
  confidence_score numeric(4,2) NOT NULL DEFAULT 3.00,
  effort_score numeric(4,2) NOT NULL DEFAULT 1.00,
  risk_score numeric(4,2) NOT NULL DEFAULT 1.00,
  priority_score numeric(10,4) GENERATED ALWAYS AS (
    round(
      ((impact_score * confidence_score)::numeric / greatest((effort_score * risk_score)::numeric, 1::numeric)),
      4
    )
  ) STORED,
  experiment_link text NULL,
  decision text NULL,
  decided_at timestamptz NULL,
  tags text[] NOT NULL DEFAULT '{}'::text[],
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT rd_hypotheses_hypothesis_type_check CHECK (
    hypothesis_type IN (
      'product',
      'content',
      'growth',
      'retention',
      'safety',
      'pricing',
      'operations',
      'other'
    )
  ),
  CONSTRAINT rd_hypotheses_status_check CHECK (
    status IN ('draft', 'active', 'testing', 'validated', 'invalidated', 'archived')
  ),
  CONSTRAINT rd_hypotheses_scores_check CHECK (
    impact_score BETWEEN 1 AND 10
    AND confidence_score BETWEEN 1 AND 10
    AND effort_score BETWEEN 1 AND 10
    AND risk_score BETWEEN 1 AND 10
  ),
  CONSTRAINT rd_hypotheses_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

CREATE TABLE IF NOT EXISTS public.rd_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type text NOT NULL DEFAULT 'weekly_digest',
  title text NOT NULL,
  period_start date NULL,
  period_end date NULL,
  status text NOT NULL DEFAULT 'draft',
  visibility text NOT NULL DEFAULT 'internal',
  executive_summary text NULL,
  key_findings jsonb NOT NULL DEFAULT '[]'::jsonb,
  recommendations jsonb NOT NULL DEFAULT '[]'::jsonb,
  linked_finding_ids uuid[] NOT NULL DEFAULT '{}'::uuid[],
  linked_hypothesis_ids uuid[] NOT NULL DEFAULT '{}'::uuid[],
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT rd_reports_report_type_check CHECK (
    report_type IN ('weekly_digest', 'monthly_framework_memo', 'product_opportunity', 'alert')
  ),
  CONSTRAINT rd_reports_status_check CHECK (
    status IN ('draft', 'reviewed', 'published', 'archived')
  ),
  CONSTRAINT rd_reports_visibility_check CHECK (
    visibility IN ('internal', 'leadership', 'restricted')
  ),
  CONSTRAINT rd_reports_period_check CHECK (
    period_start IS NULL
    OR period_end IS NULL
    OR period_end >= period_start
  ),
  CONSTRAINT rd_reports_key_findings_array_check CHECK (
    jsonb_typeof(key_findings) = 'array'
  ),
  CONSTRAINT rd_reports_recommendations_array_check CHECK (
    jsonb_typeof(recommendations) = 'array'
  ),
  CONSTRAINT rd_reports_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

CREATE TABLE IF NOT EXISTS public.rd_user_signal_rollups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rollup_date date NOT NULL,
  rollup_period text NOT NULL DEFAULT 'day',
  signal_source text NOT NULL DEFAULT 'analytics',
  signal_type text NOT NULL DEFAULT 'usage',
  locale text NOT NULL DEFAULT 'all',
  plan_tier text NOT NULL DEFAULT 'all',
  content_category text NOT NULL DEFAULT 'all',
  event_count integer NOT NULL DEFAULT 0,
  subject_count integer NOT NULL DEFAULT 0,
  positive_count integer NOT NULL DEFAULT 0,
  neutral_count integer NOT NULL DEFAULT 0,
  negative_count integer NOT NULL DEFAULT 0,
  conversion_rate numeric(6,4) NULL,
  avg_helpfulness_score numeric(5,2) NULL,
  avg_audio_completion_rate numeric(6,4) NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT rd_user_signal_rollups_key UNIQUE (
    rollup_date,
    rollup_period,
    signal_source,
    signal_type,
    locale,
    plan_tier,
    content_category
  ),
  CONSTRAINT rd_user_signal_rollups_period_check CHECK (
    rollup_period IN ('day', 'week', 'month')
  ),
  CONSTRAINT rd_user_signal_rollups_source_check CHECK (
    signal_source IN (
      'generator',
      'evaluator',
      'audio',
      'history',
      'account',
      'checkout',
      'support',
      'survey',
      'analytics',
      'other'
    )
  ),
  CONSTRAINT rd_user_signal_rollups_signal_type_check CHECK (
    signal_type IN ('usage', 'retention', 'conversion', 'quality', 'safety', 'feedback', 'cost', 'other')
  ),
  CONSTRAINT rd_user_signal_rollups_locale_check CHECK (
    locale IN ('all', 'en', 'ro', 'fr', 'es', 'pt', 'it', 'hi', 'zh', 'de')
  ),
  CONSTRAINT rd_user_signal_rollups_plan_tier_check CHECK (
    plan_tier IN ('all', 'anonymous', 'free', 'pro', 'premium', 'lifetime', 'training')
  ),
  CONSTRAINT rd_user_signal_rollups_content_category_check CHECK (
    length(content_category) BETWEEN 1 AND 64
    AND content_category !~* '(@|email|phone|name|user_id|session_id|anonymous_id)'
  ),
  CONSTRAINT rd_user_signal_rollups_counts_check CHECK (
    event_count >= 0
    AND subject_count >= 0
    AND positive_count >= 0
    AND neutral_count >= 0
    AND negative_count >= 0
  ),
  CONSTRAINT rd_user_signal_rollups_rates_check CHECK (
    (conversion_rate IS NULL OR conversion_rate BETWEEN 0 AND 1)
    AND (avg_helpfulness_score IS NULL OR avg_helpfulness_score BETWEEN 0 AND 5)
    AND (avg_audio_completion_rate IS NULL OR avg_audio_completion_rate BETWEEN 0 AND 1)
  ),
  CONSTRAINT rd_user_signal_rollups_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  ),
  CONSTRAINT rd_user_signal_rollups_metadata_no_pii_check CHECK (
    NOT (
      metadata ?| ARRAY[
        'user_id',
        'session_id',
        'anonymous_id',
        'email',
        'phone',
        'name',
        'raw_text',
        'problem_text',
        'desired_state',
        'generated_text'
      ]
    )
  )
);

COMMENT ON TABLE public.rd_sources IS
  'Internal R&D source catalog. Direct anon/authenticated access is denied; use service/admin access only.';
COMMENT ON TABLE public.rd_findings IS
  'Internal R&D findings extracted from sources, research, or aggregate signals. Direct client access is denied.';
COMMENT ON TABLE public.rd_hypotheses IS
  'Internal R&D hypotheses with generated priority scoring. Direct client access is denied.';
COMMENT ON TABLE public.rd_reports IS
  'Internal R&D intelligence reports. Direct client access is denied.';
COMMENT ON TABLE public.rd_user_signal_rollups IS
  'Aggregate-only user/product signal rollups for R&D. No raw user text, IDs, emails, names, phone numbers, session IDs, anonymous IDs, or PII columns.';

COMMENT ON COLUMN public.rd_findings.priority_score IS
  'Generated as (impact_score * confidence_score) / greatest(effort_score * risk_score, 1).';
COMMENT ON COLUMN public.rd_hypotheses.priority_score IS
  'Generated as (impact_score * confidence_score) / greatest(effort_score * risk_score, 1).';
COMMENT ON COLUMN public.rd_user_signal_rollups.metadata IS
  'Aggregate metadata only. Do not store raw user text, user identifiers, contact data, or PII.';

CREATE INDEX IF NOT EXISTS rd_sources_type_status_idx
  ON public.rd_sources (source_type, status);
CREATE INDEX IF NOT EXISTS rd_sources_trust_level_idx
  ON public.rd_sources (trust_level);
CREATE INDEX IF NOT EXISTS rd_sources_captured_at_idx
  ON public.rd_sources (captured_at);

CREATE INDEX IF NOT EXISTS rd_findings_source_id_idx
  ON public.rd_findings (source_id);
CREATE INDEX IF NOT EXISTS rd_findings_status_priority_idx
  ON public.rd_findings (status, priority_score DESC);
CREATE INDEX IF NOT EXISTS rd_findings_type_evidence_idx
  ON public.rd_findings (finding_type, evidence_level);

CREATE INDEX IF NOT EXISTS rd_hypotheses_primary_finding_id_idx
  ON public.rd_hypotheses (primary_finding_id);
CREATE INDEX IF NOT EXISTS rd_hypotheses_status_priority_idx
  ON public.rd_hypotheses (status, priority_score DESC);
CREATE INDEX IF NOT EXISTS rd_hypotheses_type_idx
  ON public.rd_hypotheses (hypothesis_type);

CREATE INDEX IF NOT EXISTS rd_reports_type_status_idx
  ON public.rd_reports (report_type, status);
CREATE INDEX IF NOT EXISTS rd_reports_period_idx
  ON public.rd_reports (period_start, period_end);

CREATE INDEX IF NOT EXISTS rd_user_signal_rollups_date_idx
  ON public.rd_user_signal_rollups (rollup_date);
CREATE INDEX IF NOT EXISTS rd_user_signal_rollups_source_type_idx
  ON public.rd_user_signal_rollups (signal_source, signal_type);

ALTER TABLE public.rd_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_sources FORCE ROW LEVEL SECURITY;
ALTER TABLE public.rd_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_findings FORCE ROW LEVEL SECURITY;
ALTER TABLE public.rd_hypotheses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_hypotheses FORCE ROW LEVEL SECURITY;
ALTER TABLE public.rd_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_reports FORCE ROW LEVEL SECURITY;
ALTER TABLE public.rd_user_signal_rollups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_user_signal_rollups FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rd_sources_deny_client_access" ON public.rd_sources;
CREATE POLICY "rd_sources_deny_client_access"
ON public.rd_sources
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

DROP POLICY IF EXISTS "rd_findings_deny_client_access" ON public.rd_findings;
CREATE POLICY "rd_findings_deny_client_access"
ON public.rd_findings
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

DROP POLICY IF EXISTS "rd_hypotheses_deny_client_access" ON public.rd_hypotheses;
CREATE POLICY "rd_hypotheses_deny_client_access"
ON public.rd_hypotheses
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

DROP POLICY IF EXISTS "rd_reports_deny_client_access" ON public.rd_reports;
CREATE POLICY "rd_reports_deny_client_access"
ON public.rd_reports
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

DROP POLICY IF EXISTS "rd_user_signal_rollups_deny_client_access" ON public.rd_user_signal_rollups;
CREATE POLICY "rd_user_signal_rollups_deny_client_access"
ON public.rd_user_signal_rollups
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

REVOKE ALL ON TABLE public.rd_sources FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.rd_findings FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.rd_hypotheses FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.rd_reports FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.rd_user_signal_rollups FROM anon, authenticated, PUBLIC;

GRANT ALL ON TABLE public.rd_sources TO service_role;
GRANT ALL ON TABLE public.rd_findings TO service_role;
GRANT ALL ON TABLE public.rd_hypotheses TO service_role;
GRANT ALL ON TABLE public.rd_reports TO service_role;
GRANT ALL ON TABLE public.rd_user_signal_rollups TO service_role;

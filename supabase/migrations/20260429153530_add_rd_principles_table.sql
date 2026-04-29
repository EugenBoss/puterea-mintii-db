-- ============================================================
-- PsyMind R&D Principle Registry
-- Date: 29 April 2026
-- Scope: internal-only controlled principle detection and review.
--
-- Security:
-- - This table is service/admin-only.
-- - RLS is enabled and forced.
-- - Direct anon/authenticated browser access is explicitly denied.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.rd_principles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  summary text NOT NULL,
  principle_type text NOT NULL,
  detection_type text NOT NULL,
  source_ids uuid[] NULL,
  related_finding_ids uuid[] NULL,
  affected_modules text[] NOT NULL DEFAULT '{}'::text[],
  affected_criteria text[] NOT NULL DEFAULT '{}'::text[],
  evidence_level text NOT NULL DEFAULT 'unknown',
  impact_score integer NOT NULL DEFAULT 3,
  confidence_score integer NOT NULL DEFAULT 3,
  risk_level integer NOT NULL DEFAULT 1,
  effort_score integer NOT NULL DEFAULT 1,
  priority_score numeric(10,4) GENERATED ALWAYS AS (
    round(
      ((impact_score * confidence_score)::numeric / greatest((effort_score * risk_level)::numeric, 1::numeric)),
      4
    )
  ) STORED,
  allowed_usage text[] NOT NULL DEFAULT '{}'::text[],
  forbidden_usage text[] NOT NULL DEFAULT '{}'::text[],
  implementation_status text NOT NULL DEFAULT 'detected',
  requires_human_review boolean NOT NULL DEFAULT true,
  reviewer_notes text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz NULL,
  implemented_at timestamptz NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  CONSTRAINT rd_principles_principle_type_check CHECK (
    principle_type IN (
      'core_rule',
      'safety_rule',
      'personalization_rule',
      'structure_rule',
      'evaluation_rule',
      'generator_rule',
      'product_rule',
      'research_hypothesis'
    )
  ),
  CONSTRAINT rd_principles_detection_type_check CHECK (
    detection_type IN (
      'new',
      'confirm_existing',
      'contradict_existing',
      'refine_existing',
      'noise'
    )
  ),
  CONSTRAINT rd_principles_evidence_level_check CHECK (
    evidence_level IN ('unknown', 'weak', 'moderate', 'strong', 'canonical')
  ),
  CONSTRAINT rd_principles_scores_check CHECK (
    impact_score BETWEEN 1 AND 10
    AND confidence_score BETWEEN 1 AND 10
    AND risk_level BETWEEN 1 AND 10
    AND effort_score BETWEEN 1 AND 10
  ),
  CONSTRAINT rd_principles_implementation_status_check CHECK (
    implementation_status IN (
      'detected',
      'needs_review',
      'accepted',
      'rejected',
      'watch',
      'implemented',
      'archived'
    )
  ),
  CONSTRAINT rd_principles_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

COMMENT ON TABLE public.rd_principles IS
  'Internal R&D principle registry for controlled detection and review. Direct client access is denied.';
COMMENT ON COLUMN public.rd_principles.priority_score IS
  'Generated as (impact_score * confidence_score) / greatest(effort_score * risk_level, 1).';
COMMENT ON COLUMN public.rd_principles.requires_human_review IS
  'Defaults true so detected principles require explicit review before adoption.';

CREATE INDEX IF NOT EXISTS rd_principles_implementation_status_idx
  ON public.rd_principles (implementation_status);
CREATE INDEX IF NOT EXISTS rd_principles_principle_type_idx
  ON public.rd_principles (principle_type);
CREATE INDEX IF NOT EXISTS rd_principles_detection_type_idx
  ON public.rd_principles (detection_type);
CREATE INDEX IF NOT EXISTS rd_principles_evidence_level_idx
  ON public.rd_principles (evidence_level);

CREATE INDEX IF NOT EXISTS rd_principles_affected_modules_gin_idx
  ON public.rd_principles USING gin (affected_modules);
CREATE INDEX IF NOT EXISTS rd_principles_affected_criteria_gin_idx
  ON public.rd_principles USING gin (affected_criteria);
CREATE INDEX IF NOT EXISTS rd_principles_source_ids_gin_idx
  ON public.rd_principles USING gin (source_ids);
CREATE INDEX IF NOT EXISTS rd_principles_related_finding_ids_gin_idx
  ON public.rd_principles USING gin (related_finding_ids);

ALTER TABLE public.rd_principles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_principles FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rd_principles_deny_client_access" ON public.rd_principles;
CREATE POLICY "rd_principles_deny_client_access"
ON public.rd_principles
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

REVOKE ALL ON TABLE public.rd_principles FROM anon, authenticated, PUBLIC;

GRANT ALL ON TABLE public.rd_principles TO service_role;

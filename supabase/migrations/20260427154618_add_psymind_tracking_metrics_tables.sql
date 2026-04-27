-- Purpose: Add PsyMind internal tracking, metrics diagnosis, experiments, costs,
-- risks, support, cancellation, and knowledge ledger tables.
-- Source draft file: /Users/eugen/Documents/PsyMind-Workspace/psymind-app/supabase_metrics_tables.sql
-- Privacy note: Some internal tables may contain raw/emotional user data and must
-- remain PsyMind-controlled with service/admin access only until RLS is reviewed.
-- Not for external ad analytics: Do not export raw/emotional user data,
-- user_sessions rows, risk labels, generated text, or blocked metadata fields to
-- external ad platforms.

-- PsyMind launch metrics, diagnosis, experiments, costs, risks, support, cancellation,
-- and knowledge ledger schema draft.
--
-- This SQL is intended for internal Supabase product analytics only.
-- Do not export raw/emotional user data, user_sessions rows, or blocked metadata fields
-- to external ad platforms.
--
-- RLS TODO, intentionally not active in this draft:
-- - Prefer service_role writes from server-side API endpoints.
-- - Keep raw text tables admin/service-only unless explicit policies are reviewed.
-- - Add user-scoped read/delete policies only after product flows and retention rules are final.

CREATE TABLE IF NOT EXISTS public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  anonymous_id text NOT NULL,
  session_id uuid NOT NULL,
  event_name text NOT NULL,
  event_value text NULL,
  experiment_id text NULL,
  variant_id text NULL,
  vertical text NULL,
  risk_level text NULL,
  traffic_source text NULL,
  utm_source text NULL,
  utm_campaign text NULL,
  utm_content text NULL,
  device text NULL,
  country text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.events IS
  'Internal product event tracking. events.metadata must not contain blocked emotional/raw fields and must not be forwarded externally.';
COMMENT ON COLUMN public.events.metadata IS
  'Operational metadata only. Do not store raw problem text, desired state, generated text, emotional state, mental-health flags, or other blocked ad-forwarding fields here.';

CREATE TABLE IF NOT EXISTS public.user_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  anonymous_id text NOT NULL,
  experiment_id text NULL,
  variant_id text NULL,
  vertical text NULL,
  problem_text text NULL,
  desired_state text NULL,
  risk_level text NOT NULL DEFAULT 'normal',
  generated_text text NULL,
  audio_seconds int NULL,
  audio_completed boolean NOT NULL DEFAULT false,
  feels_personal text NULL,
  after_state text NULL,
  total_cost numeric NOT NULL DEFAULT 0,
  prompt_version text NULL,
  model_version text NULL,
  risk_classifier_version text NULL,
  voice_id text NULL,
  music_track_id text NULL,
  audio_script_version text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.user_sessions IS
  'Internal sensitive product sessions. May contain raw/emotional user text and generated text. Must not be exported to ad platforms.';
COMMENT ON COLUMN public.user_sessions.problem_text IS
  'Raw user text. Apply 30-day guest retention and account/history deletion rules.';
COMMENT ON COLUMN public.user_sessions.desired_state IS
  'Raw user text. Apply 30-day guest retention and account/history deletion rules.';
COMMENT ON COLUMN public.user_sessions.generated_text IS
  'Generated personalized text. Treat as sensitive product data and keep internal.';

CREATE TABLE IF NOT EXISTS public.metric_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  experiment_id text NULL,
  variant_id text NULL,
  vertical text NULL,
  metric_name text NOT NULL,
  metric_value numeric NOT NULL,
  status text NOT NULL,
  threshold_red numeric NULL,
  threshold_yellow numeric NULL,
  threshold_green numeric NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.diagnosis_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  experiment_id text NULL,
  variant_id text NULL,
  vertical text NULL,
  severity text NOT NULL,
  area text NOT NULL,
  problem_detected text NOT NULL,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  likely_causes jsonb NOT NULL DEFAULT '[]'::jsonb,
  recommended_tests jsonb NOT NULL DEFAULT '[]'::jsonb,
  decision text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.experiments (
  id text PRIMARY KEY,
  name text NOT NULL,
  hypothesis text NULL,
  primary_metric text NOT NULL,
  guardrail_metrics jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'draft',
  start_date timestamptz NULL,
  end_date timestamptz NULL,
  owner text NULL,
  decision text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.experiment_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id text NOT NULL REFERENCES public.experiments(id),
  variant_id text NOT NULL,
  variant_name text NOT NULL,
  allocation_percent numeric NOT NULL DEFAULT 50,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT experiment_variants_experiment_variant_key UNIQUE (experiment_id, variant_id)
);

CREATE TABLE IF NOT EXISTS public.cost_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  user_id uuid NULL,
  anonymous_id text NULL,
  text_model text NULL,
  input_tokens int NOT NULL DEFAULT 0,
  output_tokens int NOT NULL DEFAULT 0,
  text_cost numeric NOT NULL DEFAULT 0,
  audio_provider text NULL,
  audio_seconds int NOT NULL DEFAULT 0,
  audio_cost numeric NOT NULL DEFAULT 0,
  email_cost numeric NOT NULL DEFAULT 0,
  storage_cost numeric NOT NULL DEFAULT 0,
  payment_fee numeric NOT NULL DEFAULT 0,
  total_cost numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.risk_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  user_id uuid NULL,
  anonymous_id text NULL,
  risk_level text NOT NULL,
  risk_domain text NULL,
  confidence numeric NULL,
  recommended_flow text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.knowledge_ledger (
  id text PRIMARY KEY,
  title text NOT NULL,
  canonical_source text NOT NULL,
  current_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  owner text NULL,
  status text NOT NULL DEFAULT 'draft',
  used_in jsonb NOT NULL DEFAULT '[]'::jsonb,
  requires_human_approval boolean NOT NULL DEFAULT true,
  last_updated timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  anonymous_id text NULL,
  category text NOT NULL,
  status text NOT NULL DEFAULT 'open',
  source text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.support_tickets IS
  'Support classification table. Avoid storing unnecessary emotional detail in metadata.';

CREATE TABLE IF NOT EXISTS public.cancellation_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  plan text NULL,
  cancel_reason text NULL,
  save_offer_shown text NULL,
  save_offer_accepted boolean NOT NULL DEFAULT false,
  final_cancel_completed boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS events_event_name_idx ON public.events (event_name);
CREATE INDEX IF NOT EXISTS events_session_id_idx ON public.events (session_id);
CREATE INDEX IF NOT EXISTS events_anonymous_id_idx ON public.events (anonymous_id);
CREATE INDEX IF NOT EXISTS events_created_at_idx ON public.events (created_at);
CREATE INDEX IF NOT EXISTS events_experiment_variant_idx ON public.events (experiment_id, variant_id);
CREATE INDEX IF NOT EXISTS events_user_id_idx ON public.events (user_id);

CREATE INDEX IF NOT EXISTS user_sessions_user_id_idx ON public.user_sessions (user_id);
CREATE INDEX IF NOT EXISTS user_sessions_anonymous_id_idx ON public.user_sessions (anonymous_id);
CREATE INDEX IF NOT EXISTS user_sessions_created_at_idx ON public.user_sessions (created_at);
CREATE INDEX IF NOT EXISTS user_sessions_experiment_variant_idx ON public.user_sessions (experiment_id, variant_id);

CREATE INDEX IF NOT EXISTS metric_snapshots_date_metric_idx ON public.metric_snapshots (date, metric_name);
CREATE INDEX IF NOT EXISTS metric_snapshots_experiment_variant_idx ON public.metric_snapshots (experiment_id, variant_id);

CREATE INDEX IF NOT EXISTS diagnosis_reports_date_severity_idx ON public.diagnosis_reports (date, severity);
CREATE INDEX IF NOT EXISTS diagnosis_reports_experiment_variant_idx ON public.diagnosis_reports (experiment_id, variant_id);

CREATE INDEX IF NOT EXISTS cost_logs_session_id_idx ON public.cost_logs (session_id);
CREATE INDEX IF NOT EXISTS cost_logs_user_id_idx ON public.cost_logs (user_id);

CREATE INDEX IF NOT EXISTS risk_logs_session_id_idx ON public.risk_logs (session_id);
CREATE INDEX IF NOT EXISTS risk_logs_user_id_idx ON public.risk_logs (user_id);

CREATE INDEX IF NOT EXISTS support_tickets_user_id_idx ON public.support_tickets (user_id);

CREATE INDEX IF NOT EXISTS cancellation_events_user_id_idx ON public.cancellation_events (user_id);

INSERT INTO public.experiments (
  id,
  name,
  hypothesis,
  primary_metric,
  guardrail_metrics,
  status
) VALUES (
  'launch_14d_v1',
  'Launch 14-day MVP vertical test',
  'Overthinking-before-sleep and confidence/inner-voice are the first viable acquisition wedges.',
  'helpful_session_rate',
  '[
    "worse_after_session_rate",
    "gross_margin_estimate",
    "paid_conversion_rate",
    "feels_personal_yes_somewhat_rate"
  ]'::jsonb,
  'draft'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  hypothesis = EXCLUDED.hypothesis,
  primary_metric = EXCLUDED.primary_metric,
  guardrail_metrics = EXCLUDED.guardrail_metrics,
  status = EXCLUDED.status;

INSERT INTO public.experiment_variants (
  experiment_id,
  variant_id,
  variant_name,
  allocation_percent,
  config
) VALUES
  (
    'launch_14d_v1',
    'overthinking_sleep',
    'Overthinking before sleep',
    50,
    '{"promise": "Turn tonight''s mental noise into a personalized calming audio."}'::jsonb
  ),
  (
    'launch_14d_v1',
    'confidence_inner_voice',
    'Confidence / inner voice',
    50,
    '{"promise": "Create a personalized confidence audio from the words holding you back."}'::jsonb
  )
ON CONFLICT (experiment_id, variant_id) DO UPDATE SET
  variant_name = EXCLUDED.variant_name,
  allocation_percent = EXCLUDED.allocation_percent,
  config = EXCLUDED.config;

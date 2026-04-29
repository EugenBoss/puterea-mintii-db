CREATE TABLE IF NOT EXISTS public.system_errors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service text NOT NULL,
  endpoint text NULL,
  error_code text NOT NULL,
  message_safe text NOT NULL,
  severity text NOT NULL,
  user_impact text NULL,
  suggested_action text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT system_errors_severity_check CHECK (
    severity IN ('info', 'warning', 'error', 'critical')
  ),
  CONSTRAINT system_errors_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

CREATE INDEX IF NOT EXISTS system_errors_created_at_idx
  ON public.system_errors (created_at DESC);

CREATE INDEX IF NOT EXISTS system_errors_service_created_at_idx
  ON public.system_errors (service, created_at DESC);

CREATE INDEX IF NOT EXISTS system_errors_severity_created_at_idx
  ON public.system_errors (severity, created_at DESC);

ALTER TABLE public.system_errors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_errors FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "system_errors_deny_client_access" ON public.system_errors;
CREATE POLICY "system_errors_deny_client_access"
ON public.system_errors
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

REVOKE ALL ON TABLE public.system_errors FROM anon, authenticated, PUBLIC;
GRANT ALL ON TABLE public.system_errors TO service_role;

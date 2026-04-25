-- ============================================================
-- ADMIN / MANAGER ROLES
-- Date: 25 April 2026
-- Goal:
--   Allow server-side admin dashboard access through profiles.admin_role.
--   Valid roles: admin, manager. NULL means normal user.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS admin_role text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_admin_role_check'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_admin_role_check
      CHECK (admin_role IS NULL OR admin_role IN ('admin', 'manager'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS profiles_admin_role_idx
  ON public.profiles (admin_role)
  WHERE admin_role IS NOT NULL;

-- Bootstrap first admin manually after deploy, replacing the email:
-- UPDATE public.profiles
-- SET admin_role = 'admin', updated_at = now()
-- WHERE lower(email) = lower('admin@example.com');

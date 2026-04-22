-- ============================================================
-- RLS FOR USER-FACING APP TABLES
-- Date: 22 April 2026
-- Goal:
--   Restrict browser access to authenticated users only,
--   and only to their own rows where applicable.
-- ============================================================

-- ----------------------------
-- 1. Enable RLS
-- ----------------------------
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.affirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.generations ENABLE ROW LEVEL SECURITY;

-- Remove broad grants if present.
REVOKE ALL ON TABLE public.profiles FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.affirmations FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.evaluations FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.generations FROM anon, PUBLIC;

-- ----------------------------
-- 2. profiles: user can read/update only own row
-- ----------------------------
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;

CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = id);

CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);

-- ----------------------------
-- 3. affirmations: authenticated user can read only own affirmations
-- Backend generates/inserts them via service_role.
-- ----------------------------
DROP POLICY IF EXISTS "affirmations_select_own" ON public.affirmations;

CREATE POLICY "affirmations_select_own"
ON public.affirmations
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- ----------------------------
-- 4. evaluations: authenticated user manages only own rows
-- ----------------------------
DROP POLICY IF EXISTS "evaluations_select_own" ON public.evaluations;
DROP POLICY IF EXISTS "evaluations_insert_own" ON public.evaluations;
DROP POLICY IF EXISTS "evaluations_update_own" ON public.evaluations;
DROP POLICY IF EXISTS "evaluations_delete_own" ON public.evaluations;

CREATE POLICY "evaluations_select_own"
ON public.evaluations
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "evaluations_insert_own"
ON public.evaluations
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "evaluations_update_own"
ON public.evaluations
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "evaluations_delete_own"
ON public.evaluations
FOR DELETE
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- ----------------------------
-- 5. generations: authenticated user manages only own rows
-- ----------------------------
DROP POLICY IF EXISTS "generations_select_own" ON public.generations;
DROP POLICY IF EXISTS "generations_insert_own" ON public.generations;
DROP POLICY IF EXISTS "generations_update_own" ON public.generations;
DROP POLICY IF EXISTS "generations_delete_own" ON public.generations;

CREATE POLICY "generations_select_own"
ON public.generations
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "generations_insert_own"
ON public.generations
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "generations_update_own"
ON public.generations
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "generations_delete_own"
ON public.generations
FOR DELETE
TO authenticated
USING ((SELECT auth.uid()) = user_id);

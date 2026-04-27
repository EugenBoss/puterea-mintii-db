-- ============================================================
-- Grant authenticated app users access to their own RLS-scoped rows.
-- RLS policies still restrict rows by auth.uid(); these grants only
-- restore table-level privileges required for browser Supabase client
-- History, generations, evaluations, and profile updates.
-- ============================================================

GRANT SELECT, UPDATE ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.affirmations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.evaluations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.generations TO authenticated;

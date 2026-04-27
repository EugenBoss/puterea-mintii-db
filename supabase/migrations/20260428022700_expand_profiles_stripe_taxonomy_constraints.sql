-- ============================================================
-- Transitional profiles constraint expansion.
--
-- Stripe/webhook code now writes the new public taxonomy
-- (pro, premium, lifetime), while live profiles and legacy
-- fallbacks still use crestere/transformare/training.
--
-- This migration only replaces check constraints. It does not
-- migrate rows, add subscription_plan validation, or change data.
-- ============================================================

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_tier_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_tier_check
  CHECK (
    tier = ANY (
      ARRAY[
        'free'::text,
        'pro'::text,
        'premium'::text,
        'lifetime'::text,
        'founding_lifetime'::text,
        'crestere'::text,
        'transformare'::text,
        'training'::text
      ]
    )
  );

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_stripe_subscription_status_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_stripe_subscription_status_check
  CHECK (
    stripe_subscription_status IS NULL
    OR stripe_subscription_status = ANY (
      ARRAY[
        'active'::text,
        'trialing'::text,
        'past_due'::text,
        'canceled'::text,
        'unpaid'::text,
        'payment_failed'::text,
        'paid'::text
      ]
    )
  );

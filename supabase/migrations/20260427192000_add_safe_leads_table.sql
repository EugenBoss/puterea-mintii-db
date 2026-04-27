-- Safe internal lead capture table.
-- This table stores safe lead metadata only.
-- It must not store raw emotional entries.
-- It must not store generated content.
-- It must not store evaluator text, scores, diagnoses, user problem text, or scripts.

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  source text null,
  locale text null,
  language text null,
  gdpr_consent text null,
  gdpr_timestamp timestamptz null,
  email_verified text null,
  plan_interest text null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_leads_email
  on public.leads (email);

create index if not exists idx_leads_created_at
  on public.leads (created_at desc);

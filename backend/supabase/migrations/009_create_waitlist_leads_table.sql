create table if not exists public.waitlist_leads (
  id uuid primary key default gen_random_uuid(),
  name text,
  email text not null,
  company text,
  phone text,
  message text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint waitlist_leads_email_not_blank check (btrim(email) <> '')
);

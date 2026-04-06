create extension if not exists pgcrypto;

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  company_size text not null,
  source text default 'landing_page',
  created_at timestamptz not null default now()
);

create unique index if not exists waitlist_email_unique
on public.waitlist (lower(email));

alter table public.waitlist enable row level security;

drop policy if exists "public can insert waitlist" on public.waitlist;
create policy "public can insert waitlist"
on public.waitlist
for insert
to anon, authenticated
with check (true);

drop policy if exists "no public reads waitlist" on public.waitlist;
create policy "no public reads waitlist"
on public.waitlist
for select
to anon, authenticated
using (false);
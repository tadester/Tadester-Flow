create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status public.organization_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint organizations_name_not_blank check (btrim(name) <> ''),
  constraint organizations_slug_not_blank check (btrim(slug) <> '')
);

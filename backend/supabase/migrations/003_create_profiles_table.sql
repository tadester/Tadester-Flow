create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  organization_id uuid not null references public.organizations (id) on delete restrict,
  email text not null,
  full_name text not null,
  role public.profile_role not null,
  status public.profile_status not null default 'active',
  phone text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profiles_email_not_blank check (btrim(email) <> ''),
  constraint profiles_full_name_not_blank check (btrim(full_name) <> '')
);

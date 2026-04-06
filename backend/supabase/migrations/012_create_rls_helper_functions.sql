create or replace function public.current_user_organization_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select organization_id
  from public.profiles
  where id = auth.uid()
  limit 1;
$$;

create or replace function public.current_user_profile_role()
returns public.profile_role
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid()
  limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_profile_role() = 'admin', false);
$$;

create or replace function public.is_dispatcher_or_operator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    public.current_user_profile_role() in ('dispatcher', 'operator'),
    false
  );
$$;

create or replace function public.is_field_worker()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_profile_role() = 'field_worker', false);
$$;

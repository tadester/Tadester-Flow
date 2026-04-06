create extension if not exists pgcrypto;

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'organization_status'
  ) then
    create type public.organization_status as enum ('active', 'inactive');
  end if;

  if not exists (
    select 1 from pg_type where typname = 'profile_role'
  ) then
    create type public.profile_role as enum (
      'admin',
      'dispatcher',
      'operator',
      'field_worker'
    );
  end if;

  if not exists (
    select 1 from pg_type where typname = 'profile_status'
  ) then
    create type public.profile_status as enum ('active', 'inactive');
  end if;

  if not exists (
    select 1 from pg_type where typname = 'location_status'
  ) then
    create type public.location_status as enum ('active', 'inactive');
  end if;

  if not exists (
    select 1 from pg_type where typname = 'job_status'
  ) then
    create type public.job_status as enum (
      'draft',
      'scheduled',
      'in_progress',
      'completed',
      'cancelled'
    );
  end if;

  if not exists (
    select 1 from pg_type where typname = 'job_priority'
  ) then
    create type public.job_priority as enum ('low', 'medium', 'high', 'urgent');
  end if;

  if not exists (
    select 1 from pg_type where typname = 'assignment_status'
  ) then
    create type public.assignment_status as enum (
      'assigned',
      'accepted',
      'rejected',
      'unassigned',
      'completed'
    );
  end if;

  if not exists (
    select 1 from pg_type where typname = 'ping_source'
  ) then
    create type public.ping_source as enum (
      'mobile_foreground',
      'mobile_background',
      'manual_test'
    );
  end if;

  if not exists (
    select 1 from pg_type where typname = 'location_event_type'
  ) then
    create type public.location_event_type as enum (
      'geofence_enter',
      'geofence_exit',
      'arrival',
      'departure',
      'job_started',
      'job_completed'
    );
  end if;
end $$;

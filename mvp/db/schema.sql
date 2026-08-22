create extension if not exists pgcrypto;

create type lead_status as enum ('new','engaged','qualified','hot','handoff','won','lost');
create type activity_type as enum ('inbound','outbound','follow_up','note','handoff','outcome');

create table if not exists leads (
  id uuid primary key default gen_random_uuid(),
  external_id text,
  source text not null default 'manual',
  name text,
  phone text,
  email text,
  message text,
  status lead_status not null default 'new',
  score int not null default 0 check (score between 0 and 100),
  intent text,
  estimated_value numeric(12,2),
  recovered boolean not null default false,
  next_action text,
  next_follow_up_at timestamptz,
  last_contact_at timestamptz,
  assigned_to text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references leads(id) on delete cascade,
  type activity_type not null,
  channel text not null default 'manual',
  direction text,
  body text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists outcomes (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null unique references leads(id) on delete cascade,
  outcome lead_status not null check (outcome in ('won','lost')),
  revenue numeric(12,2) not null default 0,
  recovered_revenue numeric(12,2) not null default 0,
  reason text,
  closed_at timestamptz not null default now()
);

create index if not exists idx_leads_status on leads(status);
create index if not exists idx_leads_score on leads(score desc);
create index if not exists idx_leads_follow_up on leads(next_follow_up_at) where next_follow_up_at is not null;
create index if not exists idx_activities_lead_created on activities(lead_id, created_at desc);

create or replace function touch_updated_at() returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists leads_touch_updated_at on leads;
create trigger leads_touch_updated_at before update on leads
for each row execute function touch_updated_at();

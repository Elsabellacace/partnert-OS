-- Partner-OS AI · Supabase/PostgreSQL schema
-- MVP multiusuario: cada Growth Partner solo ve sus propios clientes y datos relacionados.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  market text,
  offer text,
  ideal_customer text,
  goal text,
  links text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scans (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  frictions jsonb not null default '[]'::jsonb,
  opportunities jsonb not null default '[]'::jsonb,
  next_actions jsonb not null default '[]'::jsonb,
  recommended_priority text,
  source text not null default 'growth_scanner',
  created_at timestamptz not null default now()
);

create table if not exists public.opportunities (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  scan_id uuid references public.scans(id) on delete set null,
  title text not null,
  description text,
  priority text not null default 'Media' check (priority in ('Alta','Media','Baja')),
  next_action text,
  status text not null default 'Detectada' check (status in ('Detectada','Analizando','Propuesta','En ejecución','Resultado','Cerrada')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  title text not null,
  objective text not null,
  priority text,
  next_action text,
  status text not null default 'Listo para ejecutar',
  steps jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.executions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  plan_id uuid not null unique references public.plans(id) on delete cascade,
  completed_steps jsonb not null default '[]'::jsonb,
  observed_result text,
  status text not null default 'En ejecución' check (status in ('En ejecución','Ejecutado')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.results (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  plan_id uuid not null unique references public.plans(id) on delete cascade,
  execution_id uuid references public.executions(id) on delete set null,
  metric text not null,
  direction text not null default 'up' check (direction in ('up','down')),
  before_value numeric not null,
  after_value numeric not null,
  observed text,
  learning text,
  verdict text,
  next_decision text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.decisions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  plan_id uuid not null unique references public.plans(id) on delete cascade,
  result_id uuid references public.results(id) on delete set null,
  decision text not null check (decision in ('Escalar','Mantener','Corregir','Descartar')),
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists clients_owner_id_idx on public.clients(owner_id);
create index if not exists scans_client_id_idx on public.scans(client_id);
create index if not exists opportunities_client_id_idx on public.opportunities(client_id);
create index if not exists plans_client_id_idx on public.plans(client_id);
create index if not exists executions_client_id_idx on public.executions(client_id);
create index if not exists results_client_id_idx on public.results(client_id);
create index if not exists decisions_client_id_idx on public.decisions(client_id);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.scans enable row level security;
alter table public.opportunities enable row level security;
alter table public.plans enable row level security;
alter table public.executions enable row level security;
alter table public.results enable row level security;
alter table public.decisions enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "clients_select_own" on public.clients for select using (auth.uid() = owner_id);
create policy "clients_insert_own" on public.clients for insert with check (auth.uid() = owner_id);
create policy "clients_update_own" on public.clients for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "clients_delete_own" on public.clients for delete using (auth.uid() = owner_id);

create policy "scans_own_client" on public.scans for all
using (exists (select 1 from public.clients c where c.id = scans.client_id and c.owner_id = auth.uid()))
with check (exists (select 1 from public.clients c where c.id = scans.client_id and c.owner_id = auth.uid()));

create policy "opportunities_own_client" on public.opportunities for all
using (exists (select 1 from public.clients c where c.id = opportunities.client_id and c.owner_id = auth.uid()))
with check (exists (select 1 from public.clients c where c.id = opportunities.client_id and c.owner_id = auth.uid()));

create policy "plans_own_client" on public.plans for all
using (exists (select 1 from public.clients c where c.id = plans.client_id and c.owner_id = auth.uid()))
with check (exists (select 1 from public.clients c where c.id = plans.client_id and c.owner_id = auth.uid()));

create policy "executions_own_client" on public.executions for all
using (exists (select 1 from public.clients c where c.id = executions.client_id and c.owner_id = auth.uid()))
with check (exists (select 1 from public.clients c where c.id = executions.client_id and c.owner_id = auth.uid()));

create policy "results_own_client" on public.results for all
using (exists (select 1 from public.clients c where c.id = results.client_id and c.owner_id = auth.uid()))
with check (exists (select 1 from public.clients c where c.id = results.client_id and c.owner_id = auth.uid()));

create policy "decisions_own_client" on public.decisions for all
using (exists (select 1 from public.clients c where c.id = decisions.client_id and c.owner_id = auth.uid()))
with check (exists (select 1 from public.clients c where c.id = decisions.client_id and c.owner_id = auth.uid()));

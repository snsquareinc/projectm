-- Phase 1 addendum: which contractors are assigned to which project.
-- Run once in Supabase after 001_phase1.sql. Safe to re-run.

create table if not exists project_vendors (
  project_id uuid not null references projects(id) on delete cascade,
  vendor_id uuid not null references vendors(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (project_id, vendor_id)
);

alter table project_vendors enable row level security;

drop policy if exists "signed-in full access" on project_vendors;
create policy "signed-in full access" on project_vendors for all to authenticated using (true) with check (true);

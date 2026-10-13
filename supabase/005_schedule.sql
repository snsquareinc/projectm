-- Phase 2: project schedule. Tasks with start and end dates, linked to a budget line.
-- Run once in Supabase after 001 to 004. Safe to re-run.

create table if not exists schedule_tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  budget_line_id uuid references project_lines(id) on delete set null,
  name text not null,
  start_date date not null,
  end_date date not null,
  percent_complete numeric not null default 0 check (percent_complete between 0 and 100),
  notes text not null default '',
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);

alter table schedule_tasks enable row level security;

drop policy if exists "signed-in full access" on schedule_tasks;
create policy "signed-in full access" on schedule_tasks for all to authenticated using (true) with check (true);

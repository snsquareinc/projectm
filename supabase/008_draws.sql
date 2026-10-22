-- Phase 3: bank draws. A draw is one funding request to the bank.
-- Run once in Supabase after 001 to 007. Safe to re-run.

create table if not exists draws (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  draw_number int not null,
  status text not null default 'Draft' check (status in ('Draft', 'Sent', 'Funded')),
  due_date date,
  funded_amount numeric not null default 0,
  funded_date date,
  created_at timestamptz not null default now(),
  unique (project_id, draw_number)
);

-- One row per budget line per draw: how much of the line is built as of that draw.
create table if not exists draw_lines (
  id uuid primary key default gen_random_uuid(),
  draw_id uuid not null references draws(id) on delete cascade,
  budget_line_id uuid not null references project_lines(id) on delete cascade,
  percent_built numeric not null default 0 check (percent_built between 0 and 100),
  bank_funds boolean not null default true,
  unique (draw_id, budget_line_id)
);

alter table draws enable row level security;
alter table draw_lines enable row level security;

drop policy if exists "signed-in full access" on draws;
create policy "signed-in full access" on draws for all to authenticated using (true) with check (true);

drop policy if exists "signed-in full access" on draw_lines;
create policy "signed-in full access" on draw_lines for all to authenticated using (true) with check (true);

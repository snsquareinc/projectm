-- Phase 4: project photos. Files live in the private 'receipts' bucket under photos/<project id>/.
-- Run once in Supabase after 001 to 008. Safe to re-run.

create table if not exists project_photos (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  path text not null,                              -- file in the 'receipts' bucket
  taken_on date not null default current_date,
  caption text not null default '',
  created_at timestamptz not null default now()
);

alter table project_photos enable row level security;

drop policy if exists "signed-in full access" on project_photos;
create policy "signed-in full access" on project_photos for all to authenticated using (true) with check (true);

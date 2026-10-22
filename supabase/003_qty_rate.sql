-- Sq.Ft. / Qty and Rate per budget line. Budget = Qty x Rate.
-- Run once in Supabase after 001 and 002. Safe to re-run.

alter table project_lines add column if not exists qty numeric not null default 1;
alter table project_lines add column if not exists rate numeric not null default 0;

-- Existing lines keep their budget: quantity 1 at the old budget amount.
update project_lines set rate = budget where rate = 0 and budget <> 0;

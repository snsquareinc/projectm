-- Unit and notes on each budget line. Run once after 001 to 003. Safe to re-run.

alter table project_lines add column if not exists unit text not null default '';
alter table project_lines add column if not exists notes text not null default '';

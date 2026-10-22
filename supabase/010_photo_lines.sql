-- Phase 4b: link a photo to a budget line. Run once after 009. Safe to re-run.
alter table project_photos add column if not exists budget_line_id uuid references project_lines(id) on delete set null;

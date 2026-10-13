-- Notes on each transaction (payment). Run once in Supabase after 001 to 005. Safe to re-run.
alter table payments add column if not exists notes text not null default '';

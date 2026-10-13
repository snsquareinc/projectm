-- Signed contract amount per budget line.
-- Budget stays the amount set aside; Contract is what was signed.
alter table project_lines add column if not exists contract_amount numeric not null default 0;

-- Free-form budget lines (custom lines and division-level lines) get their own number,
-- such as 040-901, shown in the Code column. Library sub-tasks keep their library code.
alter table project_lines add column if not exists line_code text;

-- Number the existing free-form lines, 901 upward, within each project and division.
with numbered as (
  select id, row_number() over (partition by project_id, division_code order by created_at, id) as n
  from project_lines
  where subtask_code is null and line_code is null
)
update project_lines pl
set line_code = left(pl.division_code, 4) || (900 + numbered.n)::text
from numbered
where pl.id = numbered.id;

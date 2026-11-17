-- Link each project to its Google Drive folder. The Files page opens it.
alter table projects add column if not exists drive_url text;

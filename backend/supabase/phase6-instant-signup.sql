-- Provider signup: active immediately, no approval gate
alter table khade_providers alter column status set default 'active';
alter table khade_providers alter column verified set default 0;

update khade_providers set status = 'active' where status in ('pending_review', 'pending', 'under_review');

drop policy if exists "active providers only" on khade_providers;
drop policy if exists "pending providers blocked" on khade_providers;

-- Optional: drop legacy document columns
alter table khade_providers drop column if exists cac_number;

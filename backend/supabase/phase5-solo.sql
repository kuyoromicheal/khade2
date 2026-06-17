-- Solo Pro provider subtype (khade_* tables)

alter table khade_providers add column if not exists provider_subtype text default 'solo_pro';
alter table khade_providers add column if not exists work_locations text[] default '{}';
alter table khade_providers add column if not exists coverage_areas text[] default '{}';

update khade_providers set provider_subtype = 'salon'
  where provider_type = 'salon' and provider_subtype = 'solo_pro';
update khade_providers set provider_subtype = 'mobile'
  where provider_type = 'mobile' and provider_subtype = 'solo_pro';

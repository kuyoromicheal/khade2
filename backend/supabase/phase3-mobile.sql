-- Mobile provider support (khade_* tables)

alter table khade_providers add column if not exists provider_type text default 'mobile';
alter table khade_providers add column if not exists travel_radius_km int default 10;
alter table khade_providers add column if not exists travel_fee_per_km numeric default 0;
alter table khade_providers add column if not exists min_travel_fee numeric default 0;
alter table khade_providers add column if not exists base_area text;

-- Infer from visit_types where possible
update khade_providers set provider_type = 'salon' where visit_types = 'salon' and provider_type is null;
update khade_providers set provider_type = 'both' where visit_types = 'both' and provider_type = 'mobile';
update khade_providers set base_area = area where base_area is null;

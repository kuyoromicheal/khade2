-- Khade v3 — wallet, provider detail, views (khade_* prefix, safe to re-run)

-- Provider detail columns
alter table khade_providers add column if not exists photos text[] default '{}';
alter table khade_providers add column if not exists opening_hours jsonb default '{
  "monday":{"open":"09:00","close":"19:00"},
  "tuesday":{"open":"09:00","close":"19:00"},
  "wednesday":{"open":"09:00","close":"19:00"},
  "thursday":{"open":"09:00","close":"20:00"},
  "friday":{"open":"09:00","close":"20:00"},
  "saturday":{"open":"08:00","close":"21:00"},
  "sunday":null
}'::jsonb;
alter table khade_providers add column if not exists is_verified boolean default false;
alter table khade_providers add column if not exists instant_confirm boolean default true;
alter table khade_providers add column if not exists does_home_visits boolean default true;
alter table khade_providers add column if not exists has_salon boolean default false;
alter table khade_providers add column if not exists accepts_groups boolean default true;
alter table khade_providers add column if not exists is_certified boolean default false;
alter table khade_providers add column if not exists has_team boolean default false;
alter table khade_providers add column if not exists location_area text;

-- Sync verified flag from existing column
update khade_providers set is_verified = true where verified = 1 and is_verified = false;

-- Customer loyalty
alter table khade_users add column if not exists loyalty_points int default 0;
alter table khade_users add column if not exists total_bookings int default 0;

-- Wallet transaction status
alter table khade_wallet_transactions add column if not exists status text default 'completed';

-- Provider views (recently viewed)
create table if not exists khade_provider_views (
  id serial primary key,
  user_id int references khade_users(id) on delete cascade,
  provider_id int references khade_providers(id) on delete cascade,
  viewed_at timestamptz default now(),
  unique(user_id, provider_id)
);

-- Provider photos gallery
create table if not exists khade_provider_photos (
  id serial primary key,
  provider_id int references khade_providers(id) on delete cascade,
  url text not null,
  display_order int default 0,
  created_at timestamptz default now()
);

-- Provider branches (multi-location)
create table if not exists khade_provider_branches (
  id serial primary key,
  provider_id int references khade_providers(id) on delete cascade,
  branch_name text,
  address text,
  lat numeric,
  lng numeric,
  is_primary boolean default false
);

alter table khade_provider_views disable row level security;
alter table khade_provider_photos disable row level security;
alter table khade_provider_branches disable row level security;

do $$ begin
  alter publication supabase_realtime add table khade_wallet_transactions;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table khade_users;
exception when duplicate_object then null;
end $$;

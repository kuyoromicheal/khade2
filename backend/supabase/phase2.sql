-- Khade Phase 2 schema extensions
-- Run after schema.sql and auth-extensions.sql

alter table khade_users add column if not exists tier text default 'Bronze';
alter table khade_bookings add column if not exists note text;
alter table khade_providers add column if not exists provider_tier text default 'Bronze';
alter table khade_providers add column if not exists cac_number text;
alter table khade_providers add column if not exists business_name text;

create table if not exists khade_messages (
  id int primary key,
  booking_id int references khade_bookings(id) on delete cascade,
  sender_id int references khade_users(id),
  body text not null,
  created_at timestamptz default now()
);

create table if not exists khade_provider_locations (
  provider_id int primary key references khade_providers(id) on delete cascade,
  lat numeric,
  lng numeric,
  updated_at timestamptz default now()
);

create table if not exists khade_booking_groups (
  id int primary key,
  lead_user_id int references khade_users(id),
  title text,
  event_date timestamptz,
  status text default 'pending',
  created_at timestamptz default now()
);

alter table khade_messages disable row level security;
alter table khade_provider_locations disable row level security;
alter table khade_booking_groups disable row level security;

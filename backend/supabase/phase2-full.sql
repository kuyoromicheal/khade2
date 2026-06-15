-- Khade Phase 2 full schema — run after schema.sql + auth-extensions.sql
-- Safe to re-run (IF NOT EXISTS)

alter table khade_users add column if not exists tier text default 'Bronze';
alter table khade_users add column if not exists role text default 'customer';
alter table khade_users add column if not exists password_hash text;
alter table khade_users add column if not exists provider_id int references khade_providers(id);
alter table khade_users add column if not exists gold_subscriber int default 0;
alter table khade_bookings add column if not exists note text;
alter table khade_bookings add column if not exists group_id int;
alter table khade_bookings add column if not exists payment_reference text;
alter table khade_bookings add column if not exists payment_status text default 'pending';
alter table khade_providers add column if not exists provider_tier text default 'Bronze';
alter table khade_providers add column if not exists cac_number text;
alter table khade_providers add column if not exists business_name text;
alter table khade_providers add column if not exists owner_user_id int;
alter table khade_providers add column if not exists bio text;
alter table khade_providers add column if not exists visit_types text default 'both';
alter table khade_providers add column if not exists availability jsonb default '{}'::jsonb;
alter table khade_providers add column if not exists earnings_balance int default 0;

create table if not exists khade_messages (
  id int primary key,
  booking_id int references khade_bookings(id) on delete cascade,
  sender_id int references khade_users(id),
  sender_name text,
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
  guest_count int default 1,
  address text,
  status text default 'pending',
  created_at timestamptz default now()
);

create table if not exists khade_client_profiles (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  user_id int references khade_users(id),
  name text,
  phone text,
  notes text,
  allergies text,
  color_formula text,
  lifetime_value int default 0,
  visit_count int default 0,
  last_visit timestamptz,
  created_at timestamptz default now()
);

create table if not exists khade_staff (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  name text not null,
  role text,
  phone text,
  active int default 1,
  created_at timestamptz default now()
);

create table if not exists khade_inventory (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  name text not null,
  sku text,
  quantity int default 0,
  reorder_level int default 5,
  unit_price int default 0,
  created_at timestamptz default now()
);

create table if not exists khade_campaigns (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  title text,
  message text,
  channel text default 'sms',
  sent_count int default 0,
  status text default 'draft',
  created_at timestamptz default now()
);

create table if not exists khade_capital_loans (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  amount int not null,
  purpose text,
  status text default 'pending',
  repayment_pct numeric default 10,
  created_at timestamptz default now()
);

create table if not exists khade_payouts (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  amount int not null,
  status text default 'pending',
  bank_name text,
  account_number text,
  created_at timestamptz default now(),
  processed_at timestamptz
);

create table if not exists khade_platform_revenue (
  id int primary key,
  source text not null,
  amount int not null,
  reference text,
  created_at timestamptz default now()
);

create table if not exists khade_fcm_tokens (
  id int primary key,
  user_id int references khade_users(id) on delete cascade,
  token text not null,
  platform text,
  created_at timestamptz default now()
);

create table if not exists khade_pending_payments (
  reference text primary key,
  user_id int,
  amount int,
  purpose text,
  booking_meta jsonb,
  status text default 'pending',
  created_at timestamptz default now()
);

alter table khade_messages disable row level security;
alter table khade_provider_locations disable row level security;
alter table khade_booking_groups disable row level security;
alter table khade_client_profiles disable row level security;
alter table khade_staff disable row level security;
alter table khade_inventory disable row level security;
alter table khade_campaigns disable row level security;
alter table khade_capital_loans disable row level security;
alter table khade_payouts disable row level security;
alter table khade_platform_revenue disable row level security;
alter table khade_fcm_tokens disable row level security;
alter table khade_pending_payments disable row level security;

-- Enable Supabase Realtime (run if publication exists)
do $$ begin
  alter publication supabase_realtime add table khade_notifications;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table khade_wallet_transactions;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table khade_feed_posts;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table khade_messages;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table khade_provider_locations;
exception when duplicate_object then null;
end $$;

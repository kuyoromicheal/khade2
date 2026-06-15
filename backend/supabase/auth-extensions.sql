-- Run after schema.sql — auth, provider ops, monetization
-- Safe to re-run (IF NOT EXISTS / additive)

alter table khade_users add column if not exists role text default 'customer';
alter table khade_users add column if not exists password_hash text;
alter table khade_users add column if not exists provider_id int references khade_providers(id);
alter table khade_users add column if not exists gold_subscriber int default 0;

alter table khade_providers add column if not exists owner_user_id int references khade_users(id);
alter table khade_providers add column if not exists bio text;
alter table khade_providers add column if not exists visit_types text default 'both';
alter table khade_providers add column if not exists availability jsonb default '{}'::jsonb;
alter table khade_providers add column if not exists earnings_balance int default 0;
alter table khade_providers add column if not exists featured_until timestamptz;
alter table khade_providers add column if not exists boost_until timestamptz;
alter table khade_providers add column if not exists verified_paid int default 0;

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

alter table khade_payouts disable row level security;
alter table khade_platform_revenue disable row level security;

-- Khade Supabase schema (prefixed khade_* to avoid conflicts with existing tables)
-- Run in Supabase Dashboard → SQL Editor → New query → Run

-- Safe re-run: drops only Khade tables
drop table if exists khade_feed_comments cascade;
drop table if exists khade_feed_posts cascade;
drop table if exists khade_reviews cascade;
drop table if exists khade_wallet_transactions cascade;
drop table if exists khade_notifications cascade;
drop table if exists khade_bookings cascade;
drop table if exists khade_services cascade;
drop table if exists khade_providers cascade;
drop table if exists khade_users cascade;
drop table if exists khade_categories cascade;
drop table if exists khade_counters cascade;

create table khade_categories (
  id int primary key,
  slug text not null,
  label text not null,
  emoji text,
  filter text,
  image_url text
);

create table khade_users (
  id int primary key,
  name text not null,
  email text,
  phone text,
  city text,
  tier text,
  wallet_balance int default 0,
  bookings_count int default 0,
  saved_providers int default 0,
  saved_provider_ids jsonb default '[]'::jsonb,
  member_since int,
  created_at timestamptz
);

create table khade_providers (
  id int primary key,
  status text default 'active',
  name text not null,
  category text,
  category_slug text,
  emoji text,
  rating numeric default 0,
  review_count int default 0,
  distance_km numeric,
  latitude numeric,
  longitude numeric,
  area text,
  price_from int,
  badge text,
  verified int default 0,
  featured int default 0,
  gradient_start text,
  gradient_end text,
  image_url text,
  avatar_url text,
  phone text
);

create table khade_services (
  id int primary key,
  provider_id int references khade_providers(id) on delete cascade,
  name text not null,
  duration text,
  price int not null
);

create table khade_bookings (
  id int primary key,
  user_id int references khade_users(id) on delete cascade,
  provider_id int references khade_providers(id),
  service_id int references khade_services(id),
  status text default 'upcoming',
  location_type text,
  address text,
  dest_lat numeric,
  dest_lng numeric,
  scheduled_at timestamptz,
  total_amount int,
  booking_code text,
  payment_method text,
  created_at timestamptz default now()
);

create table khade_feed_posts (
  id int primary key,
  provider_id int references khade_providers(id),
  image_emoji text,
  image_url text,
  video_url text,
  media_type text default 'image',
  badge text,
  caption text,
  likes int default 0,
  comments int default 0,
  liked_by jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

create table khade_feed_comments (
  id int primary key,
  feed_post_id int references khade_feed_posts(id) on delete cascade,
  user_id int references khade_users(id),
  author_name text,
  text text not null,
  created_at timestamptz default now()
);

create table khade_notifications (
  id int primary key,
  user_id int references khade_users(id) on delete cascade,
  title text,
  body text,
  emoji text,
  read int default 0,
  created_at timestamptz default now()
);

create table khade_wallet_transactions (
  id int primary key,
  user_id int references khade_users(id) on delete cascade,
  type text not null,
  amount int not null,
  description text,
  reference text,
  created_at timestamptz default now()
);

create table khade_reviews (
  id int primary key,
  user_id int references khade_users(id),
  provider_id int references khade_providers(id) on delete cascade,
  rating int not null,
  comment text,
  author_name text,
  created_at timestamptz default now()
);

create table khade_counters (
  table_name text primary key,
  value int not null default 0
);

-- Backend-only tables: RLS off (API uses service_role key; never expose that key in the app)
alter table khade_categories disable row level security;
alter table khade_users disable row level security;
alter table khade_providers disable row level security;
alter table khade_services disable row level security;
alter table khade_bookings disable row level security;
alter table khade_feed_posts disable row level security;
alter table khade_feed_comments disable row level security;
alter table khade_notifications disable row level security;
alter table khade_wallet_transactions disable row level security;
alter table khade_reviews disable row level security;
alter table khade_counters disable row level security;

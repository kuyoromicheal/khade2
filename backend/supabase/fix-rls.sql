-- Run this if migration fails with "row-level security policy"
-- Supabase SQL Editor → paste → Run

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

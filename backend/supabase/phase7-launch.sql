-- Launch readiness: provider bank details, FCM token, realtime tables

alter table khade_providers add column if not exists bank_code text;
alter table khade_providers add column if not exists bank_name text;
alter table khade_providers add column if not exists bank_account_number text;
alter table khade_providers add column if not exists bank_account_name text;

alter table khade_users add column if not exists fcm_token text;

create index if not exists idx_khade_bookings_provider on khade_bookings(provider_id);
create index if not exists idx_khade_bookings_user on khade_bookings(user_id);
create index if not exists idx_khade_messages_booking on khade_messages(booking_id);
create index if not exists idx_khade_wallet_user on khade_wallet_transactions(user_id);

do $$ begin
  alter publication supabase_realtime add table khade_bookings;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table khade_messages;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table khade_feed_posts;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table khade_feed_comments;
exception when duplicate_object then null;
end $$;

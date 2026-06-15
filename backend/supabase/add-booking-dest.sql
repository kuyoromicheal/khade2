-- Run if bookings table already exists without GPS destination columns
alter table khade_bookings add column if not exists dest_lat numeric;
alter table khade_bookings add column if not exists dest_lng numeric;

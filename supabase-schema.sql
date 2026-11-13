-- ============================================================
-- PaySync — Supabase Schema
-- Jalankan keseluruhan SQL ini dalam:
-- Supabase Dashboard → SQL Editor → New Query → Paste → Run
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ============================================================
-- TABLE: trips
-- ============================================================
create table if not exists trips (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  emoji         text default '✈️',
  date_start    date,
  date_end      date,
  default_currency text default 'RM',
  status        text default 'active' check (status in ('active','completed','archived')),
  password_hash text,
  created_at    timestamptz default now()
);

-- ============================================================
-- TABLE: members
-- ============================================================
create table if not exists members (
  id         uuid primary key default gen_random_uuid(),
  trip_id    uuid references trips(id) on delete cascade,
  name       text not null,
  joined_at  date default current_date,
  created_at timestamptz default now()
);

-- ============================================================
-- TABLE: expenses
-- ============================================================
create table if not exists expenses (
  id           uuid primary key default gen_random_uuid(),
  trip_id      uuid references trips(id) on delete cascade,
  description  text not null,
  amount       numeric(12,2) not null,
  currency     text not null default 'RM',
  category     text default 'other',
  split_method text default 'equal',
  expense_date date,
  notes        text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- ============================================================
-- TABLE: payers (siapa yang bayar untuk sesuatu expense)
-- ============================================================
create table if not exists payers (
  id          uuid primary key default gen_random_uuid(),
  expense_id  uuid references expenses(id) on delete cascade,
  member_name text not null,
  amount      numeric(12,2) not null
);

-- ============================================================
-- TABLE: splits (pengagihan expense kepada ahli)
-- ============================================================
create table if not exists splits (
  id          uuid primary key default gen_random_uuid(),
  expense_id  uuid references expenses(id) on delete cascade,
  member_name text not null,
  amount      numeric(12,2) not null
);

-- ============================================================
-- TABLE: settlements (rekod pembayaran hutang)
-- ============================================================
create table if not exists settlements (
  id           uuid primary key default gen_random_uuid(),
  trip_id      uuid references trips(id) on delete cascade,
  from_member  text not null,
  to_member    text not null,
  currency     text not null,
  amount_paid  numeric(12,2) not null,
  notes        text,
  settle_date  date default current_date,
  created_at   timestamptz default now()
);

-- ============================================================
-- TABLE: activity_log
-- ============================================================
create table if not exists activity_log (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid references trips(id) on delete cascade,
  description text not null,
  created_at  timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Benarkan semua akses melalui anon key (trip dilindungi password dalam app)
-- ============================================================
alter table trips        enable row level security;
alter table members      enable row level security;
alter table expenses     enable row level security;
alter table payers       enable row level security;
alter table splits       enable row level security;
alter table settlements  enable row level security;
alter table activity_log enable row level security;

-- Policy: benarkan semua operasi untuk anon (kawalan akses dibuat dalam app)
create policy "allow_all_trips"        on trips        for all to anon using (true) with check (true);
create policy "allow_all_members"      on members      for all to anon using (true) with check (true);
create policy "allow_all_expenses"     on expenses     for all to anon using (true) with check (true);
create policy "allow_all_payers"       on payers       for all to anon using (true) with check (true);
create policy "allow_all_splits"       on splits       for all to anon using (true) with check (true);
create policy "allow_all_settlements"  on settlements  for all to anon using (true) with check (true);
create policy "allow_all_activity_log" on activity_log for all to anon using (true) with check (true);

-- ============================================================
-- REALTIME: aktifkan untuk semua table supaya perubahan
-- dapat dilihat secara langsung oleh semua pengguna
-- ============================================================
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;

alter publication supabase_realtime add table trips;
alter publication supabase_realtime add table members;
alter publication supabase_realtime add table expenses;
alter publication supabase_realtime add table payers;
alter publication supabase_realtime add table splits;
alter publication supabase_realtime add table settlements;
alter publication supabase_realtime add table activity_log;

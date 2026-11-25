-- =====================================================
-- Skema database online CoinWise (Supabase / PostgreSQL)
-- Tempel semua isi file ini di Supabase > SQL Editor > Run
-- =====================================================

create table if not exists public.users (
  username      text primary key,
  name          text not null,
  email         text not null unique,
  salt          text not null,
  password_hash text not null,
  created_at    timestamptz not null default now()
);

create table if not exists public.blockchain (
  username  text not null references public.users(username) on delete cascade,
  idx       integer not null,
  data      text not null,
  ts        bigint not null,
  prev_hash text not null,
  nonce     bigint not null,
  hash      text not null,
  primary key (username, idx)
);

create table if not exists public.skor_game (
  username text not null references public.users(username) on delete cascade,
  skor     integer not null,
  waktu    bigint not null,
  primary key (username, waktu)
);

create table if not exists public.saran_kesan (
  username text not null references public.users(username) on delete cascade,
  rating   integer not null,
  kategori text not null,
  kesan    text not null,
  saran    text not null,
  waktu    bigint not null,
  primary key (username, waktu)
);

-- Izin untuk aplikasi (role "anon" = pemakai publishable/anon key)
grant usage on schema public to anon;
grant select, insert on public.users       to anon;
grant select, insert on public.blockchain  to anon;
grant select, insert on public.skor_game   to anon;
grant select, insert on public.saran_kesan to anon;

-- Row Level Security: hanya boleh membaca dan menambah (tidak boleh ubah/hapus)
alter table public.users       enable row level security;
alter table public.blockchain  enable row level security;
alter table public.skor_game   enable row level security;
alter table public.saran_kesan enable row level security;

create policy "users_select"  on public.users       for select to anon using (true);
create policy "users_insert"  on public.users       for insert to anon with check (true);
create policy "chain_select"  on public.blockchain  for select to anon using (true);
create policy "chain_insert"  on public.blockchain  for insert to anon with check (true);
create policy "skor_select"   on public.skor_game   for select to anon using (true);
create policy "skor_insert"   on public.skor_game   for insert to anon with check (true);
create policy "saran_select"  on public.saran_kesan for select to anon using (true);
create policy "saran_insert"  on public.saran_kesan for insert to anon with check (true);

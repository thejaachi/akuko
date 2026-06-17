-- =====================================================================
-- Akuko — 0010_book_requests.sql
-- User book requests + reading circles (community MVP).
-- =====================================================================

create table if not exists public.book_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null,
  author      text,
  genre       text,
  notes       text,
  status      text not null default 'pending'
                check (status in ('pending', 'fulfilled', 'rejected')),
  created_at  timestamptz not null default now()
);

create index if not exists idx_book_requests_user
  on public.book_requests (user_id, created_at desc);

alter table public.book_requests enable row level security;

drop policy if exists book_requests_select_own on public.book_requests;
create policy book_requests_select_own on public.book_requests
  for select using (auth.uid() = user_id);

drop policy if exists book_requests_insert_own on public.book_requests;
create policy book_requests_insert_own on public.book_requests
  for insert with check (auth.uid() = user_id);

-- Reading circles (optional Supabase backing; app also ships mock data).
create table if not exists public.reading_circles (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  book_id       uuid references public.books (id) on delete set null,
  description   text,
  member_count  integer not null default 0,
  is_public     boolean not null default true,
  created_by    uuid references auth.users (id) on delete set null,
  created_at    timestamptz not null default now()
);

create table if not exists public.reading_circle_members (
  circle_id   uuid not null references public.reading_circles (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  joined_at   timestamptz not null default now(),
  primary key (circle_id, user_id)
);

alter table public.reading_circles enable row level security;
alter table public.reading_circle_members enable row level security;

drop policy if exists reading_circles_select_public on public.reading_circles;
create policy reading_circles_select_public on public.reading_circles
  for select using (is_public = true or created_by = auth.uid());

drop policy if exists reading_circle_members_select_own on public.reading_circle_members;
create policy reading_circle_members_select_own on public.reading_circle_members
  for select using (auth.uid() = user_id);

drop policy if exists reading_circle_members_insert_own on public.reading_circle_members;
create policy reading_circle_members_insert_own on public.reading_circle_members
  for insert with check (auth.uid() = user_id);

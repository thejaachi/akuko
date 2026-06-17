-- =====================================================================
-- Akuko — 0001_schema.sql
-- Core relational schema. Conforms exactly to docs/CANONICAL_SPEC.md.
-- Postgres 15 (Supabase). Designed to be idempotent-friendly.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";      -- gen_random_uuid()
create extension if not exists "uuid-ossp";      -- uuid_generate_v4() (compat)
create extension if not exists "pg_trgm";        -- trigram search on title/author

-- ---------------------------------------------------------------------
-- profiles  (1:1 with auth.users)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  full_name           text,
  avatar_url          text,
  bio                 text,
  is_admin            boolean not null default false,
  reading_preferences jsonb   not null default '{"fontSize":16,"lineSpacing":1.5,"themeMode":"system","fontFamily":"serif"}'::jsonb,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.profiles is 'Public user profile, 1:1 with auth.users. reading_preferences = {fontSize,lineSpacing,themeMode,fontFamily}.';

-- ---------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------
create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  description text,
  icon        text,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists idx_categories_sort_order on public.categories (sort_order);

-- ---------------------------------------------------------------------
-- books
-- ---------------------------------------------------------------------
create table if not exists public.books (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  author          text not null,
  description     text,
  cover_url       text,
  file_url        text,
  file_type       text check (file_type in ('epub','pdf')),
  file_size_bytes bigint,
  category_id     uuid references public.categories (id) on delete set null,
  isbn            text,
  language        text not null default 'en',
  page_count      integer,
  publisher       text,
  published_date  date,
  price           numeric(10,2) not null default 0,
  is_premium      boolean not null default false,
  is_featured     boolean not null default false,
  is_trending     boolean not null default false,
  is_new_release  boolean not null default false,
  rating_avg      numeric(3,2) not null default 0,
  rating_count    integer not null default 0,
  download_count  integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Browse / filter indexes
create index if not exists idx_books_category_id  on public.books (category_id);
create index if not exists idx_books_is_featured  on public.books (is_featured)    where is_featured;
create index if not exists idx_books_is_trending  on public.books (is_trending)    where is_trending;
create index if not exists idx_books_is_new       on public.books (is_new_release) where is_new_release;
create index if not exists idx_books_created_at   on public.books (created_at desc);

-- Full-text-ish search via trigram on title + author
create index if not exists idx_books_title_trgm  on public.books using gin (title  gin_trgm_ops);
create index if not exists idx_books_author_trgm on public.books using gin (author gin_trgm_ops);

-- ---------------------------------------------------------------------
-- reading_progress  (unique: user_id + book_id)
-- ---------------------------------------------------------------------
create table if not exists public.reading_progress (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  book_id          uuid not null references public.books (id)    on delete cascade,
  location         text,
  progress_percent numeric(5,2) not null default 0,
  last_read_at     timestamptz not null default now(),
  constraint uq_reading_progress_user_book unique (user_id, book_id)
);

create index if not exists idx_reading_progress_user on public.reading_progress (user_id, last_read_at desc);

-- ---------------------------------------------------------------------
-- bookmarks
-- ---------------------------------------------------------------------
create table if not exists public.bookmarks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  book_id    uuid not null references public.books (id)    on delete cascade,
  location   text not null,
  label      text,
  created_at timestamptz not null default now()
);

create index if not exists idx_bookmarks_user_book on public.bookmarks (user_id, book_id);

-- ---------------------------------------------------------------------
-- highlights
-- ---------------------------------------------------------------------
create table if not exists public.highlights (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  book_id       uuid not null references public.books (id)    on delete cascade,
  location      text not null,
  selected_text text,
  color         text not null default 'yellow',
  created_at    timestamptz not null default now()
);

create index if not exists idx_highlights_user_book on public.highlights (user_id, book_id);

-- ---------------------------------------------------------------------
-- notes
-- ---------------------------------------------------------------------
create table if not exists public.notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  book_id    uuid not null references public.books (id)    on delete cascade,
  location   text,
  content    text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_notes_user_book on public.notes (user_id, book_id);

-- ---------------------------------------------------------------------
-- reviews  (unique: user_id + book_id)
-- ---------------------------------------------------------------------
create table if not exists public.reviews (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  book_id    uuid not null references public.books (id)    on delete cascade,
  rating     integer not null check (rating between 1 and 5),
  comment    text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_reviews_user_book unique (user_id, book_id)
);

create index if not exists idx_reviews_book on public.reviews (book_id);

-- ---------------------------------------------------------------------
-- reading_lists
-- ---------------------------------------------------------------------
create table if not exists public.reading_lists (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  name        text not null,
  description text,
  is_public   boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists idx_reading_lists_user   on public.reading_lists (user_id);
create index if not exists idx_reading_lists_public on public.reading_lists (is_public) where is_public;

-- ---------------------------------------------------------------------
-- reading_list_items  (unique: list_id + book_id)
-- ---------------------------------------------------------------------
create table if not exists public.reading_list_items (
  id       uuid primary key default gen_random_uuid(),
  list_id  uuid not null references public.reading_lists (id) on delete cascade,
  book_id  uuid not null references public.books (id)         on delete cascade,
  added_at timestamptz not null default now(),
  constraint uq_reading_list_items_list_book unique (list_id, book_id)
);

create index if not exists idx_reading_list_items_list on public.reading_list_items (list_id);

-- ---------------------------------------------------------------------
-- reading_goals
-- ---------------------------------------------------------------------
create table if not exists public.reading_goals (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  goal_type  text not null check (goal_type in ('books','minutes','pages')),
  target     integer not null,
  period     text not null check (period in ('daily','weekly','monthly','yearly')),
  start_date date,
  created_at timestamptz not null default now()
);

create index if not exists idx_reading_goals_user on public.reading_goals (user_id);

-- ---------------------------------------------------------------------
-- reading_streaks  (1:1 user)
-- ---------------------------------------------------------------------
create table if not exists public.reading_streaks (
  user_id          uuid primary key references public.profiles (id) on delete cascade,
  current_streak   integer not null default 0,
  longest_streak   integer not null default 0,
  last_active_date date
);

-- ---------------------------------------------------------------------
-- subscription_plans
-- ---------------------------------------------------------------------
create table if not exists public.subscription_plans (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  price       numeric(10,2) not null,
  interval    text not null check (interval in ('monthly','yearly')),
  features    jsonb not null default '[]'::jsonb,
  is_active   boolean not null default true
);

-- ---------------------------------------------------------------------
-- user_subscriptions
-- ---------------------------------------------------------------------
create table if not exists public.user_subscriptions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id)            on delete cascade,
  plan_id    uuid not null references public.subscription_plans (id)  on delete restrict,
  status     text not null check (status in ('active','cancelled','expired','trialing')),
  started_at timestamptz not null default now(),
  expires_at timestamptz
);

create index if not exists idx_user_subscriptions_user   on public.user_subscriptions (user_id);
create index if not exists idx_user_subscriptions_active on public.user_subscriptions (user_id, status) where status = 'active';

-- ---------------------------------------------------------------------
-- ai_summaries  (cached AI output)
-- ---------------------------------------------------------------------
create table if not exists public.ai_summaries (
  id           uuid primary key default gen_random_uuid(),
  book_id      uuid not null references public.books (id) on delete cascade,
  chapter_ref  text,
  summary_type text not null check (summary_type in ('book','chapter')),
  content      text not null,
  created_at   timestamptz not null default now()
);

-- Cache lookup key: one cached summary per (book, summary_type, chapter_ref).
-- chapter_ref may be NULL (whole-book). NULLS NOT DISTINCT (PG15+) makes NULLs
-- collide, so there is exactly one whole-book summary row per book/type. A real
-- (non-expression) unique index lets edge functions use ON CONFLICT inference.
create unique index if not exists uq_ai_summaries_lookup
  on public.ai_summaries (book_id, summary_type, chapter_ref) nulls not distinct;

-- ---------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  type       text not null check (type in ('reading_reminder','new_book','promotion','system')),
  title      text not null,
  body       text,
  data       jsonb,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_unread on public.notifications (user_id, is_read, created_at desc);

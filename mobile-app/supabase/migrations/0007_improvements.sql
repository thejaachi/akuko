-- =====================================================================
-- Akuko — 0007_improvements.sql
-- Additive, idempotent-friendly schema improvements derived from the
-- database review (see docs/DATABASE_REVIEW.md). This migration NEVER edits
-- prior migrations (0001–0006); all changes are forward-only.
--
-- Contents:
--   1. authors            — normalized author entity + books.author_id FK
--                           (keeps the legacy books.author text for backfill)
--   2. downloads          — per-user download history (backs free vs unlimited
--                           download gating) + owner-only RLS
--   3. Missing indexes    — FK columns / common query filters not yet indexed
--   4. Data constraints   — non-negative / range CHECKs that the canonical
--                           spec implies but the base tables never enforced
--   5. Security tightening — lock down profiles over-exposure (drop the
--                           read-all policy, add a column-safe public view) and
--                           restrict ai_summaries reads to premium/owner/admin
--   6. Realtime           — ensure public.subscriptions is in the realtime
--                           publication (no-op if already added / no publication)
--
-- Idempotency: uses `create table/index if not exists`, `add column if not
-- exists`, `create or replace view`, `drop policy if exists` + `create policy`,
-- and DO-block guards (pg_constraint / pg_publication_tables) so re-applying the
-- file is safe.
--
-- NOTE on indexes: this file uses plain `create index if not exists` because
-- Supabase applies migrations inside a transaction (CONCURRENTLY is not allowed
-- there). For very large production tables you may instead create the same
-- indexes manually OUTSIDE a transaction with `create index concurrently` to
-- avoid write locks — the index names below are chosen to match.
-- =====================================================================

-- =====================================================================
-- 1. authors  (normalize the free-text books.author column)
-- =====================================================================
create table if not exists public.authors (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  bio        text,
  photo_url  text,
  created_at timestamptz not null default now(),
  -- A unique name lets us de-duplicate during backfill and use ON CONFLICT.
  constraint uq_authors_name unique (name)
);

comment on table public.authors is
  'Normalized author entity. books.author_id references this; the legacy free-text books.author column is retained for backfill/compatibility.';

-- Trigram search on author name (parity with the existing books.author trgm idx).
create index if not exists idx_authors_name_trgm
  on public.authors using gin (name gin_trgm_ops);

-- books.author_id : nullable FK so existing rows stay valid; on delete set null
-- so deleting an author never deletes the catalog entry.
alter table public.books
  add column if not exists author_id uuid references public.authors (id) on delete set null;

create index if not exists idx_books_author_id on public.books (author_id);

-- Backfill: create one author per distinct non-blank books.author, then link.
-- Both steps are idempotent (ON CONFLICT DO NOTHING / only fills NULL author_id).
insert into public.authors (name)
select distinct btrim(b.author)
from public.books b
where b.author is not null
  and btrim(b.author) <> ''
on conflict (name) do nothing;

update public.books b
set author_id = a.id
from public.authors a
where b.author_id is null
  and a.name = btrim(b.author);

-- RLS for authors: public read, admin write (mirrors books/categories).
alter table public.authors enable row level security;

drop policy if exists authors_select_all on public.authors;
create policy authors_select_all on public.authors
  for select to anon, authenticated
  using (true);

drop policy if exists authors_admin_write on public.authors;
create policy authors_admin_write on public.authors
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 2. downloads  (per-user download history → backs download-quota gating)
-- =====================================================================
create table if not exists public.downloads (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  book_id       uuid not null references public.books (id)    on delete cascade,
  file_type     text check (file_type in ('epub','pdf')),
  downloaded_at timestamptz not null default now()
);

comment on table public.downloads is
  'One row per download event. Used to enforce the free-tier download cap (Entitlements.maxFreeDownloads) vs unlimited premium downloads.';

-- Quota lookups: "how many books has this user downloaded?" and recency lists.
create index if not exists idx_downloads_user        on public.downloads (user_id, downloaded_at desc);
create index if not exists idx_downloads_book         on public.downloads (book_id);
-- Distinct-book counting for the free cap (count distinct book_id per user).
create index if not exists idx_downloads_user_book    on public.downloads (user_id, book_id);

-- RLS: strictly owner-only. A user may read and record their own downloads.
-- (Edge functions using the service role bypass RLS, e.g. signed-url logging.)
alter table public.downloads enable row level security;

drop policy if exists downloads_select_own on public.downloads;
create policy downloads_select_own on public.downloads
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists downloads_insert_own on public.downloads;
create policy downloads_insert_own on public.downloads
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists downloads_delete_own on public.downloads;
create policy downloads_delete_own on public.downloads
  for delete to authenticated
  using (auth.uid() = user_id);

-- =====================================================================
-- 3. Missing indexes (FK columns / common filters lacking coverage)
-- =====================================================================
-- reading_list_items.book_id : FK with no index (only list_id was indexed).
-- Speeds "which lists contain book X" and FK cascade on books delete.
create index if not exists idx_reading_list_items_book
  on public.reading_list_items (book_id);

-- user_subscriptions.plan_id : FK (on delete restrict) with no index. An
-- unindexed restrict-FK forces a seq scan of user_subscriptions whenever a plan
-- row is updated/deleted, and slows plan→subscription joins.
create index if not exists idx_user_subscriptions_plan
  on public.user_subscriptions (plan_id);

-- NOTE: ai_summaries.book_id lookups are already served by the leading column of
-- uq_ai_summaries_lookup(book_id, summary_type, chapter_ref) — no separate index
-- needed. bookmarks/highlights/notes/reading_progress/reviews are queried by the
-- leading user_id/book_id of their existing composite indexes/uniques.

-- =====================================================================
-- 4. Data integrity constraints (non-negative amounts / valid ranges)
-- These are implied by the canonical spec but were never enforced. Added under
-- pg_constraint guards so the file stays idempotent.
-- =====================================================================
do $$
begin
  -- books: prices/counters can never be negative; ratings stay in [0,5]; sizes
  -- and page counts are non-negative when present.
  if not exists (select 1 from pg_constraint where conname = 'chk_books_price_nonneg' and conrelid = 'public.books'::regclass) then
    alter table public.books add constraint chk_books_price_nonneg check (price >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'chk_books_rating_avg_range' and conrelid = 'public.books'::regclass) then
    alter table public.books add constraint chk_books_rating_avg_range check (rating_avg >= 0 and rating_avg <= 5);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'chk_books_rating_count_nonneg' and conrelid = 'public.books'::regclass) then
    alter table public.books add constraint chk_books_rating_count_nonneg check (rating_count >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'chk_books_download_count_nonneg' and conrelid = 'public.books'::regclass) then
    alter table public.books add constraint chk_books_download_count_nonneg check (download_count >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'chk_books_page_count_pos' and conrelid = 'public.books'::regclass) then
    alter table public.books add constraint chk_books_page_count_pos check (page_count is null or page_count > 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'chk_books_file_size_nonneg' and conrelid = 'public.books'::regclass) then
    alter table public.books add constraint chk_books_file_size_nonneg check (file_size_bytes is null or file_size_bytes >= 0);
  end if;

  -- reading_progress: percentage must be within [0,100].
  if not exists (select 1 from pg_constraint where conname = 'chk_reading_progress_percent_range' and conrelid = 'public.reading_progress'::regclass) then
    alter table public.reading_progress add constraint chk_reading_progress_percent_range check (progress_percent >= 0 and progress_percent <= 100);
  end if;

  -- reading_goals: target must be positive.
  if not exists (select 1 from pg_constraint where conname = 'chk_reading_goals_target_pos' and conrelid = 'public.reading_goals'::regclass) then
    alter table public.reading_goals add constraint chk_reading_goals_target_pos check (target > 0);
  end if;

  -- subscription_plans: price must be non-negative.
  if not exists (select 1 from pg_constraint where conname = 'chk_subscription_plans_price_nonneg' and conrelid = 'public.subscription_plans'::regclass) then
    alter table public.subscription_plans add constraint chk_subscription_plans_price_nonneg check (price >= 0);
  end if;

  -- subscriptions: a sane billing window (end after start when both present).
  if not exists (select 1 from pg_constraint where conname = 'chk_subscriptions_period_order' and conrelid = 'public.subscriptions'::regclass) then
    alter table public.subscriptions add constraint chk_subscriptions_period_order
      check (current_period_start is null or current_period_end is null or current_period_end >= current_period_start);
  end if;
end$$;

-- =====================================================================
-- 5. Security tightening
-- =====================================================================
-- 5a. profiles over-exposure.
-- 0002 created `profiles_select_all USING (true)`, which lets any authenticated
-- user read EVERY profile row including `is_admin` and `bio` (flagged in
-- docs/AUDIT.md §9.1). Replace it with owner/admin-only base-table reads, and
-- expose only the genuinely public columns through a view.
drop policy if exists profiles_select_all on public.profiles;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated
  using (auth.uid() = id or public.is_admin());

-- Column-safe projection of profiles for "public" display (review authors,
-- public reading-list owners, etc.). Excludes is_admin. The view runs with the
-- definer's rights (security_invoker is left at its default of off) so it can
-- read across rows even though the base-table policy is now owner-only.
create or replace view public.public_profiles as
  select id, full_name, avatar_url, bio
  from public.profiles;

comment on view public.public_profiles is
  'Public-safe projection of profiles (id, full_name, avatar_url, bio). Excludes is_admin / reading_preferences. Use this instead of selecting profiles directly when showing other users.';

revoke all on public.public_profiles from anon, authenticated;
grant select on public.public_profiles to anon, authenticated;

-- 5b. ai_summaries reads.
-- 0002 created `ai_summaries_select_all` (any authenticated user). AI output is
-- a premium feature, so restrict reads to premium users, the summarized book's
-- relationship is global (no owner), plus admins. Writes remain service-role only.
drop policy if exists ai_summaries_select_all on public.ai_summaries;
drop policy if exists ai_summaries_select_premium on public.ai_summaries;
create policy ai_summaries_select_premium on public.ai_summaries
  for select to authenticated
  using (public.is_premium(auth.uid()) or public.is_admin());

-- =====================================================================
-- 6. Realtime: ensure the canonical subscriptions table streams changes so the
-- client entitlement state updates live when the Paystack webhook flips a row.
-- Guarded so it is a no-op if already added or if the publication is absent.
-- =====================================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'subscriptions'
  ) then
    alter publication supabase_realtime add table public.subscriptions;
  end if;
exception
  when undefined_object then
    -- supabase_realtime publication not present (e.g. minimal local stack); skip.
    null;
end$$;

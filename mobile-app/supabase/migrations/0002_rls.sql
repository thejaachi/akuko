-- =====================================================================
-- Akuko — 0002_rls.sql
-- Row Level Security: enable on every table + policies.
--
-- Policy model:
--   * profiles ............ owner read/update; any authenticated user may
--                           read profiles (public profile data only — keep
--                           sensitive fields out of the table).
--   * categories/books/
--     subscription_plans ... public read; admin-only write.
--   * reviews ............. public read; owner-only write.
--   * reading_lists ....... owner full access + public lists readable by all.
--   * reading_list_items .. visible/writable when parent list is owned;
--                           readable when parent list is public.
--   * all other user-owned
--     tables .............. strictly auth.uid() = user_id.
--
-- NOTE: is_admin() is defined in 0003. To keep this file runnable on its own
-- (e.g. re-applied out of order), we (re)create a minimal version here; 0003
-- supplies the canonical definition via CREATE OR REPLACE.
-- =====================================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.is_admin from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

-- ---------------------------------------------------------------------
-- Enable RLS on every table
-- ---------------------------------------------------------------------
alter table public.profiles            enable row level security;
alter table public.categories          enable row level security;
alter table public.books               enable row level security;
alter table public.reading_progress    enable row level security;
alter table public.bookmarks           enable row level security;
alter table public.highlights          enable row level security;
alter table public.notes               enable row level security;
alter table public.reviews             enable row level security;
alter table public.reading_lists       enable row level security;
alter table public.reading_list_items  enable row level security;
alter table public.reading_goals       enable row level security;
alter table public.reading_streaks     enable row level security;
alter table public.subscription_plans  enable row level security;
alter table public.user_subscriptions  enable row level security;
alter table public.ai_summaries        enable row level security;
alter table public.notifications       enable row level security;

-- =====================================================================
-- profiles
-- =====================================================================
drop policy if exists profiles_select_all      on public.profiles;
drop policy if exists profiles_insert_own       on public.profiles;
drop policy if exists profiles_update_own        on public.profiles;
drop policy if exists profiles_admin_update_all  on public.profiles;

-- Any authenticated user can read profiles (public profile info only).
create policy profiles_select_all on public.profiles
  for select to authenticated
  using (true);

-- A user may insert their own profile row (normally done by handle_new_user).
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check (auth.uid() = id);

-- A user may update their own profile.
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Admins may update any profile (e.g. moderation, grant admin).
create policy profiles_admin_update_all on public.profiles
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- categories  (public read, admin write)
-- =====================================================================
drop policy if exists categories_select_all on public.categories;
drop policy if exists categories_admin_write on public.categories;

create policy categories_select_all on public.categories
  for select to anon, authenticated
  using (true);

create policy categories_admin_write on public.categories
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- books  (public read, admin write)
-- =====================================================================
drop policy if exists books_select_all on public.books;
drop policy if exists books_admin_write on public.books;

create policy books_select_all on public.books
  for select to anon, authenticated
  using (true);

create policy books_admin_write on public.books
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- subscription_plans  (public read, admin write)
-- =====================================================================
drop policy if exists subscription_plans_select_all on public.subscription_plans;
drop policy if exists subscription_plans_admin_write on public.subscription_plans;

create policy subscription_plans_select_all on public.subscription_plans
  for select to anon, authenticated
  using (true);

create policy subscription_plans_admin_write on public.subscription_plans
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- Generic owner-only tables: reading_progress, bookmarks, highlights,
-- notes, reading_goals, user_subscriptions, notifications
-- (auth.uid() = user_id for all operations)
-- =====================================================================

-- reading_progress
drop policy if exists reading_progress_owner_all on public.reading_progress;
create policy reading_progress_owner_all on public.reading_progress
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- bookmarks
drop policy if exists bookmarks_owner_all on public.bookmarks;
create policy bookmarks_owner_all on public.bookmarks
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- highlights
drop policy if exists highlights_owner_all on public.highlights;
create policy highlights_owner_all on public.highlights
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- notes
drop policy if exists notes_owner_all on public.notes;
create policy notes_owner_all on public.notes
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- reading_goals
drop policy if exists reading_goals_owner_all on public.reading_goals;
create policy reading_goals_owner_all on public.reading_goals
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- user_subscriptions: users read their own; writes are performed by the
-- backend (service role / edge function) which bypasses RLS. Users cannot
-- self-grant a subscription.
drop policy if exists user_subscriptions_select_own on public.user_subscriptions;
create policy user_subscriptions_select_own on public.user_subscriptions
  for select to authenticated
  using (auth.uid() = user_id);

-- notifications: owner can read + mark read; deletes by owner allowed.
drop policy if exists notifications_select_own on public.notifications;
drop policy if exists notifications_update_own on public.notifications;
drop policy if exists notifications_delete_own on public.notifications;

create policy notifications_select_own on public.notifications
  for select to authenticated
  using (auth.uid() = user_id);

create policy notifications_update_own on public.notifications
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy notifications_delete_own on public.notifications
  for delete to authenticated
  using (auth.uid() = user_id);

-- =====================================================================
-- reading_streaks  (1:1 user; owner read, owner may upsert)
-- =====================================================================
drop policy if exists reading_streaks_owner_all on public.reading_streaks;
create policy reading_streaks_owner_all on public.reading_streaks
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =====================================================================
-- reviews  (public read, owner write)
-- =====================================================================
drop policy if exists reviews_select_all on public.reviews;
drop policy if exists reviews_owner_write on public.reviews;

create policy reviews_select_all on public.reviews
  for select to anon, authenticated
  using (true);

create policy reviews_owner_write on public.reviews
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =====================================================================
-- reading_lists  (owner full access; public lists readable by anyone)
-- =====================================================================
drop policy if exists reading_lists_select on public.reading_lists;
drop policy if exists reading_lists_owner_write on public.reading_lists;

create policy reading_lists_select on public.reading_lists
  for select to anon, authenticated
  using (is_public or auth.uid() = user_id);

create policy reading_lists_owner_write on public.reading_lists
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =====================================================================
-- reading_list_items  (mirror parent list visibility/ownership)
-- =====================================================================
drop policy if exists reading_list_items_select on public.reading_list_items;
drop policy if exists reading_list_items_owner_write on public.reading_list_items;

create policy reading_list_items_select on public.reading_list_items
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.reading_lists l
      where l.id = reading_list_items.list_id
        and (l.is_public or l.user_id = auth.uid())
    )
  );

create policy reading_list_items_owner_write on public.reading_list_items
  for all to authenticated
  using (
    exists (
      select 1 from public.reading_lists l
      where l.id = reading_list_items.list_id
        and l.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.reading_lists l
      where l.id = reading_list_items.list_id
        and l.user_id = auth.uid()
    )
  );

-- =====================================================================
-- ai_summaries  (read by authenticated; writes by backend/service role)
-- =====================================================================
drop policy if exists ai_summaries_select_all on public.ai_summaries;
create policy ai_summaries_select_all on public.ai_summaries
  for select to authenticated
  using (true);
-- (No insert/update policy: the ai-summary edge function uses the service
--  role key, which bypasses RLS, to cache generated summaries.)

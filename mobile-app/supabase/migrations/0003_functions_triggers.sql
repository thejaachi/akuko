-- =====================================================================
-- Akuko — 0003_functions_triggers.sql
-- Helper functions and triggers.
--   * is_admin()                 -> boolean (also (re)defined here; 0002 relies on it)
--   * handle_new_user()          -> seeds profiles + reading_streaks on signup
--   * set_updated_at()           -> updated_at touch trigger
--   * recompute_book_rating()    -> keeps books.rating_avg / rating_count in sync
--   * touch_reading_streak()     -> updates reading_streaks on reading activity
-- =====================================================================

-- ---------------------------------------------------------------------
-- is_admin(): true if the current auth user is flagged admin.
-- SECURITY DEFINER + owner = table owner => bypasses RLS, so calling it
-- from a profiles RLS policy does NOT recurse.
-- ---------------------------------------------------------------------
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

comment on function public.is_admin() is 'Returns true when the current auth.uid() maps to a profile with is_admin = true.';

-- ---------------------------------------------------------------------
-- handle_new_user(): when a row is created in auth.users, create the
-- matching public.profiles row (pulling name/avatar from OAuth metadata)
-- and an empty reading_streaks row.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    ),
    coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    )
  )
  on conflict (id) do nothing;

  insert into public.reading_streaks (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- set_updated_at(): generic updated_at touch trigger.
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_books_updated_at on public.books;
create trigger trg_books_updated_at
  before update on public.books
  for each row execute function public.set_updated_at();

drop trigger if exists trg_notes_updated_at on public.notes;
create trigger trg_notes_updated_at
  before update on public.notes
  for each row execute function public.set_updated_at();

drop trigger if exists trg_reviews_updated_at on public.reviews;
create trigger trg_reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- recompute_book_rating(): recompute books.rating_avg / rating_count
-- after any insert/update/delete on reviews.
-- ---------------------------------------------------------------------
create or replace function public.recompute_book_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_book uuid := coalesce(new.book_id, old.book_id);
begin
  update public.books b
  set rating_avg = coalesce(agg.avg_rating, 0),
      rating_count = coalesce(agg.cnt, 0)
  from (
    select round(avg(rating)::numeric, 2) as avg_rating,
           count(*)                        as cnt
    from public.reviews
    where book_id = target_book
  ) agg
  where b.id = target_book;

  return null;  -- AFTER trigger: return value ignored
end;
$$;

drop trigger if exists trg_reviews_recompute_rating on public.reviews;
create trigger trg_reviews_recompute_rating
  after insert or update of rating or delete on public.reviews
  for each row execute function public.recompute_book_rating();

-- ---------------------------------------------------------------------
-- touch_reading_streak(): update a user's reading_streaks based on
-- reading activity (called from reading_progress changes).
--   * same day            -> no change
--   * consecutive day     -> current_streak + 1
--   * gap (>1 day) or new -> reset current_streak to 1
-- longest_streak tracks the max ever seen.
-- ---------------------------------------------------------------------
create or replace function public.touch_reading_streak()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  prev_date date;
  prev_current int;
  prev_longest int;
  today date := (now() at time zone 'utc')::date;
  new_current int;
begin
  insert into public.reading_streaks (user_id, current_streak, longest_streak, last_active_date)
  values (new.user_id, 1, 1, today)
  on conflict (user_id) do nothing;

  select last_active_date, current_streak, longest_streak
    into prev_date, prev_current, prev_longest
  from public.reading_streaks
  where user_id = new.user_id
  for update;

  if prev_date = today then
    return new;  -- already counted today
  elsif prev_date = today - 1 then
    new_current := coalesce(prev_current, 0) + 1;
  else
    new_current := 1;  -- gap or first activity
  end if;

  update public.reading_streaks
  set current_streak   = new_current,
      longest_streak   = greatest(coalesce(prev_longest, 0), new_current),
      last_active_date = today
  where user_id = new.user_id;

  return new;
end;
$$;

drop trigger if exists trg_reading_progress_streak on public.reading_progress;
create trigger trg_reading_progress_streak
  after insert or update of last_read_at, progress_percent on public.reading_progress
  for each row execute function public.touch_reading_streak();

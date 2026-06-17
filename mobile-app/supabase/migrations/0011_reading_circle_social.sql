-- =====================================================================
-- Akuko — 0011_reading_circle_social.sql
-- Reading circle social feed, follows, and dictionary usage tracking.
-- =====================================================================

-- Circle posts (member-visible feed).
create table if not exists public.circle_posts (
  id          uuid primary key default gen_random_uuid(),
  circle_id   uuid not null references public.reading_circles (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  content     text not null check (char_length(content) between 1 and 500),
  created_at  timestamptz not null default now()
);

create index if not exists idx_circle_posts_circle
  on public.circle_posts (circle_id, created_at desc);

-- Post likes (one per user per post).
create table if not exists public.circle_post_likes (
  post_id     uuid not null references public.circle_posts (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- Post comments.
create table if not exists public.circle_post_comments (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references public.circle_posts (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  content     text not null check (char_length(content) between 1 and 500),
  created_at  timestamptz not null default now()
);

create index if not exists idx_circle_post_comments_post
  on public.circle_post_comments (post_id, created_at asc);

-- User follows (social graph).
create table if not exists public.user_follows (
  follower_id   uuid not null references auth.users (id) on delete cascade,
  following_id  uuid not null references auth.users (id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create index if not exists idx_user_follows_following
  on public.user_follows (following_id);

-- Dictionary lookups (server-side daily cap for free tier).
create table if not exists public.dictionary_lookups (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  word        text not null,
  looked_up_at timestamptz not null default now()
);

create index if not exists idx_dictionary_lookups_user_day
  on public.dictionary_lookups (user_id, looked_up_at desc);

-- ── RLS ───────────────────────────────────────────────────────────────────

alter table public.circle_posts enable row level security;
alter table public.circle_post_likes enable row level security;
alter table public.circle_post_comments enable row level security;
alter table public.user_follows enable row level security;
alter table public.dictionary_lookups enable row level security;

-- Members can read posts in circles they belong to.
drop policy if exists circle_posts_select_member on public.circle_posts;
create policy circle_posts_select_member on public.circle_posts
  for select using (
    exists (
      select 1 from public.reading_circle_members m
      where m.circle_id = circle_posts.circle_id
        and m.user_id = auth.uid()
    )
    or exists (
      select 1 from public.reading_circles c
      where c.id = circle_posts.circle_id and c.is_public = true
    )
  );

drop policy if exists circle_posts_insert_own on public.circle_posts;
create policy circle_posts_insert_own on public.circle_posts
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.reading_circle_members m
      where m.circle_id = circle_posts.circle_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists circle_post_likes_select_member on public.circle_post_likes;
create policy circle_post_likes_select_member on public.circle_post_likes
  for select using (
    exists (
      select 1 from public.circle_posts p
      join public.reading_circle_members m on m.circle_id = p.circle_id
      where p.id = circle_post_likes.post_id and m.user_id = auth.uid()
    )
  );

drop policy if exists circle_post_likes_insert_own on public.circle_post_likes;
create policy circle_post_likes_insert_own on public.circle_post_likes
  for insert with check (auth.uid() = user_id);

drop policy if exists circle_post_likes_delete_own on public.circle_post_likes;
create policy circle_post_likes_delete_own on public.circle_post_likes
  for delete using (auth.uid() = user_id);

drop policy if exists circle_post_comments_select_member on public.circle_post_comments;
create policy circle_post_comments_select_member on public.circle_post_comments
  for select using (
    exists (
      select 1 from public.circle_posts p
      join public.reading_circle_members m on m.circle_id = p.circle_id
      where p.id = circle_post_comments.post_id and m.user_id = auth.uid()
    )
  );

drop policy if exists circle_post_comments_insert_own on public.circle_post_comments;
create policy circle_post_comments_insert_own on public.circle_post_comments
  for insert with check (auth.uid() = user_id);

drop policy if exists user_follows_select_own on public.user_follows;
create policy user_follows_select_own on public.user_follows
  for select using (
    auth.uid() = follower_id or auth.uid() = following_id
  );

drop policy if exists user_follows_insert_own on public.user_follows;
create policy user_follows_insert_own on public.user_follows
  for insert with check (auth.uid() = follower_id);

drop policy if exists user_follows_delete_own on public.user_follows;
create policy user_follows_delete_own on public.user_follows
  for delete using (auth.uid() = follower_id);

drop policy if exists dictionary_lookups_select_own on public.dictionary_lookups;
create policy dictionary_lookups_select_own on public.dictionary_lookups
  for select using (auth.uid() = user_id);

drop policy if exists dictionary_lookups_insert_own on public.dictionary_lookups;
create policy dictionary_lookups_insert_own on public.dictionary_lookups
  for insert with check (auth.uid() = user_id);

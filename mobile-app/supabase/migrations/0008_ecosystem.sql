-- =====================================================================
-- Akuko — 0008_ecosystem.sql
-- Future-proof publishing ecosystem schema (Phase 2–4 tables + flags).
-- Additive only — does not modify migrations 0001–0007.
--
-- Contents:
--   feature_flags, publishers, publisher_members, book_files
--   profiles/books extensions, payment_transactions (Paystack ledger)
--   royalties, royalty_distributions, author_earnings, withdrawals
--   followers, analytics_events, admin_logs
--   list_books view (alias of reading_list_items)
--   Helpers: is_feature_enabled(), user_role()
--   RLS + indexes on all new objects
--
-- Idempotency: IF NOT EXISTS / OR REPLACE / ON CONFLICT / DO guards.
-- =====================================================================

-- =====================================================================
-- 1. feature_flags (before is_feature_enabled — function reads this table)
-- =====================================================================
create table if not exists public.feature_flags (
  key         text primary key,
  enabled     boolean not null default false,
  description text,
  phase       int not null default 1 check (phase between 1 and 4),
  updated_at  timestamptz not null default now()
);

comment on table public.feature_flags is
  'Runtime feature toggles. Phase 2–4 capabilities exist in schema but stay off until enabled here.';

drop trigger if exists trg_feature_flags_updated_at on public.feature_flags;
create trigger trg_feature_flags_updated_at
  before update on public.feature_flags
  for each row execute function public.set_updated_at();

insert into public.feature_flags (key, enabled, description, phase) values
  -- Phase 1 (launch toggles — enabled for current product surface)
  ('admin_dashboard', true,  'Internal admin catalogue, users, moderation', 1),
  ('reviews',         true,  'Book reviews UI and community ratings', 1),
  ('ai_summaries',    true,  'Cached LLM book/chapter summaries', 1),
  ('ai_assistant',    true,  'In-reader reading assistant', 1),
  ('audiobook_mode',  true,  'Audio file playback / TTS product surface', 1),
  ('ads',             true,  'In-app advertising placements', 1),
  -- Phase 2–4 (schema present; disabled until rollout)
  ('author_dashboard',   false, 'Author portal: catalogue, stats, uploads', 2),
  ('author_uploads',     false, 'Authors submit drafts for review', 2),
  ('publisher_dashboard', false, 'Publisher org portal', 3),
  ('publisher_uploads',  false, 'Publisher-managed catalogue uploads', 3),
  ('publisher_teams',    false, 'Multi-user publisher_members roles', 3),
  ('royalties',          false, 'Royalty rules and distribution reporting', 4),
  ('payouts',            false, 'Withdrawals and Paystack transfers', 4)
on conflict (key) do update set
  description = excluded.description,
  phase       = excluded.phase;

-- =====================================================================
-- 1b. Helper functions (used by RLS; 0003 defines is_admin / is_premium)
-- =====================================================================
create or replace function public.is_feature_enabled(flag_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select f.enabled from public.feature_flags f where f.key = flag_key),
    false
  );
$$;

comment on function public.is_feature_enabled(text) is
  'Returns true when feature_flags.key exists and enabled = true. Used in RLS and client guards.';

grant execute on function public.is_feature_enabled(text) to anon, authenticated;

-- =====================================================================
-- 2. publishers + publisher_members
-- =====================================================================
create table if not exists public.publishers (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  slug       text not null,
  logo_url   text,
  bio        text,
  status     text not null default 'pending'
               check (status in ('pending','approved','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_publishers_slug unique (slug)
);

comment on table public.publishers is
  'Publishing organizations (Selar/Substack-style). books.publisher_id links here; legacy books.publisher text retained.';

create index if not exists idx_publishers_status on public.publishers (status);
create index if not exists idx_publishers_slug   on public.publishers (slug);

drop trigger if exists trg_publishers_updated_at on public.publishers;
create trigger trg_publishers_updated_at
  before update on public.publishers
  for each row execute function public.set_updated_at();

create table if not exists public.publisher_members (
  id           uuid primary key default gen_random_uuid(),
  publisher_id uuid not null references public.publishers (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  role         text not null default 'viewer'
                 check (role in ('owner','editor','viewer')),
  created_at   timestamptz not null default now(),
  constraint uq_publisher_members_pub_user unique (publisher_id, user_id)
);

comment on table public.publisher_members is
  'Team membership for a publisher org. Gated by feature flag publisher_teams.';

create index if not exists idx_publisher_members_publisher on public.publisher_members (publisher_id);
create index if not exists idx_publisher_members_user      on public.publisher_members (user_id);

-- =====================================================================
-- 3. Extend profiles (role + FK links to author/publisher entities)
-- =====================================================================
alter table public.profiles
  add column if not exists role text not null default 'reader'
    check (role in ('reader','author','publisher','admin'));

alter table public.profiles
  add column if not exists author_id uuid references public.authors (id) on delete set null;

alter table public.profiles
  add column if not exists publisher_id uuid references public.publishers (id) on delete set null;

create index if not exists idx_profiles_role         on public.profiles (role);
create index if not exists idx_profiles_author_id    on public.profiles (author_id);
create index if not exists idx_profiles_publisher_id on public.profiles (publisher_id);

comment on column public.profiles.role is
  'App persona: reader|author|publisher|admin. Self-service cannot escalate (see guard_profiles_privileged_update).';

-- Prevent non-admins from changing role / author_id / publisher_id on their own row.
create or replace function public.guard_profiles_privileged_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    if new.role is distinct from old.role
       or new.author_id is distinct from old.author_id
       or new.publisher_id is distinct from old.publisher_id then
      raise exception 'Cannot modify role, author_id, or publisher_id without admin privileges'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_guard_privileged on public.profiles;
create trigger trg_profiles_guard_privileged
  before update on public.profiles
  for each row execute function public.guard_profiles_privileged_update();

create or replace function public.user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'reader'
  );
$$;

comment on function public.user_role() is
  'Returns profiles.role for the current user (reader|author|publisher|admin). Defaults to reader.';

grant execute on function public.user_role() to authenticated;

-- =====================================================================
-- 4. Extend books (workflow, pricing, publisher link)
-- =====================================================================
alter table public.books
  add column if not exists status text not null default 'published'
    check (status in ('draft','pending_review','published','rejected','archived'));

alter table public.books
  add column if not exists uploaded_by uuid references public.profiles (id) on delete set null;

alter table public.books
  add column if not exists approved_by uuid references public.profiles (id) on delete set null;

alter table public.books
  add column if not exists approved_at timestamptz;

alter table public.books
  add column if not exists rejection_reason text;

alter table public.books
  add column if not exists pricing_model text not null default 'free'
    check (pricing_model in ('free','paid','subscription_only'));

alter table public.books
  add column if not exists publisher_id uuid references public.publishers (id) on delete set null;

create index if not exists idx_books_status       on public.books (status);
create index if not exists idx_books_publisher_id   on public.books (publisher_id);
create index if not exists idx_books_uploaded_by    on public.books (uploaded_by);
create index if not exists idx_books_pricing_model  on public.books (pricing_model);

comment on column public.books.status is
  'Publishing workflow state. Existing catalogue backfilled to published.';

-- Catalogue browse: only published (and legacy rows) visible to anon/auth by default.
-- Admin policies in 0002 still allow admin write; public SELECT unchanged (all rows).
-- Client should filter status = published; optional view below for public catalogue.
create or replace view public.published_books as
  select *
  from public.books
  where status = 'published';

comment on view public.published_books is
  'Public catalogue projection. Use for storefront when draft/rejected rows must be hidden.';

grant select on public.published_books to anon, authenticated;

-- =====================================================================
-- 5. book_files (multi-format per book; complements books.file_url)
-- =====================================================================
create table if not exists public.book_files (
  id              uuid primary key default gen_random_uuid(),
  book_id         uuid not null references public.books (id) on delete cascade,
  file_type       text not null check (file_type in ('epub','pdf','audio')),
  storage_path    text not null,
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0),
  created_at      timestamptz not null default now(),
  constraint uq_book_files_book_type unique (book_id, file_type)
);

comment on table public.book_files is
  'Normalized file assets per book (epub/pdf/audio). books.file_url remains the primary legacy path.';

create index if not exists idx_book_files_book_id on public.book_files (book_id);

-- Backfill primary file from books where present (idempotent).
insert into public.book_files (book_id, file_type, storage_path, file_size_bytes)
select b.id, b.file_type, b.file_url, b.file_size_bytes
from public.books b
where b.file_url is not null
  and b.file_type in ('epub','pdf')
on conflict (book_id, file_type) do nothing;

-- =====================================================================
-- 6. payment_transactions (Paystack event ledger — NOT entitlement)
-- =====================================================================
create table if not exists public.payment_transactions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  reference      text not null,
  amount         numeric(12,2) not null check (amount >= 0),
  currency       text not null default 'NGN',
  status         text not null default 'pending'
                   check (status in ('pending','success','failed','abandoned','reversed')),
  paystack_event text,
  metadata       jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now(),
  constraint uq_payment_transactions_reference unique (reference)
);

comment on table public.payment_transactions is
  'Immutable Paystack payment ledger (initialize/charge/webhook). Entitlement lives in public.subscriptions (0006), not here.';

create index if not exists idx_payment_transactions_user    on public.payment_transactions (user_id, created_at desc);
create index if not exists idx_payment_transactions_status  on public.payment_transactions (status);
create index if not exists idx_payment_transactions_created on public.payment_transactions (created_at desc);

-- =====================================================================
-- 7. Royalties & payouts (Phase 4 — feature-flag gated writes)
-- =====================================================================
create table if not exists public.royalties (
  id             uuid primary key default gen_random_uuid(),
  book_id        uuid not null references public.books (id) on delete cascade,
  author_id      uuid not null references public.authors (id) on delete cascade,
  model          text not null check (model in ('direct_sale','subscription_pool')),
  rate_percent   numeric(5,2) not null check (rate_percent > 0 and rate_percent <= 100),
  effective_from date not null default current_date,
  created_at     timestamptz not null default now()
);

comment on table public.royalties is
  'Per-book royalty rule. Calculations write royalty_distributions / author_earnings via service role.';

create index if not exists idx_royalties_book    on public.royalties (book_id);
create index if not exists idx_royalties_author  on public.royalties (author_id);

create table if not exists public.royalty_distributions (
  id            uuid primary key default gen_random_uuid(),
  royalty_id    uuid not null references public.royalties (id) on delete cascade,
  period_month  date not null,
  amount        numeric(12,2) not null check (amount >= 0),
  calculated_at timestamptz not null default now(),
  constraint uq_royalty_distributions_period unique (royalty_id, period_month)
);

comment on table public.royalty_distributions is
  'Monthly royalty accrual per royalty rule. period_month is first day of month (YYYY-MM-01).';

create index if not exists idx_royalty_distributions_royalty on public.royalty_distributions (royalty_id);
create index if not exists idx_royalty_distributions_period   on public.royalty_distributions (period_month desc);

create table if not exists public.author_earnings (
  id            uuid primary key default gen_random_uuid(),
  author_id     uuid not null references public.authors (id) on delete cascade,
  period_month  date not null,
  amount        numeric(12,2) not null default 0 check (amount >= 0),
  currency      text not null default 'NGN',
  calculated_at timestamptz not null default now(),
  constraint uq_author_earnings_period unique (author_id, period_month)
);

comment on table public.author_earnings is
  'Aggregated earnings per author per calendar month.';

create index if not exists idx_author_earnings_author on public.author_earnings (author_id);
create index if not exists idx_author_earnings_period on public.author_earnings (period_month desc);

create table if not exists public.withdrawals (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.profiles (id) on delete cascade,
  amount                numeric(12,2) not null check (amount > 0),
  currency              text not null default 'NGN',
  status                text not null default 'pending'
                          check (status in ('pending','processing','paid','failed')),
  paystack_transfer_code text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

comment on table public.withdrawals is
  'Author/publisher payout requests. Processed via Paystack Transfers (service role). Gated by payouts flag.';

create index if not exists idx_withdrawals_user   on public.withdrawals (user_id, created_at desc);
create index if not exists idx_withdrawals_status on public.withdrawals (status);

drop trigger if exists trg_withdrawals_updated_at on public.withdrawals;
create trigger trg_withdrawals_updated_at
  before update on public.withdrawals
  for each row execute function public.set_updated_at();

-- =====================================================================
-- 8. followers (reader → author)
-- =====================================================================
create table if not exists public.followers (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  author_id   uuid not null references public.authors (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, author_id)
);

comment on table public.followers is
  'Social follow graph: authenticated readers follow normalized authors.';

create index if not exists idx_followers_author   on public.followers (author_id);
create index if not exists idx_followers_follower on public.followers (follower_id);

-- =====================================================================
-- 9. list_books — alias view (do not duplicate reading_list_items)
-- =====================================================================
create or replace view public.list_books as
  select
    id,
    list_id,
    book_id,
    added_at
  from public.reading_list_items;

comment on view public.list_books is
  'Alias of reading_list_items (books in a reading list). Canonical table: reading_list_items + reading_lists.';

grant select on public.list_books to anon, authenticated;

-- =====================================================================
-- 10. analytics_events + admin_logs
-- =====================================================================
create table if not exists public.analytics_events (
  id         uuid primary key default gen_random_uuid(),
  event_type text not null,
  user_id    uuid references public.profiles (id) on delete set null,
  book_id    uuid references public.books (id) on delete set null,
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

comment on table public.analytics_events is
  'Append-only product analytics. Inserts from client (authenticated) or edge (service role).';

create index if not exists idx_analytics_events_type_created
  on public.analytics_events (event_type, created_at desc);
create index if not exists idx_analytics_events_book
  on public.analytics_events (book_id)
  where book_id is not null;
create index if not exists idx_analytics_events_user
  on public.analytics_events (user_id)
  where user_id is not null;

create table if not exists public.admin_logs (
  id          uuid primary key default gen_random_uuid(),
  admin_id    uuid not null references public.profiles (id) on delete cascade,
  action      text not null,
  entity_type text,
  entity_id   uuid,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

comment on table public.admin_logs is
  'Audit trail for admin actions (moderation, flags, catalogue).';

create index if not exists idx_admin_logs_admin    on public.admin_logs (admin_id, created_at desc);
create index if not exists idx_admin_logs_entity   on public.admin_logs (entity_type, entity_id);
create index if not exists idx_admin_logs_created  on public.admin_logs (created_at desc);

-- =====================================================================
-- 11. Row Level Security
-- =====================================================================

-- feature_flags
alter table public.feature_flags enable row level security;

drop policy if exists feature_flags_select_all on public.feature_flags;
create policy feature_flags_select_all on public.feature_flags
  for select to anon, authenticated
  using (true);

drop policy if exists feature_flags_admin_write on public.feature_flags;
create policy feature_flags_admin_write on public.feature_flags
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- publishers
alter table public.publishers enable row level security;

drop policy if exists publishers_select_approved on public.publishers;
create policy publishers_select_approved on public.publishers
  for select to anon, authenticated
  using (
    status = 'approved'
    or public.is_admin()
    or exists (
      select 1 from public.publisher_members pm
      where pm.publisher_id = publishers.id
        and pm.user_id = auth.uid()
    )
  );

drop policy if exists publishers_admin_write on public.publishers;
create policy publishers_admin_write on public.publishers
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists publishers_insert_when_flag on public.publishers;
create policy publishers_insert_when_flag on public.publishers
  for insert to authenticated
  with check (
    public.is_feature_enabled('publisher_uploads')
    or public.is_admin()
  );

-- publisher_members
alter table public.publisher_members enable row level security;

drop policy if exists publisher_members_select on public.publisher_members;
create policy publisher_members_select on public.publisher_members
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.publisher_members pm
      where pm.publisher_id = publisher_members.publisher_id
        and pm.user_id = auth.uid()
        and pm.role in ('owner','editor')
    )
  );

drop policy if exists publisher_members_admin_write on public.publisher_members;
create policy publisher_members_admin_write on public.publisher_members
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists publisher_members_owner_manage on public.publisher_members;
create policy publisher_members_owner_manage on public.publisher_members
  for all to authenticated
  using (
    public.is_feature_enabled('publisher_teams')
    and exists (
      select 1 from public.publisher_members pm
      where pm.publisher_id = publisher_members.publisher_id
        and pm.user_id = auth.uid()
        and pm.role = 'owner'
    )
  )
  with check (
    public.is_feature_enabled('publisher_teams')
    and exists (
      select 1 from public.publisher_members pm
      where pm.publisher_id = publisher_members.publisher_id
        and pm.user_id = auth.uid()
        and pm.role = 'owner'
    )
  );

-- book_files
alter table public.book_files enable row level security;

drop policy if exists book_files_select_published on public.book_files;
create policy book_files_select_published on public.book_files
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.books b
      where b.id = book_files.book_id
        and b.status = 'published'
    )
    or public.is_admin()
  );

drop policy if exists book_files_admin_write on public.book_files;
create policy book_files_admin_write on public.book_files
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- payment_transactions (ledger: owner read; service role writes)
alter table public.payment_transactions enable row level security;

drop policy if exists payment_transactions_select_own on public.payment_transactions;
create policy payment_transactions_select_own on public.payment_transactions
  for select to authenticated
  using (auth.uid() = user_id or public.is_admin());

-- royalties
alter table public.royalties enable row level security;

drop policy if exists royalties_select on public.royalties;
create policy royalties_select on public.royalties
  for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_feature_enabled('royalties')
      and exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
          and p.author_id = royalties.author_id
      )
    )
  );

drop policy if exists royalties_admin_write on public.royalties;
create policy royalties_admin_write on public.royalties
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());
-- (No client insert on royalty_distributions / author_earnings: service role only.)

-- royalty_distributions
alter table public.royalty_distributions enable row level security;

drop policy if exists royalty_distributions_select on public.royalty_distributions;
create policy royalty_distributions_select on public.royalty_distributions
  for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_feature_enabled('royalties')
      and exists (
        select 1
        from public.royalties r
        join public.profiles p on p.id = auth.uid() and p.author_id = r.author_id
        where r.id = royalty_distributions.royalty_id
      )
    )
  );

-- author_earnings
alter table public.author_earnings enable row level security;

drop policy if exists author_earnings_select on public.author_earnings;
create policy author_earnings_select on public.author_earnings
  for select to authenticated
  using (
    public.is_admin()
    or (
      public.is_feature_enabled('royalties')
      and exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
          and p.author_id = author_earnings.author_id
      )
    )
  );

-- withdrawals
alter table public.withdrawals enable row level security;

drop policy if exists withdrawals_select_own on public.withdrawals;
create policy withdrawals_select_own on public.withdrawals
  for select to authenticated
  using (
    auth.uid() = user_id
    or public.is_admin()
  );

-- (No client insert on withdrawals until payouts is productized: Paystack transfers use service role.)

drop policy if exists withdrawals_admin_update on public.withdrawals;
create policy withdrawals_admin_update on public.withdrawals
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- followers
alter table public.followers enable row level security;

drop policy if exists followers_select_all on public.followers;
create policy followers_select_all on public.followers
  for select to anon, authenticated
  using (true);

drop policy if exists followers_manage_own on public.followers;
create policy followers_manage_own on public.followers
  for all to authenticated
  using (auth.uid() = follower_id)
  with check (auth.uid() = follower_id);

-- analytics_events
alter table public.analytics_events enable row level security;

drop policy if exists analytics_events_insert_auth on public.analytics_events;
create policy analytics_events_insert_auth on public.analytics_events
  for insert to authenticated
  with check (user_id is null or user_id = auth.uid());

drop policy if exists analytics_events_select_admin on public.analytics_events;
create policy analytics_events_select_admin on public.analytics_events
  for select to authenticated
  using (public.is_admin());

-- admin_logs
alter table public.admin_logs enable row level security;

drop policy if exists admin_logs_select_admin on public.admin_logs;
create policy admin_logs_select_admin on public.admin_logs
  for select to authenticated
  using (public.is_admin());

drop policy if exists admin_logs_insert_admin on public.admin_logs;
create policy admin_logs_insert_admin on public.admin_logs
  for insert to authenticated
  with check (public.is_admin() and admin_id = auth.uid());

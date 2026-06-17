-- =====================================================================
-- Akuko — 0006_subscriptions.sql
-- Paystack-backed subscription state.
--
-- Introduces a single-source-of-truth `public.subscriptions` table (one row
-- per user) that the Paystack webhook / verify edge functions (service role)
-- keep in sync. Premium gating across the app (signed-url, tts, client guard)
-- derives from this table via `public.is_premium(uid)`.
--
-- Design notes:
--   * The pre-existing `subscription_plans` / `user_subscriptions` tables
--     (0001) are left untouched for backwards compatibility. This table is the
--     new canonical entitlement record used by the Paystack flow.
--   * Clients may only SELECT their own row. All writes happen via the service
--     role (webhooks/verify), so a user can never self-grant premium.
-- =====================================================================

-- ---------------------------------------------------------------------
-- subscriptions  (1:1 with profiles)
-- ---------------------------------------------------------------------
create table if not exists public.subscriptions (
  id                        uuid primary key default gen_random_uuid(),
  user_id                   uuid not null references public.profiles (id) on delete cascade,
  paystack_customer_code    text,
  paystack_subscription_code text,
  plan                      text not null default 'free'
                              check (plan in ('free','premium')),
  status                    text not null default 'active'
                              check (status in (
                                'active','non-renewing','attention','completed',
                                'cancelled','past_due','incomplete'
                              )),
  current_period_start      timestamptz,
  current_period_end        timestamptz,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  constraint uq_subscriptions_user unique (user_id)
);

comment on table public.subscriptions is
  'Canonical per-user subscription/entitlement record. Written only by the service role (Paystack webhook/verify). plan in (free,premium).';

create index if not exists idx_subscriptions_sub_code
  on public.subscriptions (paystack_subscription_code);
create index if not exists idx_subscriptions_customer_code
  on public.subscriptions (paystack_customer_code);

-- updated_at touch trigger (reuses set_updated_at() from 0003).
drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- is_premium(uid): true when the user has a premium subscription that is
-- currently valid. "Valid" = plan = 'premium', a non-terminal status, and
-- current_period_end is NULL (lifetime/unknown) or still in the future.
-- 'non-renewing' is included: the user cancelled auto-renew but retains
-- access until the paid period ends.
-- SECURITY DEFINER + fixed search_path so RLS does not block the lookup and
-- the function can be reused from edge functions / policies safely.
-- ---------------------------------------------------------------------
create or replace function public.is_premium(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.subscriptions s
    where s.user_id = uid
      and s.plan = 'premium'
      and s.status in ('active','non-renewing')
      and (s.current_period_end is null or s.current_period_end > now())
  );
$$;

comment on function public.is_premium(uuid) is
  'Returns true when the given user currently has valid premium entitlement (plan=premium, active/non-renewing, not expired).';

-- ---------------------------------------------------------------------
-- RLS: owner may read their own row; NO client writes (service role only,
-- which bypasses RLS). This is what makes the payment webhook authoritative.
-- ---------------------------------------------------------------------
alter table public.subscriptions enable row level security;

drop policy if exists subscriptions_select_own on public.subscriptions;
create policy subscriptions_select_own on public.subscriptions
  for select to authenticated
  using (auth.uid() = user_id);

-- (Intentionally no insert/update/delete policy: only the service role —
--  used by the Paystack edge functions — may mutate subscription state.)

-- ---------------------------------------------------------------------
-- Backfill: give every existing profile a default free subscription row.
-- ---------------------------------------------------------------------
insert into public.subscriptions (user_id, plan, status)
select p.id, 'free', 'active'
from public.profiles p
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------
-- Extend handle_new_user() to also seed a default free subscription on
-- signup. The original body (profiles + reading_streaks seeding) is preserved
-- verbatim; only the subscriptions insert is appended.
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

  insert into public.subscriptions (user_id, plan, status)
  values (new.id, 'free', 'active')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

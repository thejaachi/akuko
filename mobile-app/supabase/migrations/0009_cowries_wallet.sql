-- =====================================================================
-- Akuko — 0009_cowries_wallet.sql
-- Cowries wallet balance + transaction ledger.
-- =====================================================================

create table if not exists public.wallets (
  user_id         uuid primary key references auth.users (id) on delete cascade,
  balance_cowries bigint not null default 0 check (balance_cowries >= 0),
  currency        text not null default 'NGN',
  updated_at      timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  type            text not null check (type in ('top_up', 'purchase', 'refund')),
  amount_cowries  bigint not null,
  fiat_amount     numeric(12, 2),
  currency        text not null default 'NGN',
  reference       text,
  created_at      timestamptz not null default now()
);

create index if not exists idx_wallet_transactions_user
  on public.wallet_transactions (user_id, created_at desc);

alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;

drop policy if exists wallets_select_own on public.wallets;
create policy wallets_select_own on public.wallets
  for select using (auth.uid() = user_id);

drop policy if exists wallet_tx_select_own on public.wallet_transactions;
create policy wallet_tx_select_own on public.wallet_transactions
  for select using (auth.uid() = user_id);

-- Atomic cowrie purchase — deducts balance and records a purchase transaction.
create or replace function public.purchase_with_cowries(
  p_book_id uuid,
  p_amount_cowries bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  insert into public.wallets (user_id)
  values (v_user)
  on conflict (user_id) do nothing;

  select balance_cowries into v_balance
  from public.wallets
  where user_id = v_user
  for update;

  if v_balance < p_amount_cowries then
    raise exception 'insufficient cowries';
  end if;

  update public.wallets
  set balance_cowries = balance_cowries - p_amount_cowries,
      updated_at = now()
  where user_id = v_user;

  insert into public.wallet_transactions (
    user_id, type, amount_cowries, reference
  ) values (
    v_user, 'purchase', p_amount_cowries, p_book_id::text
  );
end;
$$;

grant execute on function public.purchase_with_cowries(uuid, bigint) to authenticated;

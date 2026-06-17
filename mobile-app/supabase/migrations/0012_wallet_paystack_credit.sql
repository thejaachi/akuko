-- =====================================================================
-- Akuko — 0012_wallet_paystack.sql
-- Paystack wallet credit RPC, subscription cowrie purchase, shipping address.
-- =====================================================================

alter table public.profiles
  add column if not exists shipping_address jsonb;

comment on column public.profiles.shipping_address is
  'Hardcopy delivery: {street, city, state, postal_code, phone}';

-- Credit cowries after verified Paystack wallet top-up (idempotent by reference).
create or replace function public.credit_wallet_cowries(
  p_user_id uuid,
  p_amount_cowries bigint,
  p_reference text,
  p_fiat_amount numeric default null,
  p_currency text default 'NGN'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null or p_amount_cowries <= 0 then
    raise exception 'invalid credit parameters';
  end if;

  if p_reference is not null and exists (
    select 1 from public.wallet_transactions
    where user_id = p_user_id and reference = p_reference and type = 'top_up'
  ) then
    return;
  end if;

  insert into public.wallets (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  update public.wallets
  set balance_cowries = balance_cowries + p_amount_cowries,
      updated_at = now()
  where user_id = p_user_id;

  insert into public.wallet_transactions (
    user_id, type, amount_cowries, fiat_amount, currency, reference
  ) values (
    p_user_id,
    'top_up',
    p_amount_cowries,
    p_fiat_amount,
    coalesce(p_currency, 'NGN'),
    coalesce(p_reference, 'paystack_top_up')
  );
end;
$$;

-- Deduct cowries and activate premium subscription for the caller.
create or replace function public.purchase_subscription_with_cowries(
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
    v_user, 'purchase', p_amount_cowries, 'subscription_premium'
  );

  insert into public.subscriptions (user_id, plan, status, current_period_start)
  values (v_user, 'premium', 'active', now())
  on conflict (user_id) do update
  set plan = 'premium',
      status = 'active',
      current_period_start = now(),
      updated_at = now();
end;
$$;

grant execute on function public.credit_wallet_cowries(uuid, bigint, text) to service_role;
grant execute on function public.purchase_subscription_with_cowries(bigint) to authenticated;

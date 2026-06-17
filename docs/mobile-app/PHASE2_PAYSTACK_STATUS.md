# Phase 2 — Paystack Integration Status

**Date:** 2026-06-04

## Edge functions

| Function | JWT | Purpose |
|----------|-----|---------|
| `paystack-initialize` | Required | Server-side `transaction/initialize`; returns `authorizationUrl` + `reference` |
| `paystack-verify` | Required | `transaction/verify/{reference}`; upserts `subscriptions` on success |
| `paystack-webhook` | **Disabled** (`--no-verify-jwt`) | HMAC-SHA512 on raw body; lifecycle events |
| `paystack-cancel` | Required | Disables Paystack subscription for caller |

Shared: `supabase/functions/_shared/paystack.ts` (`paystackFetch`, `verifyPaystackSignature`, ledger helpers).

## Webhook events handled

| Event | `subscriptions` | `payment_transactions` |
|-------|-----------------|------------------------|
| `charge.success` | premium / active | append (upsert by reference) |
| `subscription.create` | premium / active | append |
| `invoice.create` | extend period / active | append |
| `invoice.payment_failed` | `past_due` | append (status `failed`) |
| `subscription.disable` | non-renewing or free/cancelled | append if reference present |
| Other | 200 ack, ignored | — |

## Security

- **Secret key** only in edge secrets: `supabase secrets set PAYSTACK_SECRET_KEY=sk_...`
- **Webhook:** `verifyPaystackSignature` constant-time HMAC-SHA512 vs `x-paystack-signature`
- **Verify:** JWT user id authoritative over Paystack metadata `user_id`
- **Flutter:** `PAYSTACK_PUBLIC_KEY` in `.env.example` only; no `PAYSTACK_SECRET_KEY` in client

## Flutter client

- `lib/features/subscriptions/data/services/paystack_service.dart` — invokes initialize / verify / cancel
- `paystack_checkout_page.dart` — WebView + callback prefix `https://akuko.app/paystack/callback`
- Premium UX: `SubscriptionGuard` + `Entitlements.fromSubscription` + DB `is_premium()`

## Database

- `0006_subscriptions.sql` — canonical entitlement (`subscriptions`, `is_premium()`)
- `0008_ecosystem.sql` — `payment_transactions` ledger (service-role writes, admin/owner read)

## Gap fixed this release

- **Ledger writes:** `upsertPaymentTransaction()` added to `_shared/paystack.ts`; called from `paystack-verify` and `paystack-webhook` for charge/subscription/invoice events.

No new migration `0009_*` required.

## Deploy checklist

1. `supabase secrets set PAYSTACK_SECRET_KEY=...`
2. Deploy functions; webhook with `--no-verify-jwt`
3. Paystack dashboard webhook URL: `https://<ref>.supabase.co/functions/v1/paystack-webhook`
4. Set Flutter `PAYSTACK_PUBLIC_KEY`, plan codes in `.env` / dart-define

## Env example

See `akuko/.env.example` — `PAYSTACK_PUBLIC_KEY`, `PAYSTACK_PLAN_*`, edge secret documented in comments.

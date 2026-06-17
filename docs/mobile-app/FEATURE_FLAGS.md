# Akuko — Feature Flags

> Defined in `supabase/migrations/0008_ecosystem.sql` (`public.feature_flags`).
> Schema for Phase 2–4 exists in the database; **product behavior** is gated by these
> toggles so rollout does not require new migrations.

---

## How clients read flags

### Flutter (Riverpod / repository)

```dart
// Example: load all flags once at startup or on admin refresh
final rows = await supabase.from('feature_flags').select('key, enabled, phase');
final enabled = {
  for (final r in rows) r['key'] as String: r['enabled'] as bool,
};
```

Or check a single flag:

```dart
final row = await supabase
    .from('feature_flags')
    .select('enabled')
    .eq('key', 'reviews')
    .maybeSingle();
final on = row?['enabled'] == true;
```

Use flags in **router redirects**, **subscription_guard**-style gates, and feature
stubs before wiring full UI.

### SQL / RLS / Edge Functions

```sql
select public.is_feature_enabled('royalties');
```

`is_feature_enabled(text)` is `SECURITY DEFINER`, granted to `anon` and
`authenticated`. Returns `false` if the key is missing.

### Admin dashboard

- **Read:** `select key, enabled, description, phase, updated_at from feature_flags order by phase, key;`
- **Toggle:** `update feature_flags set enabled = true where key = 'author_dashboard';` (admin RLS only)
- Prefer logging changes to `admin_logs` when the admin app exists.

---

## Flag inventory

| Key | Phase | Default (0008 seed) | Description |
|-----|-------|---------------------|-------------|
| `admin_dashboard` | 1 | **true** | Internal admin: catalogue, users, moderation, flag toggles |
| `reviews` | 1 | **true** | Reviews UI + community ratings (`reviews` table) |
| `ai_summaries` | 1 | **true** | Cached LLM summaries (`ai_summaries`) |
| `ai_assistant` | 1 | **true** | In-reader reading assistant edge function |
| `audiobook_mode` | 1 | **true** | Audio assets (`book_files.file_type = audio`) + TTS |
| `ads` | 1 | **true** | In-app ad placements |
| `author_dashboard` | 2 | false | Author portal (stats, catalogue) |
| `author_uploads` | 2 | false | Author draft upload → `books.status` workflow |
| `publisher_dashboard` | 3 | false | Publisher org portal |
| `publisher_uploads` | 3 | false | Publisher-managed uploads (`publishers` insert policy) |
| `publisher_teams` | 3 | false | `publisher_members` owner-managed teams |
| `royalties` | 4 | false | `royalties`, `royalty_distributions`, `author_earnings` reads for linked authors |
| `payouts` | 4 | false | `withdrawals` product surface (writes remain service/admin until launch) |

**Phase 1** = ship with flags **on** (seed). **Phases 2–4** = schema ready, flags **off** until ops enable them.

---

## Mapping flags → schema / UI

| Flag | Tables / objects | Client feature stub |
|------|------------------|---------------------|
| `admin_dashboard` | `admin_logs`, all catalogue tables | `lib/features/admin/` |
| `reviews` | `reviews` | `lib/features/reviews/` |
| `ai_summaries` | `ai_summaries` | `lib/features/ai/` |
| `ai_assistant` | edge `reading-assistant` | `lib/features/ai/` |
| `audiobook_mode` | `book_files` (audio), edge `tts` | `lib/features/tts/` |
| `ads` | `analytics_events` (ad_impression, etc.) | (new) |
| `author_dashboard` | `profiles.author_id`, `authors`, `author_earnings` | (new) |
| `author_uploads` | `books.uploaded_by`, `status` workflow | (new) |
| `publisher_dashboard` | `publishers`, `profiles.publisher_id` | (new) |
| `publisher_uploads` | `books.publisher_id`, RLS `publishers_insert_when_flag` | (new) |
| `publisher_teams` | `publisher_members` | (new) |
| `royalties` | `royalties`, `royalty_distributions`, `author_earnings` | (new) |
| `payouts` | `withdrawals`, `payment_transactions` | (new) |

---

## Related helpers

| Function | Purpose |
|----------|---------|
| `public.is_feature_enabled(text)` | Flag lookup for RLS and SQL |
| `public.user_role()` | Current user's `profiles.role` (`reader` default) |
| `public.is_admin()` | Admin check (0002/0003) |
| `public.is_premium(uuid)` | Subscription entitlement (0006) — **not** a feature flag |

---

## Operational notes

1. **Do not** use `subscriptions` rows to gate feature flags — subscriptions remain the Paystack **entitlement** source of truth.
2. Enabling `royalties` / `payouts` exposes **read** paths for authors; **writes** to royalty calculations and withdrawals still expect **service role** (edge/cron) unless admin policies are used.
3. Re-seeding: migration uses `ON CONFLICT (key) DO UPDATE` for `description` and `phase` only — **does not** reset `enabled` on re-apply (preserves production toggles).

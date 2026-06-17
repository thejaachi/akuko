# Akuko — Ecosystem ERD (0008)

> Full publishing ecosystem after `0008_ecosystem.sql`, on top of `0001`–`0007`.
> For the pre-0008 catalogue diagram see [`DATABASE_SCHEMA.md`](./DATABASE_SCHEMA.md).

```mermaid
erDiagram
  auth_users ||--|| profiles : "1:1 (id)"
  profiles ||--o| authors : "linked via author_id"
  profiles ||--o| publishers : "linked via publisher_id"
  profiles ||--o| reading_streaks : "1:1"
  profiles ||--o| subscriptions : "1:1 entitlement"
  profiles ||--o{ reading_progress : has
  profiles ||--o{ bookmarks : has
  profiles ||--o{ highlights : has
  profiles ||--o{ notes : has
  profiles ||--o{ reviews : writes
  profiles ||--o{ reading_lists : owns
  profiles ||--o{ reading_goals : sets
  profiles ||--o{ notifications : receives
  profiles ||--o{ downloads : downloads
  profiles ||--o{ payment_transactions : pays
  profiles ||--o{ withdrawals : requests
  profiles ||--o{ publisher_members : "team member"
  profiles ||--o{ followers : "as follower"
  profiles ||--o{ analytics_events : "optional"
  profiles ||--o{ admin_logs : "as admin"
  profiles ||--o{ books : "uploaded_by"

  authors ||--o{ books : "wrote (author_id)"
  authors ||--o{ royalties : earns
  authors ||--o{ author_earnings : "monthly aggregate"
  authors ||--o{ followers : "followed by"

  publishers ||--o{ publisher_members : has
  publishers ||--o{ books : publishes
  publishers ||--o{ profiles : "primary org link"

  categories ||--o{ books : classifies
  books ||--o{ book_files : "multi-format"
  books ||--o{ reading_progress : tracked_in
  books ||--o{ bookmarks : marked_in
  books ||--o{ highlights : highlighted_in
  books ||--o{ notes : annotated_in
  books ||--o{ reviews : reviewed_in
  books ||--o{ reading_list_items : listed_in
  books ||--o{ ai_summaries : summarized_in
  books ||--o{ downloads : downloaded_as
  books ||--o{ royalties : "royalty rules"
  books ||--o{ analytics_events : "optional"

  reading_lists ||--o{ reading_list_items : contains
  reading_list_items ||--o| list_books : "view alias"

  royalties ||--o{ royalty_distributions : "monthly accrual"

  subscription_plans ||--o{ user_subscriptions : "legacy catalog"

  feature_flags {
    text key PK
    bool enabled
    text description
    int phase
    timestamptz updated_at
  }

  publishers {
    uuid id PK
    text name
    text slug UK
    text logo_url
    text bio
    text status "pending|approved|suspended"
    timestamptz created_at
    timestamptz updated_at
  }

  publisher_members {
    uuid id PK
    uuid publisher_id FK
    uuid user_id FK
    text role "owner|editor|viewer"
    timestamptz created_at
  }

  profiles {
    uuid id PK
    text full_name
    text avatar_url
    text bio
    bool is_admin
    text role "reader|author|publisher|admin"
    uuid author_id FK
    uuid publisher_id FK
    jsonb reading_preferences
    timestamptz created_at
    timestamptz updated_at
  }

  books {
    uuid id PK
    text title
    text author
    uuid author_id FK
    uuid publisher_id FK
    text status "draft|pending_review|published|rejected|archived"
    uuid uploaded_by FK
    uuid approved_by FK
    timestamptz approved_at
    text rejection_reason
    text pricing_model "free|paid|subscription_only"
    text file_url
    text file_type
    bool is_premium
    timestamptz created_at
    timestamptz updated_at
  }

  book_files {
    uuid id PK
    uuid book_id FK
    text file_type "epub|pdf|audio"
    text storage_path
    bigint file_size_bytes
    timestamptz created_at
  }

  payment_transactions {
    uuid id PK
    uuid user_id FK
    text reference UK
    numeric amount
    text currency
    text status
    text paystack_event
    jsonb metadata
    timestamptz created_at
  }

  subscriptions {
    uuid id PK
    uuid user_id FK UK
    text plan "free|premium"
    text status
    text paystack_customer_code
    text paystack_subscription_code
    timestamptz current_period_end
  }

  royalties {
    uuid id PK
    uuid book_id FK
    uuid author_id FK
    text model "direct_sale|subscription_pool"
    numeric rate_percent
    date effective_from
    timestamptz created_at
  }

  royalty_distributions {
    uuid id PK
    uuid royalty_id FK
    date period_month
    numeric amount
    timestamptz calculated_at
  }

  author_earnings {
    uuid id PK
    uuid author_id FK
    date period_month
    numeric amount
    text currency
    timestamptz calculated_at
  }

  withdrawals {
    uuid id PK
    uuid user_id FK
    numeric amount
    text currency
    text status "pending|processing|paid|failed"
    text paystack_transfer_code
    timestamptz created_at
    timestamptz updated_at
  }

  followers {
    uuid follower_id PK_FK
    uuid author_id PK_FK
    timestamptz created_at
  }

  reading_list_items {
    uuid id PK
    uuid list_id FK
    uuid book_id FK
    timestamptz added_at
  }

  list_books {
    uuid id
    uuid list_id
    uuid book_id
    timestamptz added_at
  }

  analytics_events {
    uuid id PK
    text event_type
    uuid user_id FK
    uuid book_id FK
    jsonb payload
    timestamptz created_at
  }

  admin_logs {
    uuid id PK
    uuid admin_id FK
    text action
    text entity_type
    uuid entity_id
    jsonb metadata
    timestamptz created_at
  }

  authors {
    uuid id PK
    text name UK
    text bio
    text photo_url
    timestamptz created_at
  }
```

---

## Views

| View | Purpose |
|------|---------|
| `public.published_books` | Catalogue rows where `books.status = 'published'` |
| `public.list_books` | Alias of `reading_list_items` (no duplicate table) |
| `public.public_profiles` | Safe profile projection (0007) |

---

## Payment model split

| Object | Role |
|--------|------|
| `subscriptions` (0006) | **Entitlement** — one row per user, `plan`, billing window, Paystack subscription codes |
| `payment_transactions` (0008) | **Ledger** — every charge/reference/event; does not grant premium by itself |
| `withdrawals` (0008) | **Payouts** — transfer requests (Paystack Transfer API) |

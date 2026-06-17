# Database Schema

All tables use prefix `{wp_prefix}akuko_`.

## ERD

```mermaid
erDiagram
    users ||--o{ reading_progress : has
    users ||--o{ subscriptions : has
    users ||--o{ downloads : requests
    users ||--o{ refresh_tokens : has
    users ||--o{ notifications : receives
    users ||--o{ book_highlights : creates
    users ||--o{ book_notes : creates
    users ||--o{ bookmarks : creates
    users ||--o{ reading_history : tracks

    reading_progress {
        bigint id PK
        bigint user_id
        bigint book_id
        varchar position
        decimal percentage
        varchar chapter
        datetime updated_at
    }

    subscriptions {
        bigint id PK
        bigint user_id
        varchar plan
        varchar status
        varchar paystack_reference
        datetime starts_at
        datetime expires_at
    }

    downloads {
        bigint id PK
        bigint user_id
        bigint book_id
        varchar format
        varchar token_hash
        datetime expires_at
        datetime downloaded_at
    }

    refresh_tokens {
        bigint id PK
        bigint user_id
        varchar token_hash UK
        varchar device_id
        varchar device_name
        datetime expires_at
        datetime revoked_at
    }

    feature_flags {
        bigint id PK
        varchar flag_key UK
        tinyint enabled
        text description
        tinyint rollout_percent
    }

    api_logs {
        bigint id PK
        bigint user_id
        varchar endpoint
        varchar method
        varchar ip_address
        smallint status_code
        longtext request_body
        datetime created_at
    }
```

## Tables

| Table | Purpose |
|-------|---------|
| `reading_progress` | Per-user book reading position |
| `reading_statistics` | Aggregate reading time/sessions |
| `book_highlights` | Highlighted text with CFI |
| `book_notes` | User notes with CFI |
| `reading_history` | Open events for analytics |
| `subscriptions` | Mobile premium entitlements |
| `downloads` | Signed download tokens |
| `api_logs` | Audit trail |
| `notifications` | In-app notifications |
| `feature_flags` | Feature toggles |
| `refresh_tokens` | JWT refresh token sessions |
| `bookmarks` | Reader bookmarks |

## Migration

File: `database/migrations/001_initial_schema.php`

Run on plugin activation via `Initial_Schema::run()` using WordPress `dbDelta()`.

Version tracked in option: `akuko_mobile_api_db_version`

## User Meta (non-table)

| Meta Key | Purpose |
|----------|---------|
| `_akuko_wishlist` | Array of book IDs |
| `_akuko_push_devices` | FCM/APNs device tokens |

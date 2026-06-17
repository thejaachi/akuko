# Architecture

## Overview

The Akuko Mobile API is a BFF layer that exposes a mobile-optimized REST API at `/wp-json/akuko/v1/*`. The Flutter app never talks directly to WooCommerce, Dokan, or Paystack — all integration is abstracted behind services and repositories.

```mermaid
flowchart TB
    subgraph Client
        Flutter[Akuko Flutter App]
    end

    subgraph Plugin["Akuko Mobile API Plugin"]
        MW[Middleware<br/>JWT · Rate Limit · Audit]
        CTRL[Controllers]
        SVC[Services]
        REPO[Repositories]
        EVT[Event Dispatcher]
        CACHE[Cache Service]
    end

    subgraph WordPress
        WC[WooCommerce]
        DK[Dokan]
        PS[Paystack WC Plugin]
        DB[(Custom Tables + WP DB)]
    end

    Flutter -->|Bearer JWT| MW
    MW --> CTRL
    CTRL --> SVC
    SVC --> REPO
    SVC --> CACHE
    SVC --> EVT
    REPO --> WC
    REPO --> DK
    REPO --> PS
    REPO --> DB
```

## Folder Structure

```
akuko-mobile-api/
├── akuko-mobile-api.php       # Bootstrap, activation hooks
├── composer.json              # PSR-4 autoload, firebase/php-jwt
├── includes/
│   ├── class-akuko-plugin.php
│   ├── class-akuko-container.php
│   ├── api/                   # REST route registration
│   ├── controllers/           # Thin HTTP layer
│   ├── services/              # Business logic + interfaces/
│   ├── repositories/          # Data access + interfaces/
│   ├── models/                # DTOs / transformers
│   ├── middleware/            # JWT, rate limit, audit
│   ├── helpers/
│   ├── validators/
│   ├── cache/
│   ├── events/
│   ├── jobs/
│   └── notifications/
├── admin/                     # WP Admin UI
├── database/migrations/       # dbDelta schema
├── tests/
└── docs/
```

## Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **Controllers** | Validate input, auth checks, call service, return JSON envelope |
| **Services** | Business rules, orchestration, premium/download logic |
| **Repositories** | All SQL via `$wpdb->prepare`, WC/WP abstraction |
| **Models** | Transform WC_Product → mobile JSON DTO |
| **Middleware** | Cross-cutting: JWT, rate limiting, audit logs |

## Authentication Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as Akuko API
    participant Auth as AuthenticationService
    participant DB as refresh_tokens table

    App->>API: POST /auth/login
    API->>Auth: login(email, password)
    Auth->>Auth: wp_authenticate()
    Auth->>Auth: JWT::encode (access, 1h)
    Auth->>DB: store refresh token hash
    Auth-->>App: access_token + refresh_token

    App->>API: GET /auth/me (Bearer access_token)
    API->>Auth: validate_access_token()
    Auth-->>App: user profile

    App->>API: POST /auth/refresh
    API->>Auth: refresh(refresh_token)
    Auth->>DB: rotate token
    Auth-->>App: new token pair
```

## Download Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as DownloadService
    participant Prem as PremiumService
    participant DB as downloads table

    App->>API: POST /downloads/{book_id}/request
    API->>Prem: has_access(user, book)?
    alt No access
        Prem-->>App: 403 access_denied
    else Has access
        API->>API: HMAC sign token + expiry
        API->>DB: store token_hash
        API-->>App: signed URL (15 min TTL)
    end
```

## Premium Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as PremiumService
    participant Pay as PaymentRepository
    participant PS as Paystack API
    participant Sub as subscriptions table

    App->>PS: Paystack SDK checkout
    PS-->>App: reference
    App->>API: POST /premium/subscribe {reference}
    API->>Pay: verify_paystack(reference)
    Pay->>PS: GET /transaction/verify
    PS-->>Pay: success
    API->>Sub: create active subscription
    API-->>App: premium status + benefits
```

## Payment Flow

Book purchases use existing WooCommerce + Paystack checkout on web or in-app WebView. Mobile calls `POST /payments/verify` to confirm transaction status. Premium uses `POST /premium/subscribe` after Paystack success.

## Class Diagram (Services)

```mermaid
classDiagram
    class AuthenticationService {
        +register()
        +login()
        +refresh()
        +validate_access_token()
    }
    class BookService {
        +list_books()
        +get_book()
        +get_featured()
    }
    class PremiumService {
        +get_status()
        +subscribe()
        +has_access()
    }
    class DownloadService {
        +request_download()
        +validate_token()
    }
    AuthenticationService --> UserRepository
    BookService --> BookRepository
    BookService --> CacheService
    PremiumService --> SubscriptionRepository
    PremiumService --> PaymentRepository
    DownloadService --> PremiumService
```

## Response Envelope

All endpoints return:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": { "page": 1, "per_page": 20, "total": 100 }
}
```

## Events

| Event | Trigger |
|-------|---------|
| `book_purchased` | `woocommerce_order_status_completed` |
| `premium_activated` | Successful premium subscribe |
| `book_downloaded` | Download token issued |
| `review_submitted` | New review created |

## Security

- JWT HS256 with rotatable secret
- Refresh tokens stored as SHA-256 hashes
- Rate limit: 120 req/min per IP (transients)
- All repository queries use prepared statements
- Paystack secret via `wp-config.php` constant (never hardcoded)

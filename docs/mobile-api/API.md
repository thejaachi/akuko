# API Reference

Base URL: `https://books.ikikearts.com/wp-json/akuko/v1`

## Authentication

All protected endpoints require: `Authorization: Bearer <access_token>`

### POST /auth/register

Register a new user.

**Body:** `email`, `password`, `first_name?`, `last_name?`, `name?`, `device_id?`, `device_name?`

Returns JWT tokens immediately; email confirmation is not required when
`AKUKO_SKIP_EMAIL_VERIFICATION` is true (default). Set
`define( 'AKUKO_SKIP_EMAIL_VERIFICATION', false );` in `wp-config.php` to
enable WordPress new-user notification emails.

### POST /auth/login

**Body:** `email`, `password`, `device_id?`, `device_name?`

**Response:** `access_token`, `refresh_token`, `expires_in`, `user`

### POST /auth/logout

**Auth required.** Body: `refresh_token?` (omit to revoke all sessions)

### POST /auth/forgot-password

**Body:** `email`

### POST /auth/reset-password

**Body:** `token`, `password`

### POST /auth/refresh

**Body:** `refresh_token`

### GET /auth/me

**Auth required.** Returns current user profile and device sessions.

---

## Books

### GET /books

Query: `page`, `per_page`, `category`

### GET /books/{id}

### GET /books/featured

Query: `limit` (default 10)

### GET /books/trending

### GET /books/new-releases

### GET /books/{id}/related

---

## Categories

### GET /categories

---

## Authors

### GET /authors

### GET /authors/{id}

---

## Search

### GET /search?q=

Query: `q` (min 2 chars), `page`, `per_page`

---

## Library

### GET /library

**Auth required.** Purchased books.

### GET /library/continue-reading

**Auth required.**

---

## Reading

### GET /reading/progress/{book_id}

### PUT /reading/progress/{book_id}

Body: `position`, `percentage`, `chapter`

### GET /bookmarks

Query: `book_id?`

### POST /bookmarks

Body: `book_id`, `cfi`, `label?`

### DELETE /bookmarks

Query: `id`

### GET /highlights | POST /highlights | DELETE /highlights

Same pattern as bookmarks. POST body: `book_id`, `text`, `cfi?`, `color?`

### GET /notes | POST /notes | DELETE /notes

POST body: `book_id`, `content`, `cfi?`

---

## Downloads

### POST /downloads/{book_id}/request

**Auth required.** Body: `format` (epub|pdf|audio)

**Response:** `url`, `expires_at`, `expires_in`

---

## Premium

### GET /premium/status

**Auth required.**

### POST /premium/subscribe

**Auth required.** Body: `reference` (Paystack transaction reference)

---

## Payments

### POST /payments/verify

**Auth required.** Body: `reference`

### GET /payments/history

**Auth required.**

---

## Reviews

### GET /books/{id}/reviews

### POST /books/{id}/reviews

**Auth required.** Body: `content`, `rating` (1-5)

---

## Wishlist

### GET /wishlist

### POST /wishlist

Body: `book_id`

### DELETE /wishlist

Query: `book_id`

---

## Notifications

### GET /notifications

### POST /notifications/device-token

Body: `token`, `platform` (android|ios)

---

## Settings

### GET /settings

Public app configuration.

---

## AI (Stub — 501)

### POST /ai/summary

Body: `book_id`

### POST /ai/chat

Body: `messages[]`

---

## Audiobooks (Stub)

### GET /audiobooks/{book_id}

---

## Recommendations

### GET /recommendations/home

---

## Analytics

### POST /analytics/event

Body: `event`, `payload`

---

## Feature Flags

### GET /feature-flags

---

## Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `akuko_unauthorized` | 401 | Missing/invalid Bearer token |
| `akuko_rate_limited` | 429 | Too many requests |
| `access_denied` | 403 | No purchase/premium for resource |
| `not_implemented` | 501 | Feature stub |
| `not_found` | 404 | Resource not found |

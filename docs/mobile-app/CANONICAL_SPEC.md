# Akuko — Canonical Specification (Single Source of Truth)

> Both the Supabase backend and the Flutter client MUST conform to the entities,
> field names, and types defined here. Use `snake_case` in the database and
> map to `camelCase` in Dart models.

## Product
Akuko is a modern ebook reader + bookstore. EPUB & PDF reading, premium
subscriptions, AI features, community, and admin tooling.

## Tech Stack
- Flutter 3.x / Dart 3.x
- Supabase (Postgres, Auth, Storage, Edge Functions, Realtime)
- Riverpod (state) + GoRouter (navigation)
- Clean Architecture + Repository Pattern
- Material 3, responsive

## Canonical Data Model (DB tables / columns)

### profiles  (1:1 with auth.users)
- id uuid PK (= auth.users.id)
- full_name text
- avatar_url text
- bio text
- is_admin bool default false
- reading_preferences jsonb  -- {fontSize, lineSpacing, themeMode, fontFamily}
- created_at timestamptz default now()
- updated_at timestamptz default now()

### categories
- id uuid PK
- name text not null
- slug text unique not null
- description text
- icon text
- sort_order int default 0
- created_at timestamptz default now()

### books
- id uuid PK
- title text not null
- author text not null
- description text
- cover_url text
- file_url text            -- storage path to epub/pdf
- file_type text check (file_type in ('epub','pdf'))
- file_size_bytes bigint
- category_id uuid FK -> categories(id)
- isbn text
- language text default 'en'
- page_count int
- publisher text
- published_date date
- price numeric(10,2) default 0
- is_premium bool default false
- is_featured bool default false
- is_trending bool default false
- is_new_release bool default false
- rating_avg numeric(3,2) default 0
- rating_count int default 0
- download_count int default 0
- created_at timestamptz default now()
- updated_at timestamptz default now()

### reading_progress  (unique: user_id+book_id)
- id uuid PK
- user_id uuid FK -> profiles(id)
- book_id uuid FK -> books(id)
- location text          -- EPUB CFI or PDF page index
- progress_percent numeric(5,2) default 0
- last_read_at timestamptz default now()

### bookmarks
- id uuid PK
- user_id uuid FK
- book_id uuid FK
- location text not null
- label text
- created_at timestamptz default now()

### highlights
- id uuid PK
- user_id uuid FK
- book_id uuid FK
- location text not null
- selected_text text
- color text default 'yellow'
- created_at timestamptz default now()

### notes
- id uuid PK
- user_id uuid FK
- book_id uuid FK
- location text
- content text not null
- created_at timestamptz default now()
- updated_at timestamptz default now()

### reviews  (unique: user_id+book_id)
- id uuid PK
- user_id uuid FK
- book_id uuid FK
- rating int check (rating between 1 and 5)
- comment text
- created_at timestamptz default now()
- updated_at timestamptz default now()

### reading_lists
- id uuid PK
- user_id uuid FK
- name text not null
- description text
- is_public bool default false
- created_at timestamptz default now()

### reading_list_items  (unique: list_id+book_id)
- id uuid PK
- list_id uuid FK -> reading_lists(id)
- book_id uuid FK
- added_at timestamptz default now()

### reading_goals
- id uuid PK
- user_id uuid FK
- goal_type text check (goal_type in ('books','minutes','pages'))
- target int not null
- period text check (period in ('daily','weekly','monthly','yearly'))
- start_date date
- created_at timestamptz default now()

### reading_streaks  (1:1 user)
- user_id uuid PK FK
- current_streak int default 0
- longest_streak int default 0
- last_active_date date

### subscription_plans
- id uuid PK
- name text not null
- description text
- price numeric(10,2) not null
- interval text check (interval in ('monthly','yearly'))
- features jsonb
- is_active bool default true

### user_subscriptions
- id uuid PK
- user_id uuid FK
- plan_id uuid FK -> subscription_plans(id)
- status text check (status in ('active','cancelled','expired','trialing'))
- started_at timestamptz default now()
- expires_at timestamptz

### ai_summaries  (cached AI output)
- id uuid PK
- book_id uuid FK
- chapter_ref text          -- null = whole-book summary
- summary_type text check (summary_type in ('book','chapter'))
- content text not null
- created_at timestamptz default now()

### notifications
- id uuid PK
- user_id uuid FK
- type text check (type in ('reading_reminder','new_book','promotion','system'))
- title text not null
- body text
- data jsonb
- is_read bool default false
- created_at timestamptz default now()

## Storage Buckets
- `book-files` (private): epub/pdf, signed-URL access (premium gated)
- `book-covers` (public): cover images
- `avatars` (public): profile pictures

## MVP SCOPE (Phase 1 — build first)
Auth (email/password + Google + forgot password), profile, browse/search books,
categories, featured/trending/new sections, book detail, EPUB+PDF reader with
font size / line spacing / Light-Dark-Sepia themes, reading progress, bookmarks.
Everything else (highlights, notes, reviews, reading lists/goals/streaks,
subscriptions, AI, TTS, offline sync, notifications, admin) = Phase 2+.

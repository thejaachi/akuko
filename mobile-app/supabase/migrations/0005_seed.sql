-- =====================================================================
-- Akuko — 0005_seed.sql
-- Reference/sample data: categories, books, subscription plans.
-- Uses fixed UUIDs so re-runs are idempotent and FKs resolve reliably.
-- Cover/file URLs are placeholders (replace with real Storage paths).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Categories (8)
-- ---------------------------------------------------------------------
insert into public.categories (id, name, slug, description, icon, sort_order) values
  ('11111111-0000-0000-0000-000000000001', 'Fiction',          'fiction',          'Novels and literary fiction.',                 'auto_stories',  1),
  ('11111111-0000-0000-0000-000000000002', 'Non-Fiction',      'non-fiction',      'Real stories, essays and reference.',          'menu_book',     2),
  ('11111111-0000-0000-0000-000000000003', 'Science Fiction',  'science-fiction',  'Futuristic and speculative worlds.',           'rocket_launch', 3),
  ('11111111-0000-0000-0000-000000000004', 'Fantasy',          'fantasy',          'Magic, myth and epic adventure.',              'castle',        4),
  ('11111111-0000-0000-0000-000000000005', 'Mystery & Thriller','mystery-thriller','Suspense, crime and page-turners.',            'search',        5),
  ('11111111-0000-0000-0000-000000000006', 'Business',         'business',         'Entrepreneurship, finance and management.',    'trending_up',   6),
  ('11111111-0000-0000-0000-000000000007', 'Self-Help',        'self-help',        'Personal growth and productivity.',            'self_improvement', 7),
  ('11111111-0000-0000-0000-000000000008', 'History',          'history',          'World history and biographies.',               'history_edu',   8)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Books (12)
-- file_url values point at the (private) book-files bucket.
-- cover_url values point at the (public) book-covers bucket.
-- ---------------------------------------------------------------------
insert into public.books
  (id, title, author, description, cover_url, file_url, file_type, file_size_bytes,
   category_id, isbn, language, page_count, publisher, published_date, price,
   is_premium, is_featured, is_trending, is_new_release)
values
  ('22222222-0000-0000-0000-000000000001',
   'The Silent Harbor', 'Maya Okafor',
   'A sweeping literary novel about memory and the sea.',
   'book-covers/the-silent-harbor.jpg', 'book-files/the-silent-harbor.epub', 'epub', 1843200,
   '11111111-0000-0000-0000-000000000001', '9780000000011', 'en', 312, 'Harbor House', '2023-04-12', 0,
   false, true, true, false),

  ('22222222-0000-0000-0000-000000000002',
   'Atomic Habits, Revisited', 'Daniel Reeves',
   'A practical guide to building systems that stick.',
   'book-covers/atomic-habits-revisited.jpg', 'book-files/atomic-habits-revisited.pdf', 'pdf', 5242880,
   '11111111-0000-0000-0000-000000000007', '9780000000028', 'en', 268, 'Northwind Press', '2024-01-09', 4.99,
   true, true, false, true),

  ('22222222-0000-0000-0000-000000000003',
   'Quantum Drift', 'Lena Park',
   'Humanity''s first faster-than-light voyage goes wrong.',
   'book-covers/quantum-drift.jpg', 'book-files/quantum-drift.epub', 'epub', 2097152,
   '11111111-0000-0000-0000-000000000003', '9780000000035', 'en', 401, 'Stellar Books', '2024-06-01', 6.99,
   true, false, true, true),

  ('22222222-0000-0000-0000-000000000004',
   'The Cartographer''s Oath', 'Idris Mwangi',
   'An epic fantasy of maps that rewrite the world.',
   'book-covers/cartographers-oath.jpg', 'book-files/cartographers-oath.epub', 'epub', 3145728,
   '11111111-0000-0000-0000-000000000004', '9780000000042', 'en', 552, 'Mythic Quill', '2022-11-15', 0,
   false, true, false, false),

  ('22222222-0000-0000-0000-000000000005',
   'Cold Ledger', 'Sara Bianchi',
   'A forensic accountant stumbles onto a deadly conspiracy.',
   'book-covers/cold-ledger.jpg', 'book-files/cold-ledger.epub', 'epub', 1572864,
   '11111111-0000-0000-0000-000000000005', '9780000000059', 'en', 344, 'Granite Crime', '2023-09-20', 3.99,
   false, false, true, false),

  ('22222222-0000-0000-0000-000000000006',
   'The Founder''s Dilemma', 'Kwame Mensah',
   'Hard lessons from building and scaling startups.',
   'book-covers/founders-dilemma.jpg', 'book-files/founders-dilemma.pdf', 'pdf', 4194304,
   '11111111-0000-0000-0000-000000000006', '9780000000066', 'en', 290, 'Ledger & Co', '2024-03-05', 9.99,
   true, true, false, true),

  ('22222222-0000-0000-0000-000000000007',
   'A Brief History of Everything Else', 'Noor Rahman',
   'The overlooked stories that shaped civilization.',
   'book-covers/history-everything-else.jpg', 'book-files/history-everything-else.epub', 'epub', 2621440,
   '11111111-0000-0000-0000-000000000008', '9780000000073', 'en', 478, 'Chronicle Press', '2021-07-30', 0,
   false, false, false, false),

  ('22222222-0000-0000-0000-000000000008',
   'Deep Work, Deep Life', 'Hannah Cole',
   'Reclaiming focus in an age of endless distraction.',
   'book-covers/deep-work-deep-life.jpg', 'book-files/deep-work-deep-life.pdf', 'pdf', 3670016,
   '11111111-0000-0000-0000-000000000007', '9780000000080', 'en', 232, 'Northwind Press', '2023-02-14', 4.49,
   true, false, true, false),

  ('22222222-0000-0000-0000-000000000009',
   'The Glass Forest', 'Tomas Vega',
   'A haunting mystery set in a remote alpine village.',
   'book-covers/glass-forest.jpg', 'book-files/glass-forest.epub', 'epub', 1966080,
   '11111111-0000-0000-0000-000000000005', '9780000000097', 'en', 366, 'Granite Crime', '2024-05-18', 0,
   false, true, false, true),

  ('22222222-0000-0000-0000-000000000010',
   'Signals from Andromeda', 'Priya Nair',
   'First contact arrives as a song no one can decode.',
   'book-covers/signals-andromeda.jpg', 'book-files/signals-andromeda.epub', 'epub', 2359296,
   '11111111-0000-0000-0000-000000000003', '9780000000103', 'en', 388, 'Stellar Books', '2022-08-22', 5.99,
   true, false, false, false),

  ('22222222-0000-0000-0000-000000000011',
   'The Honest Truth About Money', 'Grace Adeyemi',
   'A no-nonsense personal finance handbook.',
   'book-covers/honest-truth-money.jpg', 'book-files/honest-truth-money.pdf', 'pdf', 2883584,
   '11111111-0000-0000-0000-000000000002', '9780000000110', 'en', 256, 'Ledger & Co', '2023-12-01', 0,
   false, false, true, false),

  ('22222222-0000-0000-0000-000000000012',
   'Embers of the Ninth Realm', 'Yuki Tanaka',
   'A young mage must unite nine warring kingdoms.',
   'book-covers/embers-ninth-realm.jpg', 'book-files/embers-ninth-realm.epub', 'epub', 3407872,
   '11111111-0000-0000-0000-000000000004', '9780000000127', 'en', 612, 'Mythic Quill', '2024-09-10', 7.99,
   true, true, true, true)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Subscription plans (monthly + yearly)
-- ---------------------------------------------------------------------
insert into public.subscription_plans (id, name, description, price, interval, features, is_active) values
  ('33333333-0000-0000-0000-000000000001',
   'Akuko Premium Monthly',
   'Unlimited access to all premium books, AI summaries, and TTS audiobooks.',
   9.99, 'monthly',
   '{"unlimited_premium_books": true, "ai_summaries": true, "reading_assistant": true, "tts_audiobooks": true, "offline_downloads": true, "ad_free": true}'::jsonb,
   true),
  ('33333333-0000-0000-0000-000000000002',
   'Akuko Premium Yearly',
   'All Premium features billed annually — best value (2 months free).',
   99.99, 'yearly',
   '{"unlimited_premium_books": true, "ai_summaries": true, "reading_assistant": true, "tts_audiobooks": true, "offline_downloads": true, "ad_free": true, "priority_support": true}'::jsonb,
   true)
on conflict (id) do nothing;

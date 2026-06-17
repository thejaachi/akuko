# Akuko — API Design (Repository ↔ Supabase mapping)

> Defines the Domain-layer repository interfaces the Flutter Clean Architecture
> client expects, and maps each method to a concrete Supabase call: PostgREST
> filter, RPC, Storage op, or Edge Function. Field names follow
> [`CANONICAL_SPEC.md`](./CANONICAL_SPEC.md) (`snake_case` in DB, `camelCase` in
> Dart DTO mapping).

**Conventions**

- `supabase` = the initialized `SupabaseClient` (anon key + user JWT).
- PostgREST reads/writes are RLS-enforced; the tables in the snippets assume the
  signed-in user.
- Edge functions are called via `supabase.functions.invoke(name, body: ...)`.
- All responses map DB rows → Dart entities in the Data layer.
- **Return type convention (as implemented):** repositories are declared as
  `abstract interface class` and every method returns a `Future<Result<T>>`
  (a sealed `Result<T>` = `Ok<T>` | `Err<Failure>`, see
  `lib/core/utils/result.dart`). Presentation-layer providers unwrap via
  `getOrThrow()` so failures surface through the shared `ErrorView`. The
  signatures below omit the `Result<>` wrapper for readability — read
  `Future<Book>` as `Future<Result<Book>>`, etc. Streams (`authStateChanges`)
  and synchronous getters (`currentUser`) are not wrapped.

---

## 1. AuthRepository

```dart
abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<AuthUser> signUpWithEmail({required String email, required String password, String? fullName});
  Future<AuthUser> signInWithEmail({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}
```

| Method | Supabase call |
|--------|---------------|
| `authStateChanges` | `supabase.auth.onAuthStateChange` |
| `currentUser` | `supabase.auth.currentUser` |
| `signUpWithEmail` | `supabase.auth.signUp(email, password, data: {'full_name': fullName})` |
| `signInWithEmail` | `supabase.auth.signInWithPassword(email, password)` |
| `signInWithGoogle` | `supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'io.akuko.app://login-callback/')` |
| `sendPasswordReset` | `supabase.auth.resetPasswordForEmail(email, redirectTo: ...)` |
| `signOut` | `supabase.auth.signOut()` |

> A `profiles` row is created automatically by the `handle_new_user()` trigger;
> no extra insert needed on signup.

---

## 2. ProfileRepository

```dart
abstract interface class ProfileRepository {
  Future<Profile> getMyProfile();
  Future<Profile> getProfile(String userId);
  Future<Profile> updateProfile({String? fullName, String? bio, ReadingPreferences? preferences});
  Future<String> uploadAvatar(File file);   // returns avatar_url
}
```

| Method | Supabase call |
|--------|---------------|
| `getMyProfile` | `from('profiles').select().eq('id', uid).single()` |
| `getProfile` | `from('profiles').select('id,full_name,avatar_url,bio').eq('id', userId).single()` |
| `updateProfile` | `from('profiles').update({...}).eq('id', uid).select().single()` |
| `uploadAvatar` | `storage.from('avatars').upload('$uid/avatar.jpg', file, upsert)` → `getPublicUrl` → update `profiles.avatar_url` |

`ReadingPreferences` ↔ `reading_preferences` jsonb `{fontSize,lineSpacing,themeMode,fontFamily}`.

---

## 3. BookRepository

```dart
abstract interface class BookRepository {
  Future<List<Book>> getFeatured({int limit = 10});
  Future<List<Book>> getTrending({int limit = 10});
  Future<List<Book>> getNewReleases({int limit = 10});
  Future<List<Book>> getByCategory(String categoryId, {int limit = 20, int offset = 0});
  Future<List<Book>> search(String query, {int limit = 30});
  Future<Book> getById(String id);
  Future<List<Category>> listCategories();
}
```

| Method | Supabase call |
|--------|---------------|
| `getFeatured` | `from('books').select().eq('is_featured', true).limit(limit)` |
| `getTrending` | `from('books').select().eq('is_trending', true).limit(limit)` |
| `getNewReleases` | `from('books').select().eq('is_new_release', true).order('created_at', desc).limit(limit)` |
| `getByCategory` | `from('books').select().eq('category_id', categoryId).order('created_at', desc).range(offset, offset+limit-1)` |
| `search` | `from('books').select().or('title.ilike.%q%,author.ilike.%q%').limit(limit)` (backed by `pg_trgm` GIN indexes) — or RPC `search_books(q)` for ranked results |
| `getById` | `from('books').select('*, categories(name,slug)').eq('id', id).single()` |
| `listCategories` | `from('categories').select().order('sort_order')` |

**Optional ranked-search RPC** (define in a later migration if needed):

```sql
create or replace function public.search_books(q text, max_rows int default 20)
returns setof public.books language sql stable as $$
  select * from public.books
  where title % q or author % q or title ilike '%'||q||'%' or author ilike '%'||q||'%'
  order by greatest(similarity(title, q), similarity(author, q)) desc
  limit max_rows;
$$;
```

Invoke: `supabase.rpc('search_books', params: {'q': query})`.

---

## 4. ReadingRepository (progress, bookmarks, highlights, notes)

**MVP (as implemented in `reader/domain/repositories/reading_repository.dart`)** —
takes/returns full entities so the location/percent payload stays in one place:

```dart
abstract interface class ReadingRepository {
  Future<ReadingProgress> saveProgress(ReadingProgress progress);   // upsert
  Future<ReadingProgress?> getProgress(String bookId);
  Future<Bookmark> addBookmark(Bookmark bookmark);
  Future<List<Bookmark>> listBookmarks(String bookId);
  Future<void> deleteBookmark(String bookmarkId);
}
```

| Method | Supabase call |
|--------|---------------|
| `getProgress` | `from('reading_progress').select().eq('book_id', bookId).maybeSingle()` |
| `saveProgress` | `from('reading_progress').upsert({user_id, book_id, location, progress_percent, last_read_at}, onConflict: 'user_id,book_id')` |
| `listBookmarks` | `from('bookmarks').select().eq('book_id', bookId).order('created_at')` |
| `addBookmark` | `from('bookmarks').insert({...}).select().single()` |
| `deleteBookmark` | `from('bookmarks').delete().eq('id', bookmarkId)` |

**Phase 2 — highlights & notes** (entities/tables already in `CANONICAL_SPEC.md`):

```dart
  Future<List<Highlight>> getHighlights(String bookId);
  Future<Highlight> addHighlight({required String bookId, required String location, String? selectedText, String color});
  Future<void> removeHighlight(String highlightId);
  Future<List<Note>> getNotes(String bookId);
  Future<Note> upsertNote({String? id, required String bookId, String? location, required String content});
  Future<void> removeNote(String noteId);
```

| Method | Supabase call |
|--------|---------------|
| `getHighlights` | `from('highlights').select().eq('book_id', bookId)` |
| `addHighlight` | `from('highlights').insert({...}).select().single()` |
| `getNotes` | `from('notes').select().eq('book_id', bookId).order('created_at')` |
| `upsertNote` | insert when `id == null`, else `update().eq('id', id)` |

> `saveProgress` does **not** send `user_id` from the client other than as
> `auth.uid()`; RLS enforces ownership. Writing progress also bumps the user's
> reading streak via DB trigger.

---

## 5. BookFileRepository (downloads / reader source)

```dart
abstract interface class BookFileRepository {
  Future<String> getSignedUrl(String bookId, {int expiresIn = 3600}); // for reading/streaming
  Future<File> downloadForOffline(String bookId);                     // cache to device
}
```

| Method | Supabase call |
|--------|---------------|
| `getSignedUrl` | `functions.invoke('signed-url', body: {'bookId': bookId, 'expiresIn': expiresIn})` → `{ signedUrl, expiresIn }` |
| `downloadForOffline` | call `getSignedUrl`, then HTTP GET the file and persist locally |

**`signed-url` contract**

```
POST /functions/v1/signed-url   (Bearer <jwt>)
body:     { "bookId": "<uuid>", "expiresIn": 3600 }
200:      { "signedUrl": "https://...", "expiresIn": 3600 }
402:      { "error": "Premium subscription required" }
404:      { "error": "Book not found" }
```

---

## 6. ReviewRepository

```dart
abstract interface class ReviewRepository {
  Future<List<Review>> getReviews(String bookId, {int limit = 20, int offset = 0});
  Future<Review?> getMyReview(String bookId);
  Future<Review> upsertReview({required String bookId, required int rating, String? comment});
  Future<void> deleteReview(String reviewId);
}
```

| Method | Supabase call |
|--------|---------------|
| `getReviews` | `from('reviews').select('*, profiles(full_name,avatar_url)').eq('book_id', bookId).range(...)` |
| `getMyReview` | `from('reviews').select().eq('book_id', bookId).maybeSingle()` |
| `upsertReview` | `from('reviews').upsert({user_id, book_id, rating, comment}, onConflict: 'user_id,book_id')` |
| `deleteReview` | `from('reviews').delete().eq('id', reviewId)` |

> `books.rating_avg` / `rating_count` update automatically via trigger — the
> client should re-read the book (or rely on Realtime) to refresh the aggregate.

---

## 7. LibraryRepository (reading lists)

```dart
abstract interface class LibraryRepository {
  Future<List<ReadingList>> getMyLists();
  Future<List<ReadingList>> getPublicLists({int limit = 20});
  Future<ReadingList> createList({required String name, String? description, bool isPublic = false});
  Future<void> deleteList(String listId);
  Future<List<Book>> getListBooks(String listId);
  Future<void> addToList({required String listId, required String bookId});
  Future<void> removeFromList({required String listId, required String bookId});
}
```

| Method | Supabase call |
|--------|---------------|
| `getMyLists` | `from('reading_lists').select().eq('user_id', uid)` |
| `getPublicLists` | `from('reading_lists').select().eq('is_public', true).limit(limit)` |
| `createList` | `from('reading_lists').insert({...}).select().single()` |
| `getListBooks` | `from('reading_list_items').select('books(*)').eq('list_id', listId)` |
| `addToList` | `from('reading_list_items').insert({list_id, book_id})` (unique guards dupes) |
| `removeFromList` | `from('reading_list_items').delete().eq('list_id', listId).eq('book_id', bookId)` |

---

## 8. GoalsRepository (goals + streaks)

```dart
abstract interface class GoalsRepository {
  Future<List<ReadingGoal>> getGoals();
  Future<ReadingGoal> createGoal({required String goalType, required int target, required String period, DateTime? startDate});
  Future<void> deleteGoal(String goalId);
  Future<ReadingStreak> getStreak();
}
```

| Method | Supabase call |
|--------|---------------|
| `getGoals` | `from('reading_goals').select().eq('user_id', uid)` |
| `createGoal` | `from('reading_goals').insert({...}).select().single()` |
| `getStreak` | `from('reading_streaks').select().eq('user_id', uid).maybeSingle()` |

---

## 9. SubscriptionRepository

```dart
abstract interface class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();
  Future<UserSubscription?> getMySubscription();
  Future<bool> isPremiumActive();
}
```

| Method | Supabase call |
|--------|---------------|
| `getPlans` | `from('subscription_plans').select().eq('is_active', true)` |
| `getMySubscription` | `from('user_subscriptions').select('*, subscription_plans(*)').eq('status','active').maybeSingle()` |
| `isPremiumActive` | derived from `getMySubscription` (status active && expires_at in future) |

> Subscription **writes** are not exposed to the client; they are performed by a
> billing webhook / Edge Function using the service role after a successful
> payment (Phase 5).

---

## 10. AiRepository (AI features — Phase 5)

```dart
abstract interface class AiRepository {
  Future<String> summarize({required String bookId, String summaryType = 'book', String? chapterRef});
  Future<AssistantAnswer> ask({required String bookId, required String question, String? context, List<ChatTurn> history});
  Future<TtsJob> generateAudio({required String bookId, String? chapterRef, String? voice});
}
```

| Method | Edge function | Body | Response |
|--------|---------------|------|----------|
| `summarize` | `ai-summary` | `{bookId, summaryType, chapterRef}` | `{summary, cached}` |
| `ask` | `reading-assistant` | `{bookId, question, context, history}` | `{answer, citations:[{location,snippet}]}` |
| `generateAudio` | `tts` | `{bookId, chapterRef, text?, voice, format}` | `202 {status:'processing', jobId}` or `{audioUrl, durationSec}` |

---

## 11. NotificationRepository

```dart
abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications();
  Future<void> markRead(String id);
  Future<int> unreadCount();
}
```

| Method | Supabase call |
|--------|---------------|
| `watchNotifications` | `from('notifications').stream(primaryKey: ['id']).eq('user_id', uid).order('created_at', desc)` (Realtime) |
| `markRead` | `from('notifications').update({'is_read': true}).eq('id', id)` |
| `unreadCount` | `from('notifications').select('id', count: exact).eq('is_read', false)` |

---

## Edge function & RPC index (for the Flutter worker)

| Name | Kind | Auth | Purpose |
|------|------|------|---------|
| `signed-url` | Edge fn | JWT | time-limited download URL for `book-files` (premium gated) |
| `ai-summary` | Edge fn | JWT | book/chapter summary, cached in `ai_summaries` |
| `reading-assistant` | Edge fn | JWT | per-book Q&A |
| `tts` | Edge fn | JWT | audiobook generation (premium) |
| `search_books(q, max_rows)` | RPC (optional) | anon/JWT | ranked trigram search |

**Env vars (server-side / Edge):** `LLM_API_KEY`, `LLM_MODEL`, `TTS_API_KEY`,
`TTS_PROVIDER`, `CORS_ALLOW_ORIGIN` (auto-injected: `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`).
**Client build vars (`--dart-define` / `.env`):** `AKUKO_SUPABASE_URL`,
`AKUKO_SUPABASE_ANON_KEY`, `AKUKO_AUTH_REDIRECT`.

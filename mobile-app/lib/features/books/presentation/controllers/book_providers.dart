import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/books/data/datasources/book_remote_datasource.dart';
import 'package:akuko/features/books/data/repositories/supabase_book_repository.dart';
import 'package:akuko/features/books/domain/repositories/book_repository.dart';
import 'package:akuko/features/books/presentation/widgets/book_horizontal_section.dart';
import 'package:akuko/shared/domain/entities/book.dart';
import 'package:akuko/shared/domain/entities/book_delivery_format.dart';
import 'package:akuko/shared/domain/entities/category.dart';

final bookRemoteDataSourceProvider = Provider<BookRemoteDataSource>((ref) {
  return BookRemoteDataSource(ref.watch(booksApiProvider));
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return SupabaseBookRepository(ref.watch(bookRemoteDataSourceProvider));
});

/// Selected African language filter (`null` = all). Client-side on `books.language`.
final selectedLanguageFilterProvider = StateProvider<String?>((ref) => null);

/// Delivery format filter for home carousels (`null` = all formats).
final bookFormatFilterProvider =
    StateProvider<BookDeliveryFormat?>((ref) => null);

List<Book> _filterByLanguage(List<Book> books, String? lang) {
  if (lang == null || lang.isEmpty) return books;
  return books.where((b) => b.language.toLowerCase() == lang.toLowerCase()).toList();
}

List<Book> _filterByFormat(List<Book> books, BookDeliveryFormat? format) {
  if (format == null) return books;
  return books.where((b) => b.deliveryFormat == format).toList();
}

List<Book> _applyHomeFilters(
  List<Book> books,
  String? lang,
  BookDeliveryFormat? format,
) =>
    _filterByFormat(_filterByLanguage(books, lang), format);

final featuredBooksRawProvider = FutureProvider<List<Book>>((ref) async {
  return (await ref.watch(bookRepositoryProvider).getFeatured()).getOrThrow();
});

final trendingBooksRawProvider = FutureProvider<List<Book>>((ref) async {
  return (await ref.watch(bookRepositoryProvider).getTrending()).getOrThrow();
});

final newReleasesRawProvider = FutureProvider<List<Book>>((ref) async {
  return (await ref.watch(bookRepositoryProvider).getNewReleases())
      .getOrThrow();
});

final featuredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final lang = ref.watch(selectedLanguageFilterProvider);
  return ref.watch(featuredBooksRawProvider).whenData(
        (books) => _filterByLanguage(books, lang),
      );
});

final trendingBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final lang = ref.watch(selectedLanguageFilterProvider);
  return ref.watch(trendingBooksRawProvider).whenData(
        (books) => _filterByLanguage(books, lang),
      );
});

final newReleasesProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final lang = ref.watch(selectedLanguageFilterProvider);
  return ref.watch(newReleasesRawProvider).whenData(
        (books) => _filterByLanguage(books, lang),
      );
});

List<BookCarouselItem> _toCarouselItems(
  List<Book> books, {
  List<CuratedBookSpec>? specs,
}) {
  final specById = <String, CuratedBookSpec>{
    for (final s in specs ?? <CuratedBookSpec>[]) s.id: s,
  };
  return books
      .map(
        (b) => BookCarouselItem(
          book: b,
          spec: specById[b.id],
          showGift: specById[b.id]?.showGiftButton ?? false,
        ),
      )
      .toList();
}

final christianBooksRawProvider = FutureProvider<List<Book>>((ref) async {
  return (await ref.watch(bookRepositoryProvider).getChristianBooks())
      .getOrThrow();
});

/// Christian Literature — curated placeholders merged with category DB rows.
final christianLiteratureProvider =
    Provider<AsyncValue<List<BookCarouselItem>>>((ref) {
  final lang = ref.watch(selectedLanguageFilterProvider);
  final format = ref.watch(bookFormatFilterProvider);
  final curated = _applyHomeFilters(
    CuratedHomeContent.toBooks(CuratedHomeContent.christianLiteratureBooks),
    lang,
    format,
  );
  return ref.watch(christianBooksRawProvider).when(
        loading: () => AsyncData(_toCarouselItems(
          curated,
          specs: CuratedHomeContent.christianLiteratureBooks,
        )),
        error: (e, st) => AsyncData(_toCarouselItems(
          curated,
          specs: CuratedHomeContent.christianLiteratureBooks,
        )),
        data: (db) {
          final merged = CuratedHomeContent.mergeWithDb(
            curated,
            _applyHomeFilters(db, lang, format),
          );
          return AsyncData(_toCarouselItems(
            merged,
            specs: CuratedHomeContent.christianLiteratureBooks,
          ));
        },
      );
});

/// @deprecated Use [christianLiteratureProvider].
final silentHarborProvider = christianLiteratureProvider;

/// Bestselling — curated placeholders merged with trending DB rows.
final homeBestsellingProvider =
    Provider<AsyncValue<List<BookCarouselItem>>>((ref) {
  final lang = ref.watch(selectedLanguageFilterProvider);
  final format = ref.watch(bookFormatFilterProvider);
  final curated = _applyHomeFilters(
    CuratedHomeContent.toBooks(CuratedHomeContent.bestsellingBooks),
    lang,
    format,
  );
  return ref.watch(trendingBooksRawProvider).when(
        loading: () => AsyncData(_toCarouselItems(
          curated,
          specs: CuratedHomeContent.bestsellingBooks,
        )),
        error: (e, st) => AsyncData(_toCarouselItems(
          curated,
          specs: CuratedHomeContent.bestsellingBooks,
        )),
        data: (db) {
          final merged = CuratedHomeContent.mergeWithDb(
            curated,
            _applyHomeFilters(db, lang, format),
          );
          return AsyncData(_toCarouselItems(
            merged,
            specs: CuratedHomeContent.bestsellingBooks,
          ));
        },
      );
});

/// New Releases — curated placeholders merged with DB new-release rows.
final homeNewReleasesProvider =
    Provider<AsyncValue<List<BookCarouselItem>>>((ref) {
  final lang = ref.watch(selectedLanguageFilterProvider);
  final format = ref.watch(bookFormatFilterProvider);
  final curated = _applyHomeFilters(
    CuratedHomeContent.toBooks(CuratedHomeContent.newReleaseBooks),
    lang,
    format,
  );
  return ref.watch(newReleasesRawProvider).when(
        loading: () => AsyncData(_toCarouselItems(
          curated,
          specs: CuratedHomeContent.newReleaseBooks,
        )),
        error: (e, st) => AsyncData(_toCarouselItems(
          curated,
          specs: CuratedHomeContent.newReleaseBooks,
        )),
        data: (db) {
          final merged = CuratedHomeContent.mergeWithDb(
            curated,
            _applyHomeFilters(db, lang, format),
          );
          return AsyncData(_toCarouselItems(
            merged,
            specs: CuratedHomeContent.newReleaseBooks,
          ));
        },
      );
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = (await ref.watch(bookRepositoryProvider).listCategories())
      .getOrThrow();
  return CuratedHomeContent.mergeGenres(db);
});

/// Genre grid rows with curated motif mapping.
final homeGenresProvider = Provider<AsyncValue<List<Category>>>((ref) {
  return ref.watch(categoriesProvider).whenData(CuratedHomeContent.mergeGenres);
});

/// Single book detail — Supabase UUID first, curated id/slug fallback.
final bookDetailProvider =
    FutureProvider.family<Book, String>((ref, id) async {
  final curated = CuratedHomeContent.lookupById(id);
  if (curated != null) return curated.toBook();

  final result = await ref.watch(bookRepositoryProvider).getById(id);
  return result.fold(
    (failure) {
      final fallback = CuratedHomeContent.lookupById(id);
      if (fallback != null) return fallback.toBook();
      throw failure;
    },
    (book) => book,
  );
});

/// Alias kept for existing call sites.
final bookByIdProvider = bookDetailProvider;

/// Books in a category, keyed by category id.
final booksByCategoryProvider =
    FutureProvider.family<List<Book>, String>((ref, categoryId) async {
  return (await ref.watch(bookRepositoryProvider).getByCategory(categoryId))
      .getOrThrow();
});

/// Current search query (debounced/updated by the search page).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results derived from [searchQueryProvider]. Returns an empty list
/// for blank queries without hitting the network.
final searchResultsProvider = FutureProvider<List<Book>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];
  return (await ref.watch(bookRepositoryProvider).search(query)).getOrThrow();
});

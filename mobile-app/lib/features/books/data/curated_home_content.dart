import 'package:akuko/shared/domain/entities/book.dart';
import 'package:akuko/shared/domain/entities/book_delivery_format.dart';
import 'package:akuko/shared/domain/entities/category.dart';

/// Master content categories for Fiction / Nonfiction / Poetry pills.
enum MasterContentCategory {
  fiction,
  nonfiction,
  poetry;

  static MasterContentCategory? fromSlug(String slug) {
    final normalized = slug.toLowerCase();
    return switch (normalized) {
      'fiction' => MasterContentCategory.fiction,
      'nonfiction' || 'non-fiction' => MasterContentCategory.nonfiction,
      'poetry' => MasterContentCategory.poetry,
      _ => null,
    };
  }

  String get label => switch (this) {
        MasterContentCategory.fiction => 'Fiction',
        MasterContentCategory.nonfiction => 'Nonfiction',
        MasterContentCategory.poetry => 'Poetry',
      };

  String get slug => name;
}

/// Static curated home catalogue — explicit titles/authors for maintainability.
/// Merged with Supabase featured/trending/new-release rows when available.
class CuratedHomeContent {
  const CuratedHomeContent._();

  // ── Book of the Month ─────────────────────────────────────────────────────

  static const bookOfTheMonth = CuratedBookSpec(
    id: 'curated-book-of-month',
    title: 'You Made a Fool of Death with Your Beauty',
    author: 'Akwaeke Emezi',
    language: 'en',
    masterCategory: MasterContentCategory.fiction,
    description:
        'A story of love, loss, and transformation — a modern African fantasy.',
    gradientStart: 0xFF8B4513,
    gradientEnd: 0xFF2D5A3D,
    accentIndex: 0,
  );

  // ── Christian Literature (formerly Silent Harbor) ─────────────────────────

  static const christianLiteratureSectionTitle = 'Christian Literature';

  static const christianLiteratureBooks = [
    CuratedBookSpec(
      id: 'curated-silent-harbor',
      title: 'The Silent Harbor',
      author: 'Amara Okonkwo',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      category: 'Christian Literature',
      isChristian: true,
      gradientStart: 0xFF2E4A7A,
      gradientEnd: 0xFF1A1410,
      accentIndex: 1,
      showGiftButton: true,
    ),
    CuratedBookSpec(
      id: 'curated-silent-harbor-companion',
      title: 'Harbor Lights',
      author: 'Amara Okonkwo',
      language: 'en',
      category: 'Christian Literature',
      isChristian: true,
      gradientStart: 0xFF2E4A7A,
      gradientEnd: 0xFF332A22,
      accentIndex: 2,
      showGiftButton: true,
    ),
    CuratedBookSpec(
      id: 'curated-christian-grace',
      title: 'Grace in the Wilderness',
      author: 'Emeka Nwosu',
      language: 'en',
      category: 'Christian Literature',
      isChristian: true,
      gradientStart: 0xFF2D5A3D,
      gradientEnd: 0xFF1A1410,
      accentIndex: 0,
    ),
  ];

  /// @deprecated Use [christianLiteratureSectionTitle].
  static const silentHarborSectionTitle = christianLiteratureSectionTitle;

  /// @deprecated Use [christianLiteratureBooks].
  static const silentHarborBooks = christianLiteratureBooks;

  // ── Bestselling ───────────────────────────────────────────────────────────

  static const bestsellingSectionTitle = 'Bestselling';

  static const bestsellingBooks = [
    CuratedBookSpec(
      id: 'curated-bestseller-1',
      title: 'Things Fall Apart',
      author: 'Chinua Achebe',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      gradientStart: 0xFFC45C26,
      gradientEnd: 0xFF1A1410,
      accentIndex: 0,
    ),
    CuratedBookSpec(
      id: 'curated-bestseller-2',
      title: 'Half of a Yellow Sun',
      author: 'Chimamanda Ngozi Adichie',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      gradientStart: 0xFFC9A227,
      gradientEnd: 0xFF2A221C,
      accentIndex: 1,
    ),
    CuratedBookSpec(
      id: 'curated-bestseller-3',
      title: 'Petals of Blood',
      author: 'Ngũgĩ wa Thiong\'o',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      gradientStart: 0xFF2D5A3D,
      gradientEnd: 0xFF121212,
      accentIndex: 2,
    ),
    CuratedBookSpec(
      id: 'curated-bestseller-4',
      title: 'Americanah',
      author: 'Chimamanda Ngozi Adichie',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      gradientStart: 0xFF2E4A7A,
      gradientEnd: 0xFF332A22,
      accentIndex: 3,
    ),
  ];

  // ── New Releases ──────────────────────────────────────────────────────────

  static const newReleasesSectionTitle = 'New Releases';

  static const newReleaseBooks = [
    CuratedBookSpec(
      id: 'curated-new-1',
      title: 'The Dragonfly Sea',
      author: 'Yvonne Adhiambo Owuor',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      isNewRelease: true,
      gradientStart: 0xFF2D5A3D,
      gradientEnd: 0xFF1A1410,
      accentIndex: 0,
    ),
    CuratedBookSpec(
      id: 'curated-new-2',
      title: 'Freshwater',
      author: 'Akwaeke Emezi',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      isNewRelease: true,
      gradientStart: 0xFFC45C26,
      gradientEnd: 0xFF2A221C,
      accentIndex: 1,
    ),
    CuratedBookSpec(
      id: 'curated-new-3',
      title: 'Stay With Me',
      author: 'Ayọ̀bámi Adébáyọ̀',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      isNewRelease: true,
      gradientStart: 0xFF2E4A7A,
      gradientEnd: 0xFF121212,
      accentIndex: 2,
    ),
    CuratedBookSpec(
      id: 'curated-new-4',
      title: 'Speak No Evil',
      author: 'Uzodinma Iweala',
      language: 'en',
      masterCategory: MasterContentCategory.fiction,
      isNewRelease: true,
      gradientStart: 0xFFC9A227,
      gradientEnd: 0xFF332A22,
      accentIndex: 3,
    ),
    CuratedBookSpec(
      id: 'curated-sweetness-poems',
      title: 'Sweetness: a collection of poems',
      author: 'Jaachịmma Anyatọnwụ',
      language: 'en',
      masterCategory: MasterContentCategory.poetry,
      category: 'Poetry',
      coverAssetPath: 'assets/images/covers/sweetness_poems.png',
      isNewRelease: true,
      gradientStart: 0xFF8B0000,
      gradientEnd: 0xFF1A1410,
      accentIndex: 1,
    ),
  ];

  // ── Browse by Genre ───────────────────────────────────────────────────────

  static const genreSectionTitle = 'Browse by Genre';

  static const curatedGenres = [
    CuratedGenreSpec(
      id: 'curated-genre-history',
      name: 'History',
      slug: 'history',
      motif: GenreMotif.pyramid,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-self-help',
      name: 'Self-Help',
      slug: 'self-help',
      motif: GenreMotif.brain,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-fiction',
      name: 'Fiction',
      slug: 'fiction',
      motif: GenreMotif.book,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-romance',
      name: 'Romance',
      slug: 'romance',
      motif: GenreMotif.heart,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-sci-fi',
      name: 'Sci-Fi',
      slug: 'sci-fi',
      motif: GenreMotif.orbit,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-thriller',
      name: 'Thriller',
      slug: 'thriller',
      motif: GenreMotif.lightning,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-poetry',
      name: 'Poetry',
      slug: 'poetry',
      motif: GenreMotif.quill,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-biography',
      name: 'Biography',
      slug: 'biography',
      motif: GenreMotif.portrait,
    ),
    CuratedGenreSpec(
      id: 'curated-genre-christian',
      name: 'Christian Literature',
      slug: 'christian-literature',
      motif: GenreMotif.cross,
    ),
  ];

  /// Curated books grouped by master Fiction / Nonfiction / Poetry category.
  static List<CuratedBookSpec> booksForMasterCategory(
    MasterContentCategory category,
  ) {
    const all = [
      bookOfTheMonth,
      ...christianLiteratureBooks,
      ...bestsellingBooks,
      ...newReleaseBooks,
    ];
    return all
        .where((b) => b.masterCategory == category)
        .toList();
  }

  /// Converts curated specs to [Book] entities for carousel/grid reuse.
  static List<Book> toBooks(List<CuratedBookSpec> specs) =>
      specs.map((s) => s.toBook()).toList();

  /// Curated first, then DB rows whose titles are not already present.
  static List<Book> mergeWithDb(List<Book> curated, List<Book> db) {
    final seenTitles = curated.map((b) => b.title.toLowerCase()).toSet();
    final extras = db.where((b) => !seenTitles.contains(b.title.toLowerCase()));
    return [...curated, ...extras];
  }

  /// All curated book specs for id/slug lookup.
  static List<CuratedBookSpec> get allBooks => const [
        bookOfTheMonth,
        ...christianLiteratureBooks,
        ...bestsellingBooks,
        ...newReleaseBooks,
      ];

  /// Resolve a curated book by id or slug (e.g. `curated-silent-harbor`).
  static CuratedBookSpec? lookupById(String id) {
    final normalized = id.toLowerCase().trim();
    for (final spec in allBooks) {
      if (spec.id.toLowerCase() == normalized) return spec;
    }
    return null;
  }

  /// Curated genres fill gaps when Supabase categories are sparse.
  static List<Category> mergeGenres(List<Category> db) {
    if (db.length >= curatedGenres.length) return db;
    final seenSlugs = db.map((c) => c.slug.toLowerCase()).toSet();
    final extras = curatedGenres
        .where((g) => !seenSlugs.contains(g.slug.toLowerCase()))
        .map((g) => g.toCategory());
    return [...db, ...extras];
  }
}

/// Lightweight spec for a curated catalogue row.
class CuratedBookSpec {
  const CuratedBookSpec({
    required this.id,
    required this.title,
    required this.author,
    this.language = 'en',
    this.description,
    this.category,
    this.coverAssetPath,
    this.gradientStart = 0xFF2A221C,
    this.gradientEnd = 0xFF1A1410,
    this.accentIndex = 0,
    this.isNewRelease = false,
    this.isTrending = false,
    this.isChristian = false,
    this.showGiftButton = false,
    this.masterCategory = MasterContentCategory.fiction,
    this.deliveryFormat = BookDeliveryFormat.ebook,
  });

  final String id;
  final String title;
  final String author;
  final String language;
  final String? category;
  final String? coverAssetPath;
  final MasterContentCategory masterCategory;
  final String? description;
  final int gradientStart;
  final int gradientEnd;
  final int accentIndex;
  final bool isNewRelease;
  final bool isTrending;
  final bool isChristian;
  final bool showGiftButton;
  final BookDeliveryFormat deliveryFormat;

  Book toBook() => Book(
        id: id,
        title: title,
        author: author,
        description: description,
        language: language,
        isNewRelease: isNewRelease,
        isTrending: isTrending,
        genreName: category,
        isChristian: isChristian,
        deliveryFormat: deliveryFormat,
        coverUrl: coverAssetPath,
      );
}

enum GenreMotif {
  pyramid,
  brain,
  book,
  heart,
  orbit,
  lightning,
  quill,
  portrait,
  cross,
}

class CuratedGenreSpec {
  const CuratedGenreSpec({
    required this.id,
    required this.name,
    required this.slug,
    required this.motif,
  });

  final String id;
  final String name;
  final String slug;
  final GenreMotif motif;

  Category toCategory() => Category(
        id: id,
        name: name,
        slug: slug,
      );
}

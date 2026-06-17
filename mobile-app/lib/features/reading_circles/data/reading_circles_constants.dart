import 'package:akuko/features/reading_circles/domain/entities/reading_circle.dart';

/// Local mock circles keyed by book id prefix. TODO(backend): reading_circles table.
const readingCirclesByBookPrefix = <String, ReadingCircle>{
  'default': ReadingCircle(
    id: 'circle-lagos-noir',
    name: 'Modern Lagos Noir',
    bookId: 'default',
    memberCount: 128,
    description: 'Readers exploring contemporary Nigerian noir fiction.',
  ),
};

/// All circles for the dedicated reading circles page.
const mockReadingCircles = <ReadingCircle>[
  ReadingCircle(
    id: 'circle-lagos-noir',
    name: 'Modern Lagos Noir',
    bookId: 'default',
    memberCount: 128,
    description: 'Readers exploring contemporary Nigerian noir fiction.',
  ),
  ReadingCircle(
    id: 'circle-achebe-classics',
    name: 'Achebe Classics Club',
    bookId: 'curated-bestseller-1',
    memberCount: 256,
    description: 'Monthly discussions on Chinua Achebe and African canon.',
  ),
  ReadingCircle(
    id: 'circle-poetry-nights',
    name: 'Poetry Nights',
    bookId: 'curated-genre-poetry',
    memberCount: 84,
    description: 'Share verses, discover new poets across the continent.',
  ),
  ReadingCircle(
    id: 'circle-faith-readers',
    name: 'Faith & Literature',
    bookId: 'curated-genre-christian',
    memberCount: 167,
    description: 'Christian literature and spiritual reflection together.',
  ),
];

ReadingCircle? circleForBook(String bookId) {
  if (readingCirclesByBookPrefix.containsKey(bookId)) {
    return readingCirclesByBookPrefix[bookId];
  }
  if (bookId.isNotEmpty) {
    return readingCirclesByBookPrefix['default']!.copyWith(bookId: bookId);
  }
  return null;
}

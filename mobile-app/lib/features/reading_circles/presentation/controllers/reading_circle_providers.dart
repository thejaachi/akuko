import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/features/reading_circles/data/reading_circles_constants.dart';
import 'package:akuko/features/reading_circles/domain/entities/reading_circle.dart';

/// All mock circles for the dedicated page. TODO(backend): Supabase query.
final readingCirclesProvider = Provider<List<ReadingCircle>>((ref) {
  return mockReadingCircles;
});

final readingCircleForBookProvider =
    Provider.family<ReadingCircle?, String>((ref, bookId) {
  return circleForBook(bookId);
});

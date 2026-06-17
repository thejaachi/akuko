import 'package:equatable/equatable.dart';

import 'package:akuko/shared/domain/entities/book.dart';

/// A book in the user's library together with their reading progress.
/// Backed by a `reading_progress` row joined to its `books` row.
class LibraryEntry extends Equatable {
  const LibraryEntry({
    required this.book,
    this.location,
    this.progressPercent = 0,
    this.lastReadAt,
  });

  final Book book;
  final String? location;
  final double progressPercent;
  final DateTime? lastReadAt;

  bool get isFinished => progressPercent >= 99.5;

  @override
  List<Object?> get props => [book, location, progressPercent, lastReadAt];
}

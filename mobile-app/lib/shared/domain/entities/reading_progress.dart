import 'package:equatable/equatable.dart';

/// Mirrors the `reading_progress` table (unique: user_id + book_id).
///
/// [location] is an opaque locator: an EPUB CFI string or a PDF page index.
class ReadingProgress extends Equatable {
  const ReadingProgress({
    this.id,
    required this.userId,
    required this.bookId,
    this.location,
    this.progressPercent = 0,
    this.lastReadAt,
  });

  final String? id;
  final String userId;
  final String bookId;
  final String? location;
  final double progressPercent;
  final DateTime? lastReadAt;

  ReadingProgress copyWith({
    String? location,
    double? progressPercent,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
      id: id,
      userId: userId,
      bookId: bookId,
      location: location ?? this.location,
      progressPercent: progressPercent ?? this.progressPercent,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, bookId, location, progressPercent, lastReadAt];
}

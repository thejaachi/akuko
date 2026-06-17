import 'package:akuko/shared/domain/entities/reading_progress.dart';

/// Maps `reading_progress` rows to/from the [ReadingProgress] entity.
class ReadingProgressModel {
  const ReadingProgressModel._();

  static ReadingProgress fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      location: json['location'] as String?,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
      lastReadAt: json['last_read_at'] == null
          ? null
          : DateTime.tryParse(json['last_read_at'].toString()),
    );
  }

  /// Payload for an upsert (excludes server-managed `id`).
  static Map<String, dynamic> toUpsertJson(ReadingProgress progress) {
    return {
      'user_id': progress.userId,
      'book_id': progress.bookId,
      'location': progress.location,
      'progress_percent': progress.progressPercent,
      'last_read_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

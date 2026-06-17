import 'package:akuko/shared/domain/entities/bookmark.dart';

/// Maps `bookmarks` rows to/from the [Bookmark] entity.
class BookmarkModel {
  const BookmarkModel._();

  static Bookmark fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      location: json['location'] as String? ?? '',
      label: json['label'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static Map<String, dynamic> toInsertJson(Bookmark bookmark) {
    return {
      'user_id': bookmark.userId,
      'book_id': bookmark.bookId,
      'location': bookmark.location,
      'label': bookmark.label,
    };
  }
}

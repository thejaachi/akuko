import 'package:equatable/equatable.dart';

/// Mirrors the `bookmarks` table in the canonical spec.
class Bookmark extends Equatable {
  const Bookmark({
    this.id,
    required this.userId,
    required this.bookId,
    required this.location,
    this.label,
    this.createdAt,
  });

  final String? id;
  final String userId;
  final String bookId;
  final String location;
  final String? label;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, userId, bookId, location, label, createdAt];
}

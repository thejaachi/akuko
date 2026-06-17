import 'package:equatable/equatable.dart';

class BookRequest extends Equatable {
  const BookRequest({
    required this.id,
    required this.userId,
    required this.title,
    this.author,
    this.genre,
    this.notes,
    this.status = 'pending',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? author;
  final String? genre;
  final String? notes;
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, userId, title, author, genre, notes, status, createdAt];
}

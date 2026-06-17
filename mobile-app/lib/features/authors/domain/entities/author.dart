import 'package:equatable/equatable.dart';

/// Mirrors `public.authors` table.
class Author extends Equatable {
  const Author({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
    this.bookCount = 0,
  });

  final String id;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final int bookCount;

  @override
  List<Object?> get props => [id, name, bio, avatarUrl, bookCount];
}

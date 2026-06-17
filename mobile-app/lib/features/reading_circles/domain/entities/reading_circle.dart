import 'package:equatable/equatable.dart';

/// A community reading circle — stub until `reading_circles` table ships.
class ReadingCircle extends Equatable {
  const ReadingCircle({
    required this.id,
    required this.name,
    required this.bookId,
    this.memberCount = 0,
    this.description,
  });

  final String id;
  final String name;
  final String bookId;
  final int memberCount;
  final String? description;

  ReadingCircle copyWith({
    String? id,
    String? name,
    String? bookId,
    int? memberCount,
    String? description,
  }) {
    return ReadingCircle(
      id: id ?? this.id,
      name: name ?? this.name,
      bookId: bookId ?? this.bookId,
      memberCount: memberCount ?? this.memberCount,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, name, bookId, memberCount, description];
}

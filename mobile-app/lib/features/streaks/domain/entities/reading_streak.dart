import 'package:equatable/equatable.dart';

/// Mirrors `reading_streaks` (1:1 per user).
class ReadingStreak extends Equatable {
  const ReadingStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
  });

  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  static const empty = ReadingStreak(userId: '');

  @override
  List<Object?> get props => [userId, currentStreak, longestStreak, lastActiveDate];
}

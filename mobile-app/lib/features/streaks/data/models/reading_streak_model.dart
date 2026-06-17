import 'package:akuko/features/streaks/domain/entities/reading_streak.dart';

class ReadingStreakModel {
  const ReadingStreakModel._();

  static ReadingStreak fromJson(Map<String, dynamic> json) {
    final lastActive = json['last_active_date'] as String?;
    return ReadingStreak(
      userId: json['user_id'] as String,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      lastActiveDate:
          lastActive != null ? DateTime.tryParse(lastActive) : null,
    );
  }
}

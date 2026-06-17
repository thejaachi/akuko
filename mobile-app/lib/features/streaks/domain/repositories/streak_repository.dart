import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/streaks/domain/entities/reading_streak.dart';

abstract interface class StreakRepository {
  Future<Result<ReadingStreak>> getStreak(String userId);
}

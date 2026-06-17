import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/streaks/data/datasources/streak_remote_datasource.dart';
import 'package:akuko/features/streaks/data/models/reading_streak_model.dart';
import 'package:akuko/features/streaks/domain/entities/reading_streak.dart';
import 'package:akuko/features/streaks/domain/repositories/streak_repository.dart';

class SupabaseStreakRepository implements StreakRepository {
  SupabaseStreakRepository(this._remote);

  final StreakRemoteDataSource _remote;

  Failure _mapError(Object error) => switch (error) {
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Failed to load reading streak', error),
      };

  @override
  Future<Result<ReadingStreak>> getStreak(String userId) {
    return guardAsync(() async {
      final row = await _remote.fetchStreak(userId);
      if (row == null) return ReadingStreak(userId: userId);
      return ReadingStreakModel.fromJson(row);
    }, onError: (e, _) => _mapError(e));
  }
}

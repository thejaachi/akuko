import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/config/shared_preferences_provider.dart';
import 'package:akuko/core/constants/app_constants.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/library/presentation/controllers/library_providers.dart';
import 'package:akuko/features/streaks/data/datasources/streak_remote_datasource.dart';
import 'package:akuko/features/streaks/data/repositories/supabase_streak_repository.dart';
import 'package:akuko/features/streaks/domain/entities/journey_reward.dart';
import 'package:akuko/features/streaks/domain/entities/reading_streak.dart';
import 'package:akuko/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:akuko/features/streaks/domain/repositories/streak_repository.dart';

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>((ref) {
  return StreakRemoteDataSource();
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return SupabaseStreakRepository(ref.watch(streakRemoteDataSourceProvider));
});

final readingStreakProvider = FutureProvider<ReadingStreak>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return ReadingStreak.empty;
  return (await ref.watch(streakRepositoryProvider).getStreak(userId))
      .getOrThrow();
});

/// Audio listening streak — local stub until `reading_streaks` gains an
/// `audio_streak` column. TODO(backend): extend schema + trigger.
final audioStreakProvider = Provider<int>((ref) {
  return ref.watch(sharedPreferencesProvider).getInt(
            AppConstants.prefsAudioStreak,
          ) ??
      0;
});

const _levelTitles = [
  'Curious Reader',
  'Page Turner',
  'Story Explorer',
  'Storyteller',
  'Literary Sage',
  'Akuko Legend',
];

String _titleForLevel(int level) =>
    _levelTitles[(level - 1).clamp(0, _levelTitles.length - 1)];

/// Reward level derived from completed books + reading streak.
final journeyRewardProvider = Provider<AsyncValue<JourneyReward>>((ref) {
  final streakAsync = ref.watch(readingStreakProvider);
  final libraryAsync = ref.watch(continueReadingProvider);
  final audioStreak = ref.watch(audioStreakProvider);

  if (streakAsync.isLoading || libraryAsync.isLoading) {
    return const AsyncLoading();
  }
  if (streakAsync.hasError) {
    return AsyncError(streakAsync.error!, streakAsync.stackTrace!);
  }

  final streak = streakAsync.value ?? ReadingStreak.empty;
  final entries = libraryAsync.value ?? const [];
  final completed = entries.where((e) => e.isFinished).length;
  // TODO(audio): replace stub with TTS/listening progress when available.
  final listened = (completed * 0.3).floor();

  final xp = completed * 100 + streak.currentStreak * 25 + listened * 50;
  final level = (xp ~/ 500).clamp(1, 99) + 1;
  final xpInLevel = xp % 500;
  final progress = xpInLevel / 500;

  return AsyncData(
    JourneyReward(
      level: level,
      levelTitle: _titleForLevel(level),
      readingStreakDays: streak.currentStreak,
      audioStreakDays: audioStreak,
      booksCompleted: completed,
      booksListened: listened,
      progressToNextLevel: progress,
    ),
  );
});

/// Watches journey level-ups and inserts milestone notifications when possible.
final journeyMilestoneWatcherProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<JourneyReward>>(journeyRewardProvider, (_, next) {
    next.whenData((reward) async {
      final prefs = ref.read(sharedPreferencesProvider);
      final lastLevel = prefs.getInt(AppConstants.prefsJourneyLevel) ?? 0;
      if (reward.level <= lastLevel) return;

      await prefs.setInt(AppConstants.prefsJourneyLevel, reward.level);

      final userId = ref.read(authRepositoryProvider).currentUser?.id;
      if (userId == null) return;

      await ref.read(notificationRemoteDataSourceProvider).insertMilestone(
            userId: userId,
            title: 'Level ${reward.level} reached!',
            body: 'You are now a ${reward.levelTitle}. Keep reading!',
          );
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    });
  });
});

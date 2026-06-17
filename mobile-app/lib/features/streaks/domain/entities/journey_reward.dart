import 'package:equatable/equatable.dart';

/// Aggregated journey stats for Home / Library reward UI.
class JourneyReward extends Equatable {
  const JourneyReward({
    required this.level,
    required this.levelTitle,
    required this.readingStreakDays,
    required this.audioStreakDays,
    required this.booksCompleted,
    required this.booksListened,
    required this.progressToNextLevel,
  });

  final int level;
  final String levelTitle;
  final int readingStreakDays;
  final int audioStreakDays;
  final int booksCompleted;
  final int booksListened;
  final double progressToNextLevel;

  static const initial = JourneyReward(
    level: 1,
    levelTitle: 'Curious Reader',
    readingStreakDays: 0,
    audioStreakDays: 0,
    booksCompleted: 0,
    booksListened: 0,
    progressToNextLevel: 0,
  );

  @override
  List<Object?> get props => [
        level,
        levelTitle,
        readingStreakDays,
        audioStreakDays,
        booksCompleted,
        booksListened,
        progressToNextLevel,
      ];
}

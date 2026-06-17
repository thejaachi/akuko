import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/reading_circles/domain/entities/reading_circle.dart';
import 'package:akuko/features/reading_circles/presentation/controllers/reading_circle_providers.dart';

class ReadingCircleSheet extends ConsumerWidget {
  const ReadingCircleSheet({this.bookId, super.key});

  final String? bookId;

  static Future<void> show(BuildContext context, {String? bookId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.warmSurface,
      builder: (_) => ReadingCircleSheet(bookId: bookId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(readingCirclesProvider);
    final highlighted = bookId != null
        ? ref.watch(readingCircleForBookProvider(bookId!))
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Circles',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textWarm,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Join a circle to read together and share notes.',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: circles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = circles[i];
                  final isMatch = highlighted?.id == c.id;
                  return _CircleTile(circle: c, highlighted: isMatch);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleTile extends StatelessWidget {
  const _CircleTile({required this.circle, required this.highlighted});

  final ReadingCircle circle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: highlighted
          ? AppColors.forestGreen.withOpacity(0.25)
          : AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted ? AppColors.forestGreen : AppColors.cardBorder,
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.cobaltBlue.withOpacity(0.4),
        child: Text(
          circle.name.isNotEmpty ? circle.name[0] : '?',
          style: const TextStyle(color: AppColors.textWarm),
        ),
      ),
      title: Text(
        circle.name,
        style: TextStyle(
          color: AppColors.textWarm,
          fontWeight: highlighted ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(
        '${circle.memberCount} members',
        style: const TextStyle(color: AppColors.textMuted),
      ),
      trailing: FilledButton(
        onPressed: () {
          Navigator.pop(context);
          context.showSnack('Joined ${circle.name}! (stub)');
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          minimumSize: const Size(72, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Join'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/guards/subscription_guard.dart';
import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/african_pattern_painter.dart';
import 'package:akuko/features/reading_circles/domain/entities/reading_circle.dart';
import 'package:akuko/features/reading_circles/presentation/controllers/reading_circle_providers.dart';

class ReadingCirclesPage extends ConsumerWidget {
  const ReadingCirclesPage({super.key});

  void _onCreateCircle(BuildContext context, WidgetRef ref) {
    final guard = ref.read(subscriptionGuardProvider);
    if (!guard.canCreateReadingCircle()) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text(
            'Premium feature',
            style: TextStyle(color: AppColors.textWarm),
          ),
          content: const Text(
            'Creating reading circles is available on Premium and '
            'All-Access plans. Upgrade to start your own circle and '
            'post up to 500 characters.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.subscription);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.burntSienna,
              ),
              child: const Text('View plans'),
            ),
          ],
        ),
      );
      return;
    }
    context.showSnack('Create circle flow coming soon');
  }

  void _openCircle(BuildContext context, ReadingCircle circle) {
    context.push(AppRoutes.circleDetailPath(circle.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(readingCirclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Circles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreateCircle(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Create Circle'),
        backgroundColor: AppColors.burntSienna,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        cacheExtent: 400,
        itemCount: circles.length,
        itemBuilder: (_, i) => RepaintBoundary(
          child: _CircleCard(
            circle: circles[i],
            onJoin: () => _openCircle(context, circles[i]),
          ),
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.onJoin});

  final ReadingCircle circle;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJoin,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanPatternPainter(
                  tier: PatternTier.standard,
                  color: AppColors.warmGold,
                  opacity: 0.08,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.cobaltBlue,
                          AppColors.charcoal,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.textWarm,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          circle.name,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWarm,
                          ),
                        ),
                        if (circle.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            circle.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${circle.memberCount} members',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: AppColors.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Open',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: AppColors.warmGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: onJoin,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                    ),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

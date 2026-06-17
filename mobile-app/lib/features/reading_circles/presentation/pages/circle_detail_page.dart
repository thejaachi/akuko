import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/guards/subscription_guard.dart';
import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/african_pattern_painter.dart';
import 'package:akuko/features/reading_circles/data/reading_circles_constants.dart';
import 'package:akuko/features/reading_circles/data/repositories/circle_social_repository.dart';
import 'package:akuko/features/reading_circles/presentation/controllers/circle_social_providers.dart';
import 'package:akuko/features/reading_circles/presentation/widgets/circle_post_card.dart';

/// Feed of posts for a single reading circle.
class CircleDetailPage extends ConsumerStatefulWidget {
  const CircleDetailPage({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<CircleDetailPage> createState() => _CircleDetailPageState();
}

class _CircleDetailPageState extends ConsumerState<CircleDetailPage> {
  final _postController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  ReadingCircleInfo? get _circle {
    for (final c in mockReadingCircles) {
      if (c.id == widget.circleId) {
        return ReadingCircleInfo(
          id: c.id,
          name: c.name,
          description: c.description,
          memberCount: c.memberCount,
        );
      }
    }
    return ReadingCircleInfo(
      id: widget.circleId,
      name: 'Reading Circle',
      memberCount: 0,
    );
  }

  Future<void> _createPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    final guard = ref.read(subscriptionGuardProvider);
    final limit = guard.circlePostCharLimit();
    if (text.length > limit) {
      context.showSnack(
        guard.isPremium()
            ? 'Posts are limited to $limit characters'
            : 'Free posts are limited to $limit characters. Upgrade for longer posts.',
      );
      if (!guard.isPremium()) {
        context.push(AppRoutes.subscription);
      }
      return;
    }

    setState(() => _posting = true);
    try {
      await ref.read(circleSocialRepositoryProvider).createPost(
            circleId: widget.circleId,
            content: text,
          );
      _postController.clear();
      ref.invalidate(circlePostsProvider(widget.circleId));
      if (mounted) context.showSnack('Posted!');
    } catch (e) {
      if (mounted) {
        context.showSnack(
          'Could not post — join the circle first or try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final circle = _circle!;
    final posts = ref.watch(circlePostsProvider(widget.circleId));
    final guard = ref.watch(subscriptionGuardProvider);
    final charLimit = guard.circlePostCharLimit();

    return Scaffold(
      appBar: AppBar(
        title: Text(circle.name),
        backgroundColor: AppColors.earthBackground,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AfricanPatternPainter(
                tier: PatternTier.standard,
                color: AppColors.burntSienna,
                opacity: 0.04,
              ),
            ),
          ),
          Column(
            children: [
              if (circle.description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    circle.description!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 16,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${circle.memberCount} members',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$charLimit char limit',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        maxLength: charLimit,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts…',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textWarm),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _posting ? null : _createPost,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.burntSienna,
                      ),
                      child: _posting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: posts.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.forum_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No posts yet — be the first to share!',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'Start the conversation',
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      cacheExtent: 500,
                      itemCount: items.length,
                      itemBuilder: (_, i) => RepaintBoundary(
                        child: CirclePostCard(
                          post: items[i],
                          circleId: widget.circleId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lightweight circle metadata for the detail header.
class ReadingCircleInfo {
  const ReadingCircleInfo({
    required this.id,
    required this.name,
    this.description,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final int memberCount;
}

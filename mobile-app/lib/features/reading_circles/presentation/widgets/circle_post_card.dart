import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akuko/core/guards/subscription_guard.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/reading_circles/domain/entities/circle_post.dart';
import 'package:akuko/features/reading_circles/presentation/controllers/circle_social_providers.dart';

/// Post card with like toggle, comment thread, and avatar follow action.
class CirclePostCard extends ConsumerStatefulWidget {
  const CirclePostCard({
    required this.post,
    required this.circleId,
    super.key,
  });

  final CirclePost post;
  final String circleId;

  @override
  ConsumerState<CirclePostCard> createState() => _CirclePostCardState();
}

class _CirclePostCardState extends ConsumerState<CirclePostCard> {
  bool _showComments = false;
  final _commentController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    setState(() => _busy = true);
    try {
      await likePost(
        ref,
        circleId: widget.circleId,
        postId: widget.post.id,
        currentlyLiked: widget.post.likedByMe,
      );
    } catch (e) {
      if (mounted) context.showSnack('Could not update like');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final guard = ref.read(subscriptionGuardProvider);
    final limit = guard.circlePostCharLimit();
    if (text.length > limit) {
      context.showSnack('Comments are limited to $limit characters');
      return;
    }

    setState(() => _busy = true);
    try {
      await addComment(
        ref,
        circleId: widget.circleId,
        postId: widget.post.id,
        content: text,
      );
      _commentController.clear();
      setState(() => _showComments = true);
    } catch (e) {
      if (mounted) context.showSnack('Could not post comment');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final followAsync = ref.watch(followUserProvider(post.userId));
    final isFollowing = followAsync.valueOrNull ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.burntSienna.withOpacity(0.3),
                  backgroundImage: post.authorAvatarUrl != null
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? Text(
                          (post.authorName ?? 'R').characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textWarm,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName ?? 'Reader',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: AppColors.textWarm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFollowing)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Member',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textWarm,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: _busy ? null : _toggleLike,
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: post.likedByMe
                        ? AppColors.burntSienna
                        : AppColors.textMuted,
                    size: 20,
                  ),
                ),
                Text(
                  '${post.likeCount}',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () =>
                      setState(() => _showComments = !_showComments),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
                Text(
                  '${post.commentCount}',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            if (_showComments) ...[
              const Divider(color: AppColors.cardBorder),
              _CommentsSection(postId: post.id),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: ref
                          .read(subscriptionGuardProvider)
                          .circlePostCharLimit(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.warmSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        counterStyle: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textWarm),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _submitComment,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.burntSienna,
                    ),
                    icon: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CommentsSection extends ConsumerWidget {
  const _CommentsSection({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(circlePostCommentsProvider(postId));

    return comments.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Text(
        'Could not load comments',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No comments yet — start the conversation.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length.clamp(0, 20),
          itemBuilder: (_, i) {
            final c = items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.textWarm,
                        ),
                        children: [
                          TextSpan(
                            text: '${c.authorName ?? 'Reader'}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.warmGold,
                            ),
                          ),
                          TextSpan(text: c.content),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

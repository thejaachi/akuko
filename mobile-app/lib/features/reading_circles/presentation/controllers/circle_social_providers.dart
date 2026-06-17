import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/features/reading_circles/data/repositories/circle_social_repository.dart';
import 'package:akuko/features/reading_circles/domain/entities/circle_post.dart';

/// Posts for a reading circle feed.
final circlePostsProvider =
    FutureProvider.family<List<CirclePost>, String>((ref, circleId) async {
  return ref.watch(circleSocialRepositoryProvider).fetchPosts(circleId);
});

/// Comments for a single post.
final circlePostCommentsProvider =
    FutureProvider.family<List<CirclePostComment>, String>((ref, postId) async {
  return ref.watch(circleSocialRepositoryProvider).fetchComments(postId);
});

/// Whether the current user follows [targetUserId].
final followUserProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  return ref.watch(circleSocialRepositoryProvider).isFollowing(targetUserId);
});

/// Toggle like on a post.
Future<void> likePost(
  WidgetRef ref, {
  required String circleId,
  required String postId,
  required bool currentlyLiked,
}) async {
  await ref.read(circleSocialRepositoryProvider).toggleLike(
        postId,
        currentlyLiked: currentlyLiked,
      );
  ref.invalidate(circlePostsProvider(circleId));
}

/// Add a comment to a post.
Future<void> addComment(
  WidgetRef ref, {
  required String circleId,
  required String postId,
  required String content,
}) async {
  await ref.read(circleSocialRepositoryProvider).addComment(
        postId: postId,
        content: content,
      );
  ref
    ..invalidate(circlePostsProvider(circleId))
    ..invalidate(circlePostCommentsProvider(postId));
}

/// Follow or unfollow a user.
Future<void> toggleFollowUser(
  WidgetRef ref, {
  required String targetUserId,
  required bool currentlyFollowing,
}) async {
  final repo = ref.read(circleSocialRepositoryProvider);
  if (currentlyFollowing) {
    await repo.unfollowUser(targetUserId);
  } else {
    await repo.followUser(targetUserId);
  }
  ref.invalidate(followUserProvider(targetUserId));
}

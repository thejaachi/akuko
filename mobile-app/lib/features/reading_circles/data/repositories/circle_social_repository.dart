import 'package:akuko/features/reading_circles/domain/entities/circle_post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final circleSocialRepositoryProvider = Provider<CircleSocialRepository>((ref) {
  return CircleSocialRepository();
});

/// Stub social feed — reading circles API not in WordPress plugin yet.
class CircleSocialRepository {
  Future<List<CirclePost>> fetchPosts(String circleId) async => const [];

  Future<List<CirclePostComment>> fetchComments(String postId) async =>
      const [];

  Future<CirclePost> createPost({
    required String circleId,
    required String content,
  }) async {
    throw StateError('Reading circles API not available yet');
  }

  Future<void> toggleLike(String postId, {required bool currentlyLiked}) async {}

  Future<CirclePostComment> addComment({
    required String postId,
    required String content,
  }) async {
    throw StateError('Reading circles API not available yet');
  }

  Future<bool> isFollowing(String targetUserId) async => false;

  Future<void> followUser(String targetUserId) async {}

  Future<void> unfollowUser(String targetUserId) async {}
}

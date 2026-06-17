import 'package:equatable/equatable.dart';

/// A post in a reading circle feed.
class CirclePost extends Equatable {
  const CirclePost({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String circleId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  CirclePost copyWith({
    String? id,
    String? circleId,
    String? userId,
    String? content,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatarUrl,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return CirclePost(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [
        id,
        circleId,
        userId,
        content,
        createdAt,
        authorName,
        authorAvatarUrl,
        likeCount,
        commentCount,
        likedByMe,
      ];
}

/// A comment on a circle post.
class CirclePostComment extends Equatable {
  const CirclePostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;

  @override
  List<Object?> get props =>
      [id, postId, userId, content, createdAt, authorName];
}

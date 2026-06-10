class Comment {
  final String id;
  final String postId;
  final String nickname;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.nickname,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        nickname: (json['nickname'] as String?) ?? '익명',
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${createdAt.month}.${createdAt.day}';
  }
}

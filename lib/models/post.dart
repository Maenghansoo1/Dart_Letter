class Post {
  final String id;
  final String? corpCode;
  final String? corpName;
  final String postType; // 'stock' | 'info'
  final String nickname;
  final String title;
  final String content;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  const Post({
    required this.id,
    this.corpCode,
    this.corpName,
    required this.postType,
    required this.nickname,
    required this.title,
    required this.content,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        corpCode: json['corp_code'] as String?,
        corpName: json['corp_name'] as String?,
        postType: (json['post_type'] as String?) ?? 'stock',
        nickname: (json['nickname'] as String?) ?? '익명',
        title: json['title'] as String,
        content: json['content'] as String,
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
        commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Post copyWith({int? likesCount, int? commentsCount}) => Post(
        id: id,
        corpCode: corpCode,
        corpName: corpName,
        postType: postType,
        nickname: nickname,
        title: title,
        content: content,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        createdAt: createdAt,
      );

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.month}.${createdAt.day}';
  }
}

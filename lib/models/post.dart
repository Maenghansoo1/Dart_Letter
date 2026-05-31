class Post {
  final String id;
  final String corpCode;
  final String corpName;
  final String title;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  const Post({
    required this.id,
    required this.corpCode,
    required this.corpName,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        corpCode: json['corp_code'] as String,
        corpName: json['corp_name'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        authorId: json['author_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        likeCount: json['like_count'] as int? ?? 0,
        commentCount: json['comment_count'] as int? ?? 0,
      );

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${createdAt.month}.${createdAt.day}';
  }
}

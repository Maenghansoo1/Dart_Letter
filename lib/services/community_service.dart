import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../models/post.dart';
import 'api_service.dart';

class CommunityService {
  Future<({List<Post> items, int total})> getPosts({
    String? feed,
    String? corpCode,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (feed != null) params['feed'] = feed;
    if (corpCode != null) params['corp_code'] = corpCode;
    final data = await ApiService.instance.get('/community/posts', queryParameters: params);
    final json = data as Map<String, dynamic>;
    final items = (json['items'] as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, total: (json['total'] as num?)?.toInt() ?? 0);
  }

  Future<Post> getPost(String postId) async {
    final data = await ApiService.instance.get('/community/posts/$postId');
    return Post.fromJson(data as Map<String, dynamic>);
  }

  Future<Post> createPost({
    String? corpCode,
    String? corpName,
    required String nickname,
    required String title,
    required String content,
  }) async {
    final data = await ApiService.instance.post('/community/posts', data: {
      'corp_code': corpCode,
      'corp_name': corpName,
      'nickname': nickname,
      'title': title,
      'content': content,
    });
    return Post.fromJson(data as Map<String, dynamic>);
  }

  Future<int> likePost(String postId) async {
    final data = await ApiService.instance.post('/community/posts/$postId/like');
    return (data as Map<String, dynamic>)['likes_count'] as int;
  }

  Future<List<Comment>> getComments(String postId) async {
    final data = await ApiService.instance.get('/community/posts/$postId/comments');
    return (data as List)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> createComment(
      String postId, {required String nickname, required String content}) async {
    final data = await ApiService.instance
        .post('/community/posts/$postId/comments', data: {'nickname': nickname, 'content': content});
    return Comment.fromJson(data as Map<String, dynamic>);
  }
}

final communityServiceProvider = Provider((_) => CommunityService());

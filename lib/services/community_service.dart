import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import 'api_service.dart';

class CommunityService {
  Future<List<Post>> getRecentPosts() async {
    final data = await ApiService.instance.get('/community/posts');
    return (data as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Post>> getPostsByCompany(String corpCode) async {
    final data = await ApiService.instance.get('/community/$corpCode/posts');
    return (data as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPost({
    required String corpCode,
    required String title,
    required String content,
  }) async {
    await ApiService.instance.post('/community/posts', data: {
      'corp_code': corpCode,
      'title': title,
      'content': content,
    });
  }
}

final communityServiceProvider = Provider((_) => CommunityService());

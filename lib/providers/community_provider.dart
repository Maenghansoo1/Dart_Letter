import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/community_service.dart';

final recentPostsProvider = FutureProvider<List<Post>>((ref) {
  return ref.watch(communityServiceProvider).getRecentPosts();
});

final companyPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, corpCode) {
  return ref.watch(communityServiceProvider).getPostsByCompany(corpCode);
});

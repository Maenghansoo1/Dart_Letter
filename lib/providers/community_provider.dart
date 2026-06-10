import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/community_service.dart';

// 세션 중 좋아요한 postId 집합 (앱 내 중복 방지)
final likedPostsProvider = StateProvider<Set<String>>((_) => {});

// 댓글 목록
final commentsProvider = FutureProvider.autoDispose.family<List<Comment>, String>((ref, postId) {
  return ref.watch(communityServiceProvider).getComments(postId);
});

// 단일 게시글
final postDetailProvider = FutureProvider.autoDispose.family<Post, String>((ref, postId) {
  return ref.watch(communityServiceProvider).getPost(postId);
});

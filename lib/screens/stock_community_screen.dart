import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../services/community_service.dart';
import '../widgets/error_view.dart';
import 'post_write_screen.dart';

class StockCommunityScreen extends StatefulWidget {
  const StockCommunityScreen({
    super.key,
    required this.corpCode,
    required this.corpName,
  });

  final String corpCode;
  final String corpName;

  @override
  State<StockCommunityScreen> createState() => _StockCommunityScreenState();
}

class _StockCommunityScreenState extends State<StockCommunityScreen> {
  final _scroll = ScrollController();
  final _posts = <Post>[];
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _fetchId = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _posts.length < _total) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    final int id;
    if (reset) {
      id = ++_fetchId;
      setState(() {
        _loading = true;
        _error = null;
        _posts.clear();
        _page = 1;
        _total = 0;
      });
    } else {
      if (_loadingMore) return;
      id = _fetchId;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await CommunityService().getPosts(
        corpCode: widget.corpCode,
        page: _page,
        limit: 20,
      );
      if (!mounted || id != _fetchId) return;
      setState(() {
        _posts.addAll(result.items);
        _total = result.total;
        _page++;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || id != _fetchId) return;
      setState(() {
        _error = '게시글을 불러오지 못했습니다';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _openWrite() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostWriteScreen(
          corpCode: widget.corpCode,
          corpName: widget.corpName,
        ),
      ),
    ).then((_) => _load(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.corpName} 커뮤니티'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWrite,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('글쓰기', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, _) => _PostSkeleton(),
      );
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _load(reset: true));
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('${widget.corpName}에 대한 첫 글을 작성해보세요',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        itemCount: _posts.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _StockPostCard(post: _posts[i]);
        },
      ),
    );
  }
}

class _StockPostCard extends ConsumerWidget {
  const _StockPostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedPostsProvider).contains(post.id);
    return InkWell(
      onTap: () => context.push('/community/post/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(post.nickname,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const Spacer(),
                Text(post.relativeTime,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 6),
            Text(post.title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(post.content,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.thumb_up_outlined,
                    size: 14,
                    color: liked ? AppColors.primary : AppColors.textHint),
                const SizedBox(width: 3),
                Text('${post.likesCount}',
                    style: TextStyle(
                        fontSize: 12,
                        color: liked ? AppColors.primary : AppColors.textHint)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 3),
                Text('${post.commentsCount}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  Widget _box(double width, double height) => Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(200, 16),
          const SizedBox(height: 6),
          _box(double.infinity, 14),
          const SizedBox(height: 8),
          _box(60, 12),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// 飞行社区(小紫书) —— 双列瀑布流 + 无限加载 + 回到顶部
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  /// 供首页复用的帖子卡片
  static Widget postCard(CommunityPost post) => _PostCard(post: post);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtl = ScrollController();
  final _posts = <CommunityPost>[];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _showBackTop = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
    _loadMore(refresh: true);
  }

  @override
  void dispose() {
    _scrollCtl.removeListener(_onScroll);
    _scrollCtl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollCtl.offset > 600;
    if (show != _showBackTop) setState(() => _showBackTop = show);
    if (_scrollCtl.position.pixels >=
            _scrollCtl.position.maxScrollExtent - 300 &&
        _hasMore &&
        !_loading) {
      _loadMore();
    }
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    final page = refresh ? 1 : _page + 1;
    final (posts, hasMore) = await Api.community(page: page, size: 10);
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _posts
          ..clear()
          ..addAll(posts);
      } else {
        _posts.addAll(posts);
      }
      _page = page;
      _hasMore = hasMore;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        RefreshIndicator(
          color: AppTheme.accentCyan,
          backgroundColor: AppTheme.bgCard,
          onRefresh: () => _loadMore(refresh: true),
          child: CustomScrollView(
            controller: _scrollCtl,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PostCard(post: _posts[i]),
                    childCount: _posts.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentCyan),
                          )
                        : Text(
                            _hasMore ? '上滑加载更多' : '— 已经到底啦 —',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
        if (_showBackTop) _buildBackTop(),
      ],
    );
  }

  Widget _buildBackTop() {
    return Positioned(
      right: 16,
      bottom: 24,
      child: GestureDetector(
        onTap: () => _scrollCtl.animateTo(0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic),
        child: GlassContainer(
          borderRadius: 100,
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: const Icon(Icons.arrow_upward_rounded,
              size: 20, color: AppTheme.accentCyan),
        ),
      ),
    );
  }
}

/// 帖子卡片 —— 有封面显示大图，无封面显示纯文字卡
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final hasCover = post.cover.isNotEmpty;
    return GlassContainer(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCover)
            _CoverImage(url: post.cover)
          else if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  post.displayTitle,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppTheme.accentCyan, AppTheme.accentBlue]),
                  ),
                  child: Text(
                    post.author.isNotEmpty ? post.author[0] : '飞',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(post.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ),
                const Icon(Icons.favorite_border_rounded,
                    size: 14, color: AppTheme.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 封面图：渐变占位 + 加载淡入
class _CoverImage extends StatefulWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F6F8), Color(0xFFE9ECF1)],
              ),
            ),
          ),
          if (!_failed)
            Image.network(
              widget.url,
              fit: BoxFit.cover,
              frameBuilder: (_, child, frame, __) => AnimatedOpacity(
                opacity: frame != null ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: child,
              ),
              errorBuilder: (_, __, ___) {
                if (!_failed) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _failed = true);
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          if (_failed)
            const Center(
              child: Icon(Icons.image_not_supported_outlined,
                  size: 28, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }
}

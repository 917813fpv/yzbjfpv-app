import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/app_nav.dart';
import '../core/config.dart';
import '../core/models.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import 'community_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // 轮播
  final _carouselCtl = PageController(viewportFraction: 1.0);
  List<CarouselItem> _carousel = [];
  Timer? _carouselTimer;
  int _carouselIndex = 0;

  // 资讯
  List<NewsItem> _news = [];
  final Set<String> _knownNewsIds = {};
  int _freshNewsCount = 0;
  Timer? _newsTimer;

  // 赛事
  List<Race> _races = [];
  Timer? _raceTimer;

  // 合作伙伴
  List<Partner> _partners = [];
  final _partnerCtl = ScrollController(); // marquee自动滚动
  Timer? _marqueeTimer;

  // 社区预览(无限加载: 每批24条)
  List<CommunityPost> _community = [];
  int _communityPage = 1;
  bool _communityEnded = false;
  bool _communityLoading = false;

  // UI状态
  final _scrollCtl = ScrollController();
  bool _showBackTop = false;
  bool _bubbleShown = false;
  DateTime _browseStart = DateTime.now();
  bool _refreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtl.addListener(_onScroll);
    _loadAll();
    _startTimers();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _newsTimer?.cancel();
    _raceTimer?.cancel();
    _marqueeTimer?.cancel();
    _scrollCtl.removeListener(_onScroll);
    _scrollCtl.dispose();
    _carouselCtl.dispose();
    _partnerCtl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 前台切回自动刷新
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAll();
    }
  }

  void _onScroll() {
    final show = _scrollCtl.offset > MediaQuery.of(context).size.height;
    if (show != _showBackTop) setState(() => _showBackTop = show);
    // 社区无限加载: 距底部400px内触发下一批
    if (_scrollCtl.hasClients &&
        _scrollCtl.position.maxScrollExtent - _scrollCtl.offset < 400) {
      _loadCommunity();
    }
    // 30秒浏览气泡提示
    if (!_bubbleShown &&
        DateTime.now().difference(_browseStart).inSeconds > 30 &&
        _scrollCtl.offset > 400) {
      _bubbleShown = true;
      _showBubble();
    }
  }

  void _startTimers() {
    _newsTimer?.cancel();
    _newsTimer = Timer.periodic(
        const Duration(milliseconds: AppConfig.newsRefreshMs), (_) => _loadNews());
    _raceTimer?.cancel();
    _raceTimer = Timer.periodic(
        const Duration(milliseconds: AppConfig.raceRefreshMs), (_) => _loadRaces());
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_carousel.isEmpty || !mounted) return;
      _carouselIndex = (_carouselIndex + 1) % _carousel.length;
      if (_carouselCtl.hasClients) {
        _carouselCtl.animateToPage(_carouselIndex,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
      }
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadCarousel(),
      _loadNews(),
      _loadRaces(),
      _loadPartners(),
      _loadCommunity(reset: true),
    ]);
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _loadAll();
    setState(() => _refreshing = false);
  }

  Future<void> _loadCarousel() async {
    final items = await Api.carousel();
    if (!mounted) return;
    if (items.isNotEmpty && items.length != _carousel.length) {
      setState(() => _carousel = items);
    } else if (items.isNotEmpty) {
      _carousel = items;
    }
  }

  Future<void> _loadNews() async {
    final items = await Api.news();
    if (!mounted || items.isEmpty) return;
    final fresh = items.where((n) => !_knownNewsIds.contains(n.id)).toList();
    if (_knownNewsIds.isNotEmpty && fresh.isNotEmpty) {
      setState(() => _freshNewsCount = fresh.length);
    }
    if (_knownNewsIds.isEmpty) {
      setState(() => _news = items);
    }
    for (final n in items) {
      _knownNewsIds.add(n.id);
    }
  }

  Future<void> _loadRaces() async {
    final items = await Api.races();
    if (!mounted || items.isEmpty) return;
    setState(() => _races = items);
  }

  Future<void> _loadPartners() async {
    final items = await Api.partners();
    if (!mounted || items.isEmpty) return;
    setState(() => _partners = items);
    // 布局完成后启动marquee（此时controller才挂载）
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  /// 合作伙伴匀速自动滚动（对齐Web端RAF 96px/s），不可交互，滚到末尾回0无缝循环
  void _startMarquee() {
    if (_marqueeTimer != null || !_partnerCtl.hasClients) return;
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_partnerCtl.hasClients || !mounted) return;
      final max = _partnerCtl.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _partnerCtl.offset + 1.6;
      _partnerCtl.jumpTo(next >= max ? 0 : next);
    });
  }

  Future<void> _loadCommunity({bool reset = false}) async {
    if (_communityLoading) return;
    if (reset) {
      _communityPage = 1;
      _communityEnded = false;
    }
    if (_communityEnded) return;
    _communityLoading = true;
    final (posts, hasMore) = await Api.community(page: _communityPage, size: 24);
    _communityLoading = false;
    if (!mounted) return;
    if (posts.isEmpty) {
      if (reset) setState(() => _community = []);
      _communityEnded = true;
      return;
    }
    setState(() {
      if (reset) {
        _community = posts;
      } else {
        final known = _community.map((p) => p.id).toSet();
        _community.addAll(posts.where((p) => !known.contains(p.id)));
      }
      _communityPage++;
      _communityEnded = !hasMore;
    });
  }

  void _showBubble() {
    if (!mounted) return;
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 120, right: 20,
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.fromLTRB(14, 12, 28, 12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('沉浸式浏览已开启', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('发布你的飞行瞬间吧', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);
    Timer(const Duration(seconds: 6), overlay.remove);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: AppTheme.accentCyan,
      backgroundColor: AppTheme.bgCard,
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollCtl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildCarousel(),
          _buildNewsModule(),
          _buildRaceModule(),
          _buildPartnersModule(),
          _buildCommunityModule(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==================== 轮播图 ====================
  Widget _buildCarousel() {
    if (_carousel.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text('载入轮播中...', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _carouselCtl,
            itemCount: _carousel.length,
            onPageChanged: (i) => _carouselIndex = i,
            itemBuilder: (_, i) {
              final item = _carousel[i];
              return GestureDetector(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    image: item.image.isNotEmpty
                        ? DecorationImage(image: NetworkImage(item.image), fit: BoxFit.cover)
                        : null,
                  ),
                  child: item.image.isEmpty
                      ? Center(
                          child: Text(item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary)))
                      : null,
                ),
              );
            },
          ),
        ),
        // 圆点指示器
        Positioned(
          bottom: 24, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_carousel.length, (i) {
              final active = i == _carouselIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6, height: 6,
                decoration: BoxDecoration(
                    color: active ? AppTheme.accentCyan : const Color(0xFFD8DDE5),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: active
                        ? [BoxShadow(color: AppTheme.accentCyan.withValues(alpha: 0.35), blurRadius: 8)]
                        : null,
                  ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ==================== 模块标题 ====================
  Widget _moduleHeader(String title, String enSub, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(enSub,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted,
                      letterSpacing: 1)),
            ],
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ==================== 今日资讯 ====================
  Widget _buildNewsModule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('今日资讯', "Today's News", action: _freshNewsCount > 0
            ? GestureDetector(
                onTap: () => setState(() => _freshNewsCount = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x1A0A54F5),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0x330A54F5)),
                  ),
                  child: Text('$_freshNewsCount条新',
                      style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan)),
                ),
              )
            : null),
        ..._news.take(3).map((n) => ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                    color: AppTheme.accentCyan, shape: BoxShape.circle),
              ),
              title: Text(n.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(_timeAgo(n.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () => _showNewsDetail(n),
            )),
      ],
    );
  }

  /// 资讯详情底部弹窗（NewsItem已有content字段，API直接返回）
  void _showNewsDetail(NewsItem n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(n.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, height: 1.4)),
              ),
              if (n.createdAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(_timeAgo(n.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                ),
              const Divider(height: 1, color: AppTheme.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    n.content.isNotEmpty ? n.content : '（暂无正文内容）',
                    style: const TextStyle(
                        fontSize: 14, height: 1.8, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 近期赛事 ====================
  Widget _buildRaceModule() {
    return Column(
      children: [
        _moduleHeader('近期赛事', 'FPV Races',
            action: GestureDetector(
              onTap: () => AppNav.tab.value = 1,
              child: const Text('更多 ›',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            )),
        ..._races.take(2).map((r) {
          final tagColor = r.category == '国际赛'
              ? AppTheme.accentPurple
              : r.category == '竞速赛'
                  ? AppTheme.accentCyan
                  : AppTheme.accentGreen;
          return GestureDetector(
            onTap: () {
              AppNav.raceId.value = r.id;
              AppNav.tab.value = 1;
            },
            child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: GlassContainer(
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tagColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(r.category,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tagColor)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Text(r.date, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        );
        }),
      ],
    );
  }

  // ==================== 合作伙伴(真logo匀速marquee，logo完整不裁切) ====================
  Widget _buildPartnersModule() {
    if (_partners.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleHeader('合作伙伴', 'HeZuoHuoBan'),
          Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
                child: Text('合作伙伴载入中...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('合作伙伴', 'HeZuoHuoBan'),
        SizedBox(
          height: 64,
          // 匀速自动滚动，不可交互
          child: IgnorePointer(
            child: ListView.separated(
              controller: _partnerCtl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _partners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = _partners[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: p.logo.isNotEmpty
                      ? Image.network(
                          '${AppConfig.baseUrl}${p.logo}',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) =>
                              _partnerFallback(p.name),
                        )
                      : _partnerFallback(p.name),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 网络失败兜底：首字母圆形
  Widget _partnerFallback(String name) {
    return Container(
      width: 40, height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppTheme.accentCyan, AppTheme.accentBlue]),
      ),
      child: Text(name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  // ==================== 飞行社区预览 ====================
  Widget _buildCommunityModule() {
    return Column(
      children: [
        _moduleHeader('飞手社区', 'Xiao Zi Shu 小紫书',
            action: GestureDetector(
              onTap: () => AppNav.tab.value = 3,
              child: const Text('进入社区 ›',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            )),
        if (_community.isEmpty)
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
                child: Text('社区内容载入中...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
              children: _community.map(CommunityPage.postCard).toList(),
            ),
          ),
      ],
    );
  }

  String _timeAgo(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${t.month}月${t.day}日';
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

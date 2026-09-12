import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/app_nav.dart';
import '../core/config.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// 赛事中心页：主横幅 + 6功能标签 + 上届排行榜 + 在线报名
class RaceCenterPage extends StatefulWidget {
  const RaceCenterPage({super.key});

  @override
  State<RaceCenterPage> createState() => _RaceCenterPageState();
}

class _RaceCenterPageState extends State<RaceCenterPage>
    with AutomaticKeepAliveClientMixin {
  static const _tabs = ['赛程安排', '在线报名', '上届排行榜', '竞赛规则', '赞助伙伴', '赛事广告'];

  int _tabIndex = 0;
  Race? _featured;
  List<Race> _races = [];
  String? _selectedRaceId;
  Timer? _timer;
  bool _refreshing = false;

  final _contactCtl = TextEditingController();
  bool _signingUp = false;
  String? _signupMsg;
  String? _pendingNavRace; // AppNav跳入的赛事，等列表加载后切换

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
        const Duration(milliseconds: AppConfig.raceRefreshMs), (_) => _load());
    AppNav.raceId.addListener(_onNavRace);
  }

  @override
  void dispose() {
    AppNav.raceId.removeListener(_onNavRace);
    _timer?.cancel();
    _contactCtl.dispose();
    super.dispose();
  }

  /// 首页赛事卡片跳入：选中指定赛事
  void _onNavRace() {
    final id = AppNav.raceId.value;
    if (id == null) return;
    AppNav.raceId.value = null;
    _pendingNavRace = id;
    _load();
  }

  Future<void> _load() async {
    final f = await Api.featuredRace();
    final rs = await Api.races();
    if (!mounted) return;
    setState(() {
      if (rs.isNotEmpty) _races = rs;
      // 用户手动选中赛事时不被定时刷新覆盖
      if (_selectedRaceId != null) {
        final sel = _races.where((r) => r.id == _selectedRaceId).toList();
        if (sel.isNotEmpty) {
          _featured = sel.first;
        } else if (f != null) {
          _featured = f;
        }
      } else if (f != null) {
        _featured = f;
      }
    });
    if (_pendingNavRace != null) {
      final id = _pendingNavRace!;
      _pendingNavRace = null;
      _switchRace(id);
    }
  }

  void _switchRace(String id) {
    final sel = _races.where((r) => r.id == id).toList();
    if (sel.isEmpty) return;
    setState(() {
      _selectedRaceId = id;
      _featured = sel.first;
    });
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _load();
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: AppTheme.accentCyan,
      backgroundColor: AppTheme.bgCard,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildBanner(),
          _buildRaceSwitcher(),
          _buildTabBar(),
          _buildTabContent(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==================== 赛事切换器(全部赛事独立详情) ====================
  Widget _buildRaceSwitcher() {
    if (_races.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _races.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = _races[i];
          final active = _featured?.id == r.id;
          return GestureDetector(
            onTap: () => _switchRace(r.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppTheme.accentCyan : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: active ? AppTheme.accentCyan : AppTheme.border),
              ),
              child: Text(
                '${r.date} ${r.category}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppTheme.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 主横幅 ====================
  Widget _buildBanner() {
    final r = _featured;
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.35)),
                ),
                child: const Text('焦点赛事',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentCyan)),
              ),
              const Spacer(),
              if (r != null)
                _statusChip(r),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            r?.name ?? 'DCT 第二届春季邀请赛',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            r != null && r.date.isNotEmpty
                ? '比赛时间 · ${r.date}'
                : '载入赛事信息中...',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerStat(r != null && r.signupStart.isNotEmpty
                  ? r.signupStart
                  : '规划中', '报名时间'),
              const SizedBox(width: 12),
              _bannerStat(r != null && r.fee.isNotEmpty ? r.fee : '免费', '报名费用'),
              const SizedBox(width: 12),
              _bannerStat(
                  '${r?.leaderboard.length ?? _races.length}', '参赛队伍'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(Race r) {
    final color = r.status == 'ongoing'
        ? AppTheme.accentGreen
        : r.status == 'upcoming'
            ? AppTheme.accentCyan
            : AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(r.statusText,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ==================== 6功能标签 ====================
  Widget _buildTabBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == _tabIndex;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.accentCyan.withValues(alpha: 0.15)
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: active
                        ? AppTheme.accentCyan.withValues(alpha: 0.5)
                        : AppTheme.border),
              ),
              child: Text(_tabs[i],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppTheme.accentCyan : AppTheme.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildScheduleTab();
      case 1:
        return _buildSignupTab();
      case 2:
        return _buildLeaderboardTab();
      case 3:
        return _buildRulesTab();
      case 4:
        return _buildSponsorTab();
      default:
        return _buildAdsTab();
    }
  }

  // ==================== 赛程安排 ====================
  Widget _buildScheduleTab() {
    final schedule = _featured?.schedule ?? const <RaceScheduleItem>[];
    if (schedule.isEmpty) {
      return _emptyTab('赛事策划组正在规划中...');
    }
    return Column(
      children: schedule
          .map((s) => GlassContainer(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                borderRadius: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.time,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentCyan)),
                        const SizedBox(height: 2),
                        Text(s.stage,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(s.detail,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ==================== 在线报名 ====================
  Widget _buildSignupTab() {
    if (!Storage.isLoggedIn) {
      return _emptyTab('请先在「我的」页面登录 91ID 后报名');
    }
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('在线报名',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('报名赛事：${_featured?.name ?? '--'}',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _contactCtl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '联系方式（手机号 / 微信 / QQ）',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accentCyan),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _signingUp ? null : _doSignup,
              icon: _signingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.how_to_reg_rounded, size: 18),
              label: Text(_signingUp ? '提交中...' : '立即报名',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_signupMsg != null) ...[
            const SizedBox(height: 12),
            Text(_signupMsg!,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  Future<void> _doSignup() async {
    final contact = _contactCtl.text.trim();
    if (contact.length < 4) {
      setState(() => _signupMsg = '请填写有效的联系方式');
      return;
    }
    if (_featured == null) {
      setState(() => _signupMsg = '赛事信息尚未加载完成');
      return;
    }
    setState(() {
      _signingUp = true;
      _signupMsg = null;
    });
    final ok = await Api.signup(_featured!.id, contact);
    if (!mounted) return;
    setState(() {
      _signingUp = false;
      _signupMsg = ok ? '报名成功！组委会将通过联系方式与您确认。' : '报名失败，请稍后重试或联系组委会。';
    });
  }

  // ==================== 上届排行榜 ====================
  Widget _buildLeaderboardTab() {
    final lb = _featured?.leaderboard ?? const <LeaderboardEntry>[];
    final title = _featured?.leaderboardTitle.isNotEmpty == true
        ? _featured!.leaderboardTitle
        : '上届排行榜';
    if (lb.isEmpty) {
      return _emptyTab('赛事策划组正在规划中...');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        ...lb.asMap().entries.map((e) {
          final entry = e.value;
          final medal = switch (entry.rank) {
            1 => Colors.amber,
            2 => const Color(0xFFB8C4D9),
            3 => const Color(0xFFD08A4E),
            _ => null,
          };
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            child: GlassContainer(
              borderRadius: 10,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: medal != null
                          ? medal.withValues(alpha: 0.18)
                          : const Color(0xFFF5F6F8),
                      border: Border.all(
                          color: medal?.withValues(alpha: 0.5) ??
                              AppTheme.border),
                    ),
                    child: Text('${entry.rank}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: medal ?? AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Text(entry.club,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== 竞赛规则 ====================
  Widget _buildRulesTab() {
    final rules = _featured?.rules ?? '';
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Text(
        rules.isNotEmpty ? rules : '赛事策划组正在规划中...',
        style: const TextStyle(
            fontSize: 13, color: AppTheme.textSecondary, height: 1.8),
      ),
    );
  }

  // ==================== 赞助伙伴 ====================
  Widget _buildSponsorTab() {
    final sponsor = _featured?.sponsor ?? '';
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('赞助伙伴',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(sponsor.isNotEmpty ? sponsor : '赛事策划组正在规划中...',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.8)),
        ],
      ),
    );
  }

  // ==================== 赛事广告 ====================
  Widget _buildAdsTab() {
    final ads = _featured?.ads ?? '';
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('赛事广告',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(ads.isNotEmpty ? ads : '赛事策划组正在规划中...',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.8)),
        ],
      ),
    );
  }

  Widget _emptyTab(String msg) {
    return Container(
      height: 180,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Text(msg,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ),
    );
  }
}

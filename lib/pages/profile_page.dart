import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// 我的 —— 91ID登录 + 本地账号数据持久化
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  final _idCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  UserProfile? _profile;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 恢复上次登录账号
    if (Storage.lastLoginId.isNotEmpty) _idCtl.text = Storage.lastLoginId;
    if (Storage.isLoggedIn) _refreshProfile();
  }

  @override
  void dispose() {
    _idCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    final p = await Api.profile();
    if (!mounted) return;
    if (p != null) {
      setState(() => _profile = p);
    } else if (Storage.isLoggedIn) {
      // Token失效，清除本地会话
      await Storage.clearSession();
      if (mounted) setState(() => _profile = null);
    }
  }

  Future<void> _login() async {
    final id = _idCtl.text.trim();
    final pwd = _pwdCtl.text;
    if (id.isEmpty || pwd.isEmpty) {
      _toast('请输入 91ID 账号和密码');
      return;
    }
    setState(() => _loading = true);
    final res = await Api.login(id, pwd);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      final data = (res['data'] as Map?) ?? {};
      await Storage.saveSession(
        token: (data['token'] ?? '').toString(),
        nickname: (data['nickname'] ?? '').toString(),
        id91: (data['id91'] ?? '').toString(),
        loginId: id,
      );
      _pwdCtl.clear();
      await _refreshProfile();
      _toast('欢迎回来，${Storage.nickname}');
    } else {
      _toast(res['error']?.toString() ?? '登录失败，请检查账号密码');
    }
  }

  Future<void> _logout() async {
    await Api.logout();
    await Storage.clearSession();
    if (!mounted) return;
    setState(() => _profile = null);
    _toast('已退出登录');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Storage.isLoggedIn ? _buildLoggedIn() : _buildLoginForm(),
        if (Storage.isLoggedIn) ..._buildMenuList(),
        const SizedBox(height: 100),
      ],
    );
  }

  // ==================== 登录表单 ====================
  Widget _buildLoginForm() {
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/icon/logo-app.png',
                width: 68, height: 68, filterQuality: FilterQuality.medium),
          ),
          const SizedBox(height: 14),
          const Text('登录 YZBJFPV',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('使用 91ID 账号登录，数据仅保存在本机',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          _input(
            controller: _idCtl,
            hint: '91ID 账号',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 12),
          _input(
            controller: _pwdCtl,
            hint: '密码',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('登 录',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showRegister,
            child: const Text('没有账号？注册 91ID',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.accentCyan),
        ),
      ),
    );
  }

  // ==================== 已登录头部 ====================
  Widget _buildLoggedIn() {
    final nickname = _profile?.nickname.isNotEmpty == true
        ? _profile!.nickname
        : Storage.nickname;
    final id91 = _profile?.id91.isNotEmpty == true
        ? _profile!.id91
        : Storage.id91;
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppTheme.accentCyan, AppTheme.accentBlue]),
              boxShadow: [
                BoxShadow(
                    color: Color(0x590A54F5), blurRadius: 18),
              ],
            ),
            child: Text(
              nickname.isNotEmpty ? nickname[0] : '飞',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    if (_profile?.isAdmin == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppTheme.accentOrange
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Text('管理员',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentOrange)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('91ID: $id91',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                size: 20, color: AppTheme.textMuted),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  // ==================== 功能菜单 ====================
  List<Widget> _buildMenuList() {
    final items = [
      (Icons.how_to_reg_rounded, '我的报名', () => _toast('暂无报名记录')),
      (Icons.article_outlined, '我的帖子', () => _toast('暂未发布帖子')),
      (Icons.favorite_border_rounded, '我的收藏', () => _toast('暂无收藏')),
      (Icons.download_rounded, '下载中心', () => _toast('下载中心开发中')),
      (Icons.info_outline_rounded, '关于 YZBJFPV', _showAbout),
    ];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text('常用功能',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textMuted)),
      ),
      GlassContainer(
        borderRadius: 16,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: items
              .map((it) => ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(it.$1,
                        size: 20, color: AppTheme.accentCyan),
                    title: Text(it.$2,
                        style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppTheme.textMuted),
                    onTap: it.$3,
                  ))
              .toList(),
        ),
      ),
    ];
  }

  // ==================== 91ID注册（真实接口 /91id/api/register） ====================
  void _showRegister() {
    final idCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final pwdCtl = TextEditingController();
    final pwd2Ctl = TextEditingController();
    bool obscure = true;
    bool submitting = false;
    // 91ID可用性实时查重（失焦触发）
    int? idAvailability; // null=未查 0=不可用 1=可用
    bool checkingId = false;

    Future<void> doCheckId(StateSetter setModalState) async {
      final id = idCtl.text.trim();
      if (!RegExp(r'^\d{4}$').hasMatch(id)) return;
      setModalState(() => checkingId = true);
      final ok = await Api.checkId91(id);
      if (!mounted) return;
      setModalState(() {
        checkingId = false;
        idAvailability = ok ? 1 : 0;
      });
    }

    Future<void> doSubmit(StateSetter setModalState) async {
      final id = idCtl.text.trim();
      final phone = phoneCtl.text.trim();
      final pwd = pwdCtl.text;
      final pwd2 = pwd2Ctl.text;
      final snack = (String m) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
      if (!RegExp(r'^\d{4}$').hasMatch(id)) {
        snack('91ID 必须是4位数字');
        return;
      }
      if (phone.isEmpty) {
        snack('请输入手机号');
        return;
      }
      if (pwd.length < 6) {
        snack('密码至少6位');
        return;
      }
      if (pwd != pwd2) {
        snack('两次输入的密码不一致');
        return;
      }
      setModalState(() => submitting = true);
      final res = await Api.register91(id, phone, pwd, Storage.fingerprint);
      if (!context.mounted) return;
      setModalState(() => submitting = false);
      if (res['success'] == true) {
        Navigator.of(context).pop(); // 关注册弹窗
        _idCtl.text = id; // 自动填入登录框
        _pwdCtl.clear();
        _toast('注册成功，请登录');
      } else {
        snack(res['error']?.toString() ?? '注册失败，请稍后再试');
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 18,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('注册 91ID',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('注册后即可登录 APP 与网页端，账号全端通用',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: idCtl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(fontSize: 14, letterSpacing: 2),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '91ID（4位数字）',
                  prefixIcon: const Icon(Icons.badge_rounded,
                      size: 18, color: AppTheme.textMuted),
                  suffixIcon: checkingId
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : idAvailability == null
                          ? null
                          : Icon(
                              idAvailability == 1
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 18,
                              color: idAvailability == 1
                                  ? AppTheme.accentGreen
                                  : const Color(0xFFE5383C),
                            ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentCyan)),
                ),
                onChanged: (_) => setModalState(() {
                  idAvailability = null; // 改动后重置查重
                }),
                onEditingComplete: () => doCheckId(setModalState),
              ),
              if (idAvailability != null) ...[
                const SizedBox(height: 6),
                Text(
                  idAvailability == 1 ? '该 91ID 可用' : '该 91ID 已被占用，换一个试试',
                  style: TextStyle(
                      fontSize: 11,
                      color: idAvailability == 1
                          ? AppTheme.accentGreen
                          : const Color(0xFFE5383C)),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '手机号',
                  prefixIcon: Icon(Icons.phone_iphone_rounded,
                      size: 18, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: Color(0xFFF5F6F8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppTheme.accentCyan)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwdCtl,
                obscureText: obscure,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '密码（至少6位）',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18, color: AppTheme.textMuted),
                    onPressed: () => setModalState(() => obscure = !obscure),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentCyan)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwd2Ctl,
                obscureText: obscure,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '确认密码',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentCyan)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: submitting ? null : () => doSubmit(setModalState),
                  child: submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('注 册',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAbout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('YZBJFPV',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'YZBJFPV 飞行平台客户端 V0.0.1.5Beta\n'
          '多端支持：Android / Windows / iOS\n'
          '服务器：YZCloud',
          style: TextStyle(fontSize: 13, height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了',
                style: TextStyle(color: AppTheme.accentCyan)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config.dart';
import 'core/storage.dart';
import 'core/api.dart';
import 'theme/app_theme.dart';
import 'webview_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init(); // 恢复本地账号数据
  // 移动端锁定竖屏（Windows 桌面不受影响）
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const YzbjfpvApp());
}

/// 网页壳子多端方案（用户拍板）
/// 全屏 WebView 加载 air.yzbjfpv.top，全部功能（含小紫书/底部dock/推送）由 web 端承载
/// APP 壳只负责：开屏动画（三端玻璃质感）+ 连接门禁 + 壳热更新检查（web 发版即全员生效）

class YzbjfpvApp extends StatelessWidget {
  const YzbjfpvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YZBJFPV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}

/// 三端玻璃参数：iOS 液态玻璃（深度）/ Android 毛玻璃（假液态）/ Windows 轻微特色
class GlassSpec {
  final double sigma;      // 模糊强度
  final double opacity;    // 玻璃底白
  final double highlight;  // 对角高光
  final double radius;     // 圆角
  const GlassSpec(this.sigma, this.opacity, this.highlight, this.radius);

  static GlassSpec forPlatform() {
    if (Platform.isIOS) return const GlassSpec(26, 0.42, 0.75, 40);
    if (Platform.isAndroid) return const GlassSpec(16, 0.55, 0.45, 34);
    return const GlassSpec(11, 0.66, 0.32, 28); // Windows
  }
}

/// 液态玻璃面板：BackdropFilter 模糊底层光晕 + 半透明白 + 对角高光 + 亮边框
class GlassPanel extends StatelessWidget {
  final Widget child;
  final GlassSpec spec;
  final EdgeInsetsGeometry padding;
  const GlassPanel({super.key, required this.child, required this.spec, this.padding = const EdgeInsets.all(28)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(spec.radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: spec.sigma, sigmaY: spec.sigma),
              child: ColoredBox(color: Colors.white.withValues(alpha: spec.opacity)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: spec.highlight),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: spec.highlight * 0.25),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// 开屏背景：白底 + 品牌多彩光晕（玻璃面板模糊的"内容"层）
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0x220A54F5);
    const cyan = Color(0x1E00B3C6);
    const amber = Color(0x16F59E0B);
    return const Stack(children: [
      ColoredBox(color: Colors.white),
      Positioned(left: -80, top: -60, child: _Blob(260, blue)),
      Positioned(right: -70, top: 120, child: _Blob(220, cyan)),
      Positioned(left: 60, bottom: -90, child: _Blob(240, cyan)),
      Positioned(right: -50, bottom: -70, child: _Blob(200, amber)),
      Positioned(left: 150, top: 220, child: _Blob(120, blue)),
    ]);
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// 开屏动画 + 真连接门禁 + 壳热更新：
/// logo玻璃卡缩放淡入 → 探测服务器 → web版本对比(变化则进壳绕缓存强刷) → 更新检查 → 进主界面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  final GlassSpec _glass = GlassSpec.forPlatform();
  bool _connecting = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween(begin: 0.86, end: 1.0)
        .animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    _ctl.forward();
    Timer(const Duration(milliseconds: 900), _gateConnect);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _gateConnect() async {
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _failed = false;
    });
    final ok = await Api.checkServer();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _connecting = false;
        _failed = true;
      });
      return;
    }
    // 壳热更新：对比 web 版本，变化则标记进壳绕过缓存（服务器发新 web 即全员更新）
    final remoteV = await Api.checkWebVersion();
    if (remoteV.isNotEmpty) {
      if (Storage.webVersion.isNotEmpty && remoteV != Storage.webVersion) {
        WebViewShell.forceBust = true;
      }
      await Storage.setWebVersion(remoteV);
    }
    await _checkAppUpdate();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WebViewShell()));
  }

  /// 壳层更新检查（仅壳架构大改才需要重装；日常功能更新走 web 热更）
  Future<void> _checkAppUpdate() async {
    final info = await Api.checkUpdate();
    if (info == null || !mounted) return;
    if (!info.newerThan(AppConfig.appVersion)) return;
    final force = info.mustForce;
    await showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (_) => PopScope(
        canPop: !force,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('发现新版本 ${info.version}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info.changelog.isNotEmpty)
                Text(info.changelog,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF3D4654), height: 1.6)),
              if (!force && info.deadline.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${info.deadline} 后将自动转为强制更新',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3))),
                ),
            ],
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后更新',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A93A3))),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A54F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _toast('请前往 air.yzbjfpv.top/app 下载最新版本');
              },
              child: const Text('立即更新',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const SplashBackdrop(),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: GlassPanel(
                  spec: _glass,
                  padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icon/yzbjfpv-brand.jpg',
                          width: 104, height: 104,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium),
                      const SizedBox(height: 16),
                      const Text('YZBJFPV',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 5),
                      const Text('为方便模友而生',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, letterSpacing: 2)),
                      const SizedBox(height: 26),
                      if (_connecting)
                        const Column(
                          children: [
                            SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: AppTheme.accentCyan),
                            ),
                            SizedBox(height: 10),
                            Text('正在连接服务器...',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        )
                      else if (!_failed)
                        const Text(AppConfig.appVersion,
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 连接失败错误页：玻璃卡片，可无限重试，绝不让进主界面
          if (_failed)
            Positioned(
              left: 28, right: 28, bottom: 64,
              child: GlassPanel(
                spec: _glass,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 34, color: AppTheme.textMuted),
                    const SizedBox(height: 10),
                    const Text('无法连接服务器',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 5),
                    const Text('请检查网络后重试\nair.yzbjfpv.top',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.6)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _gateConnect,
                        child: const Text('重 试',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

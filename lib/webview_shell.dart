import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'core/config.dart';
import 'theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_windows/webview_windows.dart';

/// 任务B：网页壳子（用户拍板的多端方案）
/// 全屏 WebView 加载 air.yzbjfpv.top，功能全部由 web 端承载（含小紫书+底部dock）
/// Android/iOS 走 webview_flutter，Windows 走 webview_windows(WebView2)
/// 开屏动画 / 连接门禁 / 更新检查在 SplashScreen 已处理
class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  /// 壳热更新标记：开屏发现 web 版本变化时置 true，加载时带一次性 bust 参数绕过缓存
  /// （web 资源引用由 index.html 的 v= 版本号控制，bust HTML 即拿到全新引用链）
  static bool forceBust = false;

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  WebViewController? _mobileCtrl;
  final WebviewController _winCtrl = WebviewController();
  bool _winReady = false;
  bool _winFailed = false;

  bool get _isDesktop => Platform.isWindows;

  /// App壳UA标识：web端凭 navigator.userAgent 含 YZBJFPV-App 识别App环境
  /// （浏览器永不携带 → 彻底区分App/Web，皮肤中心等App专属功能据此判断）
  static const String _uaMarker = 'YZBJFPV-App';

  /// Windows: 文档创建前注入，保留原生UA并追加标记
  static const String _winUaScript = '''
(function(){try{
var d=Object.getOwnPropertyDescriptor(Object.getPrototypeOf(navigator),'userAgent');
var b=(d&&d.get)?d.get.call(navigator):String(navigator.userAgent);
Object.defineProperty(navigator,'userAgent',{get:function(){return b+' YZBJFPV-App';}});
}catch(e){}})();
''';

  /// 热更新时的加载地址：一次性时间戳参数，仅绕过 HTML 缓存
  String get _loadUrl => WebViewShell.forceBust
      ? '${AppConfig.prodUrl}?_bust=${DateTime.now().millisecondsSinceEpoch}'
      : AppConfig.prodUrl;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _initWindows();
    } else {
      _initMobile();
    }
    WebViewShell.forceBust = false; // 只 bust 一次，之后恢复 HTTP 缓存
  }

  void _initMobile() {
    WebViewController controller;
    if (Platform.isIOS) {
      // iOS: 开启内嵌视频播放(否则点击播放强制全屏, web的playsinline被WebView层拦截)
      final params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      controller = WebViewController.fromPlatformCreationParams(params);
    } else {
      controller = WebViewController();
    }
    _mobileCtrl = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(Platform.isIOS
          ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 $_uaMarker'
          : 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36 $_uaMarker')
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {},
      ))
      ..loadRequest(Uri.parse(_loadUrl));
  }

  Future<void> _initWindows() async {
    try {
      await _winCtrl.initialize();
      await _winCtrl.addScriptToExecuteOnDocumentCreated(_winUaScript);
      await _winCtrl.setBackgroundColor(AppTheme.bgPrimary);
      await _winCtrl.loadUrl(_loadUrl);
      if (!mounted) return;
      setState(() => _winReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _winFailed = true);
    }
  }

  @override
  void dispose() {
    if (_isDesktop) _winCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _isDesktop ? _buildDesktop() : _buildMobile();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Android 物理返回键 → WebView 后退，退无可退不退出
        final ctrl = _mobileCtrl;
        if (ctrl != null && await ctrl.canGoBack()) {
          await ctrl.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: body,
      ),
    );
  }

  Widget _buildMobile() {
    final ctrl = _mobileCtrl;
    if (ctrl == null) {
      return const Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.accentCyan),
        ),
      );
    }
    return WebViewWidget(controller: ctrl);
  }

  Widget _buildDesktop() {
    if (_winFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('WebView 初始化失败，请重启应用',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              ),
              onPressed: () {
                setState(() => _winFailed = false);
                _initWindows();
              },
              child: const Text('重 试', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 4)),
            ),
          ],
        ),
      );
    }
    if (!_winReady) {
      return const Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.accentCyan),
        ),
      );
    }
    return Webview(_winCtrl);
  }
}

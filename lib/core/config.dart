/// 全局配置
class AppConfig {
  /// 直连正式域名，不提供任何本地覆盖地址（避免存过错误地址后永久连不上）
  static String get baseUrl => prodUrl;

  /// 生产环境正式域名（Cloudflare隧道直转4000端口）
  static const String prodUrl = 'https://air.yzbjfpv.top';

  /// APP当前版本（与服务端 /api/yzbjfpv-app-version 对比）
  static const String appVersion = 'V0.0.1.6Beta';

  // 刷新间隔
  static const int newsRefreshMs = 3000;
  static const int raceRefreshMs = 3000;
  static const int carouselRefreshMs = 300000;
  static const int minFetchIntervalMs = 5000;

  static const String aiModel = 'GPT-5.3-mini';
}

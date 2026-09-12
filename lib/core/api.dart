import 'dart:convert';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';
import 'storage.dart';

/// yzbjfpv-xx 统一API客户端
class Api {
  static final http.Client _client = http.Client();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (Storage.token.isNotEmpty) 'Authorization': 'Bearer ${Storage.token}',
      };

  static String _url(String path) => '${AppConfig.baseUrl}$path';

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'error': 'bad response'};
    }
  }

  // ---------- 公开接口 ----------
  /// 连接门禁: 双接口探测+3轮重试（移动网络慢启动/单接口偶发故障防误杀）
  /// 返回 null=连接成功；非null=失败诊断（展示给用户定位网络问题）
  static Future<String?> probeServer() async {
    const paths = ['/api/yzbjfpv-meta', '/api/yzbjfpv-app-version'];
    Object? lastErr;
    for (var round = 0; round < 3; round++) {
      for (final p in paths) {
        try {
          final res = await _client
              .get(Uri.parse(_url(p)))
              .timeout(const Duration(seconds: 12));
          if (res.statusCode == 200) return null;
          lastErr = 'HTTP ${res.statusCode}';
        } catch (e) {
          lastErr = e;
        }
      }
      if (round < 2) await Future.delayed(const Duration(milliseconds: 900));
    }
    return _diagText(lastErr);
  }

  /// 异常→人话诊断（用户可据此判断是手机网络/运营商DNS还是服务端问题）
  static String _diagText(Object? e) {
    final s = e == null ? '' : e.toString();
    if (s.contains('Failed host lookup')) return 'DNS解析失败(域名无法解析)';
    if (s.contains('SocketException')) return '网络连接被拒或中断';
    if (s.contains('HandshakeException') || s.contains('CERTIFICATE')) return 'TLS证书校验失败';
    if (s.contains('TimeoutException')) return '连接超时(服务器无响应)';
    if (s.startsWith('HTTP ')) return '服务器返回异常($s)';
    return '未知网络错误';
  }

  /// 兼容旧调用: 布尔形式
  static Future<bool> checkServer() async => (await probeServer()) == null;

  /// 远程更新: 版本检查（启动时调用）
  static Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final res = await _client
          .get(Uri.parse(_url('/api/yzbjfpv-app-version')))
          .timeout(const Duration(seconds: 8));
      final d = _decode(res);
      if (d['success'] != true || d['data'] == null) return null;
      return AppUpdateInfo.fromJson(d['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 壳热更新: 拉取 web 当前版本号（开屏时对比，不同则 WebView 绕过缓存强刷）
  static Future<String> checkWebVersion() async {
    try {
      final res = await _client
          .get(Uri.parse(_url('/api/yzbjfpv-meta')))
          .timeout(const Duration(seconds: 8));
      final d = _decode(res);
      if (d['success'] == true && d['data'] != null) {
        return '${(d['data'] as Map<String, dynamic>)['webVersion'] ?? ''}';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  static Future<List<CarouselItem>> carousel() async {
    final res = await _client.get(Uri.parse(_url('/api/yzbjfpv-carousel'))).timeout(const Duration(seconds: 8));
    final d = _decode(res);
    if (d['success'] != true) return [];
    return ((d['data'] as List?) ?? []).map((e) => CarouselItem.fromJson(e)).toList();
  }

  static Future<List<NewsItem>> news() async {
    final res = await _client.get(Uri.parse(_url('/api/yzbjfpv-news'))).timeout(const Duration(seconds: 8));
    final d = _decode(res);
    if (d['success'] != true) return [];
    return ((d['data'] as List?) ?? []).map((e) => NewsItem.fromJson(e)).toList();
  }

  static Future<List<Race>> races() async {
    final res = await _client.get(Uri.parse(_url('/api/yzbjfpv-race'))).timeout(const Duration(seconds: 8));
    final d = _decode(res);
    if (d['success'] != true) return [];
    return ((d['data'] as List?) ?? []).map((e) => Race.fromJson(e)).toList();
  }

  static Future<Race?> featuredRace() async {
    final res = await _client.get(Uri.parse(_url('/api/yzbjfpv-race?featured=1'))).timeout(const Duration(seconds: 8));
    final d = _decode(res);
    if (d['success'] != true || d['data'] == null) return null;
    return Race.fromJson(d['data']);
  }

  static Future<List<Partner>> partners() async {
    final res = await _client.get(Uri.parse(_url('/api/yzbjfpv-hzhb'))).timeout(const Duration(seconds: 8));
    final d = _decode(res);
    if (d['success'] != true) return [];
    return ((d['data'] as List?) ?? []).map((e) => Partner.fromJson(e)).toList();
  }

  static Future<(List<CommunityPost>, bool)> community({int page = 1, int size = 12}) async {
    final res = await _client
        .get(Uri.parse(_url('/api/yzbjfpv-xzs?page=$page&size=$size')))
        .timeout(const Duration(seconds: 10));
    final d = _decode(res);
    if (d['success'] != true) return (<CommunityPost>[], false);
    final list = ((d['data'] as List?) ?? []).map((e) => CommunityPost.fromJson(e)).toList();
    return (list, d['hasMore'] == true);
  }

  // ---------- AI ----------
  static Future<String> aiChat(String message) async {
    try {
      final res = await _client
          .post(Uri.parse(_url('/api/yzbjfpv-ai')),
              headers: _headers, body: jsonEncode({'message': message}))
          .timeout(const Duration(seconds: 15));
      final d = _decode(res);
      if (d['success'] == true && d['data'] != null) {
        return d['data']['reply'] ?? 'FlyAi 暂时无法回复。';
      }
      return d['error'] ?? 'FlyAi 暂时无法回复。';
    } catch (_) {
      return '网络异常，请稍后再试。';
    }
  }

  // ---------- 认证 ----------
  /// 91ID注册: 实时查重（91ID必须4位数字）
  static Future<bool> checkId91(String userId91) async {
    try {
      final res = await _client
          .get(Uri.parse(_url('/91id/api/check-id?userId91=$userId91')))
          .timeout(const Duration(seconds: 8));
      final d = _decode(res);
      return d['success'] == true && d['available'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 91ID注册: POST /91id/api/register
  static Future<Map<String, dynamic>> register91(
      String userId91, String phone, String password, String fingerprint) async {
    try {
      final res = await _client
          .post(Uri.parse(_url('/91id/api/register')),
              headers: _headers,
              body: jsonEncode({
                'userId91': userId91,
                'phone': phone,
                'password': password,
                'deviceFingerprint': fingerprint,
              }))
          .timeout(const Duration(seconds: 12));
      return _decode(res);
    } catch (_) {
      return {'success': false, 'error': '网络异常'};
    }
  }

  static Future<Map<String, dynamic>> login(String id, String password) async {
    try {
      final res = await _client
          .post(Uri.parse(_url('/api/yzbjfpv-auth-login')),
              headers: _headers, body: jsonEncode({'id': id, 'password': password}))
          .timeout(const Duration(seconds: 10));
      return _decode(res);
    } catch (_) {
      return {'success': false, 'error': '网络异常'};
    }
  }

  static Future<UserProfile?> profile() async {
    if (Storage.token.isEmpty) return null;
    try {
      final res = await _client
          .get(Uri.parse(_url('/api/yzbjfpv-profile')), headers: _headers)
          .timeout(const Duration(seconds: 8));
      final d = _decode(res);
      if (d['success'] == true) return UserProfile.fromJson(d['data']);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    if (Storage.token.isEmpty) return;
    try {
      await _client.post(Uri.parse(_url('/api/yzbjfpv-auth-logout')), headers: _headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // ---------- 报名 ----------
  static Future<bool> signup(String raceId, String contact) async {
    try {
      final res = await _client
          .post(Uri.parse(_url('/api/yzbjfpv-signup')),
              headers: _headers, body: jsonEncode({'raceId': raceId, 'contact': contact}))
          .timeout(const Duration(seconds: 10));
      return _decode(res)['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------- 推送通知（设备指纹 + 轮询） ----------
  static Future<void> registerDevice({required String platform}) async {
    try {
      await _client
          .post(Uri.parse(_url('/api/yzbjfpv-device')),
              headers: _headers,
              body: jsonEncode({
                'fingerprint': Storage.fingerprint,
                'platform': platform,
                'version': AppConfig.appVersion,
                'name': 'YZBJFPV-$platform',
              }))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// 返回新推送列表，并更新本地已读游标
  static Future<List<PushMessage>> pollPushes({required String platform}) async {
    try {
      final since = Storage.pushSeen;
      final res = await _client
          .get(Uri.parse(_url('/api/yzbjfpv-poll?since=$since')))
          .timeout(const Duration(seconds: 8));
      final d = _decode(res);
      if (d['success'] != true) return [];
      final all = ((d['data'] as List?) ?? []).map((e) => PushMessage.fromJson(e)).toList();
      final mine = all.where((p) => p.target == 'all' || p.target == platform).toList();
      if (all.isNotEmpty) {
        final maxTs = all.map((p) => p.sentAt).reduce((a, b) => a > b ? a : b);
        await Storage.setPushSeen(maxTs);
      }
      return mine;
    } catch (_) {
      return [];
    }
  }
}

class PushMessage {
  final String id;
  final String title;
  final String body;
  final String url;
  final String target;
  final int sentAt;

  PushMessage({required this.id, required this.title, required this.body, this.url = '', this.target = 'all', required this.sentAt});

  factory PushMessage.fromJson(Map<String, dynamic> j) => PushMessage(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        body: '${j['body'] ?? ''}',
        url: '${j['url'] ?? ''}',
        target: '${j['target'] ?? 'all'}',
        sentAt: (j['sentAt'] is num) ? (j['sentAt'] as num).toInt() : 0,
      );
}

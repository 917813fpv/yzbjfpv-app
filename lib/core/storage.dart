import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地数据持久化：账号、Token、配置
/// 用户要求的"客户端数据(包括账号)保留在本地"由本类实现
class Storage {
  static const _kToken = 'auth_token';
  static const _kNickname = 'user_nickname';
  static const _kId91 = 'user_id91';
  static const _kServerUrl = 'server_url';
  static const _kLastLoginId = 'last_login_id'; // 记住账号
  static const _kFingerprint = 'device_fingerprint';
  static const _kPushSeen = 'push_seen_at';
  static const _kWebVersion = 'web_version_cache'; // 壳热更新：上次开屏看到的 web 版本

  static String token = '';
  static String nickname = '';
  static String id91 = '';
  static String lastLoginId = '';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    token = _prefs?.getString(_kToken) ?? '';
    nickname = _prefs?.getString(_kNickname) ?? '';
    id91 = _prefs?.getString(_kId91) ?? '';
    lastLoginId = _prefs?.getString(_kLastLoginId) ?? '';
  }

  // ---------- 设备指纹（内网无真实IP，用指纹识别设备） ----------
  static String get fingerprint {
    var fp = _prefs?.getString(_kFingerprint) ?? '';
    if (fp.isEmpty) {
      final src = 'yzbjfpv-${DateTime.now().microsecondsSinceEpoch}'
          '-${DateTime.now().hashCode}'
          '-${Uri.base.port}-${identityHashCode(Storage)}';
      fp = src.hashCode.toRadixString(36) + DateTime.now().millisecond.toRadixString(36);
      while (fp.length < 10) {
        fp = '0$fp';
      }
      _prefs?.setString(_kFingerprint, fp);
    }
    return fp;
  }

  // ---------- 推送已读时间戳 ----------
  static int get pushSeen => _prefs?.getInt(_kPushSeen) ?? 0;

  static Future<void> setPushSeen(int ts) async {
    await _prefs?.setInt(_kPushSeen, ts);
  }

  static String? get serverUrl => _prefs?.getString(_kServerUrl);

  // ---------- 壳热更新：web 版本游标 ----------
  static String get webVersion => _prefs?.getString(_kWebVersion) ?? '';

  static Future<void> setWebVersion(String v) async {
    await _prefs?.setString(_kWebVersion, v);
  }

  static Future<void> setServerUrl(String url) async {
    await _prefs?.setString(_kServerUrl, url);
  }

  static Future<void> saveSession({
    required String token,
    required String nickname,
    String id91 = '',
    String loginId = '',
  }) async {
    Storage.token = token;
    Storage.nickname = nickname;
    Storage.id91 = id91;
    lastLoginId = loginId;
    await _prefs?.setString(_kToken, token);
    await _prefs?.setString(_kNickname, nickname);
    await _prefs?.setString(_kId91, id91);
    await _prefs?.setString(_kLastLoginId, loginId);
  }

  static Future<void> clearSession() async {
    token = '';
    nickname = '';
    id91 = '';
    // 保留 lastLoginId，方便下次登录
    await _prefs?.remove(_kToken);
    await _prefs?.remove(_kNickname);
    await _prefs?.remove(_kId91);
  }

  static bool get isLoggedIn => token.isNotEmpty;

  /// 导出本地数据(备份用)
  static Map<String, dynamic> export() => {
        'token': token,
        'nickname': nickname,
        'id91': id91,
        'lastLoginId': lastLoginId,
      };

  /// JSON编解码工具(供缓存使用)
  static Map<String, dynamic>? decodeJson(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

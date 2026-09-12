// 数据模型

class CarouselItem {
  final String id;
  final String title;
  final String image;
  final String link;
  CarouselItem({required this.id, required this.title, required this.image, this.link = ''});

  factory CarouselItem.fromJson(Map<String, dynamic> j) => CarouselItem(
        id: (j['id'] ?? '').toString(),
        title: j['title'] ?? '',
        image: j['image'] ?? '',
        link: j['link'] ?? '',
      );
}

class NewsItem {
  final String id;
  final String title;
  final String content;
  final DateTime? createdAt;
  NewsItem({required this.id, required this.title, this.content = '', this.createdAt});

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        id: (j['id'] ?? '').toString(),
        title: j['title'] ?? '',
        content: j['content'] ?? '',
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

class RaceScheduleItem {
  final String time;
  final String stage;
  final String detail;
  RaceScheduleItem({this.time = '', this.stage = '', this.detail = ''});

  factory RaceScheduleItem.fromJson(Map<String, dynamic> j) => RaceScheduleItem(
        time: j['time'] ?? '',
        stage: j['stage'] ?? '',
        detail: j['detail'] ?? '',
      );
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String club;
  LeaderboardEntry({this.rank = 0, this.name = '', this.club = ''});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: (j['rank'] is int) ? j['rank'] : int.tryParse('${j['rank']}') ?? 0,
        name: j['name'] ?? '',
        club: j['club'] ?? '',
      );
}

class Race {
  final String id;
  final String name;
  final String category;
  final String date;
  final String status; // upcoming / ongoing / ended
  final String signupStart;
  final String fee;
  final String rules;
  final String sponsor;
  final String ads;
  final List<RaceScheduleItem> schedule;
  final List<LeaderboardEntry> leaderboard;
  final String leaderboardTitle;

  Race({
    required this.id,
    this.name = '',
    this.category = '',
    this.date = '',
    this.status = '',
    this.signupStart = '',
    this.fee = '',
    this.rules = '',
    this.sponsor = '',
    this.ads = '',
    this.schedule = const [],
    this.leaderboard = const [],
    this.leaderboardTitle = '',
  });

  factory Race.fromJson(Map<String, dynamic> j) => Race(
        id: (j['id'] ?? '').toString(),
        name: j['name'] ?? '',
        category: j['category'] ?? '',
        date: j['date'] ?? '',
        status: j['status'] ?? '',
        signupStart: j['signupStart'] ?? '',
        fee: j['fee'] ?? '',
        rules: j['rules'] ?? '',
        sponsor: j['sponsor'] ?? '',
        ads: j['ads'] ?? '',
        schedule: (j['schedule'] as List? ?? []).map((e) => RaceScheduleItem.fromJson(e)).toList(),
        leaderboard: (j['leaderboard'] as List? ?? []).map((e) => LeaderboardEntry.fromJson(e)).toList(),
        leaderboardTitle: j['leaderboardTitle'] ?? '',
      );

  String get statusText {
    switch (status) {
      case 'upcoming': return '即将开始';
      case 'ongoing': return '进行中';
      case 'ended': return '已结束';
      default: return '';
    }
  }
}

class Partner {
  final String id;
  final String name;
  final String link;
  final String logo; // 相对路径，如 /img/partners/carousel_xxx.webp
  final String desc;
  Partner({required this.id, required this.name, this.link = '', this.logo = '', this.desc = ''});

  factory Partner.fromJson(Map<String, dynamic> j) => Partner(
        id: (j['id'] ?? '').toString(),
        name: j['name'] ?? '',
        link: j['link'] ?? '',
        logo: j['logo'] ?? '',
        desc: j['desc'] ?? '',
      );
}

class CommunityPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final String cover;
  final DateTime? createdAt;
  CommunityPost({required this.id, this.title = '', this.content = '', this.author = '', this.cover = '', this.createdAt});

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id: (j['id'] ?? '').toString(),
        title: j['title'] ?? '',
        content: j['content'] ?? '',
        author: j['author'] ?? '飞手',
        cover: j['cover'] ?? '',
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );

  String get displayTitle => title.isNotEmpty ? title : content;
}

class UserProfile {
  final String nickname;
  final String id91;
  final bool isAdmin;
  UserProfile({this.nickname = '', this.id91 = '', this.isAdmin = false});

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        nickname: j['nickname'] ?? '',
        id91: (j['id91'] ?? '').toString(),
        isAdmin: j['isAdmin'] == true,
      );
}

/// 远程更新信息（/api/yzbjfpv-app-version）
class AppUpdateInfo {
  final String version;
  final bool force;
  final String deadline;
  final String changelog;
  final Map<String, String> downloads;
  AppUpdateInfo({required this.version, this.force = false, this.deadline = '', this.changelog = '', this.downloads = const {}});

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) {
    final dl = <String, String>{};
    (j['downloads'] as Map?)?.forEach((k, v) => dl[k.toString()] = v.toString());
    return AppUpdateInfo(
      version: (j['version'] ?? '').toString(),
      force: j['force'] == true,
      deadline: (j['deadline'] ?? '').toString(),
      changelog: (j['changelog'] ?? '').toString(),
      downloads: dl,
    );
  }

  /// 版本比较: 解析V0.0.1.1Beta → [0,0,1,1]，逐位比较
  static List<int> _parse(String v) => (v.replaceAll(RegExp(r'[^0-9.]'), '').split('.')..removeWhere((s) => s.isEmpty))
      .map((s) => int.tryParse(s) ?? 0).toList();

  bool newerThan(String local) {
    final a = _parse(version), b = _parse(local);
    for (var i = 0; i < 4; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// 选择更新已过最晚日期 → 视为强制
  bool get deadlinePassed {
    if (deadline.isEmpty) return false;
    final d = DateTime.tryParse(deadline);
    return d != null && DateTime.now().isAfter(d);
  }

  bool get mustForce => force || deadlinePassed;
}

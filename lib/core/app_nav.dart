import 'package:flutter/foundation.dart';

/// 跨页导航总线：首页各入口跳tab/选中赛事用
class AppNav {
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static final ValueNotifier<String?> raceId = ValueNotifier<String?>(null);
}

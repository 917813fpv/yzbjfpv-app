import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// YZBJFPV 设计系统（白底专业版，与主站Web风格完全一致）
/// - 全平台: 净白画布 + 墨色文字 + 竞速蓝(#0a54f5)单一强调色
/// - iOS: 液态玻璃质感(白色半透明 + BackdropFilter)
/// 注意: accentCyan/accentBlue 为历史命名，值已统一为主站蓝系
class AppTheme {
  // 品牌色（与 public/css/style.css 的CSS变量一一对应）
  static const Color bgPrimary = Color(0xFFFFFFFF);   // --bg
  static const Color bgSecondary = Color(0xFFF5F6F8); // --bg-soft
  static const Color bgCard = Color(0xFFFFFFFF);     // --card
  static const Color accentCyan = Color(0xFF0A54F5); // --blue（主强调色）
  static const Color accentBlue = Color(0xFF0842C8); // --blue-deep
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentOrange = Color(0xFFEA8C00);
  static const Color accentGreen = Color(0xFF0E9F6E);
  static const Color textPrimary = Color(0xFF0B1220);   // --ink
  static const Color textSecondary = Color(0xFF3D4654); // --ink-2
  static const Color textMuted = Color(0xFF8A93A3);     // --ink-3
  static const Color border = Color(0xFFE9ECF1);        // --line

  // Windows桌面演示iOS液态玻璃用: 置环境变量 YZBJFPV_IOS_PREVIEW=1 强制启用
  static bool get isIOS =>
      Platform.isIOS || Platform.environment['YZBJFPV_IOS_PREVIEW'] == '1';

  static ThemeData get theme {
    if (isIOS) {
      // iOS 液态玻璃风格（白底）
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: const ColorScheme.light(
          primary: accentCyan,
          secondary: accentPurple,
          surface: Color(0xCCFFFFFF), // 半透明白色表面
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xF2FFFFFF), // 95%不透明白导航
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 1,
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xCCFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE9ECF1)),
          ),
        ),
        dividerTheme: const DividerThemeData(color: border),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xF5FFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );
    }
    // Android/Windows 白底专业风
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: accentCyan,
        secondary: accentPurple,
        surface: bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1,
        ),
      ),
      cardTheme: const CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
      tabBarTheme: const TabBarThemeData(labelColor: accentCyan),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF0B1220),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}

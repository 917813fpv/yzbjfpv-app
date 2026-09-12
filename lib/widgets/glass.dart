import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 液态玻璃容器 —— iOS端为真实 BackdropFilter 毛玻璃
/// 其他端为白色卡片+浅灰描边+柔和阴影（与主站卡片一致）
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double blurSigma;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.color,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    // iOS 液态玻璃: 半透明表面让 BackdropFilter 真实生效
    if (AppTheme.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            margin: margin,
            decoration: BoxDecoration(
              color: color ?? const Color(0xB3FFFFFF), // 白72%半透明
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: const Color(0x66FFFFFF)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0x2EFFFFFF), // 顶部高光
                  const Color(0x00FFFFFF),
                  const Color(0x14FFFFFF), // 底部微光
                ],
                stops: const [0, 0.55, 1],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x1F0A54F5), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: child,
          ),
        ),
      );
    }
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 玻璃按钮 —— iOS端毛玻璃质感交互按钮，其他端主站蓝
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (AppTheme.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: color ?? const Color(0x99FFFFFF), // 白60%毛玻璃
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: const Color(0x80FFFFFF)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: color ?? AppTheme.accentCyan,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 悬浮液态玻璃底部导航栏（华为质感光效）
/// - BackdropFilter 实时毛玻璃（blur 24）+ 白色85%表面
/// - 顶部1px高光渐变 + 柔和悬浮阴影
/// - 选中项：玻璃发光pill（蓝底12%+蓝描边+蓝光晕）
class FloatingGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingGlassTabBar({super.key, required this.currentIndex, required this.onTap});

  static const _tabs = [
    (Icons.home_rounded, '首页'),
    (Icons.sports_score_rounded, '赛事'),
    (Icons.auto_awesome_rounded, 'AI'),
    (Icons.forum_rounded, '社区'),
    (Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xD9FFFFFF), // 白85%半透明
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0x59FFFFFF)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99FFFFFF), // 顶部高光
                  Color(0x0DFFFFFF),
                  Color(0x14FFFFFF),
                ],
                stops: [0, 0.5, 1],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x26101828), blurRadius: 24, offset: Offset(0, 10)),
                BoxShadow(color: Color(0x330A54F5), blurRadius: 32, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final (icon, label) = _tabs[i];
                final selected = i == currentIndex;
                final isAi = i == 2;
                final color = selected
                    ? (isAi ? AppTheme.accentPurple : AppTheme.accentCyan)
                    : AppTheme.textMuted;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isAi
                                ? AppTheme.accentPurple.withValues(alpha: 0.12)
                                : AppTheme.accentCyan.withValues(alpha: 0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? (isAi
                                  ? AppTheme.accentPurple.withValues(alpha: 0.45)
                                  : AppTheme.accentCyan.withValues(alpha: 0.45))
                              : Colors.transparent,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: (isAi
                                            ? AppTheme.accentPurple
                                            : AppTheme.accentCyan)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3)),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: selected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(height: 3),
                          Text(label, style: TextStyle(
                            color: color, fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

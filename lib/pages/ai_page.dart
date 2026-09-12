import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// FlyAi 智能助手 —— FPV领域问答
class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _ChatMsg {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMsg(this.text, this.isUser) : time = DateTime.now();
}

class _AiPageState extends State<AiPage>
    with AutomaticKeepAliveClientMixin {
  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  final _msgs = <_ChatMsg>[
    _ChatMsg(
        '你好，我是 FlyAi 智能助手，专注 FPV 穿越机领域。'
        '无论是装机调参、飞行技巧还是赛事规则，都可以问我。',
        false),
  ];
  bool _thinking = false;

  static const _quickAsks = [
    '新手入门买什么机子？',
    '5寸机怎么配桨？',
    '竞速赛规则讲解',
    'Betaflight调参技巧',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtl.hasClients) return;
    _scrollCtl.animateTo(
      _scrollCtl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtl.text).trim();
    if (text.isEmpty || _thinking) return;
    _inputCtl.clear();
    setState(() {
      _msgs.add(_ChatMsg(text, true));
      _thinking = true;
    });
    _scrollToBottom();
    final reply = await Api.aiChat(text);
    if (!mounted) return;
    setState(() {
      _msgs.add(_ChatMsg(reply, false));
      _thinking = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(child: _buildMsgList()),
        if (_msgs.length <= 2) _buildQuickAsks(),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMsgList() {
    return ListView.builder(
      controller: _scrollCtl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      itemCount: _msgs.length + (_thinking ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _msgs.length) return _buildThinking();
        final m = _msgs[i];
        return _buildBubble(m);
      },
    );
  }

  Widget _buildBubble(_ChatMsg m) {
    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              _buildAvatar(isUser: false),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                color: isUser
                    ? const Color(0xFFEAF1FF)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.text,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6)),
                    const SizedBox(height: 4),
                    Text(
                      '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(isUser: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: isUser
            ? [AppTheme.accentBlue, AppTheme.accentCyan]
            : [AppTheme.accentPurple, AppTheme.accentBlue]),
        boxShadow: [
          BoxShadow(
              color: (isUser ? AppTheme.accentCyan : AppTheme.accentPurple)
                  .withValues(alpha: 0.4),
              blurRadius: 10),
        ],
      ),
      child: Center(
        child: isUser
            ? const Icon(Icons.flight_takeoff_rounded,
                size: 16, color: Colors.white)
            : const Icon(Icons.auto_awesome_rounded,
                size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildThinking() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 40, bottom: 10),
        child: GlassContainer(
          borderRadius: 14,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(0),
              const SizedBox(width: 4),
              _dot(1),
              const SizedBox(width: 4),
              _dot(2),
              const SizedBox(width: 10),
              const Text('FlyAi 思考中...',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: AppTheme.accentCyan, shape: BoxShape.circle),
        ),
      ),
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildQuickAsks() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickAsks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(_quickAsks[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x147C3AED),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color: AppTheme.accentPurple.withValues(alpha: 0.3)),
            ),
            child: Text(_quickAsks[i],
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.accentPurple)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    // 底部留足空间避开悬浮dock导航栏
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      borderRadius: 100,
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtl,
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: '向 FlyAi 提问 FPV 相关问题...',
                hintStyle:
                    TextStyle(fontSize: 13, color: AppTheme.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.accentCyan, AppTheme.accentBlue]),
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

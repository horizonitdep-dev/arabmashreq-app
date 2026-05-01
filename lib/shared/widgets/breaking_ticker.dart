import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/breaking_news_model.dart';

class BreakingTicker extends StatefulWidget {
  const BreakingTicker({
    super.key,
    required this.items,
    this.compact = false,
    this.onTap,
  });

  final List<BreakingNewsModel> items;
  final bool compact;
  final VoidCallback? onTap;

  @override
  State<BreakingTicker> createState() => _BreakingTickerState();
}

class _BreakingTickerState extends State<BreakingTicker> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant BreakingTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      _index = 0;
      return;
    }
    if (_index >= widget.items.length ||
        oldWidget.items.length != widget.items.length) {
      _index = 0;
    }
  }

  void _onCycleComplete(int itemId) {
    if (!mounted || widget.items.length <= 1) return;
    if (widget.items[_index].id != itemId) return;
    setState(() => _index = (_index + 1) % widget.items.length);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final item = widget.items[_index];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF831A1A), Color(0xFFB32323)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '\u0639\u0627\u062c\u0644',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                builder: (_, value, __) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _TickerMarqueeText(
                    key: ValueKey(item.id),
                    text: item.title,
                    onCycleComplete: () => _onCycleComplete(item.id),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickerMarqueeText extends StatefulWidget {
  const _TickerMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.onCycleComplete,
  });

  final String text;
  final TextStyle style;
  final VoidCallback? onCycleComplete;

  @override
  State<_TickerMarqueeText> createState() => _TickerMarqueeTextState();
}

class _TickerMarqueeTextState extends State<_TickerMarqueeText>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  Timer? _timer;
  bool _isCycling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartCycle());
  }

  @override
  void didUpdateWidget(covariant _TickerMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _restartCycle();
    }
  }

  void _restartCycle() {
    _timer?.cancel();
    _isCycling = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCycle());
  }

  Future<void> _runCycle() async {
    if (!mounted || _isCycling) return;
    if (!_scrollController.hasClients) {
      _timer = Timer(const Duration(milliseconds: 260), _restartCycle);
      return;
    }

    _isCycling = true;

    final maxOffset = _scrollController.position.maxScrollExtent;
    if (maxOffset <= 1) {
      _isCycling = false;
      _timer = Timer(const Duration(milliseconds: 2600), _completeCycle);
      return;
    }

    final durationMs =
        ((maxOffset / 45) * 1000).round().clamp(3600, 12000).toInt();

    // Keep the first words visible before marquee movement starts.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) {
      _isCycling = false;
      return;
    }

    try {
      await _scrollController.animateTo(
        maxOffset,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
    } catch (_) {
      // Ignore scroll cancellation when widget updates/disposes mid-animation.
    } finally {
      _isCycling = false;
    }

    if (!mounted) return;
    _timer = Timer(const Duration(milliseconds: 1700), _completeCycle);
  }

  void _completeCycle() {
    if (!mounted) return;
    widget.onCycleComplete?.call();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ClipRect(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 10),
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.right,
              style: widget.style,
            ),
          ),
        ),
      ),
    );
  }
}

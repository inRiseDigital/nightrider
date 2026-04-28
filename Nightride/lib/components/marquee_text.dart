import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.gap = 22,
    this.pause = const Duration(milliseconds: 550),
    this.speedPxPerSecond = 34,
  });

  final String text;
  final TextStyle style;
  final double gap;
  final Duration pause;
  final double speedPxPerSecond;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final ScrollController _c = ScrollController();
  bool _running = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _startLoop() async {
    if (_running) return;
    _running = true;

    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;

    while (mounted) {
      if (!_c.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final double max = _c.position.maxScrollExtent;
      if (max <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        continue;
      }

      await Future<void>.delayed(widget.pause);
      if (!mounted) break;

      final int ms =
          ((max / widget.speedPxPerSecond) * 1000).clamp(650, 9000).toInt();

      await _c.animateTo(
        max,
        duration: Duration(milliseconds: ms),
        curve: Curves.linear,
      );
      if (!mounted) break;

      await Future<void>.delayed(widget.pause);
      if (!mounted) break;

      _c.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLoop());

    return ClipRect(
      child: SingleChildScrollView(
        controller: _c,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: <Widget>[
            Text(widget.text, style: widget.style, maxLines: 1),
            SizedBox(width: widget.gap),
            Text(widget.text, style: widget.style, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

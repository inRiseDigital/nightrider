import 'package:flutter/material.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Drop-in replacement for RefreshIndicator that adds animated
/// equalizer bars to the right of the spinning circle during refresh.
class NightRiteRefresh extends StatefulWidget {
  const NightRiteRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  State<NightRiteRefresh> createState() => _NightRiteRefreshState();
}

class _NightRiteRefreshState extends State<NightRiteRefresh>
    with TickerProviderStateMixin {
  // One controller per bar — staggered so they feel organic
  late final List<AnimationController> _barCtrls;
  late final List<Animation<double>> _barAnims;

  bool _refreshing = false;

  static const int _barCount = 4;
  static const double _displacement = 56;

  @override
  void initState() {
    super.initState();
    _barCtrls = List.generate(_barCount, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 380 + i * 80),
      );
      return c;
    });

    _barAnims = _barCtrls.map((c) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _barCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _startBars() {
    for (var i = 0; i < _barCount; i++) {
      Future.delayed(Duration(milliseconds: i * 60), () {
        if (mounted && _refreshing) _barCtrls[i].repeat(reverse: true);
      });
    }
  }

  void _stopBars() {
    for (final c in _barCtrls) {
      c.animateTo(0, duration: const Duration(milliseconds: 180));
    }
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _startBars();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _stopBars();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          displacement: _displacement,
          strokeWidth: 2.5,
          onRefresh: _onRefresh,
          child: widget.child,
        ),

        // Equalizer bars — appear to the right of the spinner during refresh
        if (_refreshing)
          Positioned(
            top: _displacement - 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  // Shift right of the spinner (spinner ≈ 40 px wide, gap 10)
                  padding: const EdgeInsets.only(left: 60),
                  child: _EqualizerBars(
                    anims: _barAnims,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Equalizer bars widget ─────────────────────────────────────────────────────

class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars({required this.anims, required this.color});
  final List<Animation<double>> anims;
  final Color color;

  static const double _maxH = 22.0;
  static const double _barW = 3.5;
  static const double _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxH,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(anims.length, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : _gap),
            child: AnimatedBuilder(
              animation: anims[i],
              builder: (_, __) {
                final h = (_maxH * anims[i].value).clamp(4.0, _maxH);
                return Container(
                  width: _barW,
                  height: h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 6,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}


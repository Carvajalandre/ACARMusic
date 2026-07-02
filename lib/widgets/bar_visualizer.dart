import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BarVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color paletteVibrant;
  final Color paletteDominant;
  final Color paletteMuted;
  final int barCount;

  const BarVisualizer({
    super.key,
    required this.isPlaying,
    this.paletteVibrant = AppTheme.primary,
    this.paletteDominant = AppTheme.primary,
    this.paletteMuted = AppTheme.primary,
    this.barCount = 40,
  });

  @override
  State<BarVisualizer> createState() => _BarVisualizerState();
}

class _BarVisualizerState extends State<BarVisualizer> {
  late List<double> _heightsPct; // 0-100
  Timer? _timer;
  double _time = 0;
  final Random _rng = Random();

  static const List<Color> _palette = [
    Color(0xFFC6C6C7),
    Color(0xFFEC7C8A),
    Color(0xFF9F9D9D),
    Color(0xFFFAF9F9),
    Color(0xFFB8B9B9),
  ];

  @override
  void initState() {
    super.initState();
    _heightsPct = List.filled(widget.barCount, 10.0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (!widget.isPlaying) {
        setState(() => _heightsPct = List.filled(widget.barCount, 8.0));
        return;
      }
      _time += 0.5;
      setState(() {
        for (int i = 0; i < widget.barCount; i++) {
          double target;
          if (i < widget.barCount * 0.2) {
            // bass
            target = 40 + sin(_time * 0.8 + i) * 40 + _rng.nextDouble() * 20;
          } else if (i > widget.barCount * 0.7) {
            // highs
            target = 15 + sin(_time * 1.5 + i) * 15 + _rng.nextDouble() * 50;
          } else {
            // mids
            target = 25 + sin(_time * 1.2 + i) * 30 + _rng.nextDouble() * 30;
          }
          _heightsPct[i] = target.clamp(8.0, 100.0);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant BarVisualizer old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) {
      // timer keeps running, checks flag each tick
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _colorFor(int index, double heightPct) {
    if (heightPct > 80) return const Color(0xFFFAF9F9);
    if (heightPct > 50) return _palette[index % _palette.length];
    final opacity = (0.4 + heightPct / 100).clamp(0.0, 1.0);
    return _palette[index % _palette.length].withAlpha((opacity * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 3.0;
      final barWidth =
          (constraints.maxWidth - gap * (widget.barCount - 1)) / widget.barCount;
      final maxH = constraints.maxHeight;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          final h = maxH * (_heightsPct[i] / 100);
          return Padding(
            padding: EdgeInsets.only(right: i == widget.barCount - 1 ? 0 : gap),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              width: barWidth,
              height: max(h, 6.0),
              decoration: BoxDecoration(
                color: _colorFor(i, _heightsPct[i]),
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            ),
          );
        }),
      );
    });
  }
}
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BarVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;
  final Stream<String>? statusStream;
  final Color paletteVibrant;
  final Color paletteDominant;
  final Color paletteMuted;
  final int barCount;

  const BarVisualizer({
    super.key,
    required this.fftStream,
    this.statusStream,
    this.paletteVibrant = AppTheme.primary,
    this.paletteDominant = AppTheme.primary,
    this.paletteMuted = AppTheme.primary,
    this.barCount = 20,
  });

  @override
  State<BarVisualizer> createState() => _BarVisualizerState();
}

class _BarVisualizerState extends State<BarVisualizer> {
  late List<double> _heightsPct;
  StreamSubscription<List<double>>? _sub;

  @override
  void initState() {
    super.initState();
    _heightsPct = List.filled(widget.barCount, 4.0);
    _sub = widget.fftStream.listen(_onData);
  }

  void _onData(List<double> data) {
    if (!mounted || data.isEmpty) return;
    final len = data.length;
    setState(() {
      for (int i = 0; i < widget.barCount; i++) {
        final idx = (i * len / widget.barCount).floor().clamp(0, len - 1);
        final raw = data[idx].clamp(0.0, 1.0);
        _heightsPct[i] = (raw * 100).clamp(4.0, 100.0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BarVisualizer old) {
    super.didUpdateWidget(old);
    if (old.fftStream != widget.fftStream) {
      _sub?.cancel();
      _sub = widget.fftStream.listen(_onData);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Color _colorFor(double heightPct) {
    if (heightPct > 82) return Colors.white;
    if (heightPct > 40) {
      return Color.lerp(widget.paletteVibrant, Colors.white,
          ((heightPct - 40) / 60).clamp(0.0, 0.35))!;
    }
    return widget.paletteVibrant.withAlpha((100 + heightPct * 3).round().clamp(70, 255));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 6.0;
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
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              width: barWidth,
              height: max(h, 4.0),
              decoration: BoxDecoration(
                color: _colorFor(_heightsPct[i]),
                borderRadius: BorderRadius.circular(barWidth / 2),
                boxShadow: _heightsPct[i] > 75
                    ? [BoxShadow(color: _colorFor(_heightsPct[i]).withAlpha(120), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      );
    });
  }
}
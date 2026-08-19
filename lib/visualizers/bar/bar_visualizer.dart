import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
    this.barCount = 32,
  });

  @override
  State<BarVisualizer> createState() => _BarVisualizerState();
}

class _BarVisualizerState extends State<BarVisualizer> {
  late List<double> _levels;
  StreamSubscription<List<double>>? _sub;

  @override
  void initState() {
    super.initState();
    _levels = List.filled(widget.barCount, 0.0);
    _sub = widget.fftStream.listen(_onData);
  }

  @override
  void didUpdateWidget(covariant BarVisualizer old) {
    super.didUpdateWidget(old);
    if (old.barCount != widget.barCount) {
      _levels = List.filled(widget.barCount, 0.0);
    }
    if (old.fftStream != widget.fftStream) {
      _sub?.cancel();
      _sub = widget.fftStream.listen(_onData);
    }
  }

  void _onData(List<double> data) {
    if (!mounted || data.isEmpty) return;
    final mapped = _mapBands(data, widget.barCount);
    var energy = 0.0;
    for (final value in mapped) {
      energy += value;
    }
    energy /= mapped.length;

    setState(() {
      for (var i = 0; i < _levels.length; i++) {
        final target = mapped[i];
        final attack = target > _levels[i] ? 0.86 : 0.52;
        final silenceDecay = energy < 0.025 ? 0.34 : attack;
        _levels[i] += (target - _levels[i]) * silenceDecay;
        if (energy < 0.012) _levels[i] *= 0.35;
        _levels[i] = _levels[i].clamp(0.0, 1.0);
      }
    });
  }

  List<double> _mapBands(List<double> data, int count) {
    final output = List<double>.filled(count, 0.0);
    final last = data.length - 1;
    for (var i = 0; i < count; i++) {
      final startRatio = i / count;
      final endRatio = (i + 1) / count;
      final start = (pow(startRatio, 1.45) * last).floor().clamp(0, last);
      final end = max(start + 1, (pow(endRatio, 1.45) * last).ceil())
          .clamp(1, data.length);
      var peak = 0.0;
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        final weighted = data[j].clamp(0.0, 1.0) * (1.0 + i / count * 0.18);
        peak = max(peak, weighted);
        sum += weighted;
      }
      final avg = sum / (end - start);
      output[i] = (avg * 0.42 + peak * 0.58).clamp(0.0, 1.0);
    }
    return output;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _BarVisualizerPainter(
        levels: _levels,
        paletteVibrant: widget.paletteVibrant,
        paletteDominant: widget.paletteDominant,
        paletteMuted: widget.paletteMuted,
      ),
    );
  }
}

class _BarVisualizerPainter extends CustomPainter {
  final List<double> levels;
  final Color paletteVibrant;
  final Color paletteDominant;
  final Color paletteMuted;

  const _BarVisualizerPainter({
    required this.levels,
    required this.paletteVibrant,
    required this.paletteDominant,
    required this.paletteMuted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.isEmpty) return;
    final gap = (size.width / 120).clamp(2.0, 5.0);
    final barWidth = ((size.width - gap * (levels.length - 1)) / levels.length)
        .clamp(2.0, 14.0);
    final baseline = size.height;

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      final minHeight = size.height * 0.035;
      final height = max(minHeight, level * size.height);
      final left = i * (barWidth + gap) +
          (size.width -
                  (barWidth * levels.length + gap * (levels.length - 1))) /
              2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - height, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      final color = Color.lerp(
        Color.lerp(paletteMuted, paletteDominant, i / levels.length),
        Color.lerp(paletteVibrant, Colors.white, level * 0.25),
        0.45 + level * 0.45,
      )!;
      final paint = Paint()
        ..color = color.withAlpha((135 + level * 120).round().clamp(90, 255));
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarVisualizerPainter oldDelegate) => true;
}

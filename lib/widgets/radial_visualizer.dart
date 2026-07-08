import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RadialVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;
  final Color glowColor;

  const RadialVisualizer({
    super.key,
    required this.fftStream,
    this.glowColor = AppTheme.primary,
  });

  @override
  State<RadialVisualizer> createState() => _RadialVisualizerState();
}

class _RadialVisualizerState extends State<RadialVisualizer>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 96;

  final List<double> _levels = List.filled(_barCount, 0.0);
  final List<double> _targets = List.filled(_barCount, 0.0);
  StreamSubscription<List<double>>? _subscription;
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_tick)
      ..repeat();
    _subscription = widget.fftStream.listen(_processFftData);
  }

  @override
  void didUpdateWidget(covariant RadialVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fftStream != widget.fftStream) {
      _subscription?.cancel();
      _subscription = widget.fftStream.listen(_processFftData);
    }
  }

  void _processFftData(List<double> data) {
    if (data.isEmpty) return;
    final mapped = _mapBands(data, _barCount);
    for (var i = 0; i < _barCount; i++) {
      _targets[i] = mapped[i];
    }
  }

  List<double> _mapBands(List<double> data, int count) {
    final output = List<double>.filled(count, 0.0);
    final last = data.length - 1;
    for (var i = 0; i < count; i++) {
      final startRatio = i / count;
      final endRatio = (i + 1) / count;
      final start = (pow(startRatio, 1.35) * last).floor().clamp(0, last);
      final end = max(start + 1, (pow(endRatio, 1.35) * last).ceil())
          .clamp(1, data.length);
      var peak = 0.0;
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        final value = data[j].clamp(0.0, 1.0);
        peak = max(peak, value);
        sum += value;
      }
      final avg = sum / (end - start);
      final emphasis = i < count * 0.18
          ? 1.08
          : i > count * 0.72
              ? 0.92
              : 1.0;
      output[i] = ((peak * 0.65 + avg * 0.35) * emphasis).clamp(0.0, 1.0);
    }
    return output;
  }

  void _tick() {
    if (!mounted) return;
    var energy = 0.0;
    for (final target in _targets) {
      energy += target;
    }
    energy /= _targets.length;

    var changed = false;
    for (var i = 0; i < _barCount; i++) {
      final target = _targets[i];
      final speed = target > _levels[i] ? 0.34 : (energy < 0.02 ? 0.24 : 0.14);
      final next = (_levels[i] + (target - _levels[i]) * speed).clamp(0.0, 1.0);
      if ((next - _levels[i]).abs() > 0.001) changed = true;
      _levels[i] = energy < 0.01 ? next * 0.58 : next;
    }
    if (changed) setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RadialPainter(levels: _levels),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final List<double> levels;

  const _RadialPainter({required this.levels});

  static const List<Color> _spectrum = [
    Color(0xFFFF2BD6),
    Color(0xFFFF2B6A),
    Color(0xFFFFB000),
    Color(0xFFA8FF2A),
    Color(0xFF24F85A),
    Color(0xFF12F2D0),
    Color(0xFF2388FF),
    Color(0xFFFF2BD6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.isEmpty) return;

    final shortest = min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = shortest * 0.22;
    final maxBarLength = shortest * 0.27;
    final barCount = levels.length;
    final strokeWidth = (shortest / 105).clamp(2.0, 4.5);

    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * pi - pi / 2;
      final level = levels[i].clamp(0.0, 1.0);
      final color = _colorAt(i / barCount);
      final length = maxBarLength * (0.06 + level * 0.94);
      final start = Offset(
        center.dx + cos(angle) * innerRadius,
        center.dy + sin(angle) * innerRadius,
      );
      final end = Offset(
        center.dx + cos(angle) * (innerRadius + length),
        center.dy + sin(angle) * (innerRadius + length),
      );
      final opacity = (0.32 + level * 0.68).clamp(0.0, 1.0);

      if (level > 0.12) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = color.withAlpha((85 * opacity).round())
            ..strokeWidth = strokeWidth * 4.2
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }

      canvas.drawLine(
        start,
        end,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withAlpha((80 * opacity).round()),
              color.withAlpha((255 * opacity).round()),
            ],
          ).createShader(Rect.fromPoints(start, end))
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      if (level > 0.72) {
        canvas.drawCircle(
          end,
          strokeWidth * 0.78,
          Paint()..color = color.withAlpha((220 * opacity).round()),
        );
      }
    }
  }

  Color _colorAt(double t) {
    final scaled = t * (_spectrum.length - 1);
    final index = scaled.floor().clamp(0, _spectrum.length - 2);
    return Color.lerp(
      _spectrum[index],
      _spectrum[index + 1],
      scaled - index,
    )!;
  }

  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) => true;
}

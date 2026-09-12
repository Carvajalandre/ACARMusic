import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class BarVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;

  const BarVisualizer({
    super.key,
    required this.fftStream,
  });

  @override
  State<BarVisualizer> createState() => _BarVisualizerState();
}

class _BarVisualizerState extends State<BarVisualizer> {
  static const int _columnCount = 18;

  final List<double> _levels = List.filled(_columnCount, 0.0);
  final List<double> _targets = List.filled(_columnCount, 0.0);
  StreamSubscription<List<double>>? _subscription;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
    _subscription = widget.fftStream.listen(_processFftData);
  }

  @override
  void didUpdateWidget(covariant BarVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fftStream != widget.fftStream) {
      _subscription?.cancel();
      _subscription = widget.fftStream.listen(_processFftData);
    }
  }

  void _processFftData(List<double> data) {
    if (data.isEmpty) return;
    final mapped = _mapBands(data, _columnCount);

    var energy = 0.0;
    for (final value in mapped) {
      energy += value;
    }
    energy /= mapped.length;

    for (var i = 0; i < _columnCount; i++) {
      _targets[i] = energy;
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
      final shaped = pow((peak * 0.6 + avg * 0.4).clamp(0.0, 1.0), 0.5);
      output[i] = (shaped * 2.2).clamp(0.0, 1.0).toDouble();
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
    for (var i = 0; i < _columnCount; i++) {
      final target = _targets[i];
      final speed =
          target > _levels[i] ? 0.72 : (energy < 0.02 ? 0.55 : 0.38);
      final next =
          (_levels[i] + (target - _levels[i]) * speed).clamp(0.0, 1.0);
      if ((next - _levels[i]).abs() > 0.001) changed = true;
      _levels[i] = energy < 0.01 ? next * 0.65 : next;
    }
    if (changed) setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridBarPainter(levels: _levels),
    );
  }
}

class _GridBarPainter extends CustomPainter {
  final List<double> levels;

  static const int _maxBlocks = 10;

  const _GridBarPainter({required this.levels});

  static const List<Color> _gradient = [
    Color(0xFF22C55E),
    Color(0xFF65C73E),
    Color(0xFFA3E028),
    Color(0xFFD4E020),
    Color(0xFFF5D619),
    Color(0xFFF5B815),
    Color(0xFFF09A10),
    Color(0xFFEB7C0B),
    Color(0xFFE55E06),
    Color(0xFFE04002),
    Color(0xFFDB2200),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.isEmpty) return;

    final gap = (size.width / 180).clamp(2.0, 5.0);
    final blockW =
        ((size.width - gap * (levels.length - 1)) / levels.length)
            .clamp(4.0, 24.0);
    final blockH = blockW;
    final totalH = size.height * 0.82;
    final baseline = totalH;

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      final activeBlocks = (level * _maxBlocks).ceil().clamp(0, _maxBlocks);
      final left = i * (blockW + gap) +
          (size.width - (blockW * levels.length + gap * (levels.length - 1))) /
              2;

      for (var b = 0; b < activeBlocks; b++) {
        final t = b / (_maxBlocks - 1);
        final color = _colorAt(t);
        final top = baseline - (b + 1) * (blockH + gap * 0.6);
        final opacity = (0.45 + level * 0.55).clamp(0.0, 1.0);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, blockW, blockH),
          Radius.circular(blockW * 0.18),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = color.withAlpha((opacity * 255).round()),
        );
      }

      if (activeBlocks > 0) {
        final topT = (activeBlocks - 1) / (_maxBlocks - 1);
        final topColor = _colorAt(topT);
        final top = baseline - activeBlocks * (blockH + gap * 0.6);
        final glowOpacity = (level * 0.45).clamp(0.0, 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left - 1, top - 1, blockW + 2, blockH + 2),
            Radius.circular(blockW * 0.22),
          ),
          Paint()
            ..color = topColor.withAlpha((glowOpacity * 255).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      if (activeBlocks > 0) {
        final reflectBase = baseline + gap * 2;
        for (var b = 0; b < activeBlocks && b < 4; b++) {
          final t = b / (_maxBlocks - 1);
          final color = _colorAt(t);
          final top = reflectBase + b * (blockH + gap * 0.6);
          final opacity = (0.18 - b * 0.04).clamp(0.0, 0.18);
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, blockW, blockH),
            Radius.circular(blockW * 0.18),
          );
          canvas.drawRRect(
            rect,
            Paint()..color = color.withAlpha((opacity * 255).round()),
          );
        }
      }
    }
  }

  Color _colorAt(double t) {
    final scaled = t * (_gradient.length - 1);
    final index = scaled.floor().clamp(0, _gradient.length - 2);
    return Color.lerp(
      _gradient[index],
      _gradient[index + 1],
      scaled - index,
    )!;
  }

  @override
  bool shouldRepaint(covariant _GridBarPainter oldDelegate) => true;
}

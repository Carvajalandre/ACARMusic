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
  final List<double> _levels = List.filled(64, 0.0);
  final List<double> _targetLevels = List.filled(64, 0.0);
  StreamSubscription<List<double>>? _subscription;
  late AnimationController _animationCtrl;
  final Random _random = Random();

  static const int _barCount = 64;

  @override
  void initState() {
    super.initState();
    _animationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _subscription = widget.fftStream.listen((data) {
      if (!mounted) return;
      _processFFTData(data);
    });
  }

  void _processFFTData(List<double> data) {
    final int dataLen = data.length;
    if (dataLen == 0) return;

    setState(() {
      for (int i = 0; i < _barCount; i++) {
        final double freqRatio = i / _barCount;
        int dataIndex;

        if (freqRatio < 0.2) {
          dataIndex = (freqRatio * 5 * dataLen).floor().clamp(0, dataLen - 1);
        } else if (freqRatio < 0.7) {
          dataIndex = ((freqRatio - 0.2) / 0.5 * 0.6 * dataLen + 0.2 * dataLen).floor().clamp(0, dataLen - 1);
        } else {
          dataIndex = ((freqRatio - 0.7) / 0.3 * 0.2 * dataLen + 0.8 * dataLen).floor().clamp(0, dataLen - 1);
        }

        final double rawValue = data[dataIndex].clamp(0.0, 1.0);
        double targetLevel;

        if (freqRatio < 0.2) {
          targetLevel = 0.15 + sin(_animationCtrl.value * 2 * pi * 0.8) * 0.12 + _random.nextDouble() * 0.15;
          targetLevel = (targetLevel * 0.6 + rawValue * 0.4).clamp(0.05, 1.0);
        } else if (freqRatio > 0.7) {
          targetLevel = 0.05 + sin(_animationCtrl.value * 2 * pi * 1.5) * 0.05 + _random.nextDouble() * 0.35;
          targetLevel = (targetLevel * 0.4 + rawValue * 0.6).clamp(0.05, 1.0);
        } else {
          targetLevel = 0.1 + sin(_animationCtrl.value * 2 * pi * 1.2) * 0.1 + _random.nextDouble() * 0.25;
          targetLevel = (targetLevel * 0.5 + rawValue * 0.5).clamp(0.05, 1.0);
        }

        _targetLevels[i] = targetLevel;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationCtrl,
      builder: (context, child) {
        for (int i = 0; i < _barCount; i++) {
          final diff = _targetLevels[i] - _levels[i];
          _levels[i] += diff * 0.15;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _RadialPainter(
            levels: _levels,
            glowColor: widget.glowColor,
            animationValue: _animationCtrl.value,
          ),
        );
      },
    );
  }
}

class _RadialPainter extends CustomPainter {
  final List<double> levels;
  final Color glowColor;
  final double animationValue;

  static const int _barCount = 64;
  static const double _centerRadius = 50.0;
  static const double _maxBarLength = 40.0;

  _RadialPainter({
    required this.levels,
    required this.glowColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < _barCount; i++) {
      final angle = (i / _barCount) * 2 * pi - pi / 2;
      final level = levels[i].clamp(0.0, 1.0);

      final isCyanZone = angle > -pi * 0.8 && angle < pi * 0.8;
      final barColor = isCyanZone ? const Color(0xFF00F2FF) : const Color(0xFFFF00FF);
      final glowColor = isCyanZone ? const Color(0xFF00F2FF) : const Color(0xFFFF00FF);

      final barLength = _centerRadius + level * _maxBarLength;
      final innerRadius = _centerRadius - 2;

      final x1 = center.dx + cos(angle) * innerRadius;
      final y1 = center.dy + sin(angle) * innerRadius;
      final x2 = center.dx + cos(angle) * barLength;
      final y2 = center.dy + sin(angle) * barLength;

      final paint = Paint()
        ..color = barColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = glowColor
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      final opacity = 0.4 + level * 0.6;
      paint.color = paint.color.withAlpha((255 * opacity).round());
      glowPaint.color = glowPaint.color.withAlpha((180 * opacity).round());

      if (level > 0.3) {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

      if (level > 0.7) {
        final dotPaint = Paint()
          ..color = barColor.withAlpha((200 * opacity).round())
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x2, y2), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RadialPainter old) => true;
}
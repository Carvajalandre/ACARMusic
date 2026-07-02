import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;
  final Color lineColor;

  const ModernVisualizer({
    super.key,
    required this.fftStream,
    this.lineColor = AppTheme.tertiary,
  });

  @override
  State<ModernVisualizer> createState() => _ModernVisualizerState();
}

class _ModernVisualizerState extends State<ModernVisualizer>
    with SingleTickerProviderStateMixin {
  final List<double> _levels = List.filled(64, 0.0);
  final List<double> _targetLevels = List.filled(64, 0.0);
  StreamSubscription<List<double>>? _subscription;
  late AnimationController _animationCtrl;
  late AnimationController _pulseCtrl;
  final Random _random = Random();

  static const int _pointCount = 64;

  @override
  void initState() {
    super.initState();
    _animationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _subscription = widget.fftStream.listen((data) {
      if (!mounted) return;
      _processFFTData(data);
    });
  }

  void _processFFTData(List<double> data) {
    final int dataLen = data.length;
    if (dataLen == 0) return;

    setState(() {
      for (int i = 0; i < _pointCount; i++) {
        final double freqRatio = i / _pointCount;
        int dataIndex;

        if (freqRatio < 0.15) {
          dataIndex = (freqRatio * 6.67 * dataLen).floor().clamp(0, dataLen - 1);
        } else if (freqRatio < 0.65) {
          dataIndex = ((freqRatio - 0.15) / 0.5 * 0.7 * dataLen + 0.15 * dataLen).floor().clamp(0, dataLen - 1);
        } else {
          dataIndex = ((freqRatio - 0.65) / 0.35 * 0.15 * dataLen + 0.85 * dataLen).floor().clamp(0, dataLen - 1);
        }

        final double rawValue = data[dataIndex].clamp(0.0, 1.0);
        double targetLevel;

        if (freqRatio < 0.15) {
          targetLevel = 0.25 + sin(_animationCtrl.value * 2 * pi * 0.6) * 0.2 + _random.nextDouble() * 0.15;
          targetLevel = (targetLevel * 0.5 + rawValue * 0.5).clamp(0.05, 1.0);
        } else if (freqRatio > 0.65) {
          targetLevel = 0.05 + sin(_animationCtrl.value * 2 * pi * 1.8) * 0.05 + _random.nextDouble() * 0.3;
          targetLevel = (targetLevel * 0.4 + rawValue * 0.6).clamp(0.05, 1.0);
        } else {
          targetLevel = 0.15 + sin(_animationCtrl.value * 2 * pi * 1.0) * 0.12 + _random.nextDouble() * 0.2;
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
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animationCtrl, _pulseCtrl]),
      builder: (context, child) {
        for (int i = 0; i < _pointCount; i++) {
          final diff = _targetLevels[i] - _levels[i];
          _levels[i] += diff * 0.12;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _ModernPainter(
            levels: _levels,
            lineColor: widget.lineColor,
            pulse: _pulseCtrl.value,
          ),
        );
      },
    );
  }
}

class _ModernPainter extends CustomPainter {
  final List<double> levels;
  final Color lineColor;
  final double pulse;

  _ModernPainter({
    required this.levels,
    required this.lineColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = levels.length;
    if (n < 2) return;

    final stepX = size.width / (n - 1);
    final midY = size.height / 2;
    final maxAmplitude = size.height * 0.35;

    final path = Path();
    final cyanColor = const Color(0xFF00F2FF);
    final magentaColor = const Color(0xFFFF00FF);

    path.moveTo(0, midY);

    for (int i = 0; i < n; i++) {
      final x = i * stepX;
      final baseAmplitude = levels[i] * maxAmplitude * (0.8 + 0.25 * pulse);
      final y = midY - baseAmplitude;
      path.lineTo(x, y);
    }

    final lastX = (n - 1) * stepX;
    path.lineTo(lastX, midY);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shader = LinearGradient(
      colors: [
        cyanColor.withAlpha(200),
        Color.lerp(cyanColor, magentaColor, 0.5)!.withAlpha(220),
        magentaColor.withAlpha(200),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    linePaint.shader = shader;

    canvas.drawPath(path, linePaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glowPaint);

    final fillPath = Path.from(path);
    fillPath.lineTo(lastX, midY);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cyanColor.withAlpha(40),
          magentaColor.withAlpha(20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final centerGlowPaint = Paint()
      ..color = Color.lerp(cyanColor, magentaColor, pulse)!.withAlpha(60)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(Offset(size.width / 2, midY), 30 * (0.5 + 0.3 * pulse), centerGlowPaint);
  }

  @override
  bool shouldRepaint(_ModernPainter old) => true;
}
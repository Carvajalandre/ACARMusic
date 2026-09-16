import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class VoidVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;
  final Color glowColor;
  final int? albumId;

  const VoidVisualizer({
    super.key,
    required this.fftStream,
    this.glowColor = Colors.purple,
    this.albumId,
  });

  @override
  State<VoidVisualizer> createState() => _VoidVisualizerState();
}

class _VoidVisualizerState extends State<VoidVisualizer> {
  static const int _barCount = 64;

  final List<double> _levels = List.filled(_barCount, 0.0);
  final List<double> _targets = List.filled(_barCount, 0.0);
  StreamSubscription<List<double>>? _subscription;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
    _subscription = widget.fftStream.listen(_processFftData);
  }

  @override
  void didUpdateWidget(covariant VoidVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fftStream != widget.fftStream) {
      _subscription?.cancel();
      _subscription = widget.fftStream.listen(_processFftData);
    }
  }

  void _processFftData(List<double> data) {
    if (data.isEmpty) return;
    final rightIndices = <int>[
      for (var i = 0; i < _barCount; i++)
        if (cos(_angleForIndex(i)) >= -0.001) i,
    ];
    final mapped = _mapBands(data, rightIndices.length);
    for (var i = 0; i < _barCount; i++) {
      _targets[i] = 0.0;
    }
    for (var i = 0; i < rightIndices.length; i++) {
      final rightIndex = rightIndices[i];
      final mirroredIndex = (_barCount - rightIndex) % _barCount;
      final value = mapped[i];
      _targets[rightIndex] = value;
      _targets[mirroredIndex] = value;
    }
  }

  double _angleForIndex(int index) => (index / _barCount) * 2 * pi - pi / 2;

  List<double> _mapBands(List<double> data, int count) {
    final output = List<double>.filled(count, 0.0);
    final last = data.length - 1;
    for (var i = 0; i < count; i++) {
      final startRatio = i / count;
      final endRatio = (i + 1) / count;
      final start = (pow(startRatio, 1.5) * last).floor().clamp(0, last);
      final end = max(start + 1, (pow(endRatio, 1.5) * last).ceil())
          .clamp(1, data.length);
      var peak = 0.0;
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        final value = data[j].clamp(0.0, 1.0);
        peak = max(peak, value);
        sum += value;
      }
      final avg = sum / (end - start);
      final shaped = pow((peak * 0.7 + avg * 0.3).clamp(0.0, 1.0), 0.7);
      output[i] = (shaped * 1.2).clamp(0.0, 1.0).toDouble();
    }
    return output;
  }

  void _tick() {
    if (!mounted) return;
    for (var i = 0; i < _barCount; i++) {
      final target = _targets[i];
      final speed = target > _levels[i] ? 0.6 : 0.3;
      final next = (_levels[i] + (target - _levels[i]) * speed).clamp(0.0, 1.0);
      if ((next - _levels[i]).abs() > 0.001) setState(() {});
      _levels[i] = next;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final innerArtworkSize = side * 0.3;
        return CustomPaint(
          size: Size.infinite,
          painter: _VoidPainter(levels: _levels, glowColor: widget.glowColor),
          child: Center(
            child: ClipOval(
              child: SizedBox(
                width: innerArtworkSize,
                height: innerArtworkSize,
                child: widget.albumId != null
                    ? QueryArtworkWidget(
                        id: widget.albumId!,
                        type: ArtworkType.ALBUM,
                        size: 512,
                        quality: 100,
                        artworkFit: BoxFit.cover,
                        artworkWidth: innerArtworkSize,
                        artworkHeight: innerArtworkSize,
                        artworkQuality: FilterQuality.high,
                        keepOldArtwork: true,
                        nullArtworkWidget: _defaultArtwork(),
                      )
                    : _defaultArtwork(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _defaultArtwork() => Container(
        color: const Color(0xFF0A0A0A),
        alignment: Alignment.center,
        child: const Icon(Icons.star_rounded, color: Colors.white38, size: 28),
      );
}

class _VoidPainter extends CustomPainter {
  final List<double> levels;
  final Color glowColor;

  _VoidPainter({required this.levels, required this.glowColor});

  static const List<Color> _colors = [
    Color(0xFFFF2BD6),
    Color(0xFFFF6B6B),
    Color(0xFF4EC0CA),
    Color(0xFF88D3CE),
    Color(0xFFF8C471),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.isEmpty) return;

    final shortest = min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = shortest * 0.2;
    final maxBarLength = shortest * 0.28;
    final barCount = levels.length;
    final strokeWidth = (shortest / 90).clamp(1.5, 3.5);

    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * pi - pi / 2;
      final level = levels[i].clamp(0.0, 1.0);
      final colorIndex =
          (level * (_colors.length - 1)).floor().clamp(0, _colors.length - 2);
      final color = Color.lerp(_colors[colorIndex], _colors[colorIndex + 1],
          level * (_colors.length - 1) - colorIndex)!;
      final length = maxBarLength * (0.08 + level * 0.92);
      final start = Offset(
        center.dx + cos(angle) * innerRadius,
        center.dy + sin(angle) * innerRadius,
      );
      final end = Offset(
        center.dx + cos(angle) * (innerRadius + length),
        center.dy + sin(angle) * (innerRadius + length),
      );
      final opacity = (0.2 + level * 0.8).clamp(0.0, 1.0);

      final glow = Paint()
        ..color = glowColor.withAlpha((180 * opacity).round())
        ..strokeWidth = strokeWidth * 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, glow);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withAlpha((200 * opacity).round())
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      if (level > 0.6) {
        canvas.drawCircle(
          end,
          strokeWidth * 0.5,
          Paint()..color = color.withAlpha((150 * opacity).round()),
        );
      }
    }

    final ringPaint = Paint()
      ..color = glowColor.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.02;
    canvas.drawCircle(center, shortest * 0.32, ringPaint);
    final centerPaint = Paint()..color = glowColor.withAlpha(30);
    canvas.drawCircle(center, shortest * 0.15, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _VoidPainter oldDelegate) => true;
}

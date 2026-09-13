import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class CassetteVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color dominantColor;
  final Color mutedColor;
  final Uint8List? artworkBytes;

  const CassetteVisualizer({
    super.key,
    required this.isPlaying,
    required this.size,
    required this.dominantColor,
    required this.mutedColor,
    this.artworkBytes,
  });

  @override
  State<CassetteVisualizer> createState() => _CassetteVisualizerState();
}

class _CassetteVisualizerState extends State<CassetteVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant CassetteVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _CassettePainter(
                    reelRotation: _controller.value * math.pi * 2,
                    dominantColor: widget.dominantColor,
                    mutedColor: widget.mutedColor,
                  ),
                ),
              ),
            ),
            Positioned(
              left: widget.size * .45,
              top: widget.size * .675,
              child: _ArtworkBadge(
                bytes: widget.artworkBytes,
                size: widget.size * .105,
                color: widget.dominantColor,
              ),
            ),
          ],
        ),
      );
}

class _ArtworkBadge extends StatelessWidget {
  final Uint8List? bytes;
  final double size;
  final Color color;

  const _ArtworkBadge({this.bytes, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final child = bytes == null
        ? Icon(Icons.music_note_rounded, color: Colors.white, size: size * .62)
        : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * .12),
        border: Border.all(color: Colors.black26, width: 1),
      ),
      child: child,
    );
  }
}

class _CassettePainter extends CustomPainter {
  final double reelRotation;
  final Color dominantColor;
  final Color mutedColor;

  const _CassettePainter({
    required this.reelRotation,
    required this.dominantColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyRect = Rect.fromLTWH(w * .04, h * .16, w * .92, h * .68);
    final cassette = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * .055),
    );

    final bodyPath = Path()..addRRect(cassette);
    canvas.drawShadow(bodyPath, Colors.black.withAlpha(210), w * .05, true);
    canvas.drawRRect(
      cassette,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E3DF), Color(0xFFB8BEBC), Color(0xFF727A79)],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      cassette,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .010
        ..color = const Color(0xFF5B5F68),
    );

    // Relieve plástico superior y brillo diagonal del cuerpo.
    canvas.save();
    canvas.clipPath(bodyPath);
    final texture = Paint()..color = Colors.white.withAlpha(13);
    for (var i = 0; i < 34; i++) {
      final x = w * .07 + i * w * .026;
      canvas.drawLine(
          Offset(x, h * .19), Offset(x - w * .10, h * .35), texture);
    }
    final shine = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withAlpha(30), Colors.transparent],
      ).createShader(Rect.fromLTWH(w * .08, h * .18, w * .82, h * .20));
    canvas.drawRect(Rect.fromLTWH(w * .08, h * .18, w * .82, h * .20), shine);
    canvas.restore();

    // Frente inferior negro, como en la carcasa de referencia.
    canvas.save();
    canvas.clipPath(bodyPath);
    canvas.drawRect(
      Rect.fromLTWH(w * .06, h * .62, w * .88, h * .22),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF30353A), Color(0xFF101216)],
        ).createShader(Rect.fromLTWH(w * .06, h * .62, w * .88, h * .22)),
    );
    canvas.restore();

    final label = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .10, h * .25, w * .80, h * .38),
      Radius.circular(w * .018),
    );
    canvas.drawRRect(
      label,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEF5), Color(0xFFD5D5D0)],
        ).createShader(label.outerRect),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .10, h * .25, w * .80, h * .035),
      Paint()..color = const Color(0xFFE34242),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .10, h * .285, w * .80, h * .008),
      Paint()..color = const Color(0xFF9D2028),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .10, h * .57, w * .80, h * .06),
      Paint()..color = dominantColor.withAlpha(210),
    );

    // Compartimento negro donde se alojan los carretes y la cinta.
    final reelBay = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .205, h * .365, w * .59, h * .23),
      Radius.circular(w * .018),
    );
    canvas.drawRRect(reelBay, Paint()..color = const Color(0xFF111317));
    canvas.drawRRect(
      reelBay,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .009
        ..color = const Color(0xFF363A40),
    );

    final reelY = h * .47;
    _drawReel(canvas, Offset(w * .30, reelY), w * .105);
    _drawReel(canvas, Offset(w * .70, reelY), w * .105);

    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .43, h * .395, w * .14, h * .14),
      Radius.circular(w * .012),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFF252B30));
    canvas.drawRect(
      Rect.fromLTWH(w * .455, h * .405, w * .09, h * .12),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF59483A), Color(0xFF1E1B1A)],
        ).createShader(Rect.fromLTWH(w * .455, h * .405, w * .09, h * .12)),
    );
    for (var i = 0; i < 7; i++) {
      final x = w * .465 + i * w * .012;
      canvas.drawLine(
        Offset(x, h * .425),
        Offset(x, h * .505),
        Paint()
          ..color = Colors.white.withAlpha(125)
          ..strokeWidth = w * .004,
      );
    }
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .008
        ..color = const Color(0xFF6B7077),
    );

    // Banda inferior con marcas de posición y cuatro tornillos visibles.
    for (var i = 0; i < 31; i++) {
      final x = w * .12 + i * w * .025;
      canvas.drawRect(
        Rect.fromLTWH(x, h * .595, w * .010, h * .025),
        Paint()..color = Colors.white.withAlpha(i.isEven ? 105 : 65),
      );
    }
    final screwPaint = Paint()..color = const Color(0xFF0B0D10);
    for (final point in [
      Offset(w * .19, h * .735),
      Offset(w * .38, h * .755),
      Offset(w * .62, h * .755),
      Offset(w * .81, h * .735),
    ]) {
      canvas.drawCircle(point, w * .020, screwPaint);
      canvas.drawCircle(
          point, w * .009, Paint()..color = const Color(0xFF3D4249));
    }

    // Muescas inferiores características de un cassette compacto.
    for (final x in [w * .31, w * .50, w * .69]) {
      final notch = Path()
        ..moveTo(x - w * .035, h * .835)
        ..lineTo(x + w * .035, h * .835)
        ..lineTo(x + w * .022, h * .805)
        ..lineTo(x - w * .022, h * .805)
        ..close();
      canvas.drawPath(notch, Paint()..color = const Color(0xFF080A0D));
    }

    _drawText(canvas, 'A', Offset(w * .14, h * .285), w * .065, FontWeight.w900,
        Colors.white);
    _drawText(canvas, 'UR 90', Offset(w * .75, h * .285), w * .035,
        FontWeight.w800, const Color(0xFF25262A));
    _drawText(canvas, 'POSITION  •  NORMAL', Offset(w * .35, h * .595),
        w * .024, FontWeight.w700, Colors.white.withAlpha(220));
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize,
      FontWeight weight, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(7.0, 22.0),
          fontWeight: weight,
          letterSpacing: .4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawReel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
        center, radius * 1.08, Paint()..color = const Color(0xFF080A0D));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12;
      final tooth = Offset(
        center.dx + math.cos(a) * radius * 1.03,
        center.dy + math.sin(a) * radius * 1.03,
      );
      canvas.drawCircle(
          tooth, radius * .075, Paint()..color = const Color(0xFF96999A));
    }
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFD6D8D4));
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .20
        ..color = const Color(0xFF62666A),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(reelRotation);
    final spoke = Paint()
      ..color = const Color(0xFF3A3D40)
      ..strokeWidth = radius * .12
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3;
      canvas.drawLine(
        Offset(math.cos(angle) * radius * .16, math.sin(angle) * radius * .16),
        Offset(math.cos(angle) * radius * .58, math.sin(angle) * radius * .58),
        spoke,
      );
    }
    canvas.restore();
    canvas.drawCircle(
        center, radius * .14, Paint()..color = const Color(0xFFE6E7E2));
  }

  @override
  bool shouldRepaint(covariant _CassettePainter oldDelegate) =>
      oldDelegate.reelRotation != reelRotation ||
      oldDelegate.dominantColor != dominantColor ||
      oldDelegate.mutedColor != mutedColor;
}

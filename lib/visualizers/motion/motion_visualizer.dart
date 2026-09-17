import 'dart:math';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// A fluid, player-shaped visualizer. Its cover and metadata come from the
/// track currently being played, while the luminous ribbons run on a
/// constant loop that does not react to the FFT.
class MotionVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;
  final Color glowColor;
  final int? albumId;
  final String? title;
  final String? artist;

  const MotionVisualizer({
    super.key,
    required this.fftStream,
    this.glowColor = Colors.pink,
    this.albumId,
    this.title,
    this.artist,
  });

  @override
  State<MotionVisualizer> createState() => _MotionVisualizerState();
}

class _MotionVisualizerState extends State<MotionVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = min(constraints.maxHeight, width * .55);
          final artSize = height * .58;
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: AnimatedBuilder(
                animation: _flow,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _MotionPainter(
                      phase: _flow.value,
                      glowColor: widget.glowColor,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: height * .1),
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: artSize,
                              height: artSize,
                              child: widget.albumId == null
                                  ? _fallbackArtwork()
                                  : QueryArtworkWidget(
                                      id: widget.albumId!,
                                      type: ArtworkType.ALBUM,
                                      size: 512,
                                      quality: 100,
                                      artworkFit: BoxFit.cover,
                                      keepOldArtwork: true,
                                      nullArtworkWidget: _fallbackArtwork(),
                                    ),
                            ),
                          ),
                          SizedBox(width: width * .055),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title?.trim().isNotEmpty == true
                                      ? widget.title!
                                      : 'Pista desconocida',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: height * .105,
                                  ),
                                ),
                                SizedBox(height: height * .025),
                                Text(
                                  widget.artist?.trim().isNotEmpty == true
                                      ? widget.artist!
                                      : 'Artista desconocido',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: height * .075,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );

  Widget _fallbackArtwork() => Container(
        color: const Color(0xFF182737),
        alignment: Alignment.center,
        child: const Icon(Icons.music_note_rounded, color: Colors.white54),
      );
}

class _MotionPainter extends CustomPainter {
  final double phase;
  final Color glowColor;

  const _MotionPainter({
    required this.phase,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height * .22),
    );
    canvas.save();
    canvas.clipRRect(card);
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF071018));
    for (var layer = 0; layer < 18; layer++) {
      final path = Path()..moveTo(-size.width * .08, size.height * .5);
      final yOffset = (layer - 8.5) * size.height * .022;
      for (var step = 0; step <= 44; step++) {
        final x = size.width * (step / 44) * 1.16 - size.width * .08;
        final wave = sin(step * .42 + phase * pi * 2 + layer * .21);
        final y =
            size.height * .5 + yOffset + wave * size.height * .08;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color =
              Color.lerp(const Color(0xFF8AC7EF), Colors.white, layer / 22)!
                  .withValues(alpha: .13 + (layer % 4) * .035)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      card,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFBFE9FF), glowColor, const Color(0xFFFF3C9C)],
          stops: const [0, .55, 1],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _MotionPainter oldDelegate) => true;
}

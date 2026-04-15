import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class VinylRecord extends StatelessWidget {
  final bool isPlaying;
  final int? albumId;

  const VinylRecord({
    super.key,
    required this.isPlaying,
    this.albumId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withAlpha(40),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF111111),
                  Color(0xFF1C1C1C),
                  Color(0xFF111111)
                ],
              ),
            ),
            child: CustomPaint(painter: _VinylGroovesPainter()),
          ),
          ClipOval(
            child: SizedBox(
              width: 80,
              height: 80,
              child: albumId != null
                  ? QueryArtworkWidget(
                      id: albumId!,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      artworkWidth: 80,
                      artworkHeight: 80,
                      nullArtworkWidget: Container(
                        color: const Color(0xFF1C1C1C),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1C1C1C),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double r = 45; r < maxR - 2; r += 4) {
      paint.color =
          (r % 8 < 4) ? Colors.white.withAlpha(10) : Colors.black.withAlpha(77);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

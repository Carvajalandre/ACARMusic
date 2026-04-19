import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Disco de vinilo giratorio con:
/// - Rotación animada mientras reproduce
/// - Imagen de portada en el centro
/// - Surcos concéntricos dibujados con CustomPainter
/// - Sombra de color dinámico pasada desde el padre
class VinylRecord extends StatefulWidget {
  final bool isPlaying;
  final int? albumId;
  final Color glowColor;

  const VinylRecord({
    super.key,
    required this.isPlaying,
    this.albumId,
    this.glowColor = const Color(0xFF6D28D9),
  });

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // 1 vuelta cada 8 s
    );
    if (widget.isPlaying) _rotationController.repeat();
  }

  @override
  void didUpdateWidget(VinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (_, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.141592653589793,
          child: child,
        );
      },
      child: _buildDisc(),
    );
  }

  Widget _buildDisc() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Halo / glow exterior ──────────────────────────────────────
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withAlpha(90),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // ── Cuerpo del vinilo con surcos ──────────────────────────────
          Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Color(0xFF101010), Color(0xFF1E1E1E), Color(0xFF101010)],
              ),
            ),
            child: CustomPaint(painter: _VinylGroovesPainter()),
          ),

          // ── Imagen de portada (centro) ────────────────────────────────
          ClipOval(
            child: SizedBox(
              width: 90,
              height: 90,
              child: widget.albumId != null
                  ? QueryArtworkWidget(
                      id: widget.albumId!,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      artworkWidth: 90,
                      artworkHeight: 90,
                      nullArtworkWidget: _defaultCenterIcon(),
                    )
                  : _defaultCenterIcon(),
            ),
          ),

          // ── Punto central del disco ───────────────────────────────────
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCenterIcon() => Container(
        color: const Color(0xFF1C1C1C),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white54, size: 32),
      );
}

// ─── Pintor de surcos concéntricos ────────────────────────────────────────────
class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (double r = 50; r < maxR - 4; r += 3.5) {
      final bright = (r % 7 < 3.5);
      paint.color = bright
          ? Colors.white.withAlpha(12)
          : Colors.black.withAlpha(80);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
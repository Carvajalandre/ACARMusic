import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Disco de vinilo giratorio.
/// Implementa WidgetsBindingObserver para pausar la animación
/// cuando la app está en segundo plano → ahorra batería.
class VinylRecord extends StatefulWidget {
  final bool isPlaying;
  final int? albumId;
  final Color glowColor;
  final double size;

  const VinylRecord({
    super.key,
    required this.isPlaying,
    this.albumId,
    this.glowColor = const Color(0xFF6D28D9),
    this.size = 260,
  });

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ctrl;
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _appInForeground = false;
      // Para la animación: el audio sigue sonando, solo se detiene el render
      if (_ctrl.isAnimating) _ctrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      _appInForeground = true;
      // Reanuda la animación solo si sigue reproduciendo
      if (widget.isPlaying && !_ctrl.isAnimating) _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(VinylRecord old) {
    super.didUpdateWidget(old);
    if (!_appInForeground) return; // No arranca animación en background
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s          = widget.size;
    final centerSize = s * 0.346; // ~90px cuando s=260

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Transform.rotate(
          angle: _ctrl.value * 2 * 3.141592653589793,
          child: child,
        );
      },
      child: _buildDisc(s, centerSize),
    );
  }

  Widget _buildDisc(double s, double centerSize) {
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Halo / glow exterior ──────────────────────────────────────
          Container(
            width: s + 20, height: s + 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: widget.glowColor.withAlpha(90),
                blurRadius: 50, spreadRadius: 10)],
            ),
          ),

          // ── Cuerpo del vinilo con surcos ──────────────────────────────
          Container(
            width: s, height: s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0xFF101010), Color(0xFF1E1E1E), Color(0xFF101010)]),
            ),
            child: CustomPaint(painter: _GroovesPainter()),
          ),

          // ── Imagen de portada (centro) ────────────────────────────────
          ClipOval(
            child: SizedBox(
              width: centerSize,
              height: centerSize,
              child: widget.albumId != null
                  ? QueryArtworkWidget(
                      id: widget.albumId!,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      artworkWidth: centerSize,
                      artworkHeight: centerSize,
                      keepOldArtwork: true,
                      nullArtworkWidget: _defaultCenter())
                  : _defaultCenter(),
            ),
          ),

          // ── Punto central del disco ───────────────────────────────────
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: Colors.black, shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _defaultCenter() => Container(
        color: const Color(0xFF1C1C1C),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white54, size: 28));
}

// ─── Pintor de surcos concéntricos ────────────────────────────────────────────
class _GroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.width / 2;
    final paint  = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6;

    for (double r = 50; r < maxR - 4; r += 3.5) {
      paint.color = (r % 7 < 3.5)
          ? Colors.white.withAlpha(12)
          : Colors.black.withAlpha(80);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
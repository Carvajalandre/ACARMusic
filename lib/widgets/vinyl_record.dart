import 'package:flutter/material.dart';

class VinylRecord extends StatefulWidget {
  final bool isPlaying;
  final Widget child; // album artwork in the center

  const VinylRecord({super.key, required this.isPlaying, required this.child});

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(VinylRecord old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Rotating vinyl body AND album art
          RotationTransition(
            turns: _ctrl,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [Color(0xFF111111), Color(0xFF1C1C1C), Color(0xFF111111)],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: CustomPaint(painter: _VinylGroovesPainter()),
                ),
                // Center album art (now inside rotation)
                ClipOval(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
          // Center spindle hole (static)
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
      paint.color = (r % 8 < 4)
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.3);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

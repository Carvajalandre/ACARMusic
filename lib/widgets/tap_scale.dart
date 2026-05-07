import 'package:flutter/material.dart';

/// Envuelve cualquier widget con animación de escala al presionar.
/// No reemplaza GestureDetector interno — usa absorber separado.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  /// Escala al pulsar (0.0–1.0). Default 0.88 para botones medianos.
  final double scale;
  /// Duración de la animación de entrada (compresión).
  final Duration pressedDuration;
  /// Duración de la animación de salida (rebote).
  final Duration releasedDuration;

  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.88,
    this.pressedDuration = const Duration(milliseconds: 90),
    this.releasedDuration = const Duration(milliseconds: 160),
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   _onTapDown,
      onTapUp:     _onTapUp,
      onTapCancel: _onTapCancel,
      // HitTestBehavior.opaque asegura que el área sea tocable
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale:    _pressed ? widget.scale : 1.0,
        duration: _pressed ? widget.pressedDuration : widget.releasedDuration,
        curve:    _pressed ? Curves.easeIn : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
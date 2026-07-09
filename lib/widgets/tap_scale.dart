import 'package:flutter/material.dart';

/// Envuelve cualquier widget con animación de escala al presionar.
/// Soporte opcional de tooltip en long press — sin GestureDetectors anidados.
/// Un solo GestureDetector maneja onTap + onLongPress → sin conflicto Samsung.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  /// Si se provee, muestra este texto en long press (no bloquea el tap).
  final String? tooltip;

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
    this.tooltip,
    this.scale = 0.88,
    this.pressedDuration = const Duration(milliseconds: 90),
    this.releasedDuration = const Duration(milliseconds: 120),
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  /// true durante un long press — evita que onTapUp dispare la acción.
  bool _isLongPress = false;

  final _tooltipKey = GlobalKey<TooltipState>();

  void _onTapDown(TapDownDetails _) {
    _isLongPress = false;
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _isLongPress = false;
  }

  void _onLongPress() {
    _isLongPress = true;
    // Soltar animación de escala al mostrar tooltip
    setState(() => _pressed = false);
    _tooltipKey.currentState?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.tooltip != null
        ? Tooltip(
            key: _tooltipKey,
            message: widget.tooltip!,
            // manual: solo se muestra cuando llamamos ensureTooltipVisible()
            // No interfiere con ningún GestureDetector
            triggerMode: TooltipTriggerMode.manual,
            child: widget.child,
          )
        : widget.child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        if (!_isLongPress) widget.onTap();
        _isLongPress = false;
      },
      // onLongPress solo si hay tooltip configurado
      onLongPress: widget.tooltip != null ? _onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: _pressed ? widget.pressedDuration : widget.releasedDuration,
        curve: _pressed ? Curves.easeIn : Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}

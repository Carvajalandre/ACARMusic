import 'package:flutter/material.dart';

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;
  final double scale;
  final Duration pressedDuration;
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
    setState(() => _pressed = false);
    _tooltipKey.currentState?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.tooltip != null
        ? Tooltip(
            key: _tooltipKey,
            message: widget.tooltip!,
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

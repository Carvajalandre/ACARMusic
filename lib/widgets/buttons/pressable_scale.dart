import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class PressableIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;

  const PressableIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: icon,
      ),
    );
  }
}

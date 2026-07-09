import 'package:flutter/material.dart';

class GlowButton extends StatelessWidget {
  final bool active;
  final Color activeColor;
  final Color glowColor;
  final Widget child;

  const GlowButton({
    super.key,
    required this.active,
    required this.activeColor,
    required this.glowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? activeColor.withAlpha(28) : Colors.transparent,
        boxShadow: active
            ? [
                BoxShadow(
                  color: glowColor.withAlpha(90),
                  blurRadius: 14,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: child,
    );
  }
}

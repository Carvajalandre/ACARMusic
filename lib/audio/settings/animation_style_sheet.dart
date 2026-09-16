import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../visualizers/animation_style.dart';
import '../audio_provider.dart';

class AnimationStyleSheet extends StatelessWidget {
  final AudioProvider audio;

  const AnimationStyleSheet({super.key, required this.audio});

  void _showVoidUnavailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Void',
          style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'En desarrollo, por favor prueba otros estilos de animación',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = audio.animationStyle;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Animaciones',
                style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...VisualizerStyle.values.map((style) {
              final selected = style == current;
              final isDefault = style == VisualizerStyle.vinyl;
              final isVoid = style == VisualizerStyle.void_;
              return ListTile(
                leading:
                    Text(style.iconLabel, style: const TextStyle(fontSize: 24)),
                title: Text(
                  '${style.displayName}${isDefault ? ' (Por defecto)' : ''}',
                  style: TextStyle(
                    color: isVoid ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : isVoid
                        ? const Icon(Icons.hourglass_empty_rounded, color: AppTheme.onSurfaceVariant, size: 20)
                        : null,
                onTap: () {
                  if (isVoid) {
                    _showVoidUnavailableDialog(context);
                  } else {
                    audio.animationStyle = style;
                    Navigator.pop(context);
                  }
                },
              );
            }),
            const SizedBox(height: 12),
            const Text('Los cambios se aplican al instante en el reproductor.',
                style:
                    TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

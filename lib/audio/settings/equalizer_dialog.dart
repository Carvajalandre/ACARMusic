import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../audio_provider.dart';

class EqualizerDialog {
  static const _eqChannel = MethodChannel('com.acar.music/equalizer');

  static Future<void> openSoundEffects(
      BuildContext context, AudioProvider audio) async {
    final sessionId = audio.androidAudioSessionId ?? 0;
    try {
      final opened = await _eqChannel.invokeMethod<bool>('openEqualizer', {
        'audioSessionId': sessionId,
      });
      if (opened == false && context.mounted) {
        _showNoEqDialog(context);
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  static void _showNoEqDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(30), shape: BoxShape.circle),
            child: const Icon(Icons.graphic_eq_rounded,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Calidad y efectos de sonido',
              style: TextStyle(
                  color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'Tu dispositivo no tiene una aplicación de efectos de sonido del sistema instalada (Dolby Atmos, Mi Sound Enhancer, etc.).\n\nPuedes instalar una app de ecualizador desde la Play Store para mejorar el sonido.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

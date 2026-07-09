import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../audio_provider.dart';

class SleepTimerSheet extends StatelessWidget {
  final AudioProvider audio;

  const SleepTimerSheet({super.key, required this.audio});

  @override
  Widget build(BuildContext context) {
    final presets = [15, 30, 45, 60, 90, 120];
    final customCtrl = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
                color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('Temporizador de sueño',
                style: TextStyle(
                    color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          ListTile(
            title: const Text('Desactivado',
                style: TextStyle(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            trailing: audio.sleepTimerMinutes == 0
                ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                : null,
            onTap: () {
              audio.cancelSleepTimer();
              Navigator.pop(context);
            },
          ),
          ...presets.map((min) => ListTile(
                title: Text('$min minutos',
                    style: const TextStyle(
                        color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
                trailing: audio.sleepTimerMinutes == min
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  audio.setSleepTimer(min);
                  Navigator.pop(context);
                },
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.onSurface),
                    decoration: const InputDecoration(
                      hintText: 'Minutos personalizados',
                      hintStyle: TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 13),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.outline)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final min = int.tryParse(customCtrl.text.trim());
                    if (min != null && min > 0) {
                      audio.setSleepTimer(min);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSection(
              label: 'Experiencia',
              children: [
                _buildSettingTile(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Calidad y efectos de sonido',
                  subtitle: null,
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                  onTap: () => _openSoundEffects(context, audio),
                ),
                _buildSleepTimerTile(context, audio),
                _buildSettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Apariencia',
                  subtitle: 'Tema oscuro',
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeThumbColor: AppTheme.primary,
                  ),
                  onTap: null,
                ),
              ],
            )),
            SliverToBoxAdapter(child: _buildSection(
              label: 'Soporte',
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Acerca de',
                  subtitle: 'ACARMusic v1.0.0',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                  onTap: () => _showAbout(context),
                ),
              ],
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Text('Ajustes',
            style: GoogleFonts.manrope(
                color: AppTheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      );

  // ── Sleep Timer con countdown ─────────────────────────────────────────────
  Widget _buildSleepTimerTile(BuildContext context, AudioProvider audio) {
    return ValueListenableBuilder<Duration>(
      valueListenable: audio.sleepRemainingNotifier,
      builder: (_, remaining, __) {
        final isActive  = remaining > Duration.zero;
        final subtitle  = isActive
            ? 'Apaga en ${_fmt(remaining)}'
            : (audio.sleepTimerMinutes > 0 ? '${audio.sleepTimerMinutes} min' : 'Desactivado');

        return GestureDetector(
          onTap: () => _showSleepTimerSheet(context, audio),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withAlpha(40)
                        : AppTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer_rounded,
                      color: isActive ? AppTheme.primary : AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Temporizador de sueño',
                        style: GoogleFonts.manrope(
                            color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle.toUpperCase(),
                        style: GoogleFonts.manrope(
                            color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
                            fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (isActive)
                  GestureDetector(
                    onTap: () => audio.cancelSleepTimer(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Cancelar',
                          style: GoogleFonts.manrope(
                              color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, AudioProvider audio) {
    final presets = [15, 30, 45, 60, 90, 120];
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text('Temporizador de sueño',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            // Opción: apagado
            ListTile(
              title: Text('Desactivado',
                  style: GoogleFonts.manrope(color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
              trailing: audio.sleepTimerMinutes == 0
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
              onTap: () { audio.cancelSleepTimer(); Navigator.pop(ctx); },
            ),
            // Presets
            ...presets.map((min) => ListTile(
              title: Text('$min minutos',
                  style: GoogleFonts.manrope(color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
              trailing: audio.sleepTimerMinutes == min
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
              onTap: () { audio.setSleepTimer(min); Navigator.pop(ctx); },
            )),
            // Tiempo personalizado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.manrope(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Minutos personalizados',
                        hintStyle: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant, fontSize: 13),
                        enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.outline)),
                        focusedBorder: const UnderlineInputBorder(
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
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('OK', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
    }
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }

  Widget _buildSection({required String label, required List<Widget> children}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(label.toUpperCase(),
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
            ...children,
          ],
        ),
      );

  Widget _buildSettingTile({
    required IconData icon, required String title, required String? subtitle,
    required Widget trailing, required VoidCallback? onTap,
  }) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle.toUpperCase(),
                        style: GoogleFonts.manrope(
                            color: AppTheme.onSurfaceVariant, fontSize: 10,
                            letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                ]),
              ),
              trailing,
            ],
          ),
        ),
      );

  static const _eqChannel = MethodChannel('com.acar.music/equalizer');

  Future<void> _openSoundEffects(BuildContext context, AudioProvider audio) async {
    final sessionId = audio.androidAudioSessionId ?? 0;
    try {
      final opened = await _eqChannel.invokeMethod<bool>('openEqualizer', {
        'audioSessionId': sessionId,
      });
      if (opened == false && context.mounted) {
        // El dispositivo no tiene ecualizador de sistema → mostrar aviso
        _showNoEqDialog(context);
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message}',
              style: GoogleFonts.manrope(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _showNoEqDialog(BuildContext context) {
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
          Text('Calidad y efectos de sonido',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            'Tu dispositivo no tiene una aplicación de efectos de sonido del sistema instalada (Dolby Atmos, Mi Sound Enhancer, etc.).\n\nPuedes instalar una app de ecualizador desde la Play Store para mejorar el sonido.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ACARMusic',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.music_note_rounded, size: 48, color: AppTheme.primary),
      children: [
        Text('Reproductor de música local personal.\nSin internet, sin anuncios.',
            style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}
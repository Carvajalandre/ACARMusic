import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  int _sleepTimerMin = 0; // 0 = off

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildProfileCard()),
            SliverToBoxAdapter(child: _buildSection(
              label: 'Experience',
              children: [
                _buildSettingTile(
                  icon: Icons.equalizer_rounded,
                  title: 'Equalizer',
                  subtitle: null,
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                  onTap: () => _showEqualizer(context),
                ),
                _buildSettingTile(
                  icon: Icons.timer_rounded,
                  title: 'Sleep Timer',
                  subtitle: _sleepTimerMin == 0 ? 'Off' : '$_sleepTimerMin min',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                  onTap: () => _showSleepTimer(context),
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Appearance',
                  subtitle: 'Dark Theme',
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  onTap: null,
                ),
              ],
            )),
            SliverToBoxAdapter(child: _buildSection(
              label: 'Support',
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'Sonic Monolith v1.0.0',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                  onTap: () => _showAbout(context),
                ),
                _buildSettingTile(
                  icon: Icons.storage_rounded,
                  title: 'Storage',
                  subtitle: 'Music library cache',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                  onTap: () {},
                ),
              ],
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.black,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Text(
      'Settings',
      style: GoogleFonts.manrope(
        color: AppTheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
  );

  Widget _buildProfileCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Listener',
                  style: GoogleFonts.manrope(
                    color: AppTheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Playing music from your device',
                  style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.onPrimaryContainer, size: 18),
          ),
        ],
      ),
    ),
  );

  Widget _buildSection({required String label, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: AppTheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle.toUpperCase(),
                      style: GoogleFonts.manrope(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Equalizer', style: GoogleFonts.manrope(
              color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 24),
            Text(
              'Equalizer requires system integration.\nUse Samsung Sound settings for advanced EQ.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSleepTimer(BuildContext context) {
    final options = [0, 15, 30, 45, 60, 90];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text('Sleep Timer', style: GoogleFonts.manrope(
                color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800,
              )),
            ),
            ...options.map((min) => ListTile(
              title: Text(min == 0 ? 'Off' : '$min minutes',
                style: GoogleFonts.manrope(color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
              trailing: _sleepTimerMin == min
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _sleepTimerMin = min);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Sonic Monolith',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.music_note_rounded, size: 48, color: AppTheme.primary),
      children: [
        Text(
          'A premium local music player built with Flutter.\nDesigned for Samsung Android devices.',
          style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

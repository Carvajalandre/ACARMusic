import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import 'library_screen.dart';
import 'explore_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';
import '../widgets/mini_player.dart';
import '../widgets/permission_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LibraryScreen(),
    ExploreScreen(),
    PlaylistsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();
    
    if (!context.select<LibraryProvider, bool>((l) => l.hasPermission)) {
      return const PermissionScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Mini player sits above the bottom nav
          Selector<AudioProvider, int?>(
            selector: (_, a) => a.currentSong?.id,
            builder: (context, songId, child) {
              if (songId == null) return const SizedBox.shrink();
              return const Positioned(
                left: 0,
                right: 0,
                bottom: 80, // height of bottom nav
                child: MiniPlayer(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.library_music_rounded, label: 'Library',  index: 0, current: _currentIndex, onTap: _onTab),
          _NavItem(icon: Icons.explore_rounded,       label: 'Explore',  index: 1, current: _currentIndex, onTap: _onTab),
          _NavItem(icon: Icons.queue_music_rounded,   label: 'Library',  index: 2, current: _currentIndex, onTap: _onTab),
          _NavItem(icon: Icons.settings_rounded,      label: 'Settings', index: 3, current: _currentIndex, onTap: _onTab),
        ],
      ),
    );
  }

  void _onTab(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.onSurface : AppTheme.outline,
          size: isActive ? 26 : 24,
        ),
      ),
    );
  }
}

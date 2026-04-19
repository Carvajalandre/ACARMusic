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
    if (!context.select<LibraryProvider, bool>((l) => l.hasPermission)) {
      return const PermissionScreen();
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return _buildLandscape();
        }
        return _buildPortrait();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERTICAL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortrait() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Selector<AudioProvider, int?>(
            selector: (_, a) => a.currentSong?.id,
            builder: (context, songId, _) {
              if (songId == null) return const SizedBox.shrink();
              return const Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: MiniPlayer(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HORIZONTAL — navegación lateral
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLandscape() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Rail de navegación izquierdo
          _buildSideNav(),
          // Contenido principal
          Expanded(
            child: Stack(
              children: [
                IndexedStack(index: _currentIndex, children: _screens),
                Selector<AudioProvider, int?>(
                  selector: (_, a) => a.currentSong?.id,
                  builder: (context, songId, _) {
                    if (songId == null) return const SizedBox.shrink();
                    return const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MiniPlayer(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    final items = [
      (Icons.library_music_rounded, 'Biblioteca'),
      (Icons.explore_rounded, 'Explorar'),
      (Icons.queue_music_rounded, 'Listas'),
      (Icons.settings_rounded, 'Ajustes'),
    ];
    return Container(
      width: 64,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(items.length, (i) {
          final active = _currentIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                items[i].$1,
                color: active ? AppTheme.onSurface : AppTheme.outline,
                size: active ? 26 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.library_music_rounded, 'Biblioteca'),
      (Icons.explore_rounded, 'Explorar'),
      (Icons.queue_music_rounded, 'Listas'),
      (Icons.settings_rounded, 'Ajustes'),
    ];
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _currentIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                items[i].$1,
                color: active ? AppTheme.onSurface : AppTheme.outline,
                size: active ? 26 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../library/library_provider.dart';
import '../../library/models/custom_playlist.dart';
import 'song_list_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, library)),
            SliverToBoxAdapter(child: _buildTopCards(context, library)),
            SliverToBoxAdapter(child: _buildSectionLabel('Tus Listas')),
            _buildPlaylistsList(context, library),
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LibraryProvider library) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
        child: Row(
          children: [
            Text('Listas',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: AppTheme.primary, size: 26),
              onPressed: () => _showCreatePlaylistDialog(context, library),
            ),
          ],
        ),
      );

  Widget _buildTopCards(BuildContext context, LibraryProvider library) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: Row(
              children: [
                Expanded(
                  child: _TopCard(
                    title: 'Recién\nañadidas',
                    count: library.recentlyAdded.length,
                    icon: Icons.new_releases_rounded,
                    colors: const [Color(0xFF1A1040), Color(0xFF2D1B69)],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(
                            title: 'Recién añadidas',
                            songs: library.recentlyAdded,
                          ),
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopCard(
                    title: 'Más\nescuchadas',
                    count: library.mostPlayed.length,
                    icon: Icons.trending_up_rounded,
                    colors: const [Color(0xFF0A1A00), Color(0xFF1A3A00)],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(
                            title: 'Más escuchadas',
                            songs: library.mostPlayed,
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: Row(
              children: [
                Expanded(
                  child: _TopCard(
                    title: 'Favoritos',
                    count: library.favorites.length,
                    icon: Icons.favorite_rounded,
                    colors: const [Color(0xFF3D0010), Color(0xFF7F1D1D)],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(
                            title: 'Favoritos',
                            songs: library.favorites,
                          ),
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopCard(
                    title: 'Escuchadas\nrecientemente',
                    count: library.recentlyPlayed.length,
                    icon: Icons.history_rounded,
                    colors: const [Color(0xFF0A1A28), Color(0xFF0A3050)],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(
                            title: 'Escuchadas recientemente',
                            songs: library.recentlyPlayed,
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text(label,
            style: GoogleFonts.manrope(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
      );

  SliverList _buildPlaylistsList(
      BuildContext context, LibraryProvider library) {
    if (library.playlists.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              const Icon(Icons.playlist_add_rounded,
                  color: AppTheme.outline, size: 56),
              const SizedBox(height: 16),
              Text('Aún no tienes listas',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Toca + arriba para crear una',
                  style: GoogleFonts.manrope(
                      color: AppTheme.outline, fontSize: 13)),
            ]),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final pl = library.playlists[i];
          final songs = library.getSongsForPlaylist(pl.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: AppTheme.surfaceContainerLow,
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.playlist_play_rounded,
                    color: AppTheme.primary),
              ),
              title: Text(pl.name,
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              subtitle: Text('${songs.length} canciones',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.onSurfaceVariant),
                onPressed: () => _showPlaylistOptions(ctx, library, pl),
              ),
              onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => SongListScreen(
                      title: pl.name,
                      songs: songs,
                      playlistId: pl.id,
                    ),
                  )),
            ),
          );
        },
        childCount: library.playlists.length,
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, LibraryProvider library) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: Text('Nueva Lista',
            style: GoogleFonts.manrope(color: AppTheme.onSurface)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Nombre de la lista',
            hintStyle: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.outline)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant))),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                library.createPlaylist(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('Crear',
                style: GoogleFonts.manrope(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
      BuildContext context, LibraryProvider library, CustomPlaylist pl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(pl.name,
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const Divider(height: 1, color: AppTheme.surfaceVariant),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
            title: Text('Renombrar',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(ctx);
              _showRenameDialog(context, library, pl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            title: Text('Eliminar lista',
                style: GoogleFonts.manrope(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              library.deletePlaylist(pl.id);
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, LibraryProvider library, CustomPlaylist pl) {
    final ctrl = TextEditingController(text: pl.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: Text('Renombrar Lista',
            style: GoogleFonts.manrope(color: AppTheme.onSurface)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintStyle: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.outline)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant))),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                library.renamePlaylist(pl.id, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('Guardar',
                style: GoogleFonts.manrope(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _TopCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(13)),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned(
                right: -8,
                bottom: -12,
                child: Icon(icon,
                    color: Colors.white.withAlpha(18), size: 70)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, color: colors.last.withAlpha(200), size: 18),
                const SizedBox(height: 6),
                Text(title,
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1)),
                const SizedBox(height: 2),
                Text('$count canciones',
                    style: GoogleFonts.manrope(
                        color: Colors.white.withAlpha(180), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

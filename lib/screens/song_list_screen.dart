import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/track_tile.dart';

/// Pantalla genérica de lista de canciones.
/// Usada para: Favoritos, Recientes, Recién añadidas, Más escuchadas, Playlists personalizadas.
class SongListScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SongModel> songs;
  final String? playlistId; // si es una playlist editable

  const SongListScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.songs,
    this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    final audio   = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar con portadas ──────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.background,
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title,
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
              background: _buildBackground(songs),
            ),
            actions: [
              if (songs.isNotEmpty)
                IconButton(
                  onPressed: () {
                    final rand = DateTime.now().millisecondsSinceEpoch % songs.length;
                    audio.playSong(songs[rand], songs, rand);
                  },
                  icon: const Icon(Icons.shuffle_rounded, color: AppTheme.primary, size: 28),
                ),
              if (songs.isNotEmpty)
                IconButton(
                  onPressed: () => audio.playSong(songs.first, songs, 0),
                  icon: const Icon(Icons.play_circle_rounded, color: AppTheme.primary, size: 32),
                ),
            ],
          ),

          // ── Contador ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                subtitle ?? '${songs.length} canciones',
                style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
          ),

          // ── Lista de canciones ────────────────────────────────────────
          if (songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.music_off_rounded, color: AppTheme.outline, size: 64),
                  const SizedBox(height: 16),
                  Text('Esta lista está vacía',
                      style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant, fontSize: 16)),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = songs[i];
                  return Selector<AudioProvider, bool>(
                    selector: (_, a) => a.currentSong?.id == song.id,
                    builder: (context, isPlaying, _) => TrackTile(
                      song: song,
                      isPlaying: isPlaying,
                      onTap: () {
                        library.addToRecentlyPlayed(song);
                        library.incrementPlayCount(song.id);
                        audio.playSong(song, songs, i);
                      },
                      onMore: () => _showOptions(context, song, library),
                    ),
                  );
                },
                childCount: songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 180)),
        ],
      ),
    );
  }

  Widget _buildBackground(List<SongModel> songs) {
    // Muestra hasta 4 portadas en un grid 2x2
    final items = songs.take(4).toList();
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppTheme.primary.withAlpha(77), AppTheme.background],
          ),
        ),
        child: const Center(child: Icon(Icons.queue_music_rounded, size: 80, color: AppTheme.primary)),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (items.length == 1)
          RepaintBoundary(
            child: QueryArtworkWidget(
              id: items[0].id, type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover, keepOldArtwork: true,
              nullArtworkWidget: Container(color: AppTheme.surfaceContainerHigh),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(),
            children: items.map((s) => RepaintBoundary(
              child: QueryArtworkWidget(
                id: s.id, type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover, keepOldArtwork: true,
                nullArtworkWidget: Container(color: AppTheme.surfaceContainerHigh),
              ),
            )).toList(),
          ),
        // Degradado inferior para legibilidad del título
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, SongModel song, LibraryProvider library) {
    final isFav = library.isFavorite(song);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : AppTheme.onSurface),
            title: Text(isFav ? 'Quitar de Favoritos' : 'Agregar a Favoritos',
                style: GoogleFonts.manrope(color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            onTap: () {
              isFav ? library.removeFromFavorites(song) : library.addToFavorites(song);
              Navigator.pop(context);
            },
          ),
          if (playlistId != null)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
              title: Text('Quitar de esta lista',
                  style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () {
                library.removeSongFromPlaylist(playlistId!, song.id);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
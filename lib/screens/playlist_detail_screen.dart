import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/track_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<List<SongModel>>(
        future: library.getSongsFromPlaylist(playlistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final songs = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppTheme.background,
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlistName,
                    style: GoogleFonts.manrope(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.background,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.playlist_play_rounded,
                        size: 80,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (songs.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        audio.playSong(songs.first, songs, 0);
                      },
                      icon: const Icon(Icons.play_circle_rounded,
                          color: AppTheme.primary, size: 32),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${songs.length} songs',
                    style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (songs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_off_rounded,
                            color: AppTheme.outline, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'This playlist is empty',
                          style: GoogleFonts.manrope(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add songs from the library',
                          style: GoogleFonts.manrope(
                            color: AppTheme.outline,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final song = songs[i];
                      final isPlaying = audio.currentSong?.id == song.id;
                      return TrackTile(
                        song: song,
                        isPlaying: isPlaying,
                        onTap: () {
                          library.addToRecentlyPlayed(song);
                          audio.playSong(song, songs, i);
                        },
                        onMore: () => _showTrackOptions(context, song, library),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          );
        },
      ),
    );
  }

  void _showTrackOptions(
      BuildContext context, SongModel song, LibraryProvider library) {
    final isFav = library.isFavorite(song);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : AppTheme.onSurface,
              ),
              title: Text(
                isFav ? 'Remove from Favorites' : 'Add to Favorites',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                if (isFav) {
                  library.removeFromFavorites(song);
                } else {
                  library.addToFavorites(song);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_remove_rounded,
                  color: AppTheme.onSurface),
              title: Text(
                'Remove from Playlist',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRemoveFromPlaylistDialog(context, song, library);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFromPlaylistDialog(
      BuildContext context, SongModel song, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: Text('Remove from Playlist',
            style: GoogleFonts.manrope(color: AppTheme.onSurface)),
        content: Text('Remove "${song.title}" from this playlist?',
            style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Note: on_audio_query doesn't have a direct removeFromPlaylist method
              // This would require a different approach
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Feature requires additional implementation')),
              );
            },
            child: Text('Remove',
                style: GoogleFonts.manrope(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

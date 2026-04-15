import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/vinyl_record.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  Color _dominantColor = const Color(0xFF1A0A2E);
  Color _secondaryColor = const Color(0xFF0D1A2E);
  int? _lastSongId;

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final songId =
        context.select<AudioProvider, int?>((a) => a.currentSong?.id);

    if (songId == null) {
      return const SizedBox.shrink();
    }

    final song = audio.queue.firstWhere(
      (s) => s.id == songId,
      orElse: () => audio.currentSong!,
    );

    // Update palette when song changes
    if (_lastSongId != song.id) {
      _lastSongId = song.id;
      _updatePalette(song);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.5),
            radius: 1.2,
            colors: [
              _dominantColor.withOpacity(0.6),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, audio),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildTitleSection(song),
                      const SizedBox(height: 24),
                      Selector<AudioProvider, bool>(
                        selector: (_, a) => a.isPlaying,
                        builder: (_, isPlaying, __) =>
                            _buildVinylAndArtwork(song, isPlaying),
                      ),
                      const SizedBox(height: 32),
                      Consumer<AudioProvider>(
                          builder: (_, a, __) => _buildProgressBar(a)),
                      const SizedBox(height: 28),
                      Consumer<AudioProvider>(
                          builder: (_, a, __) => _buildControls(a)),
                      const SizedBox(height: 24),
                      _buildUtilityRow(song, context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AudioProvider audio) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 32, color: AppTheme.onSurface),
            ),
            Expanded(
              child: Text(
                'Sonic Monolith',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.queue_music_rounded,
                  color: AppTheme.onSurface),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.onSurface),
            ),
          ],
        ),
      );

  Widget _buildTitleSection(SongModel song) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.title ?? 'Unknown Track',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            song.artist ?? 'Unknown Artist',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildVinylAndArtwork(SongModel song, bool isPlaying) {
    return Column(
      children: [
        Center(
          child: VinylRecord(
            isPlaying: isPlaying,
            child: song.albumId != null
                ? RepaintBoundary(
                    child: QueryArtworkWidget(
                      id: song.albumId!,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      artworkBorder: BorderRadius.circular(999),
                      artworkWidth: 80,
                      artworkHeight: 80,
                      nullArtworkWidget: const Icon(
                        Icons.music_note_rounded,
                        color: AppTheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.onSurfaceVariant,
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTrackInfo(song),
      ],
    );
  }

  Widget _buildTrackInfo(SongModel song) {
    return Column(
      children: [
        Text(
          song.album ?? 'Unknown Album',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatMs(song.duration ?? 0)} • ${song.data?.split('/').last ?? ''}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioProvider audio) {
    return Column(
      children: [
        // Time stamps
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              audio.formatDuration(audio.position),
              style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            Text(
              audio.formatDuration(audio.duration),
              style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppTheme.tertiary,
            inactiveTrackColor: AppTheme.surfaceVariant.withOpacity(0.4),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.1),
          ),
          child: Slider(
            value: audio.progress.clamp(0.0, 1.0),
            onChanged: (v) => audio.seekTo(v),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(AudioProvider audio) {
    final repeatIcon = switch (audio.repeatMode) {
      AppRepeatState.all => Icons.repeat_rounded,
      AppRepeatState.one => Icons.repeat_one_rounded,
      _ => Icons.repeat_rounded,
    };
    final repeatColor = audio.repeatMode == AppRepeatState.off
        ? AppTheme.onSurfaceVariant
        : AppTheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle
        IconButton(
          onPressed: audio.toggleShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: audio.isShuffleOn
                ? AppTheme.primary
                : AppTheme.onSurfaceVariant,
            size: 26,
          ),
        ),
        // Skip previous
        IconButton(
          onPressed: audio.skipPrevious,
          icon: const Icon(Icons.skip_previous_rounded,
              color: AppTheme.onSurface, size: 36),
        ),
        // Play / Pause — main button
        GestureDetector(
          onTap: audio.togglePlayPause,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.tertiary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppTheme.onTertiary,
              size: 38,
            ),
          ),
        ),
        // Skip next
        IconButton(
          onPressed: audio.skipNext,
          icon: const Icon(Icons.skip_next_rounded,
              color: AppTheme.onSurface, size: 36),
        ),
        // Repeat
        IconButton(
          onPressed: audio.toggleRepeat,
          icon: Icon(repeatIcon, color: repeatColor, size: 26),
        ),
      ],
    );
  }

  Widget _buildUtilityRow(SongModel song, BuildContext context) {
    final library = context.read<LibraryProvider>();
    final isFav = library.isFavorite(song);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _UtilBtn(
            icon:
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: 'Like',
            color: isFav ? Colors.pinkAccent : null,
            onTap: () {
              if (isFav) {
                library.removeFromFavorites(song);
              } else {
                library.addToFavorites(song);
              }
              setState(() {});
            },
          ),
          _UtilBtn(
            icon: Icons.playlist_add_rounded,
            label: 'Add',
            onTap: () => _showAddToPlaylistDialog(context, library, song),
          ),
          _UtilBtn(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _updatePalette(SongModel song) async {
    if (song.albumId == null) return;
    try {
      final hue = (song.albumId! * 47) % 360;
      setState(() {
        _dominantColor =
            HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.2).toColor();
        _secondaryColor =
            HSLColor.fromAHSL(1, (hue + 60).toDouble() % 360, 0.6, 0.15)
                .toColor();
      });
    } catch (_) {}
  }

  void _showAddToPlaylistDialog(
      BuildContext context, LibraryProvider library, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Add to Playlist',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Divider(height: 32),
          if (library.playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No playlists found',
                  style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: library.playlists.length,
                itemBuilder: (context, i) {
                  final p = library.playlists[i];
                  return ListTile(
                    leading: const Icon(Icons.playlist_add_rounded,
                        color: AppTheme.primary),
                    title: Text(p.playlist,
                        style: GoogleFonts.manrope(color: AppTheme.onSurface)),
                    onTap: () {
                      library.addToPlaylist(p.id, song.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to ${p.playlist}')),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _UtilBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _UtilBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? AppTheme.onSurfaceVariant, size: 22),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              color: AppTheme.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

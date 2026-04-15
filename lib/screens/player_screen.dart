import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/vinyl_record.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: _PlayerContent(),
    );
  }
}

class _PlayerContent extends StatefulWidget {
  const _PlayerContent();

  @override
  State<_PlayerContent> createState() => _PlayerContentState();
}

class _PlayerContentState extends State<_PlayerContent> {
  Color _dominantColor = const Color(0xFF1A0A2E);
  int? _lastSongId;

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();

    return Selector<AudioProvider, SongModel?>(
      selector: (_, a) => a.currentSong,
      builder: (context, song, _) {
        if (song == null) {
          return const SizedBox.shrink();
        }

        if (_lastSongId != song.id) {
          _lastSongId = song.id;
          _updatePalette(song);
        }

        final isFav = library.isFavorite(song);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.5),
              radius: 1.2,
              colors: [
                _dominantColor.withAlpha(150),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildTitleSection(song),
                        const SizedBox(height: 24),
                        _buildVinylSection(audio, song),
                        const SizedBox(height: 24),
                        _buildTrackInfo(song),
                        const SizedBox(height: 32),
                        _buildProgressBar(audio),
                        const SizedBox(height: 28),
                        _buildControls(audio),
                        const SizedBox(height: 24),
                        _buildUtilityRow(context, song, isFav, library),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updatePalette(SongModel song) {
    if (song.albumId == null) return;
    try {
      final hue = (song.albumId! * 47) % 360;
      setState(() {
        _dominantColor =
            HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.2).toColor();
      });
    } catch (_) {}
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 32, color: AppTheme.onSurface),
            ),
            const Expanded(
              child: Text(
                'Sonic Monolith',
                textAlign: TextAlign.center,
                style: TextStyle(
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
            style: const TextStyle(
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
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildVinylSection(AudioProvider audio, SongModel song) {
    return Selector<AudioProvider, bool>(
      selector: (_, a) => a.isPlaying,
      builder: (context, isPlaying, _) {
        return Center(
          child: VinylRecord(
            isPlaying: isPlaying,
            albumId: song.albumId,
          ),
        );
      },
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
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatMs(song.duration ?? 0)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioProvider audio) {
    return Consumer<AudioProvider>(
      builder: (context, a, _) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                a.formatDuration(a.position),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                a.formatDuration(a.duration),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: AppTheme.tertiary,
              inactiveTrackColor: AppTheme.surfaceVariant.withAlpha(100),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: a.progress.clamp(0.0, 1.0),
              onChanged: (v) => a.seekTo(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AudioProvider audio) {
    return Consumer<AudioProvider>(
      builder: (context, a, _) {
        final repeatIcon = switch (a.repeatMode) {
          AppRepeatState.all => Icons.repeat_rounded,
          AppRepeatState.one => Icons.repeat_one_rounded,
          _ => Icons.repeat_rounded,
        };
        final repeatColor = a.repeatMode == AppRepeatState.off
            ? AppTheme.onSurfaceVariant
            : AppTheme.primary;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: a.toggleShuffle,
              icon: Icon(
                Icons.shuffle_rounded,
                color: a.isShuffleOn
                    ? AppTheme.primary
                    : AppTheme.onSurfaceVariant,
                size: 26,
              ),
            ),
            IconButton(
              onPressed: a.skipPrevious,
              icon: const Icon(Icons.skip_previous_rounded,
                  color: AppTheme.onSurface, size: 36),
            ),
            GestureDetector(
              onTap: a.togglePlayPause,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.tertiary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withAlpha(40),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  a.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppTheme.onTertiary,
                  size: 38,
                ),
              ),
            ),
            IconButton(
              onPressed: a.skipNext,
              icon: const Icon(Icons.skip_next_rounded,
                  color: AppTheme.onSurface, size: 36),
            ),
            IconButton(
              onPressed: a.toggleRepeat,
              icon: Icon(repeatIcon, color: repeatColor, size: 26),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUtilityRow(BuildContext context, SongModel song, bool isFav,
      LibraryProvider library) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              if (isFav) {
                library.removeFromFavorites(song);
              } else {
                library.addToFavorites(song);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.pinkAccent : AppTheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(height: 4),
                const Text(
                  'LIKE',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showAddToPlaylistDialog(context, library, song),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.playlist_add_rounded,
                    color: AppTheme.onSurfaceVariant, size: 22),
                SizedBox(height: 4),
                Text(
                  'ADD',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_rounded,
                  color: AppTheme.onSurfaceVariant, size: 22),
              SizedBox(height: 4),
              Text(
                'SHARE',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          const Text('Add to Playlist',
              style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Divider(height: 32),
          if (library.playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No playlists found',
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
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
                        style: const TextStyle(color: AppTheme.onSurface)),
                    onTap: () {
                      library.addToPlaylist(p.id, song.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${p.playlist}')));
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

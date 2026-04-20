import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/vinyl_record.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.black, body: _PlayerContent());
}

class _PlayerContent extends StatefulWidget {
  const _PlayerContent();
  @override
  State<_PlayerContent> createState() => _PlayerContentState();
}

class _PlayerContentState extends State<_PlayerContent>
    with TickerProviderStateMixin {
  Color _colorA = const Color(0xFF1A0A2E);
  Color _colorB = const Color(0xFF0D0A20);
  Color _glowColor = const Color(0xFF6D28D9);
  int? _lastSongId;

  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
    _bgAnimation =
        CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _extractPalette(SongModel song) async {
    try {
      final art = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG, size: 200);
      if (art == null || art.isEmpty) {
        _fallbackColor(song);
        return;
      }
      final palette = await PaletteGenerator.fromImageProvider(MemoryImage(art),
          size: const Size(200, 200), maximumColorCount: 8);
      if (!mounted) return;
      setState(() {
        _glowColor = palette.vibrantColor?.color ??
            palette.dominantColor?.color ??
            _glowColor;
        _colorA = palette.dominantColor?.color?.withAlpha(180) ?? _colorA;
        _colorB = palette.mutedColor?.color?.withAlpha(200) ?? _colorB;
      });
    } catch (_) {
      _fallbackColor(song);
    }
  }

  void _fallbackColor(SongModel song) {
    final hue = ((song.albumId ?? song.id) * 47) % 360;
    if (!mounted) return;
    setState(() {
      _colorA = HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.15).toColor();
      _colorB = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, 0.10).toColor();
      _glowColor = HSLColor.fromAHSL(1, hue.toDouble(), 0.8, 0.4).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, SongModel?>(
      selector: (_, a) => a.currentSong,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();
        if (_lastSongId != song.id) {
          _lastSongId = song.id;
          _extractPalette(song);
        }

        return OrientationBuilder(
          builder: (context, orientation) => AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              final t = _bgAnimation.value;
              final c1 = Color.lerp(_colorA, _colorB, t)!;
              final c2 = Color.lerp(_colorB, Colors.black, t)!;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.lerp(const Alignment(-0.5, -0.6),
                        const Alignment(0.5, 0.3), t)!,
                    radius: 1.3,
                    colors: [c1, c2, Colors.black],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: child,
              );
            },
            child: orientation == Orientation.portrait
                ? _buildPortrait(context, song)
                : _buildLandscape(context, song),
          ),
        );
      },
    );
  }

  Widget _buildPortrait(BuildContext context, SongModel song) {
    final audio = context.read<AudioProvider>();
    // ✅ watch solo para isFavorite (reconstruye cuando cambia favoritos)
    final isFav =
        context.select<LibraryProvider, bool>((l) => l.isFavorite(song));
    final library = context.read<LibraryProvider>();

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSongTitle(song),
                  const SizedBox(height: 28),
                  Selector<AudioProvider, bool>(
                    selector: (_, a) => a.isPlaying,
                    builder: (_, isPlaying, __) => Center(
                      child: VinylRecord(
                          isPlaying: isPlaying,
                          albumId: song.albumId,
                          glowColor: _glowColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAlbumInfo(song),
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
    );
  }

  Widget _buildLandscape(BuildContext context, SongModel song) {
    final audio = context.read<AudioProvider>();
    final isFav =
        context.select<LibraryProvider, bool>((l) => l.isFavorite(song));
    final library = context.read<LibraryProvider>();

    return SafeArea(
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderLandscape(context),
                    const SizedBox(height: 8),
                    Selector<AudioProvider, bool>(
                      selector: (_, a) => a.isPlaying,
                      builder: (_, isPlaying, __) => VinylRecord(
                          isPlaying: isPlaying,
                          albumId: song.albumId,
                          glowColor: _glowColor),
                    ),
                  ]),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSongTitle(song),
                  const SizedBox(height: 16),
                  _buildAlbumInfo(song),
                  const SizedBox(height: 20),
                  _buildProgressBar(audio),
                  const SizedBox(height: 16),
                  _buildControls(audio),
                  const SizedBox(height: 16),
                  _buildUtilityRow(context, song, isFav, library),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 32, color: AppTheme.onSurface)),
            const Expanded(
                child: Text('ACARMusic',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800))),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.queue_music_rounded,
                    color: AppTheme.onSurface)),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.onSurface)),
          ],
        ),
      );

  Widget _buildHeaderLandscape(BuildContext context) => Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 28, color: AppTheme.onSurface)),
          const Text('ACARMusic',
              style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.queue_music_rounded,
                  color: AppTheme.onSurface, size: 20)),
        ],
      );

  Widget _buildSongTitle(SongModel song) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(song.title ?? 'Pista desconocida',
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.1),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(song.artist ?? 'Artista desconocido',
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildAlbumInfo(SongModel song) =>
      Text(song.album ?? 'Álbum desconocido',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600));

  // ✅ Barra de progreso usa ValueListenableBuilder — sin rebuild del árbol Provider
  Widget _buildProgressBar(AudioProvider audio) =>
      ValueListenableBuilder<Duration>(
        valueListenable: audio.positionNotifier,
        builder: (context, pos, _) => ValueListenableBuilder<Duration>(
          valueListenable: audio.durationNotifier,
          builder: (context, dur, _) {
            final progress = dur.inMilliseconds > 0
                ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
            return Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(audio.formatDuration(pos),
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      Text(audio.formatDuration(dur),
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                    ]),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: AppTheme.tertiary,
                    inactiveTrackColor: AppTheme.surfaceVariant.withAlpha(100),
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                      value: progress.toDouble(),
                      onChanged: (v) => audio.seekTo(v)),
                ),
              ],
            );
          },
        ),
      );

  Widget _buildControls(AudioProvider audio) =>
      Selector<AudioProvider, (bool, bool, AppRepeatState)>(
        selector: (_, a) => (a.isPlaying, a.isShuffleOn, a.repeatMode),
        builder: (context, state, _) {
          final (isPlaying, shuffleOn, repeatMode) = state;
          final repeatIcon = repeatMode == AppRepeatState.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded;
          final repeatColor = repeatMode == AppRepeatState.off
              ? AppTheme.onSurfaceVariant
              : AppTheme.primary;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: audio.toggleShuffle,
                  icon: Icon(Icons.shuffle_rounded,
                      color: shuffleOn
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
                      size: 26)),
              IconButton(
                  onPressed: audio.skipPrevious,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: AppTheme.onSurface, size: 36)),
              GestureDetector(
                onTap: audio.togglePlayPause,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: AppTheme.tertiary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _glowColor.withAlpha(80),
                            blurRadius: 24,
                            spreadRadius: 4)
                      ]),
                  child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppTheme.onTertiary,
                      size: 36),
                ),
              ),
              IconButton(
                  onPressed: audio.skipNext,
                  icon: const Icon(Icons.skip_next_rounded,
                      color: AppTheme.onSurface, size: 36)),
              IconButton(
                  onPressed: audio.toggleRepeat,
                  icon: Icon(repeatIcon, color: repeatColor, size: 26)),
            ],
          );
        },
      );

  Widget _buildUtilityRow(BuildContext context, SongModel song, bool isFav,
          LibraryProvider library) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ✅ LIKE funcional
            _UtilBtn(
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: 'LIKE',
              color: isFav ? Colors.pinkAccent : AppTheme.onSurfaceVariant,
              onTap: () => isFav
                  ? library.removeFromFavorites(song)
                  : library.addToFavorites(song),
            ),
            // ✅ LISTA funcional
            _UtilBtn(
              icon: Icons.playlist_add_rounded,
              label: 'LISTA',
              color: AppTheme.onSurfaceVariant,
              onTap: () => _showAddToPlaylistSheet(context, library, song),
            ),
            // SHARE (próximamente)
            _UtilBtn(
              icon: Icons.share_rounded,
              label: 'SHARE',
              color: AppTheme.onSurfaceVariant.withAlpha(100),
              onTap: () {},
            ),
          ],
        ),
      );

  void _showAddToPlaylistSheet(
      BuildContext context, LibraryProvider library, SongModel song) {
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
            child: Text('Agregar a Lista',
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const Divider(height: 1, color: AppTheme.surfaceVariant),
          if (library.playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Crea una lista primero en la pestaña Listas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: library.playlists.length,
                itemBuilder: (_, i) {
                  final p = library.playlists[i];
                  return ListTile(
                    leading: const Icon(Icons.playlist_add_rounded,
                        color: AppTheme.primary),
                    title: Text(p.name,
                        style: const TextStyle(color: AppTheme.onSurface)),
                    onTap: () {
                      library.addSongToPlaylist(p.id, song.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Agregado a ${p.name}')));
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
}

class _UtilBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _UtilBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ]),
      );
}

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
  Color _colorA    = const Color(0xFF1A0A2E);
  Color _colorB    = const Color(0xFF0D0A20);
  Color _glowColor = const Color(0xFF6D28D9);
  int?  _lastSongId;

  late final AnimationController _bgCtrl;
  late final Animation<double>   _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _bgCtrl.dispose(); super.dispose(); }

  Future<void> _extractPalette(SongModel song) async {
    try {
      final art = await OnAudioQuery().queryArtwork(
          song.id, ArtworkType.AUDIO, format: ArtworkFormat.JPEG, size: 200);
      if (art == null || art.isEmpty) { _fallback(song); return; }
      final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(art), size: const Size(200, 200), maximumColorCount: 8);
      if (!mounted) return;
      setState(() {
        _glowColor = palette.vibrantColor?.color ?? palette.dominantColor?.color ?? _glowColor;
        _colorA    = palette.dominantColor?.color.withAlpha(180) ?? _colorA;
        _colorB    = palette.mutedColor?.color.withAlpha(200)    ?? _colorB;
      });
    } catch (_) { _fallback(song); }
  }

  void _fallback(SongModel song) {
    final hue = ((song.albumId ?? song.id) * 47) % 360;
    if (!mounted) return;
    setState(() {
      _colorA    = HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.15).toColor();
      _colorB    = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, 0.10).toColor();
      _glowColor = HSLColor.fromAHSL(1, hue.toDouble(), 0.8, 0.4).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, SongModel?>(
      selector: (_, a) => a.currentSong,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();
        if (_lastSongId != song.id) { _lastSongId = song.id; _extractPalette(song); }

        return OrientationBuilder(
          builder: (context, orientation) => AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, child) {
              final t  = _bgAnim.value;
              final c1 = Color.lerp(_colorA, _colorB, t)!;
              final c2 = Color.lerp(_colorB, Colors.black, t)!;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.lerp(
                        const Alignment(-0.5, -0.6), const Alignment(0.5, 0.3), t)!,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // VERTICAL — vinilo + controles apilados
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortrait(BuildContext context, SongModel song) {
    final audio   = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();
    final isFav   = context.select<LibraryProvider, bool>((l) => l.isFavorite(song));

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
                  // Vinilo giratorio
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

  // ═══════════════════════════════════════════════════════════════════════════
  // HORIZONTAL — inspirado en Samsung Music:
  //   izquierda: portada cuadrada redondeada
  //   derecha:   título, controles, barra
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLandscape(BuildContext context, SongModel song) {
    final audio   = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();
    final isFav   = context.select<LibraryProvider, bool>((l) => l.isFavorite(song));

    return SafeArea(
      child: Row(
        children: [
          // ── Portada izquierda ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: _LandscapeAlbumArt(song: song, glowColor: _glowColor),
            ),
          ),

          // ── Controles derecha ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 24, 16),
              child: Column(
                children: [
                  // Fila superior: bajar + cola
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 28, color: AppTheme.onSurface),
                      ),
                      Row(children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.queue_music_rounded,
                              color: AppTheme.onSurface, size: 22),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert_rounded,
                              color: AppTheme.onSurface, size: 22),
                        ),
                      ]),
                    ],
                  ),

                  const Spacer(),

                  // Título + artista
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(song.title ?? 'Pista desconocida',
                          textAlign: TextAlign.center,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.onSurface, fontSize: 22,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(song.artist ?? 'Artista desconocido',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Botones like / lista
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => isFav
                            ? library.removeFromFavorites(song)
                            : library.addToFavorites(song),
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.pinkAccent : AppTheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddToPlaylistSheet(context, library, song),
                        icon: const Icon(Icons.playlist_add_rounded,
                            color: AppTheme.onSurfaceVariant, size: 22),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Barra de progreso
                  _buildProgressBar(audio),
                  const SizedBox(height: 8),

                  // Controles
                  _buildControls(audio),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widgets compartidos ─────────────────────────────────────────────────

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
                  style: TextStyle(color: AppTheme.onSurface,
                      fontSize: 17, fontWeight: FontWeight.w800))),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.queue_music_rounded, color: AppTheme.onSurface)),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurface)),
          ],
        ),
      );

  Widget _buildSongTitle(SongModel song) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(song.title ?? 'Pista desconocida',
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 28,
                  fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(song.artist ?? 'Artista desconocido',
              style: const TextStyle(color: AppTheme.onSurfaceVariant,
                  fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildAlbumInfo(SongModel song) => Text(
        song.album ?? 'Álbum desconocido',
        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.onSurface,
            fontSize: 13, fontWeight: FontWeight.w600));

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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(audio.formatDuration(pos),
                      style: const TextStyle(color: AppTheme.onSurfaceVariant,
                          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  Text(audio.formatDuration(dur),
                      style: const TextStyle(color: AppTheme.onSurfaceVariant,
                          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                ]),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: AppTheme.tertiary,
                    inactiveTrackColor: AppTheme.surfaceVariant.withAlpha(100),
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                      value: progress.toDouble(), onChanged: (v) => audio.seekTo(v)),
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
              ? Icons.repeat_one_rounded : Icons.repeat_rounded;
          final repeatColor = repeatMode == AppRepeatState.off
              ? AppTheme.onSurfaceVariant : AppTheme.primary;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: audio.toggleShuffle,
                  icon: Icon(Icons.shuffle_rounded,
                      color: shuffleOn ? AppTheme.primary : AppTheme.onSurfaceVariant,
                      size: 26)),
              IconButton(
                  onPressed: audio.skipPrevious,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: AppTheme.onSurface, size: 36)),
              GestureDetector(
                onTap: audio.togglePlayPause,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: _glowColor.withAlpha(80), blurRadius: 24, spreadRadius: 4)],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.onTertiary, size: 36),
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

  Widget _buildUtilityRow(BuildContext context, SongModel song,
      bool isFav, LibraryProvider library) =>
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
            _UtilBtn(
              icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: 'LIKE',
              color: isFav ? Colors.pinkAccent : AppTheme.onSurfaceVariant,
              onTap: () => isFav
                  ? library.removeFromFavorites(song)
                  : library.addToFavorites(song),
            ),
            _UtilBtn(
              icon: Icons.playlist_add_rounded,
              label: 'LISTA',
              color: AppTheme.onSurfaceVariant,
              onTap: () => _showAddToPlaylistSheet(context, library, song),
            ),
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
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: AppTheme.outline, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Agregar a Lista',
                style: TextStyle(color: AppTheme.onSurface,
                    fontWeight: FontWeight.bold, fontSize: 16)),
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

// ─── Portada cuadrada para landscape (sin vinilo) ────────────────────────────
class _LandscapeAlbumArt extends StatelessWidget {
  final SongModel song;
  final Color glowColor;
  const _LandscapeAlbumArt({required this.song, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide * 0.55;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: glowColor.withAlpha(100), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: RepaintBoundary(
          child: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
            artworkWidth:  size,
            artworkHeight: size,
            keepOldArtwork: true,
            nullArtworkWidget: Container(
              color: AppTheme.surfaceContainerHigh,
              child: const Icon(Icons.music_note_rounded,
                  color: AppTheme.onSurfaceVariant, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón de utilidad ────────────────────────────────────────────────────────
class _UtilBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _UtilBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ]),
      );
}
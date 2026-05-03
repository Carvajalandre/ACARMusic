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

/// WidgetsBindingObserver: pausa animaciones cuando la app está en segundo plano
/// → ahorra batería y CPU mientras el usuario usa otras apps
class _PlayerContentState extends State<_PlayerContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Color _colorA    = const Color(0xFF1A0A2E);
  Color _colorB    = const Color(0xFF0D0A20);
  Color _glowColor = const Color(0xFF6D28D9);
  int?  _lastSongId;
  bool  _showQueue = false;

  // ScrollController para hacer scroll automático a la canción actual
  final ScrollController _queueScrollCtrl = ScrollController();
  static const double _queueItemHeight = 60.0;

  late final AnimationController _bgCtrl;
  late final Animation<double>   _bgAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
  }

  /// Pausa animaciones cuando la app está en segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_bgCtrl.isAnimating) _bgCtrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose();
    _queueScrollCtrl.dispose();
    super.dispose();
  }

  /// Abre la cola y hace scroll automático a la canción actual
  void _openQueue(int currentIdx) {
    setState(() => _showQueue = true);
    if (currentIdx > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_queueScrollCtrl.hasClients) {
          _queueScrollCtrl.animateTo(
            (currentIdx * _queueItemHeight).clamp(
                0.0, _queueScrollCtrl.position.maxScrollExtent),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _extractPalette(SongModel song) async {
    try {
      final art = await OnAudioQuery().queryArtwork(
          song.id, ArtworkType.AUDIO, format: ArtworkFormat.JPEG, size: 200);
      if (art == null || art.isEmpty) { _fallback(song); return; }
      final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(art), size: const Size(200, 200), maximumColorCount: 8);
      if (!mounted) return;
      setState(() {
        _glowColor = palette.vibrantColor?.color ??
            palette.dominantColor?.color ?? _glowColor;
        _colorA = palette.dominantColor?.color?.withAlpha(180) ?? _colorA;
        _colorB = palette.mutedColor?.color?.withAlpha(200)    ?? _colorB;
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

        if (_lastSongId != song.id) {
          _lastSongId = song.id;
          _extractPalette(song);
        }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // VERTICAL — layout completamente fijo, sin scroll, sin reflow por texto
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortrait(BuildContext context, SongModel song) {
    final audio   = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();
    final isFav   = context.select<LibraryProvider, bool>((l) => l.isFavorite(song));

    return SafeArea(
      child: Column(
        children: [
          // ── Header fijo ──────────────────────────────────────────────
          _headerPortrait(context),

          // ── Título + artista: altura fija de 72px ───────────────────
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title ?? 'Pista desconocida',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.onSurface, fontSize: 22,
                          fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                  const SizedBox(height: 4),
                  Text(song.artist ?? 'Artista desconocido',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),

          // ── Vinilo / Cola: ocupa el espacio restante ─────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _showQueue
                  ? Padding(
                      key: const ValueKey('queue'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildQueuePanel(audio, song),
                    )
                  : Center(
                      key: const ValueKey('vinyl'),
                      child: Selector<AudioProvider, bool>(
                        selector: (_, a) => a.isPlaying,
                        builder: (_, isPlaying, __) =>
                            LayoutBuilder(builder: (_, c) {
                          // Tamaño del vinilo basado en el espacio disponible
                          final maxSize = (c.maxHeight * 0.92).clamp(200.0, 300.0);
                          return VinylRecord(
                            isPlaying: isPlaying,
                            albumId: song.albumId,
                            glowColor: _glowColor,
                            size: maxSize,
                          );
                        }),
                      ),
                    ),
            ),
          ),

          // ── Álbum: fijo ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(song.album ?? 'Álbum desconocido',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),

          // ── Barra de progreso: fija ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _progressBar(audio),
          ),
          const SizedBox(height: 8),

          // ── Controles: fijos ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _controls(audio),
          ),
          const SizedBox(height: 12),

          // ── Botones Like/Lista/Cola: fijos ────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _actionButtons(context, song, isFav, library, audio),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HORIZONTAL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLandscape(BuildContext context, SongModel song) {
    final audio    = context.read<AudioProvider>();
    final library  = context.read<LibraryProvider>();
    final isFav    = context.select<LibraryProvider, bool>((l) => l.isFavorite(song));
    final screenH  = MediaQuery.of(context).size.height;
    final vinylSize = (screenH * 0.82).clamp(180.0, 260.0);

    return SafeArea(
      child: Row(children: [
        // ── Izquierda: flecha + vinilo/cola ───────────────────────────
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Tooltip(
                  message: 'Minimizar',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 32, color: AppTheme.onSurface),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showQueue
                      ? _buildQueuePanel(audio, song)
                      : Center(
                          key: const ValueKey('vinyl'),
                          child: Selector<AudioProvider, bool>(
                            selector: (_, a) => a.isPlaying,
                            builder: (_, isPlaying, __) => VinylRecord(
                              isPlaying: isPlaying,
                              albumId: song.albumId,
                              glowColor: _glowColor,
                              size: vinylSize,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        // ── Derecha: controles ────────────────────────────────────────
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Tooltip(
                    message: 'Más opciones',
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppTheme.onSurface, size: 22)),
                  ),
                ]),
                const Spacer(),
                // Título fijo 1 línea
                Text(song.title ?? 'Pista desconocida',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20, fontWeight: FontWeight.w900,
                        letterSpacing: -0.8)),
                const SizedBox(height: 4),
                Text(song.artist ?? 'Artista desconocido',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _actionButtons(context, song, isFav, library, audio,
                    compact: true),
                const Spacer(),
                _progressBar(audio),
                const SizedBox(height: 8),
                _controls(audio),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Panel de cola ─────────────────────────────────────────────────────────
  Widget _buildQueuePanel(AudioProvider audio, SongModel currentSong) {
    final queue      = audio.queue;
    final currentIdx = audio.currentIndex;

    return Container(
      key: const ValueKey('queue'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(children: [
            Text('Cola de reproducción',
                style: TextStyle(
                    color: AppTheme.onSurface.withAlpha(180),
                    fontSize: 12, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const Spacer(),
            // Contador posición actual
            Text('${currentIdx + 1} / ${queue.length}',
                style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withAlpha(160),
                    fontSize: 11)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: _queueScrollCtrl,
            padding: EdgeInsets.zero,
            itemCount: queue.length,
            itemExtent: _queueItemHeight,
            itemBuilder: (context, i) {
              final song      = queue[i];
              final isCurrent = i == currentIdx;
              return Container(
                color: isCurrent
                    ? AppTheme.primary.withAlpha(20)
                    : Colors.transparent,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 38, height: 38,
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        artworkFit: BoxFit.cover,
                        artworkWidth: 38, artworkHeight: 38,
                        keepOldArtwork: true,
                        nullArtworkWidget: Container(
                          color: AppTheme.surfaceContainerHigh,
                          child: const Icon(Icons.music_note_rounded,
                              color: AppTheme.onSurfaceVariant, size: 16)),
                      ),
                    ),
                  ),
                  title: Text(song.title ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isCurrent ? AppTheme.primary : AppTheme.onSurface,
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500)),
                  subtitle: Text(song.artist ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.onSurfaceVariant)),
                  trailing: isCurrent
                      ? const Icon(Icons.equalizer_rounded,
                          color: AppTheme.primary, size: 16)
                      : null,
                  onTap: () => audio.playSong(song, queue, i),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── Header portrait ───────────────────────────────────────────────────────
  Widget _headerPortrait(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(children: [
          Tooltip(
            message: 'Minimizar',
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 32, color: AppTheme.onSurface)),
          ),
          const Expanded(
            child: Text('ACARMusic',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurface,
                    fontSize: 17, fontWeight: FontWeight.w800))),
          Tooltip(
            message: 'Más opciones',
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.onSurface)),
          ),
        ]),
      );

  // ── Barra de progreso ─────────────────────────────────────────────────────
  Widget _progressBar(AudioProvider audio) =>
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
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                  Text(audio.formatDuration(dur),
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
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
                      value: progress.toDouble(),
                      onChanged: (v) => audio.seekTo(v)),
                ),
              ],
            );
          },
        ),
      );

  // ── Controles de reproducción ─────────────────────────────────────────────
  Widget _controls(AudioProvider audio) =>
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
              Tooltip(message: 'Mezclar',
                child: IconButton(
                    onPressed: audio.toggleShuffle,
                    icon: Icon(Icons.shuffle_rounded,
                        color: shuffleOn ? AppTheme.primary : AppTheme.onSurfaceVariant,
                        size: 26))),
              Tooltip(message: 'Anterior',
                child: IconButton(
                    onPressed: audio.skipPrevious,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: AppTheme.onSurface, size: 36))),
              Tooltip(
                message: isPlaying ? 'Pausar' : 'Reproducir',
                child: GestureDetector(
                  onTap: audio.togglePlayPause,
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: _glowColor.withAlpha(80),
                          blurRadius: 24, spreadRadius: 4)],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.onTertiary, size: 34),
                  ),
                ),
              ),
              Tooltip(message: 'Siguiente',
                child: IconButton(
                    onPressed: audio.skipNext,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppTheme.onSurface, size: 36))),
              Tooltip(
                message: repeatMode == AppRepeatState.one
                    ? 'Repetir esta pista'
                    : repeatMode == AppRepeatState.all
                        ? 'Repetir todo' : 'Sin repetición',
                child: IconButton(
                    onPressed: audio.toggleRepeat,
                    icon: Icon(repeatIcon, color: repeatColor, size: 26))),
            ],
          );
        },
      );

  // ── 3 botones: Like | Lista | Cola ────────────────────────────────────────
  // Cola abre el panel con scroll automático a la canción actual
  Widget _actionButtons(BuildContext context, SongModel song, bool isFav,
      LibraryProvider library, AudioProvider audio, {bool compact = false}) {
    final iconSize = compact ? 22.0 : 24.0;
    final spacing  = compact ? 40.0 : 48.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: isFav ? 'Quitar de Favoritos' : 'Agregar a Favoritos',
          child: _ActionBtn(
            icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: 'LIKE',
            color: isFav ? Colors.pinkAccent : AppTheme.onSurfaceVariant,
            size: iconSize,
            onTap: () => isFav
                ? library.removeFromFavorites(song)
                : library.addToFavorites(song),
          ),
        ),
        SizedBox(width: spacing),
        Tooltip(
          message: 'Agregar a Lista',
          child: _ActionBtn(
            icon: Icons.playlist_add_rounded,
            label: 'LISTA',
            color: AppTheme.onSurfaceVariant,
            size: iconSize,
            onTap: () => _addToPlaylistSheet(context, library, song),
          ),
        ),
        SizedBox(width: spacing),
        // Cola: abre panel Y hace scroll a la canción actual
        Tooltip(
          message: 'Cola de reproducción',
          child: _ActionBtn(
            icon: Icons.queue_music_rounded,
            label: 'COLA',
            color: _showQueue ? AppTheme.primary : AppTheme.onSurfaceVariant,
            size: iconSize,
            onTap: () {
              if (_showQueue) {
                setState(() => _showQueue = false);
              } else {
                _openQueue(audio.currentIndex);
              }
            },
          ),
        ),
      ],
    );
  }

  void _addToPlaylistSheet(
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
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Agregar a Lista',
                style: TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1, color: AppTheme.surfaceVariant),
          if (library.playlists.isEmpty)
            const Padding(padding: EdgeInsets.all(32),
                child: Text('Crea una lista primero en la pestaña Listas',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.onSurfaceVariant)))
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

// ─── Botón de acción (Like / Lista / Cola) ────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: size),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(
              color: color, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ]),
      );
}
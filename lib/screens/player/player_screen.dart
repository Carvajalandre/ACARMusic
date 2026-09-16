import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../audio/audio_provider.dart';
import '../../library/library_provider.dart';
import '../../visualizers/animation_style.dart';
import '../../visualizers/visualizer_factory.dart';
import '../../widgets/buttons/tap_scale.dart';
import '../../widgets/buttons/glow_button.dart';
import '../../audio/settings/sleep_timer_sheet.dart';
import '../../audio/settings/animation_style_sheet.dart';
import '../../audio/settings/equalizer_dialog.dart';

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
  Color _colorA = const Color(0xFF1A0A2E);
  Color _colorB = const Color(0xFF0D0A20);
  Color _glowColor = const Color(0xFF6D28D9);
  Uint8List? _artworkBytes;
  int? _lastSongId;
  bool _showQueue = false;

  // ScrollController para hacer scroll automático a la canción actual
  final ScrollController _queueScrollCtrl = ScrollController();
  static const double _queueItemHeight = 60.0;

  late final AnimationController _bgCtrl;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
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
              0.0,
              _queueScrollCtrl.position.maxScrollExtent,
            ),
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
        song.id,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      );
      if (art == null || art.isEmpty) {
        if (mounted) setState(() => _artworkBytes = null);
        _fallback(song);
        return;
      }
      if (mounted) setState(() => _artworkBytes = art);
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(art),
        size: const Size(200, 200),
        maximumColorCount: 8,
      );
      if (!mounted) return;
      setState(() {
        _glowColor = palette.vibrantColor?.color ??
            palette.dominantColor?.color ??
            _glowColor;
        _colorA = palette.dominantColor?.color.withAlpha(180) ?? _colorA;
        _colorB = palette.mutedColor?.color.withAlpha(200) ?? _colorB;
      });
    } catch (_) {
      _fallback(song);
    }
  }

  void _fallback(SongModel song) {
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
          _artworkBytes = null;
          _extractPalette(song);
        }

        return OrientationBuilder(
          builder: (context, orientation) => AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, child) {
              final t = _bgAnim.value;
              final c1 = Color.lerp(_colorA, _colorB, t)!;
              final c2 = Color.lerp(_colorB, Colors.black, t)!;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [c1, c2, Colors.black],
                    stops: const [0.0, 0.45, 1.0],
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
  // VERTICAL — layout adaptativo usando LayoutBuilder para resistir
  // pantallas pequeñas (multi-ventana, PIP, tablets pequeñas)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortrait(BuildContext context, SongModel song) {
    final audio = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();
    final isFav = context.select<LibraryProvider, bool>(
      (l) => l.isFavorite(song),
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Modo compacto cuando la altura disponible es menor a 600px
          final isCompact = constraints.maxHeight < 600;
          final isVeryTight = constraints.maxHeight < 380;

          final body = Column(
            children: [
              // ── Header fijo ──────────────────────────────────────────────
              _headerPortrait(context),

              // ── Vinilo / Cola ────────────────────────────────────────────
              if (isVeryTight)
                SizedBox(
                  height: 80,
                  child: _buildVinylOrQueue(context, song, audio, isCompact),
                )
              else
                Expanded(
                  child: _buildVinylOrQueue(context, song, audio, isCompact),
                ),

              // ── Título y autor debajo de la animación ────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  isVeryTight ? 2 : 6,
                  24,
                  isCompact ? 4 : 8,
                ),
                child: Column(
                  children: [
                    Text(
                      song.title ?? 'Pista desconocida',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: isVeryTight ? 14 : (isCompact ? 17 : 20),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (!isVeryTight) const SizedBox(height: 3),
                    if (!isVeryTight)
                      Text(
                        song.artist ?? 'Artista desconocido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: isVeryTight ? 2 : (isCompact ? 4 : 12)),

              // ── Barra de progreso ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _progressBar(audio),
              ),
              SizedBox(height: isVeryTight ? 2 : (isCompact ? 4 : 8)),

              // ── Controles ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _controls(audio),
              ),
              SizedBox(height: isVeryTight ? 2 : (isCompact ? 6 : 12)),

              // ── Botones Like/Lista/Cola ───────────────────────────────────
              Padding(
                padding: EdgeInsets.only(
                  // Reserva una franja inferior independiente para avisos.
                  // Al crecer esta zona, todo el bloque de metadatos,
                  // progreso y controles queda ligeramente más arriba.
                  bottom: isVeryTight ? 14 : (isCompact ? 34 : 58),
                ),
                child: _actionButtons(
                  context,
                  song,
                  isFav,
                  library,
                  audio,
                  compact: isVeryTight || isCompact,
                ),
              ),
            ],
          );

          if (isVeryTight) {
            return SingleChildScrollView(child: body);
          }
          return body;
        },
      ),
    );
  }

  Widget _buildVinylOrQueue(
    BuildContext context,
    SongModel song,
    AudioProvider audio,
    bool isCompact,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _showQueue
          ? Padding(
              key: const ValueKey('queue'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQueuePanel(audio, song),
            )
          : Center(
              key: const ValueKey('visualizer'),
              child: Selector<AudioProvider, bool>(
                selector: (_, a) => a.isPlaying,
                builder: (_, isPlaying, __) => LayoutBuilder(
                  builder: (_, c) {
                    return Selector<AudioProvider, VisualizerStyle>(
                      selector: (_, a) => a.animationStyle,
                      builder: (_, style, __) {
                        final available = c.biggest.shortestSide;
                        final baseSize = (c.maxHeight * .92)
                            .clamp(isCompact ? 120.0 : 200.0, 300.0)
                            .toDouble();
                        final maxSize = switch (style) {
                          VisualizerStyle.cassette =>
                            (available * .98).clamp(120.0, 420.0).toDouble(),
                          VisualizerStyle.radialVisualizer => (baseSize * 1.15)
                              .clamp(120.0, available * .98)
                              .toDouble(),
                          _ => baseSize,
                        };
                        return VisualizerFactory(
                          style: style,
                          isPlaying: isPlaying,
                          albumId: song.albumId,
                          glowColor: _glowColor,
                          paletteDominant: _colorA,
                          paletteMuted: _colorB,
                          artworkBytes: _artworkBytes,
                          title: song.title,
                          artist: song.artist,
                          size: maxSize,
                          fftStream: audio.visualizerService.fftStream,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HORIZONTAL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLandscape(BuildContext context, SongModel song) {
    final audio = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();
    final isFav = context.select<LibraryProvider, bool>(
      (l) => l.isFavorite(song),
    );
    return SafeArea(
      child: Row(
        children: [
          // ── Izquierda: flecha + vinilo/cola ───────────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 32,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableSide =
                          constraints.maxWidth < constraints.maxHeight
                              ? constraints.maxWidth
                              : constraints.maxHeight;
                      return ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _showQueue
                              ? _buildQueuePanel(audio, song)
                              : Center(
                                  key: const ValueKey('visualizer'),
                                  child: Selector<AudioProvider, bool>(
                                    selector: (_, a) => a.isPlaying,
                                    builder: (_, isPlaying, __) => Selector<
                                        AudioProvider, VisualizerStyle>(
                                      selector: (_, a) => a.animationStyle,
                                      builder: (_, style, __) {
                                        final baseSize = (availableSide - 24)
                                            .clamp(96.0, 260.0)
                                            .toDouble();
                                        final visualizerSize = switch (style) {
                                          VisualizerStyle.cassette =>
                                            (availableSide * .98)
                                                .clamp(96.0, 420.0)
                                                .toDouble(),
                                          VisualizerStyle.radialVisualizer =>
                                            (baseSize * 1.15)
                                                .clamp(
                                                    96.0, availableSide * .98)
                                                .toDouble(),
                                          _ => baseSize,
                                        };
                                        return VisualizerFactory(
                                          style: style,
                                          isPlaying: isPlaying,
                                          albumId: song.albumId,
                                          glowColor: _glowColor,
                                          paletteDominant: _colorA,
                                          paletteMuted: _colorB,
                                          artworkBytes: _artworkBytes,
                                          title: song.title,
                                          artist: song.artist,
                                          size: visualizerSize,
                                          fftStream:
                                              audio.visualizerService.fftStream,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showPlayerOptions(context),
                        tooltip: 'Más opciones',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppTheme.onSurface,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Título fijo 1 línea
                  Text(
                    song.title ?? 'Pista desconocida',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist ?? 'Artista desconocido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _actionButtons(
                    context,
                    song,
                    isFav,
                    library,
                    audio,
                    compact: true,
                  ),
                  const Spacer(),
                  _progressBar(audio),
                  const SizedBox(height: 8),
                  _controls(audio),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel de cola ─────────────────────────────────────────────────────────
  Widget _buildQueuePanel(AudioProvider audio, SongModel currentSong) {
    final queue = audio.queue;
    final currentIdx = audio.currentIndex;

    return Container(
      key: const ValueKey('queue'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Text(
                  'Cola de reproducción',
                  style: TextStyle(
                    color: AppTheme.onSurface.withAlpha(180),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Contador posición actual
                Text(
                  '${currentIdx + 1} / ${queue.length}',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withAlpha(160),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _queueScrollCtrl,
              padding: EdgeInsets.zero,
              itemCount: queue.length,
              itemExtent: _queueItemHeight,
              itemBuilder: (context, i) {
                final song = queue[i];
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
                        width: 38,
                        height: 38,
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          size: 256,
                          quality: 90,
                          artworkFit: BoxFit.cover,
                          artworkWidth: 38,
                          artworkHeight: 38,
                          artworkQuality: FilterQuality.high,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            color: AppTheme.surfaceContainerHigh,
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: AppTheme.onSurfaceVariant,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      song.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isCurrent ? AppTheme.primary : AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      song.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.equalizer_rounded,
                            color: AppTheme.primary,
                            size: 16,
                          )
                        : null,
                    onTap: () => audio.playSong(song, queue, i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header portrait ───────────────────────────────────────────────────────
  Widget _headerPortrait(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 32,
                color: AppTheme.onSurface,
              ),
            ),
            const Expanded(
              child: Text(
                'ACARMusic',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showPlayerOptions(context),
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.onSurface),
            ),
          ],
        ),
      );

  // ── Barra de progreso ─────────────────────────────────────────────────────
  Widget _progressBar(AudioProvider audio) => ValueListenableBuilder<Duration>(
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
                    Text(
                      audio.formatDuration(pos),
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      audio.formatDuration(dur),
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                    onChanged: (v) => audio.seekTo(v),
                  ),
                ),
              ],
            );
          },
        ),
      );

  // ── Controles de reproducción ─────────────────────────────────────────────
  Widget _controls(
    AudioProvider audio,
  ) =>
      Selector<AudioProvider, (bool, bool, AppRepeatState)>(
        selector: (_, a) => (a.isPlaying, a.isShuffleOn, a.repeatMode),
        builder: (context, state, _) {
          final (isPlaying, shuffleOn, repeatMode) = state;
          final repeatIcon = repeatMode == AppRepeatState.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded;
          final repeatActive = repeatMode != AppRepeatState.off;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Shuffle con glow ──────────────────────────────────────
              TapScale(
                onTap: audio.toggleShuffle,
                tooltip: 'Mezclar',
                child: GlowButton(
                  active: shuffleOn,
                  activeColor: AppTheme.primary,
                  glowColor: AppTheme.primary,
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shuffle_rounded,
                          color: shuffleOn
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                          size: 26,
                        ),
                        if (!shuffleOn)
                          Positioned(
                            child: Transform.rotate(
                              angle: -0.785,
                              child: Container(
                                width: 28,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppTheme.onSurfaceVariant,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Anterior ──────────────────────────────────────────────
              TapScale(
                onTap: audio.skipPrevious,
                tooltip: 'Anterior',
                scale: 0.82,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.skip_previous_rounded,
                    color: AppTheme.onSurface,
                    size: 36,
                  ),
                ),
              ),
              // ── Play / Pause con AnimatedSwitcher ─────────────────────
              TapScale(
                onTap: audio.togglePlayPause,
                tooltip: isPlaying ? 'Pausar' : 'Reproducir',
                scale: 0.90,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor.withAlpha(80),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    reverseDuration: const Duration(milliseconds: 90),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale:
                            Tween<double>(begin: 0.84, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(isPlaying),
                      color: AppTheme.onTertiary,
                      size: 34,
                    ),
                  ),
                ),
              ),
              // ── Siguiente ─────────────────────────────────────────────
              TapScale(
                onTap: audio.skipNext,
                tooltip: 'Siguiente',
                scale: 0.82,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.skip_next_rounded,
                    color: AppTheme.onSurface,
                    size: 36,
                  ),
                ),
              ),
              // ── Repeat con glow ───────────────────────────────────────
              TapScale(
                onTap: audio.toggleRepeat,
                tooltip: repeatMode == AppRepeatState.one
                    ? 'Repetir esta pista'
                    : repeatMode == AppRepeatState.all
                        ? 'Repetir todo'
                        : 'Sin repetición',
                child: GlowButton(
                  active: repeatActive,
                  activeColor: AppTheme.primary,
                  glowColor: AppTheme.primary,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      repeatIcon,
                      key: ValueKey(repeatMode),
                      color: repeatActive
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

  // ── 3 botones: Like | Lista | Cola ────────────────────────────────────────
  // Cola abre el panel con scroll automático a la canción actual
  Widget _actionButtons(
    BuildContext context,
    SongModel song,
    bool isFav,
    LibraryProvider library,
    AudioProvider audio, {
    bool compact = false,
  }) {
    final iconSize = compact ? 22.0 : 24.0;
    final spacing = compact ? 22.0 : 30.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionBtn(
          icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: 'LIKE',
          color: isFav ? Colors.pinkAccent : AppTheme.onSurfaceVariant,
          size: iconSize,
          burstOnTap: !isFav,
          onTap: () => isFav
              ? library.removeFromFavorites(song)
              : library.addToFavorites(song),
        ),
        SizedBox(width: spacing),
        _ActionBtn(
          icon: Icons.playlist_add_rounded,
          label: 'LISTA',
          color: AppTheme.onSurfaceVariant,
          size: iconSize,
          onTap: () => _addToPlaylistSheet(context, library, song),
        ),
        SizedBox(width: spacing),
        // Cola: abre panel Y hace scroll a la canción actual
        _ActionBtn(
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
        SizedBox(width: spacing),
        _ActionBtn(
          icon: Icons.speed_rounded,
          label: '${audio.playbackSpeed}X',
          color: AppTheme.onSurfaceVariant,
          size: iconSize,
          onTap: () => _showPlaybackSpeedSheet(context, audio),
        ),
      ],
    );
  }

  void _showPlaybackSpeedSheet(BuildContext context, AudioProvider audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Velocidad de reproducción',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...[0.5, 1.0, 1.5, 2.0].map(
                (speed) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.speed_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    '${speed}x',
                    style: const TextStyle(color: AppTheme.onSurface),
                  ),
                  trailing: audio.playbackSpeed == speed
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () async {
                    await audio.setPlaybackSpeed(speed);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menú Más opciones ────────────────────────────────────────────────────
  void _showPlayerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Más opciones',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.surfaceVariant),
                // Animaciones
                ListTile(
                  leading: const Icon(
                    Icons.animation_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Animaciones',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Selector<AudioProvider, VisualizerStyle>(
                    selector: (_, a) => a.animationStyle,
                    builder: (_, style, __) => Text(
                      style.displayName,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAnimationStyleSheet(context);
                  },
                ),
                // Ecualizador → abre app de sonido del sistema
                ListTile(
                  leading: const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Calidad y efectos de sonido',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openSystemEqualizer(context);
                  },
                ),
                // Temporizador de sueño — funcional, igual que en Ajustes
                ListTile(
                  leading: const Icon(
                    Icons.bedtime_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Temporizador de sueño',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Selector<AudioProvider, int>(
                    selector: (_, a) => a.sleepTimerMinutes,
                    builder: (_, minutes, __) => Text(
                      minutes > 0 ? '$minutes min activo' : 'Desactivado',
                      style: TextStyle(
                        color: minutes > 0
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSleepTimerSheet(
                      context,
                      context.read<AudioProvider>(),
                    );
                  },
                ),
                // Ajustes
                ListTile(
                  leading: const Icon(
                    Icons.settings_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Ajustes',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showComingSoon(context, 'Ajustes desde el reproductor');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSystemEqualizer(BuildContext context) async {
    final audio = context.read<AudioProvider>();
    await EqualizerDialog.openSoundEffects(context, audio);
  }

  void _showAnimationStyleSheet(BuildContext context) {
    final audio = context.read<AudioProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AnimationStyleSheet(audio: audio),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: Row(
          children: [
            const Icon(
              Icons.build_circle_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              feature,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Estamos desarrollando esta función.\n¡Pronto estará disponible!',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, AudioProvider audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SleepTimerSheet(audio: audio),
    );
  }

  void _addToPlaylistSheet(
    BuildContext context,
    LibraryProvider library,
    SongModel song,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Agregar a Lista',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.surfaceVariant),
            if (library.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Crea una lista primero en la pestaña Listas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: library.playlists.length,
                  itemBuilder: (_, i) {
                    final p = library.playlists[i];
                    return ListTile(
                      leading: const Icon(
                        Icons.playlist_add_rounded,
                        color: AppTheme.primary,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(color: AppTheme.onSurface),
                      ),
                      onTap: () {
                        library.addSongToPlaylist(p.id, song.id);
                        Navigator.pop(ctx);
                        _showPlaylistAddedMessage(context, p.name);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPlaylistAddedMessage(BuildContext context, String playlistName) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1700),
          margin: EdgeInsets.only(
            left: 20,
            right: 20,
            // En vertical ocupa la franja reservada bajo las acciones; no
            // cubre el progreso, los controles ni los botones inferiores.
            bottom: isLandscape ? 92 : 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.playlist_add_check_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Agregado a $playlistName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final bool burstOnTap;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    this.burstOnTap = false,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      // Más lento para que el crecimiento y el rastro sean visibles.
      duration: const Duration(milliseconds: 1150),
    );
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    if (widget.burstOnTap) {
      _burstController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.34,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.34,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    ]).animate(_burstController);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _burstController,
        builder: (context, child) => SizedBox(
          width: widget.size + 34,
          height: widget.size + 42,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 7; i++)
                _HeartTrail(
                  index: i,
                  progress: _burstController.value,
                  color: widget.color,
                ),
              Transform.scale(scale: scale.value, child: child),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: widget.size),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartTrail extends StatelessWidget {
  final int index;
  final double progress;
  final Color color;

  const _HeartTrail({
    required this.index,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final start = 0.04 + index * 0.045;
    final end = (start + 0.56).clamp(0.0, 1.0).toDouble();
    final local =
        ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    final opacity = progress < start
        ? 0.0
        : (1.0 - Curves.easeIn.transform(local)).clamp(0.0, 1.0).toDouble();
    final direction = index.isEven ? -1.0 : 1.0;
    final dx = direction * (7.0 + (index / 2).ceil() * 7.0) +
        math.sin(index * 1.7) * 4.0;
    final dy = -10.0 - local * (34.0 + index * 3.5);
    final size = 7.5 + index * 0.9 + local * 1.5;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Icon(Icons.favorite_rounded, color: color, size: size),
      ),
    );
  }
}

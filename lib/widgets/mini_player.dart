import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../audio/audio_provider.dart';
import '../screens/player/player_screen.dart';
import 'buttons/pressable_scale.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Color _accent = AppTheme.primary;
  int? _lastSongId;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final song = audio.currentSong;
    if (song == null) return const SizedBox.shrink();
    if (_lastSongId != song.id) {
      _lastSongId = song.id;
      _loadAccent(song);
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PlayerScreen(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(animation),
            child: child,
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        decoration: BoxDecoration(
          color: Color.lerp(AppTheme.surfaceContainerHigh, _accent, 0.58)!
              .withAlpha(242),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _accent.withAlpha(100)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(128),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Portada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          size: 256,
                          quality: 90,
                          artworkFit: BoxFit.cover,
                          artworkWidth: 48,
                          artworkHeight: 48,
                          artworkQuality: FilterQuality.high,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            color: Colors.black.withAlpha(70),
                            child: const Icon(Icons.music_note_rounded,
                                color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título y artista
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        Text(song.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                                color: Colors.white.withAlpha(190),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  // Controles — solo escuchan isPlaying
                  PressableIconButton(
                    onPressed: audio.skipPrevious,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white),
                  ),
                  Selector<AudioProvider, bool>(
                    selector: (_, a) => a.isPlaying,
                    builder: (_, isPlaying, __) => PressableScale(
                      onTap: audio.togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 130),
                          reverseDuration: const Duration(milliseconds: 80),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.84, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          ),
                          child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              color: _accent),
                        ),
                      ),
                    ),
                  ),
                  PressableIconButton(
                    onPressed: audio.skipNext,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            // Barra de progreso — usa ValueListenableBuilder, NO Consumer
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _ProgressBar(audio: audio, color: _accent),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAccent(SongModel song) async {
    try {
      final art = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG, size: 160);
      var result = _fallbackColor(song);
      if (art != null && art.isNotEmpty) {
        final palette = await PaletteGenerator.fromImageProvider(
            MemoryImage(art),
            size: const Size(160, 160),
            maximumColorCount: 8);
        result = palette.vibrantColor?.color ??
            palette.dominantColor?.color ??
            result;
      }
      if (mounted && _lastSongId == song.id) setState(() => _accent = result);
    } catch (_) {
      if (mounted && _lastSongId == song.id) {
        setState(() => _accent = _fallbackColor(song));
      }
    }
  }

  Color _fallbackColor(SongModel song) {
    final hue = ((song.albumId ?? song.id) * 47) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.68, 0.42).toColor();
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioProvider audio;
  final Color color;
  const _ProgressBar({required this.audio, required this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: audio.positionNotifier,
      builder: (_, pos, __) {
        final dur = audio.durationNotifier.value;
        final progress = dur.inMilliseconds > 0
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        return Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withAlpha(128),
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (_, c) => Container(
              width: c.maxWidth * progress,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

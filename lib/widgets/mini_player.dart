import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Solo escucha cambios de canción (id), no de posición
    final songId =
        context.select<AudioProvider, int?>((a) => a.currentSong?.id);
    final audio = context.read<AudioProvider>();
    final song = audio.currentSong;
    if (songId == null || song == null) return const SizedBox.shrink();

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
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(13)),
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
                          artworkFit: BoxFit.cover,
                          artworkWidth: 48,
                          artworkHeight: 48,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            color: AppTheme.surfaceContainerHigh,
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
                        Text(song.title ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                                color: AppTheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        Text(song.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  // Controles — solo escuchan isPlaying
                  _PressableIconButton(
                    onPressed: audio.skipPrevious,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: AppTheme.onSurface),
                  ),
                  Selector<AudioProvider, bool>(
                    selector: (_, a) => a.isPlaying,
                    builder: (_, isPlaying, __) => _PressableScale(
                      onTap: audio.togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: AppTheme.tertiary, shape: BoxShape.circle),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              color: AppTheme.onTertiary),
                        ),
                      ),
                    ),
                  ),
                  _PressableIconButton(
                    onPressed: audio.skipNext,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppTheme.onSurface),
                  ),
                ],
              ),
            ),
            // Barra de progreso — usa ValueListenableBuilder, NO Consumer
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _ProgressBar(audio: audio),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioProvider audio;
  const _ProgressBar({required this.audio});

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
                color: AppTheme.tertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PressableIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;

  const _PressableIconButton({
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: icon,
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

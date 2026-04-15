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
    final audio = context.read<AudioProvider>();
    final songId =
        context.select<AudioProvider, int?>((a) => a.currentSong?.id);
    final song = audio.currentSong;

    if (songId == null || song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const PlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                  position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: AppTheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        song.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: audio.skipPrevious,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: AppTheme.onSurface),
                ),
                Selector<AudioProvider, bool>(
                  selector: (_, a) => a.isPlaying,
                  builder: (context, isPlaying, child) => GestureDetector(
                    onTap: audio.togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppTheme.onTertiary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: audio.skipNext,
                  icon: const Icon(Icons.skip_next_rounded,
                      color: AppTheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mini progress bar - uses Consumer to only rebuild this part
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Consumer<AudioProvider>(
                  builder: (context, audioProv, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: constraints.maxWidth *
                              audioProv.progress.clamp(0.0, 1.0),
                          color: AppTheme.tertiary,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

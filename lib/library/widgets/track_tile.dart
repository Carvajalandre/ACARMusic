import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class TrackTile extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final Widget? trailingOverride;

  const TrackTile({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    this.onMore,
    this.trailingOverride,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isPlaying ? AppTheme.surfaceContainerLow : Colors.transparent,
      leading: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RepaintBoundary(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkFit: BoxFit.cover,
                    artworkWidth: 52,
                    artworkHeight: 52,
                    keepOldArtwork: true,
                    nullArtworkWidget: Container(
                      color: AppTheme.surfaceContainerHigh,
                      child: const Center(
                          child: Icon(Icons.music_note_rounded,
                              color: AppTheme.onSurfaceVariant)),
                    ),
                  ),
                ),
              ),
            ),
            if (isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.equalizer_rounded,
                      color: AppTheme.tertiary, size: 20),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        song.title ?? 'Unknown',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.manrope(
          color: isPlaying ? AppTheme.tertiary : AppTheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        song.artist ?? 'Artista desconocido',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            GoogleFonts.manrope(color: AppTheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: trailingOverride ??
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded,
                color: AppTheme.onSurfaceVariant),
            onPressed: onMore,
          ),
    );
  }
}

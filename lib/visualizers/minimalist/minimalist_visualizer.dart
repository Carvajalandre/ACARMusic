import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MinimalistVisualizer extends StatelessWidget {
  final int? albumId;
  final double size;
  final Color glowColor;

  const MinimalistVisualizer({
    super.key,
    this.albumId,
    this.size = 260,
    this.glowColor = const Color(0xFF6D28D9),
  });

  @override
  Widget build(BuildContext context) {
    final outerPadding = (size * 0.035).clamp(8.0, 14.0);
    final artSize = size - outerPadding * 2;
    final radius = (artSize * 0.065).clamp(10.0, 22.0);
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(outerPadding),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: glowColor.withAlpha(55),
                blurRadius: 34,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ColoredBox(
              color: const Color(0xFF111111),
              child: albumId != null
                  ? QueryArtworkWidget(
                      id: albumId!,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.contain,
                      artworkWidth: artSize * 0.75,
                      artworkHeight: artSize * 0.75,
                      artworkQuality: FilterQuality.high,
                      keepOldArtwork: true,
                      nullArtworkWidget: _defaultArt(artSize),
                    )
                  : _defaultArt(artSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultArt(double size) => Container(
        color: const Color(0xFF1C1C1C),
        child: Icon(Icons.music_note_rounded,
            color: Colors.white54, size: size * 0.18),
      );
}

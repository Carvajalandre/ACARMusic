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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.15),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withAlpha(50),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.15),
            child: SizedBox(
              width: size,
              height: size,
              child: albumId != null
                  ? QueryArtworkWidget(
                      id: albumId!,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      artworkWidth: size,
                      artworkHeight: size,
                      keepOldArtwork: true,
                      nullArtworkWidget: _defaultArt(),
                    )
                  : _defaultArt(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultArt() => Container(
        color: const Color(0xFF1C1C1C),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white54, size: 48),
      );
}

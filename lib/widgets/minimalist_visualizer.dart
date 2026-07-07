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
    final artSize = size * 0.7;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: artSize,
              height: artSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(artSize * 0.15),
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
              borderRadius: BorderRadius.circular(artSize * 0.15),
              child: SizedBox(
                width: artSize,
                height: artSize,
                child: albumId != null
                    ? QueryArtworkWidget(
                        id: albumId!,
                        type: ArtworkType.ALBUM,
                        artworkFit: BoxFit.cover,
                        artworkWidth: artSize,
                        artworkHeight: artSize,
                        keepOldArtwork: true,
                        nullArtworkWidget: _defaultArt(artSize),
                      )
                    : _defaultArt(artSize),
              ),
            ),
          ],
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

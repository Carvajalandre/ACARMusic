import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class TrackTile extends StatefulWidget {
  // 1.0 mantiene el tamaño original; 0.75 lo reduce un 25%; 1.8 lo aumenta.
  static const double sizeScale = 0.75;
  static const double _baseItemExtent = 84.0;
  static const double itemExtent = _baseItemExtent * sizeScale;

  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final Widget? trailingOverride;

  const TrackTile(
      {super.key,
      required this.song,
      required this.isPlaying,
      required this.onTap,
      this.onMore,
      this.trailingOverride});

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  Color _accent = AppTheme.primary;
  int? _lastSongId;

  double _size(double value) => value * TrackTile.sizeScale;

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaying && _lastSongId != widget.song.id) {
      _lastSongId = widget.song.id;
      _loadAccent(widget.song);
    }
    final activeColor = _accentForText(_accent);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: TrackTile.itemExtent,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.isPlaying
            ? _accent.withAlpha(42)
            : AppTheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(42)),
          bottom: BorderSide(color: Colors.white.withAlpha(42)),
        ),
      ),
      child: Center(
        child: ListTile(
          minTileHeight: _size(56),
          contentPadding:
              EdgeInsets.symmetric(horizontal: _size(20), vertical: _size(10)),
          onTap: widget.onTap,
          leading: SizedBox(
            width: _size(64),
            height: _size(64),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_size(12)),
                child: RepaintBoundary(
                  child: SizedBox(
                    width: _size(64),
                    height: _size(64),
                    child: QueryArtworkWidget(
                      id: widget.song.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(_size(12)),
                      artworkFit: BoxFit.cover,
                      artworkWidth: _size(64),
                      artworkHeight: _size(64),
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
              if (widget.isPlaying)
                Container(
                  decoration: BoxDecoration(
                      color: _accent.withAlpha(155),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Icon(Icons.equalizer_rounded,
                          color: Colors.white, size: _size(20))),
                ),
            ]),
          ),
          title: Text(widget.song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                  color: widget.isPlaying ? activeColor : AppTheme.onSurface,
                  fontSize: _size(17),
                  fontWeight: FontWeight.w700)),
          subtitle: Text(widget.song.artist ?? 'Artista desconocido',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                  color: widget.isPlaying
                      ? activeColor.withAlpha(190)
                      : AppTheme.onSurfaceVariant,
                  fontSize: _size(14))),
          trailing: widget.trailingOverride ??
              IconButton(
                  icon: Icon(Icons.more_horiz_rounded,
                      color: AppTheme.onSurfaceVariant, size: _size(24)),
                  onPressed: widget.onMore),
        ),
      ),
    );
  }

  Future<void> _loadAccent(SongModel song) async {
    try {
      final art = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG, size: 120);
      var result = _fallbackColor(song);
      if (art != null && art.isNotEmpty) {
        final palette = await PaletteGenerator.fromImageProvider(
            MemoryImage(art),
            size: const Size(120, 120),
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
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.68, 0.48).toColor();
  }

  Color _accentForText(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness < 0.62 ? hsl.withLightness(0.72).toColor() : color;
  }
}

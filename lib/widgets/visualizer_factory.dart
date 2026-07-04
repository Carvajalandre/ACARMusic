import 'package:flutter/material.dart';
import '../models/animation_style.dart';
import '../theme/app_theme.dart';
import 'vinyl_record.dart';
import 'bar_visualizer.dart';
import 'radial_visualizer.dart';
import 'modern_visualizer.dart';

class VisualizerFactory extends StatelessWidget {
  final VisualizerStyle style;
  final bool isPlaying;
  final int? albumId;
  final Color glowColor;
  final Color paletteDominant;
  final Color paletteMuted;
  final double size;
  final Stream<List<double>>? fftStream;

  const VisualizerFactory({
    super.key,
    required this.style,
    required this.isPlaying,
    this.albumId,
    this.glowColor = const Color(0xFF6D28D9),
    this.paletteDominant = const Color(0xFF1A0A2E),
    this.paletteMuted = const Color(0xFF0D0A20),
    this.size = 260,
    this.fftStream,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case VisualizerStyle.vinyl:
        return VinylRecord(
          isPlaying: isPlaying,
          albumId: albumId,
          glowColor: glowColor,
          size: size,
        );
      case VisualizerStyle.barVisualizer:
        return SizedBox(
          width: size,
          height: size,
          child: BarVisualizer(
            fftStream: fftStream ?? _silentStream(),
            paletteVibrant: glowColor,
            paletteDominant: paletteDominant,
            paletteMuted: paletteMuted,
          ),
        );
      case VisualizerStyle.radialVisualizer:
        return SizedBox(
          width: size,
          height: size,
          child: RadialVisualizer(
            fftStream: fftStream ?? _silentStream(),
            glowColor: glowColor,
          ),
        );
      case VisualizerStyle.modern:
        return SizedBox(
          width: size,
          height: size,
          child: ModernVisualizer(
            fftStream: fftStream ?? _silentStream(),
            lineColor: AppTheme.tertiary,
          ),
        );
    }
  }

  Stream<List<double>> _silentStream() async* {
    yield List.filled(64, 0.0);
  }
}
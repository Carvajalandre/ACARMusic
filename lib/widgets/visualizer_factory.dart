import 'package:flutter/material.dart';
import '../models/animation_style.dart';
import 'vinyl_record.dart';
import 'bar_visualizer.dart';
import 'radial_visualizer.dart';
import 'minimalist_visualizer.dart';

class VisualizerFactory extends StatefulWidget {
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
  State<VisualizerFactory> createState() => _VisualizerFactoryState();
}

class _VisualizerFactoryState extends State<VisualizerFactory> {
  late final Stream<List<double>> _fallbackStream = Stream<List<double>>.periodic(
    const Duration(seconds: 1),
    (_) => List.filled(32, 0.0),
  );

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case VisualizerStyle.vinyl:
        return VinylRecord(
          isPlaying: widget.isPlaying,
          albumId: widget.albumId,
          glowColor: widget.glowColor,
          size: widget.size,
        );
      case VisualizerStyle.barVisualizer:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: BarVisualizer(
            fftStream: widget.fftStream ?? _fallbackStream,
            paletteVibrant: widget.glowColor,
            paletteDominant: widget.paletteDominant,
            paletteMuted: widget.paletteMuted,
          ),
        );
      case VisualizerStyle.radialVisualizer:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: RadialVisualizer(
            fftStream: widget.fftStream ?? _fallbackStream,
            glowColor: widget.glowColor,
          ),
        );
      case VisualizerStyle.minimalist:
        return MinimalistVisualizer(
          albumId: widget.albumId,
          size: widget.size,
          glowColor: widget.glowColor,
        );
    }
  }
}
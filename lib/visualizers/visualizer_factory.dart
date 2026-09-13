import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'animation_style.dart';
import 'bar/bar_visualizer.dart';
import 'radial/radial_visualizer.dart';
import 'minimalist/minimalist_visualizer.dart';
import 'vinyl/vinyl_record.dart';
import 'cassette/cassette_visualizer.dart';

class VisualizerFactory extends StatefulWidget {
  final VisualizerStyle style;
  final bool isPlaying;
  final int? albumId;
  final Color glowColor;
  final Color paletteDominant;
  final Color paletteMuted;
  final double size;
  final Stream<List<double>>? fftStream;
  final Uint8List? artworkBytes;

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
    this.artworkBytes,
  });

  @override
  State<VisualizerFactory> createState() => _VisualizerFactoryState();
}

class _VisualizerFactoryState extends State<VisualizerFactory> {
  late final Stream<List<double>> _fallbackStream =
      Stream<List<double>>.periodic(
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
          ),
        );
      case VisualizerStyle.radialVisualizer:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: RadialVisualizer(
            fftStream: widget.fftStream ?? _fallbackStream,
            glowColor: widget.glowColor,
            albumId: widget.albumId,
          ),
        );
      case VisualizerStyle.minimalist:
        return MinimalistVisualizer(
          albumId: widget.albumId,
          isPlaying: widget.isPlaying,
          size: widget.size,
          glowColor: widget.glowColor,
        );
      case VisualizerStyle.cassette:
        return CassetteVisualizer(
          isPlaying: widget.isPlaying,
          size: widget.size,
          dominantColor: widget.paletteDominant,
          mutedColor: widget.paletteMuted,
          artworkBytes: widget.artworkBytes,
        );
    }
  }
}

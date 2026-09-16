enum VisualizerStyle {
  vinyl,
  barVisualizer,
  radialVisualizer,
  minimalist,
  cassette,
  void_,
  motion;

  String get displayName {
    switch (this) {
      case VisualizerStyle.vinyl:
        return 'Disco de vinilo';
      case VisualizerStyle.barVisualizer:
        return 'Barras';
      case VisualizerStyle.radialVisualizer:
        return 'Radial';
      case VisualizerStyle.minimalist:
        return 'Minimalista';
      case VisualizerStyle.cassette:
        return 'Cassette';
      case VisualizerStyle.void_:
        return 'Void';
      case VisualizerStyle.motion:
        return 'Motion';
    }
  }

  String get iconLabel {
    switch (this) {
      case VisualizerStyle.vinyl:
        return '💿';
      case VisualizerStyle.barVisualizer:
        return '📊';
      case VisualizerStyle.radialVisualizer:
        return '🔵';
      case VisualizerStyle.minimalist:
        return '◻️';
      case VisualizerStyle.cassette:
        return '📼';
      case VisualizerStyle.void_:
        return '🌌';
      case VisualizerStyle.motion:
        return '🌊';
    }
  }
}

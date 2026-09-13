enum VisualizerStyle {
  vinyl,
  barVisualizer,
  radialVisualizer,
  minimalist,
  cassette;

  String get displayName {
    switch (this) {
      case VisualizerStyle.vinyl:
        return 'Disco de vinilo';
      case VisualizerStyle.barVisualizer:
        return 'Bar Visualizer';
      case VisualizerStyle.radialVisualizer:
        return 'Radial Visualizer';
      case VisualizerStyle.minimalist:
        return 'Minimalista';
      case VisualizerStyle.cassette:
        return 'Cassette';
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
    }
  }
}

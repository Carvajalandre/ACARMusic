enum VisualizerStyle {
  vinyl,
  barVisualizer,
  radialVisualizer,
  modern;

  String get displayName {
    switch (this) {
      case VisualizerStyle.vinyl:
        return 'Disco de vinilo';
      case VisualizerStyle.barVisualizer:
        return 'Bar Visualizer';
      case VisualizerStyle.radialVisualizer:
        return 'Radial Visualizer';
      case VisualizerStyle.modern:
        return 'Moderno minimalista';
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
      case VisualizerStyle.modern:
        return '◻️';
    }
  }
}

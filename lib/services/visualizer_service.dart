import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class VisualizerService {
  static const _methodChannel = MethodChannel('com.acar.music/visualizer');
  static const _eventChannel = EventChannel('com.acar.music/visualizer_fft');

  StreamSubscription<List<double>>? _subscription;
  final StreamController<List<double>> _simulatedController =
      StreamController<List<double>>.broadcast();
  Timer? _simulatedTimer;

  bool _started = false;

  Stream<List<double>> get fftStream {
    if (!_hasNativeVisualizer) {
      return _simulatedController.stream;
    }
    return _eventChannel
        .receiveBroadcastStream()
        .map((data) => (data as List<dynamic>).cast<double>());
  }

  bool get _hasNativeVisualizer {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> start(int audioSessionId) async {
    if (_started) return true;
    try {
      await _methodChannel.invokeMethod('startVisualizer', {
        'audioSessionId': audioSessionId,
      });
      _started = true;
      return true;
    } on MissingPluginException {
      _startSimulated();
      _started = true;
      return true;
    } catch (e) {
      _startSimulated();
      _started = true;
      return true;
    }
  }

  Future<void> stop() async {
    _started = false;
    _simulatedTimer?.cancel();
    _simulatedTimer = null;
    try {
      await _methodChannel.invokeMethod('stopVisualizer');
    } catch (_) {}
  }

  void _startSimulated() {
    final rng = Random();
    double time = 0.0;
    final double dt = 0.08;

    _simulatedTimer?.cancel();
    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_started) return;
      time += dt;

      final data = List<double>.generate(64, (i) {
        final freqRatio = i / 64;
        double value;

        if (freqRatio < 0.2) {
          final bassEnv = 0.4 + sin(time * 0.8) * 0.25 + sin(time * 1.3) * 0.1;
          final jitter = rng.nextDouble() * 0.15;
          value = (bassEnv + jitter).clamp(0.1, 1.0);
        } else if (freqRatio > 0.7) {
          final highEnv = 0.1 + sin(time * 1.5) * 0.08 + sin(time * 2.1) * 0.05;
          final spikes = rng.nextDouble() > 0.92 ? rng.nextDouble() * 0.45 : 0.0;
          final jitter = rng.nextDouble() * 0.25;
          value = (highEnv + spikes + jitter).clamp(0.05, 1.0);
        } else {
          final midEnv = 0.2 + sin(time * 1.1) * 0.15 + sin(time * 0.7) * 0.1;
          final jitter = rng.nextDouble() * 0.2;
          value = (midEnv + jitter).clamp(0.05, 1.0);
        }

        return value;
      });

      _simulatedController.add(data);
    });
  }

  void dispose() {
    stop();
    _simulatedController.close();
    _subscription?.cancel();
  }
}
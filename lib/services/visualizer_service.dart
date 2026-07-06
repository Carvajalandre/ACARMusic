import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class VisualizerService {
  static const _methodChannel = MethodChannel('com.acar.music/visualizer');
  static const _eventChannel = EventChannel('com.acar.music/visualizer_fft');

  final StreamController<List<double>> _controller =
      StreamController<List<double>>.broadcast();

  StreamSubscription? _nativeSub;
  Timer? _simulatedTimer;
  bool _started = false;

  Stream<List<double>> get fftStream => _controller.stream;

  Future<bool> start(int audioSessionId) async {
    if (_started) return true;
    _started = true;

    bool nativeOk = false;
    try {
      nativeOk = await _methodChannel.invokeMethod<bool>('startVisualizer', {
            'audioSessionId': audioSessionId,
          }) ??
          false;
    } catch (_) {
      nativeOk = false;
    }

    if (nativeOk) {
      _nativeSub = _eventChannel.receiveBroadcastStream().listen(
        (data) => _controller.add((data as List<dynamic>).cast<double>()),
        onError: (_) => _startSimulated(),
      );
    } else {
      _startSimulated();
    }
    return true;
  }

  Future<void> stop() async {
    _started = false;
    _nativeSub?.cancel();
    _nativeSub = null;
    _simulatedTimer?.cancel();
    _simulatedTimer = null;
    try {
      await _methodChannel.invokeMethod('stopVisualizer');
    } catch (_) {}
  }

  void _startSimulated() {
    final rng = Random();
    double time = 0.0;
    const dt = 0.08;

    _simulatedTimer?.cancel();
    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_started) return;
      time += dt;
      final data = List<double>.generate(32, (i) {
        final freqRatio = i / 32;
        double value;
        if (freqRatio < 0.2) {
          value = (0.4 + sin(time * 0.8) * 0.25 + sin(time * 1.3) * 0.1 +
                  rng.nextDouble() * 0.15)
              .clamp(0.1, 1.0);
        } else if (freqRatio > 0.7) {
          final spikes = rng.nextDouble() > 0.92 ? rng.nextDouble() * 0.45 : 0.0;
          value = (0.1 + sin(time * 1.5) * 0.08 + sin(time * 2.1) * 0.05 +
                  spikes + rng.nextDouble() * 0.25)
              .clamp(0.05, 1.0);
        } else {
          value = (0.2 + sin(time * 1.1) * 0.15 + sin(time * 0.7) * 0.1 +
                  rng.nextDouble() * 0.2)
              .clamp(0.05, 1.0);
        }
        return value;
      });
      _controller.add(data);
    });
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
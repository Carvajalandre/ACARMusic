import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

enum AppRepeatState { off, all, one }

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;

  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleOn = false;
  AppRepeatState _repeatMode = AppRepeatState.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  bool _positionChanged = false;

  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffleOn => _isShuffleOn;
  AppRepeatState get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  AudioProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.music());
      await _session!.setActive(true);

      // Posición: notificar cada 100ms para no saturar el UI
      _player.positionStream.listen((pos) {
        _position = pos;
        _positionChanged = true;
      });

      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_positionChanged) {
          _positionChanged = false;
          notifyListeners();
        }
      });

      _player.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
      });

      _player.playerStateStream.listen((state) {
        final wasPlaying = _isPlaying;
        _isPlaying = state.playing;
        if (wasPlaying != _isPlaying) notifyListeners();
        if (state.processingState == ProcessingState.completed) {
          _onTrackCompleted();
        }
      });
    } catch (e) {
      debugPrint('Error inicializando audio: $e');
    }
  }

  // ─── Reproducción ─────────────────────────────────────────────────────────

  Future<void> playSong(SongModel song, List<SongModel> queue, int index) async {
    _queue = queue;
    _currentIndex = index;
    notifyListeners();

    try {
      final path = song.data;
      if (path == null || path.isEmpty) return;
      await _player.setFilePath(path);
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error reproduciendo: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(double progress) async {
    if (_duration.inMilliseconds == 0) return;
    final ms = (progress * _duration.inMilliseconds).round();
    await _player.seek(Duration(milliseconds: ms));
  }

  // ─── Navegación ───────────────────────────────────────────────────────────

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;

    if (_isShuffleOn) {
      final rand = DateTime.now().millisecondsSinceEpoch % _queue.length;
      await playSong(_queue[rand], _queue, rand);
      return;
    }

    final next = _currentIndex + 1;
    if (next < _queue.length) {
      await playSong(_queue[next], _queue, next);
    } else if (_repeatMode == AppRepeatState.all) {
      await playSong(_queue[0], _queue, 0);
    }
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;

    // Si llevamos > 3s en la canción, rebobinar
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final prev = _currentIndex - 1;
    if (prev >= 0) {
      await playSong(_queue[prev], _queue, prev);
    } else if (_repeatMode == AppRepeatState.all) {
      await playSong(_queue[_queue.length - 1], _queue, _queue.length - 1);
    }
  }

  void _onTrackCompleted() {
    switch (_repeatMode) {
      case AppRepeatState.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case AppRepeatState.all:
        skipNext();
        break;
      case AppRepeatState.off:
        if (_currentIndex < _queue.length - 1) {
          skipNext();
        }
        break;
    }
  }

  // ─── Modos ────────────────────────────────────────────────────────────────

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      AppRepeatState.off => AppRepeatState.all,
      AppRepeatState.all => AppRepeatState.one,
      AppRepeatState.one => AppRepeatState.off,
    };
    notifyListeners();
  }

  // ─── Utilidades ───────────────────────────────────────────────────────────

  String formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
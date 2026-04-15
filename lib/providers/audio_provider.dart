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
        if (wasPlaying != _isPlaying) {
          notifyListeners();
        }
        if (state.processingState == ProcessingState.completed) {
          _onTrackCompleted();
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  Future<void> playSong(
      SongModel song, List<SongModel> queue, int index) async {
    _queue = queue;
    _currentIndex = index;
    notifyListeners();

    try {
      final path = song.data;
      if (path == null) return;
      await _player.setFilePath(path);
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    int next;
    if (_isShuffleOn) {
      next =
          (_currentIndex + 1 + (DateTime.now().millisecond % _queue.length)) %
              _queue.length;
    } else {
      next = (_currentIndex + 1) % _queue.length;
    }
    await playSong(_queue[next], _queue, next);
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = (_currentIndex - 1 + _queue.length) % _queue.length;
    await playSong(_queue[prev], _queue, prev);
  }

  Future<void> seekTo(double value) async {
    final ms = (_duration.inMilliseconds * value).toInt();
    await _player.seek(Duration(milliseconds: ms));
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case AppRepeatState.off:
        _repeatMode = AppRepeatState.all;
        _player.setLoopMode(LoopMode.all);
        break;
      case AppRepeatState.all:
        _repeatMode = AppRepeatState.one;
        _player.setLoopMode(LoopMode.one);
        break;
      case AppRepeatState.one:
        _repeatMode = AppRepeatState.off;
        _player.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  void _onTrackCompleted() {
    if (_repeatMode == AppRepeatState.one) return;
    skipNext();
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    _session?.setActive(false);
    super.dispose();
  }
}

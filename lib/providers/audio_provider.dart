import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import '../audio/audio_handler.dart';

enum AppRepeatState { off, all, one }

class AudioProvider extends ChangeNotifier {
  final ACARMusicHandler _handler;

  // Acceso interno al player (que vive en el handler)
  AudioPlayer get _player => _handler.player;

  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleOn = false;
  AppRepeatState _repeatMode = AppRepeatState.off;
  bool _isPlaying = false;

  // ── ValueNotifiers para posición/duración (sin rebuilds masivos) ──────────
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);

  // ── Sleep Timer ────────────────────────────────────────────────────────────
  Timer? _sleepTimer;
  Timer? _countdownTimer;
  final ValueNotifier<Duration> sleepRemainingNotifier = ValueNotifier(Duration.zero);
  int _sleepTimerMinutes = 0;
  int get sleepTimerMinutes => _sleepTimerMinutes;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<SongModel> get queue        => _queue;
  int get currentIndex             => _currentIndex;
  bool get isPlaying               => _isPlaying;
  bool get isShuffleOn             => _isShuffleOn;
  AppRepeatState get repeatMode    => _repeatMode;
  Duration get position            => positionNotifier.value;
  Duration get duration            => durationNotifier.value;

  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  AudioProvider(this._handler) {
    _init();
    // Inyecta los callbacks de navegación en el handler
    // (para que los botones de la notificación funcionen)
    _handler.onSkipToNext     = skipNext;
    _handler.onSkipToPrevious = skipPrevious;
  }

  void _init() {
    // Posición y duración → ValueNotifier (sin notifyListeners masivos)
    _player.positionStream.listen((pos) => positionNotifier.value = pos);
    _player.durationStream.listen(
        (dur) => durationNotifier.value = dur ?? Duration.zero);

    // Estado play/pause
    _player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  // ─── Reproducción ─────────────────────────────────────────────────────────

  Future<void> playSong(SongModel song, List<SongModel> queue, int index) async {
    _queue = queue;
    _currentIndex = index;
    notifyListeners(); // Canción nueva → rebuild de portada/título

    try {
      final path = song.data;
      if (path.isEmpty) return;

      // Actualiza la notificación del sistema con la nueva canción
      _handler.setCurrentSong(song);

      await _player.setFilePath(path);
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error reproduciendo: $e');
    }
  }

  Future<void> togglePlayPause() async {
    _player.playing ? await _player.pause() : await _player.play();
  }

  Future<void> seekTo(double progress) async {
    final dur = durationNotifier.value;
    if (dur.inMilliseconds == 0) return;
    await _player.seek(
        Duration(milliseconds: (progress * dur.inMilliseconds).round()));
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
    if (positionNotifier.value.inSeconds > 3) {
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
        if (_currentIndex < _queue.length - 1) skipNext();
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

  // ─── Sleep Timer ──────────────────────────────────────────────────────────

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    _sleepTimerMinutes = minutes;
    sleepRemainingNotifier.value = Duration(minutes: minutes);

    if (minutes > 0) {
      final endTime = DateTime.now().add(Duration(minutes: minutes));
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        await _player.pause();
        _sleepTimerMinutes = 0;
        sleepRemainingNotifier.value = Duration.zero;
        _sleepTimer = null;
        notifyListeners();
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = endTime.difference(DateTime.now());
        sleepRemainingNotifier.value =
            remaining.isNegative ? Duration.zero : remaining;
      });
    }
    notifyListeners();
  }

  void cancelSleepTimer() => setSleepTimer(0);

  // ─── Utilidades ───────────────────────────────────────────────────────────

  String formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    positionNotifier.dispose();
    durationNotifier.dispose();
    sleepRemainingNotifier.dispose();
    super.dispose();
  }
}
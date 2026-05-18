import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_handler.dart';

enum AppRepeatState { off, all, one }

class AudioProvider extends ChangeNotifier with WidgetsBindingObserver {
  AudioProvider(this._handler) {
    _init();
    WidgetsBinding.instance.addObserver(this);
    _handler.onSkipToNext = skipNext;
    _handler.onSkipToPrevious = skipPrevious;
  }

  final ACARMusicHandler _handler;
  AudioPlayer get _player => _handler.player;

  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleOn = false;
  AppRepeatState _repeatMode = AppRepeatState.off;
  bool _isPlaying = false;

  // Historial de reproducción en modo shuffle — permite Anterior correcto
  final List<int> _shuffleHistory = [];
  static const int _maxHistory = 50;

  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);

  Timer? _sleepTimer;
  Timer? _countdownTimer;
  Timer? _saveDebounceTimer;
  final ValueNotifier<Duration> sleepRemainingNotifier =
      ValueNotifier(Duration.zero);
  int _sleepTimerMinutes = 0;

  SharedPreferences? _prefs;
  bool _restoreAttempted = false;
  bool _restoringSession = false;

  /// Evita llamadas concurrentes a playSong
  bool _changingTrack = false;

  static const String _sessionKey = 'audio_session_v1';

  int get sleepTimerMinutes => _sleepTimerMinutes;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffleOn => _isShuffleOn;
  AppRepeatState get repeatMode => _repeatMode;
  Duration get position => positionNotifier.value;
  Duration get duration => durationNotifier.value;

  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  void _init() {
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);

    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
      _scheduleSessionSave();
    });

    _player.durationStream
        .listen((dur) => durationNotifier.value = dur ?? Duration.zero);

    _player.playerStateStream.listen((state) {
      // Durante cambio de pista, ignorar TODOS los eventos del stream.
      // Previene: loop infinito de _onTrackCompleted, saves concurrentes,
      // y notifyListeners con estado inconsistente.
      if (_changingTrack) return;

      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) notifyListeners();
      _saveSession();
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  // ── Guarda sesión INMEDIATAMENTE al ir a background ─────────────────────
  // Sin debounce — persiste la posición exacta antes de que Android
  // pueda matar el proceso. Fix del bug "no guarda el minuto exacto".
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _saveDebounceTimer?.cancel();
      _saveSession(); // sin await — fire and forget
    }
  }

  void bindLibrary({
    required List<SongModel> songs,
    required bool hasPermission,
    required bool isLoading,
  }) {
    if (!hasPermission || isLoading || songs.isEmpty) return;
    _restoreSessionIfPossible(songs);
  }

  Future<void> playSong(SongModel song, List<SongModel> newQueue, int index,
      {bool addToHistory = true}) async {
    // Guard: evita llamadas concurrentes que causan crash
    if (_changingTrack) return;
    _changingTrack = true;

    // Suprimir broadcasts al platform channel durante la transición.
    _handler.suppressBroadcast = true;

    // Log diagnóstico: guarda paso a paso para identificar crashes nativos.
    // Si la app crashea, al re-abrir mostrará hasta qué paso llegó.
    String lastStep = 'inicio';
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;

      Future<void> logStep(String step) async {
        lastStep = step;
        await prefs.setString('last_crash_log',
            'playSong crash diagnostic\n'
            'Paso: $step\n'
            'Song: ${song.title}\n'
            'Path: ${song.data}\n'
            'Index: $index\n'
            'QueueLen: ${newQueue.length}\n'
            'PlayerState: ${_player.processingState}\n'
            'Playing: ${_player.playing}');
      }

      await logStep('1_shuffle_history');
      if (_isShuffleOn && addToHistory && _currentIndex >= 0) {
        _shuffleHistory.add(_currentIndex);
        if (_shuffleHistory.length > _maxHistory) _shuffleHistory.removeAt(0);
      }

      await logStep('2_update_state');
      final queueChanged = !identical(_queue, newQueue) ||
          _queue.length != newQueue.length;
      _queue = newQueue;
      _currentIndex = index;
      notifyListeners();

      final path = song.data;
      if (path.isEmpty) {
        await logStep('2b_empty_path_return');
        return;
      }

      await logStep('3_check_file');
      if (!File(path).existsSync()) {
        await logStep('3b_file_not_found');
        return;
      }

      await logStep('4_update_media_session');
      if (queueChanged) {
        await _handler.setQueueAndCurrentSong(newQueue, index);
      } else {
        await _handler.updateCurrentSong(song, index);
      }

      await logStep('5_setFilePath');
      await _player.setFilePath(path);

      await logStep('6_enable_broadcast');
      _handler.suppressBroadcast = false;
      _handler.refreshPlaybackState();

      await logStep('7_play');
      await _player.play();

      await logStep('8_done');
      _isPlaying = true;
      notifyListeners();
      _saveSession();

      // Limpiar log de diagnóstico si todo salió bien
      await prefs.remove('last_crash_log');
    } catch (e, st) {
      debugPrint('Error reproduciendo (paso: $lastStep): $e');
      // Guardar error Dart capturado
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        await prefs.setString('last_crash_log',
            'playSong EXCEPTION (paso: $lastStep)\n'
            'Song: ${song.title}\n'
            'Error: $e\n'
            'Stack: $st');
      } catch (_) {}
    } finally {
      _handler.suppressBroadcast = false;
      _changingTrack = false;
    }
  }

  Future<void> togglePlayPause() async {
    _player.playing ? await _handler.pause() : await _handler.play();
    await _saveSession();
  }

  Future<void> seekTo(double progress) async {
    final dur = durationNotifier.value;
    if (dur.inMilliseconds == 0) return;
    await _player
        .seek(Duration(milliseconds: (progress * dur.inMilliseconds).round()));
    await _saveSession();
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    if (_isShuffleOn) {
      // Shuffle: elige aleatoria distinta a la actual
      int rand;
      do {
        rand = DateTime.now().microsecondsSinceEpoch % _queue.length;
      } while (_queue.length > 1 && rand == _currentIndex);
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
    // Si llevan más de 3s en la pista → reinicia desde el inicio
    if (positionNotifier.value.inSeconds > 3) {
      await _player.seek(Duration.zero);
      await _saveSession();
      return;
    }
    // Shuffle activo: regresa a la canción que sonó antes (historial real)
    if (_isShuffleOn && _shuffleHistory.isNotEmpty) {
      final prevIdx = _shuffleHistory.removeLast();
      if (prevIdx >= 0 && prevIdx < _queue.length) {
        // addToHistory: false → no agrega al historial al ir hacia atrás
        await playSong(_queue[prevIdx], _queue, prevIdx, addToHistory: false);
        return;
      }
    }
    // Sin shuffle (o historial vacío): índice lineal
    final prev = _currentIndex - 1;
    if (prev >= 0) {
      await playSong(_queue[prev], _queue, prev, addToHistory: false);
    } else if (_repeatMode == AppRepeatState.all) {
      await playSong(_queue[_queue.length - 1], _queue, _queue.length - 1,
          addToHistory: false);
    }
  }

  void _onTrackCompleted() {
    switch (_repeatMode) {
      case AppRepeatState.one:
        _player.seek(Duration.zero);
        _player.play();
        _saveSession();
        break;
      case AppRepeatState.all:
        skipNext();
        break;
      case AppRepeatState.off:
        if (_currentIndex < _queue.length - 1) skipNext();
        break;
    }
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    if (!_isShuffleOn) _shuffleHistory.clear();
    notifyListeners();
    _saveSession();
  }

  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      AppRepeatState.off => AppRepeatState.all,
      AppRepeatState.all => AppRepeatState.one,
      AppRepeatState.one => AppRepeatState.off,
    };
    notifyListeners();
    _saveSession();
  }

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
        await _saveSession();
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

  Future<void> _restoreSessionIfPossible(List<SongModel> librarySongs) async {
    if (_restoreAttempted) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final raw = prefs.getString(_sessionKey);
    if (raw == null) {
      _restoreAttempted = true;
      return;
    }

    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic>) {
      _restoreAttempted = true;
      return;
    }

    final savedPath = map['currentPath'] as String?;
    final savedId = (map['currentId'] as num?)?.toInt();
    if (savedPath == null && savedId == null) {
      _restoreAttempted = true;
      return;
    }

    final songsById = <int, SongModel>{for (final s in librarySongs) s.id: s};
    final songsByPath = <String, SongModel>{
      for (final s in librarySongs) s.data: s
    };

    final restoredQueue = <SongModel>[];
    final queueIdsRaw = map['queueIds'];
    if (queueIdsRaw is List) {
      for (final rawId in queueIdsRaw) {
        final id = (rawId as num?)?.toInt();
        if (id == null) continue;
        final song = songsById[id];
        if (song != null && !restoredQueue.any((s) => s.id == song.id)) {
          restoredQueue.add(song);
        }
      }
    }

    final queuePathsRaw = map['queuePaths'];
    if (queuePathsRaw is List) {
      for (final rawPath in queuePathsRaw) {
        final path = rawPath as String?;
        if (path == null) continue;
        final song = songsByPath[path];
        if (song != null && !restoredQueue.any((s) => s.id == song.id)) {
          restoredQueue.add(song);
        }
      }
    }

    SongModel? restoredSong = savedId != null ? songsById[savedId] : null;
    restoredSong ??= savedPath != null ? songsByPath[savedPath] : null;

    if (restoredSong == null) {
      _restoreAttempted = true;
      return;
    }

    if (!restoredQueue.any((s) => s.id == restoredSong!.id)) {
      restoredQueue.add(restoredSong);
    }

    final savedIndex = (map['currentIndex'] as num?)?.toInt() ?? -1;
    final restoredIndex = savedIndex >= 0 &&
            savedIndex < restoredQueue.length &&
            restoredQueue[savedIndex].id == restoredSong.id
        ? savedIndex
        : restoredQueue.indexWhere((s) => s.id == restoredSong!.id);

    _queue = restoredQueue;
    _currentIndex = restoredIndex >= 0 ? restoredIndex : 0;
    _isShuffleOn = map['isShuffleOn'] as bool? ?? false;
    _repeatMode = _repeatModeFromName(map['repeatMode'] as String?);
    notifyListeners();

    final hasActiveSource = _player.audioSource != null ||
        _player.processingState != ProcessingState.idle;

    if (!hasActiveSource) {
      _restoringSession = true;
      try {
        await _handler.setQueueAndCurrentSong(restoredQueue, _currentIndex);
        await _player.setFilePath(restoredSong.data);

        final positionMs = (map['positionMs'] as num?)?.toInt() ?? 0;
        if (positionMs > 0) {
          await _player.seek(Duration(milliseconds: positionMs));
        }
        _handler.refreshPlaybackState();
        // No reanuda automáticamente — igual que Samsung Music
      } catch (e) {
        debugPrint('Error restaurando sesión: $e');
      } finally {
        _restoringSession = false;
      }
    } else {
      await _handler.setQueueAndCurrentSong(restoredQueue, _currentIndex);
    }

    _restoreAttempted = true;
  }

  AppRepeatState _repeatModeFromName(String? value) => switch (value) {
        'all' => AppRepeatState.all,
        'one' => AppRepeatState.one,
        _ => AppRepeatState.off,
      };

  void _scheduleSessionSave() {
    if (currentSong == null || _restoringSession) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 700), _saveSession);
  }

  Future<void> _saveSession() async {
    if (_restoringSession) return;
    final song = currentSong;
    if (song == null) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    await prefs.setString(
      _sessionKey,
      jsonEncode(<String, dynamic>{
        'currentId': song.id,
        'currentPath': song.data,
        'currentIndex': _currentIndex,
        'positionMs': _player.position.inMilliseconds,
        'wasPlaying': _player.playing,
        'isShuffleOn': _isShuffleOn,
        'repeatMode': _repeatMode.name,
        'queueIds': _queue.map((s) => s.id).toList(),
        'queuePaths': _queue.map((s) => s.data).toList(),
      }),
    );
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    _saveDebounceTimer?.cancel();
    positionNotifier.dispose();
    durationNotifier.dispose();
    sleepRemainingNotifier.dispose();
    super.dispose();
  }
}

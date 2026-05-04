import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_handler.dart';

enum AppRepeatState { off, all, one }

class AudioProvider extends ChangeNotifier {
  AudioProvider(this._handler) {
    _init();
    _handler.onSkipToNext = skipNext;
    _handler.onSkipToPrevious = skipPrevious;
    _handler.onPlaybackStateChanged = () {
      _scheduleSessionSave();
      notifyListeners();
    };
  }

  final ACARMusicHandler _handler;

  AudioPlayer get _player => _handler.player;

  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleOn = false;
  AppRepeatState _repeatMode = AppRepeatState.off;
  bool _isPlaying = false;

  final ValueNotifier<Duration> positionNotifier =
      ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier(Duration.zero);

  Timer? _sleepTimer;
  Timer? _countdownTimer;
  Timer? _saveDebounceTimer;
  final ValueNotifier<Duration> sleepRemainingNotifier =
      ValueNotifier(Duration.zero);
  int _sleepTimerMinutes = 0;

  SharedPreferences? _prefs;
  bool _restoreAttempted = false;
  bool _restoringSession = false;

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
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });

    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
      _scheduleSessionSave();
    });

    _player.durationStream
        .listen((dur) => durationNotifier.value = dur ?? Duration.zero);

    _player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
      _saveSession();
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  void bindLibrary({
    required List<SongModel> songs,
    required bool hasPermission,
    required bool isLoading,
  }) {
    if (!hasPermission || isLoading || songs.isEmpty) return;
    _restoreSessionIfPossible(songs);
  }

  Future<void> playSong(
      SongModel song, List<SongModel> queue, int index) async {
    _queue = queue;
    _currentIndex = index;
    notifyListeners();

    try {
      final path = song.data;
      if (path.isEmpty) return;

      _handler.setCurrentSong(song);

      await _player.setFilePath(path);
      await _player.play();
      _isPlaying = true;
      await _saveSession();
    } catch (e) {
      debugPrint('Error reproduciendo: $e');
    }
  }

  Future<void> togglePlayPause() async {
    _player.playing ? await _player.pause() : await _player.play();
    await _saveSession();
  }

  Future<void> seekTo(double progress) async {
    final dur = durationNotifier.value;
    if (dur.inMilliseconds == 0) return;
    await _player.seek(
      Duration(milliseconds: (progress * dur.inMilliseconds).round()),
    );
    await _saveSession();
  }

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
      await _saveSession();
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

    final songsById = <int, SongModel>{};
    final songsByPath = <String, SongModel>{};
    for (final song in librarySongs) {
      songsById[song.id] = song;
      songsByPath[song.data] = song;
    }

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

    SongModel? restoredSong;
    if (savedId != null) {
      restoredSong = songsById[savedId];
    }
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

    final positionMs = (map['positionMs'] as num?)?.toInt() ?? 0;
    
    if (!hasActiveSource) {
      _restoringSession = true;
      try {
        await _player.setFilePath(restoredSong.data);
        _handler.setCurrentSong(restoredSong);

        if (positionMs > 0) {
          await _player.seek(Duration(milliseconds: positionMs));
          positionNotifier.value = Duration(milliseconds: positionMs);
        }

        if (map['wasPlaying'] as bool? ?? false) {
          await _player.play();
        }
      } catch (e) {
        debugPrint('Error restaurando sesión: $e');
      } finally {
        _restoringSession = false;
      }
    } else {
      _handler.setCurrentSong(restoredSong);
      if (positionMs > 0) {
        await _player.seek(Duration(milliseconds: positionMs));
        positionNotifier.value = Duration(milliseconds: positionMs);
      }
    }

    _restoreAttempted = true;
    await _saveSession();
  }

  AppRepeatState _repeatModeFromName(String? value) {
    return switch (value) {
      'all' => AppRepeatState.all,
      'one' => AppRepeatState.one,
      _ => AppRepeatState.off,
    };
  }

  void _scheduleSessionSave() {
    if (currentSong == null || _restoringSession) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(
      const Duration(milliseconds: 700),
      _saveSession,
    );
  }

  Future<void> _saveSession() async {
    if (_restoringSession) return;

    final song = currentSong;
    if (song == null) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final payload = <String, dynamic>{
      'currentId': song.id,
      'currentPath': song.data,
      'currentIndex': _currentIndex,
      'positionMs': _player.position.inMilliseconds,
      'wasPlaying': _player.playing,
      'isShuffleOn': _isShuffleOn,
      'repeatMode': _repeatMode.name,
      'queueIds': _queue.map((s) => s.id).toList(),
      'queuePaths': _queue.map((s) => s.data).toList(),
    };

    await prefs.setString(_sessionKey, jsonEncode(payload));
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    _saveDebounceTimer?.cancel();
    positionNotifier.dispose();
    durationNotifier.dispose();
    sleepRemainingNotifier.dispose();
    super.dispose();
  }
}
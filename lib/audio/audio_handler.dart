import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ACARMusicHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  int? _queueIndex;

  AudioPlayer get player => _player;

  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  Future<void> Function()? onToggleShuffle;
  Future<void> Function()? onToggleRepeat;

  bool _shuffleEnabled = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  /// Suprime broadcasts al platform channel durante cambio de pista.
  /// Samsung mata apps que envían muchas actualizaciones de notificación seguidas.
  bool suppressBroadcast = false;

  ACARMusicHandler() {
    _configureAudioFocus();

    // SOLO un listener — antes había DOS (playbackEventStream + playerStateStream)
    // ambos llamando _broadcastState, causando ~6 platform channel calls por cambio
    // de pista. Samsung One UI mata apps por esto.
    _player.playerStateStream.listen(
      (_) => _broadcastState(),
      onError: (Object e, StackTrace st) =>
          debugPrint('playerStateStream error: $e'),
    );
  }

  Future<void> _configureAudioFocus() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(0.5);
          } else {
            _player.pause();
          }
        } else if (event.type == AudioInterruptionType.duck) {
          _player.setVolume(1.0);
        }
      });

      session.becomingNoisyEventStream.listen((_) => _player.pause());
    } catch (e) {
      debugPrint('AudioFocus config error: $e');
    }
  }

  Future<void> setQueueAndCurrentSong(
    List<SongModel> songs,
    int index,
  ) async {
    queue.add(songs.map(_toMediaItem).toList(growable: false));
    _queueIndex = index;
    if (index >= 0 && index < songs.length) {
      await setCurrentSong(songs[index], index: index);
    }
  }

  /// Actualiza solo mediaItem + queueIndex sin reconstruir la cola completa.
  Future<void> updateCurrentSong(SongModel song, int index) async {
    _queueIndex = index;
    mediaItem.add(_toMediaItem(song));
  }

  Future<void> setCurrentSong(SongModel song, {int? index}) async {
    _queueIndex = index ?? _queueIndex;
    mediaItem.add(_toMediaItem(song));
  }

  MediaItem _toMediaItem(SongModel song) {
    final artist = song.artist ?? 'Artista desconocido';
    // content:// URI para artwork — Android lo usa en notificación de medios.
    // Solo si hay albumId válido; si no, null (evita crash por URI inválida).
    final Uri? artUri = (song.albumId != null && song.albumId != 0)
        ? Uri.parse('content://media/external/audio/albumart/${song.albumId}')
        : null;
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: artist,
      album: song.album ?? '',
      artUri: artUri,
      duration: Duration(milliseconds: song.duration ?? 0),
      displayTitle: song.title,
      displaySubtitle: artist,
      displayDescription: song.album,
      extras: {
        'songId': song.id,
        'path': song.data,
      },
    );
  }

  /// Fuerza un broadcast del estado actual.
  void refreshPlaybackState() => _broadcastState();

  void updatePlaybackOptions({
    required bool shuffleEnabled,
    required AudioServiceRepeatMode repeatMode,
  }) {
    _shuffleEnabled = shuffleEnabled;
    _repeatMode = repeatMode;
    _broadcastState();
  }

  void _broadcastState({bool forceLoadingWhenIdle = false}) {
    // Mientras se cambia de pista, no enviar actualizaciones al sistema.
    if (suppressBroadcast) return;

    final state = _audioProcessingState;
    playbackState.add(playbackState.value.copyWith(
      controls: _mediaControls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState:
          forceLoadingWhenIdle && state == AudioProcessingState.idle
              ? AudioProcessingState.loading
              : state,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _queueIndex,
      shuffleMode: _shuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: _repeatMode,
    ));
  }

  List<MediaControl> get _mediaControls => [
        MediaControl.custom(
          androidIcon: _shuffleEnabled
              ? 'drawable/ic_notification_shuffle_on'
              : 'drawable/ic_notification_shuffle',
          label: _shuffleEnabled ? 'Mezcla activada' : 'Mezclar',
          name: 'toggleShuffle',
        ),
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.custom(
          androidIcon: switch (_repeatMode) {
            AudioServiceRepeatMode.one => 'drawable/ic_notification_repeat_one',
            AudioServiceRepeatMode.all => 'drawable/ic_notification_repeat_on',
            _ => 'drawable/ic_notification_repeat',
          },
          label: switch (_repeatMode) {
            AudioServiceRepeatMode.one => 'Repetir pista',
            AudioServiceRepeatMode.all => 'Repetir todo',
            _ => 'Sin repeticion',
          },
          name: 'toggleRepeat',
        ),
      ];

  AudioProcessingState get _audioProcessingState =>
      const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ??
      AudioProcessingState.idle;

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => await onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => await onSkipToPrevious?.call();

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'toggleShuffle':
        await onToggleShuffle?.call();
        return null;
      case 'toggleRepeat':
        await onToggleRepeat?.call();
        return null;
      default:
        return super.customAction(name, extras);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // NO llamar super.stop() — destruye la MediaSession y la notificación.
    _broadcastState();
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!_player.playing) await stop();
  }
}

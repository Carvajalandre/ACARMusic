import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ACARMusicHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  VoidCallback? onPlaybackStateChanged;

  ACARMusicHandler() {
    _init();
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((_) {
      _broadcastState(_player.playbackEvent);
      onPlaybackStateChanged?.call();
    });
  }

  Future<void> _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (e) {
      debugPrint('AudioSession error: $e');
    }
  }

  void setCurrentSong(SongModel song) {
    final item = MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Desconocido',
      album: song.album,
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri: song.albumId != null
          ? Uri.parse('content://media/external/audio/albumart/${song.albumId}')
          : null,
    );
    mediaItem.add(item);
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: false,
    ));
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> skipToNext() async => await onSkipToNext?.call();
  @override
  Future<void> skipToPrevious() async => await onSkipToPrevious?.call();
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
  @override
  Future<void> onTaskRemoved() async {
    if (!_player.playing) await stop();
  }
}
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Puente entre just_audio y el MediaSession de Android.
/// Muestra la notificación de reproducción, controla desde la pantalla
/// de bloqueo, auriculares y panel rápido.
class ACARMusicHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // Callbacks que AudioProvider inyecta para manejar la lógica de cola
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  ACARMusicHandler() {
    _initSession();
    // Redirige los eventos del player al MediaSession
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (_, __) {},
    );
    _player.playerStateStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
      onError: (_, __) {},
    );
  }

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      // Sin const — el operador | no es válido en const expression
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Activa la sesión de audio explícitamente
      await session.setActive(true);

      // Interrupciones (llamadas, otras apps de audio)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(0.5);
          } else {
            _player.pause();
          }
        } else {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(1.0);
          }
          // No reanuda automáticamente — el usuario decide
        }
      });

      // Auriculares desconectados → pausa
      session.becomingNoisyEventStream.listen((_) => _player.pause());
    } catch (e) {
      debugPrint('AudioSession config error: $e');
    }
  }

  // ── Actualiza info + emite estado inmediatamente para disparar la notificación
  void setCurrentSong(SongModel song) {
    final item = MediaItem(
      id:       song.id.toString(),
      title:    song.title  ?? 'Pista desconocida',
      artist:   song.artist ?? 'Artista desconocido',
      album:    song.album,
      duration: Duration(milliseconds: song.duration ?? 0),
      // Intenta usar la URI de portada del MediaStore de Android
      artUri: song.albumId != null
          ? Uri.parse(
              'content://media/external/audio/albumart/${song.albumId}')
          : null,
    );
    mediaItem.add(item);

    // Emite estado "loading" inmediatamente → Android crea el controlador
    // antes de que empiece el audio
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.loading,
      playing: false,
    ));
  }

  // ── Publica el estado actual al sistema (notificación + pantalla de bloqueo)
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      // Botones compactos: anterior | play/pause | siguiente
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle:      AudioProcessingState.idle,
        ProcessingState.loading:   AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready:     AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition:   _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  // ── Acciones del MediaSession (botones de la notificación) ──────────────
  @override Future<void> play()   => _player.play();
  @override Future<void> pause()  => _player.pause();
  @override Future<void> seek(Duration position) => _player.seek(position);
  @override Future<void> skipToNext()     async => await onSkipToNext?.call();
  @override Future<void> skipToPrevious() async => await onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    // El usuario eliminó la app del reciente: detener audio
    await stop();
  }
}
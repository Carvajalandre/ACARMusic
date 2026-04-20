import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'audio/audio_handler.dart';
import 'providers/audio_provider.dart';
import 'providers/library_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Inicializa audio_service con manejo de error ──────────────────────────
  ACARMusicHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => ACARMusicHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.acar.music.playback',
        androidNotificationChannelName: 'ACARMusic',
        androidNotificationChannelDescription: 'Reproducción de música',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidStopForegroundOnPause: true,
        androidNotificationOngoing: false,
        notificationColor: Color(0xFF000000),
      ),
    );
  } catch (e) {
    // Si AudioService falla (manifest no configurado aún), 
    // usa el handler directamente sin notificación del sistema
    debugPrint('AudioService.init falló, usando modo sin notificación: $e');
    audioHandler = ACARMusicHandler();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider(audioHandler)),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: const ACARMusicApp(),
    ),
  );
}
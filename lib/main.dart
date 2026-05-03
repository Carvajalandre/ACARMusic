import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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

  // Solicita permisos necesarios para notificaciones y segundo plano
  await _requestPermissions();

  // Inicializa AudioService (notificación + pantalla de bloqueo)
  ACARMusicHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => ACARMusicHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:          'com.acar.music.playback',
        androidNotificationChannelName:        'ACARMusic',
        androidNotificationChannelDescription: 'Reproducción de música',
        androidNotificationIcon:               'mipmap/ic_launcher',
        // false = mantiene el servicio en primer plano aunque esté pausado.
        // Evita que Android mate el proceso y desaparezca el controlador.
        androidStopForegroundOnPause: false,
        androidNotificationOngoing:   false,
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

/// Solicita todos los permisos necesarios al inicio
Future<void> _requestPermissions() async {
  // Android 13+: permiso de notificaciones (necesario para mostrar el controlador)
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Permisos de audio
  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }

  // Android ≤ 12: almacenamiento externo
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }

  // Samsung / MIUI / etc: permiso para iniciar en segundo plano
  // (No interrumpe si falla — es opcional en algunos dispositivos)
  try {
    final ignoreBattery = Permission.ignoreBatteryOptimizations;
    if (await ignoreBattery.isDenied) {
      await ignoreBattery.request();
    }
  } catch (_) {}
}
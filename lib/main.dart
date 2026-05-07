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

  await _requestPermissions();

  ACARMusicHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => ACARMusicHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId:          'com.acar.music.playback',
        androidNotificationChannelName:        'ACARMusic',
        androidNotificationChannelDescription: 'Reproduccion de musica',
        androidNotificationIcon:               'mipmap/ic_launcher',
        androidStopForegroundOnPause:          false,
        androidNotificationOngoing:            true,
      ),
    );
  } catch (e) {
    debugPrint('AudioService.init fallo: $e');
    audioHandler = ACARMusicHandler();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProxyProvider<LibraryProvider, AudioProvider>(
          create: (_) => AudioProvider(audioHandler),
          update: (_, library, audio) {
            audio!.bindLibrary(
              songs:         library.songs,
              hasPermission: library.hasPermission,
              isLoading:     library.isLoading,
            );
            return audio;
          },
        ),
      ],
      child: const ACARMusicApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  try {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  } catch (_) {}
}
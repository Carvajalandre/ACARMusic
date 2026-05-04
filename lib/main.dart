import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        androidNotificationChannelId: 'com.acar.music.playback',
        androidNotificationChannelName: 'ACARMusic',
        androidNotificationChannelDescription: 'Reproducción de música',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidStopForegroundOnPause: false,
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
      ),
    );
  } catch (e) {
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
    const ignoreBattery = Permission.ignoreBatteryOptimizations;
    if (await ignoreBattery.isDenied) {
      await ignoreBattery.request();
    }
  } catch (_) {}
}
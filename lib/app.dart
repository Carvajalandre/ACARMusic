import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class ACARMusicApp extends StatefulWidget {
  const ACARMusicApp({super.key});

  @override
  State<ACARMusicApp> createState() => _ACARMusicAppState();
}

class _ACARMusicAppState extends State<ACARMusicApp>
    with WidgetsBindingObserver {
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive => false,
      AppLifecycleState.hidden => false,
      AppLifecycleState.paused => false,
      AppLifecycleState.detached => false,
    };

    if (_isForeground != isForeground) {
      setState(() => _isForeground = isForeground);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: _isForeground,
      child: MaterialApp(
        title: 'ACARMusic',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

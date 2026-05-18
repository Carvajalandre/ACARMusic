import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ACARMusicApp extends StatefulWidget {
  final bool audioServiceOk;
  final String audioServiceError;

  const ACARMusicApp({
    super.key,
    required this.audioServiceOk,
    required this.audioServiceError,
  });

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      if (!widget.audioServiceOk) {
        _showErrorDialog();
      }
      // Mostrar crash log si existe (de la sesión anterior)
      _showCrashLogIfExists();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isFg = state == AppLifecycleState.resumed;
    if (_isForeground != isFg) setState(() => _isForeground = isFg);
  }

  /// Muestra el crash log guardado por el error handler global.
  /// Se limpia después de mostrarlo.
  Future<void> _showCrashLogIfExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final log = prefs.getString('last_crash_log');
      if (log == null || log.isEmpty) return;

      // Limpiar después de leer
      await prefs.remove('last_crash_log');

      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      showDialog(
        context: ctx,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            '🔍 Error capturado (sesión anterior)',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 14),
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              log,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK',
                  style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  // Muestra el ERROR COMPLETO en un dialog seleccionable
  // para que el usuario pueda copiar el texto y reportarlo
  void _showErrorDialog() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '⚠️ Error de AudioService',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 15),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            widget.audioServiceError,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar',
                style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
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
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
      ),
    );
  }
}

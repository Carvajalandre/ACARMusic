# ACARMusic
A new Flutter project.
## Getting Started
This project is a starting point for a Flutter application.
A few resources to get you started if this is your first Flutter project:
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# FOR DOWNLOAD APK:
- First use command:
- flutter clean
- flutter pub get
- flutter build apk --release
- in /build/app/outputs/flutter-apk/app-release.apk this is app
# FLUTTER VERSION IN USE PROJECT IS 3.47.2
# ACARMusic — documentación técnica

Documentación del estado actual del proyecto Flutter. Las rutas de este archivo
son relativas a la raíz del repositorio (`ACARMusic/`). Se actualizó a partir
del código presente en el checkout y no describe una versión histórica.

## Resumen

ACARMusic es un reproductor de música local para Android, construido con
Flutter. Lee la biblioteca multimedia del dispositivo, reproduce archivos
locales, mantiene audio en segundo plano y ofrece favoritos, historial,
conteo de reproducciones y playlists personalizadas.

Características implementadas:

- Biblioteca de pistas, álbumes, artistas y carpetas.
- Búsqueda por título, artista y álbum.
- Reproducción con cola, anterior/siguiente, shuffle y repeat (`off`, `all`,
  `one`).
- Controles de Android: notificación, pantalla de bloqueo, auriculares y
  Bluetooth mediante `audio_service`.
- Mini reproductor y reproductor completo en portrait y landscape.
- Playlists personalizadas con agregar, quitar, renombrar, eliminar y
  reordenar por drag & drop.
- Favoritos, recién reproducidas, recién añadidas y más escuchadas.
- Temporizador de sueño.
- Cuatro visualizadores: disco de vinilo, barras, radial y minimalista.
- Tema oscuro Material 3 con tipografía Manrope incluida localmente.
- Registro del último error en `SharedPreferences` para diagnóstico en el
  dispositivo.

Estado conocido del producto:

- El proyecto contiene targets Flutter para Android, iOS, Web, Windows, macOS
  y Linux, pero las funciones de biblioteca local, audio_service, ecualizador
  y visualizador nativo están implementadas principalmente para Android.
- La pantalla de permisos conserva textos en inglés (`Grant Permission` y
  `Music Library Access`).
- El selector llamado `Tema oscuro` en Ajustes es visual/local; la app siempre
  inicia con `ThemeMode.dark`.
- Las tarjetas de géneros de Explorar son visuales y no aplican un filtro real
  por género.
- El ecualizador depende de que el dispositivo Android tenga un panel de
  efectos de audio disponible; si no existe, la app muestra un aviso.
- El test incluido es un placeholder y no contiene aserciones funcionales.

## Identificación del checkout

| Dato | Valor actual |
|---|---|
| Nombre del paquete Dart | `acar_music` |
| Versión | `1.0.0+1` |
| Application ID Android | `com.acar.music` |
| Rama observada al actualizar este documento | `CarvaNew` |
| SDK Dart | `>=3.3.0 <4.0.0` |
| Java/Kotlin target Android | Java 17 / JVM 17 |
| Tema | Oscuro fijo, Material 3 |

La rama y la lista de cambios sin commit no deben mantenerse como datos de
producto en esta documentación. El estado de Git se consulta con
`git status --short --branch`.

## Cómo ejecutar

Requisitos habituales:

1. Flutter instalado y configurado (`flutter doctor`).
2. Android SDK y un dispositivo/emulador Android para probar la biblioteca
   multimedia y el audio en segundo plano.
3. Un archivo `android/local.properties` válido para que Gradle encuentre el
   SDK de Flutter.

Comandos principales desde la raíz:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para generar un APK de release:

```bash
flutter build apk --release
```

El build de release Android tiene `minify` y `shrinkResources` desactivados y
usa la configuración de firma debug definida en
`android/app/build.gradle.kts`. Debe reemplazarse por una firma de producción
antes de distribuir la aplicación.

## Dependencias

Las versiones fuente están en `pubspec.yaml`:

| Dependencia | Uso |
|---|---|
| `just_audio` | Motor de reproducción local |
| `audio_service` | MediaSession, servicio y notificación en segundo plano |
| `audio_session` | Audio focus, interrupciones y dispositivo ruidoso |
| `on_audio_query` | Consulta de canciones, álbumes y artistas del dispositivo |
| `provider` | Estado con `ChangeNotifier`, `Selector` y `ProxyProvider` |
| `permission_handler` | Permisos de audio, almacenamiento, micrófono, notificaciones y batería |
| `shared_preferences` | Favoritos, historial, playlists, sesión y preferencias |
| `google_fonts` | API de Manrope; las fuentes se empaquetan localmente |
| `palette_generator` | Colores de las portadas para el reproductor y tiles |

## Estructura del código

```text
lib/
├── main.dart                         Entrada, errores, permisos y providers
├── app.dart                           MaterialApp, ciclo de vida y tema
├── audio/
│   ├── audio_handler.dart              MediaSession y AudioPlayer
│   ├── audio_provider.dart             Cola, reproducción y sesión
│   └── settings/
│       ├── animation_style_sheet.dart  Selector de visualizador
│       ├── equalizer_dialog.dart       Puente al ecualizador Android
│       └── sleep_timer_sheet.dart      Selector del temporizador
├── library/
│   ├── library_provider.dart            Biblioteca y persistencia
│   ├── models/custom_playlist.dart      Modelo de playlist personalizada
│   └── widgets/track_tile.dart          Tile reutilizable de canción
├── screens/
│   ├── home/home_screen.dart            Shell y navegación principal
│   ├── home/widgets/permission_screen.dart
│   ├── library/library_screen.dart      Pistas, álbumes, artistas, carpetas
│   ├── library/playlists_screen.dart    Listas inteligentes y personales
│   ├── library/song_list_screen.dart    Listas genéricas y drag & drop
│   ├── explore/explore_screen.dart      Búsqueda, historial y géneros visuales
│   ├── player/player_screen.dart        Reproductor completo
│   ├── playlist/playlist_detail_screen.dart  Pantalla legacy/adaptadora
│   └── settings/settings_screen.dart   Ajustes
├── theme/app_theme.dart                 Paleta y ThemeData
├── visualizers/                         Visualizadores y FFT
│   ├── animation_style.dart
│   ├── visualizer_factory.dart
│   ├── visualizer_service.dart
│   ├── bar/bar_visualizer.dart
│   ├── radial/radial_visualizer.dart
│   ├── minimalist/minimalist_visualizer.dart
│   └── vinyl/vinyl_record.dart
└── widgets/
    ├── mini_player.dart
    └── buttons/{glow_button,pressable_scale,tap_scale}.dart
```

## Flujo de arranque y estado

### `lib/main.dart`

`main()` configura `GoogleFonts.config.allowRuntimeFetching = false`, inicializa
Flutter, captura errores de Flutter/Dart/platform, permite las cuatro
orientaciones y configura las barras del sistema. Después solicita permisos,
inicializa `AudioService` y monta un `MultiProvider` con:

- `LibraryProvider` para la biblioteca.
- `AudioProvider`, creado con `ChangeNotifierProxyProvider`, para enlazar la
  biblioteca disponible con el reproductor.

Si `AudioService.init` falla, se crea igualmente un `ACARMusicHandler` local y
`ACARMusicApp` muestra el error completo en un diálogo. Los errores capturados
se guardan con la clave `last_crash_log` y se muestran en el siguiente inicio.

`_requestPermissions()` solicita `audio`, `storage`, `microphone` e
`ignoreBatteryOptimizations`. El permiso de notificaciones se pide después del
primer frame desde `lib/app.dart`.

### `lib/app.dart`

`ACARMusicApp` observa el ciclo de vida, utiliza `AppTheme.darkTheme`, fuerza
`ThemeMode.dark` y envuelve `MaterialApp` en `TickerMode`. Al pasar la app a
segundo plano desactiva animaciones Flutter sin detener el audio.

### `lib/screens/home/home_screen.dart`

Es el shell principal con cuatro destinos: Biblioteca, Explorar, Listas y
Ajustes. En portrait usa navegación inferior; en landscape usa un rail
lateral. El `MiniPlayer` se muestra sobre el contenido y `PopScope` envía la
app al background al usar el botón atrás físico. Si no hay permiso para la
biblioteca, se muestra `PermissionScreen`.

## Audio y reproducción

### `lib/audio/audio_handler.dart`

`ACARMusicHandler` extiende `BaseAudioHandler with SeekHandler` y encapsula el
`AudioPlayer`. Publica `MediaItem` con título, artista, álbum, duración,
portada `content://media/.../albumart` y extras con ID/ruta.

Responsabilidades principales:

- `setQueueAndCurrentSong()` actualiza la cola completa y la canción actual.
- `updateCurrentSong()` cambia solo el `mediaItem` y el índice.
- `_broadcastState()` sincroniza posición, buffer, estado, shuffle, repeat y
  controles con Android.
- Expone callbacks para siguiente, anterior, shuffle y repeat, asignados por
  `AudioProvider`.
- Configura audio focus, ducking, interrupciones y pausa al desconectar
  auriculares (`becomingNoisy`).
- `suppressBroadcast` evita ráfagas de actualizaciones al cambiar de pista,
  especialmente importantes en dispositivos Samsung.
- `onTaskRemoved()` detiene el servicio solo si el reproductor ya estaba
  pausado; la reproducción activa sobrevive al gesto de quitar la app de
  Recientes.

El handler no llama a `super.stop()`: conserva la MediaSession/notificación y
solo detiene el `AudioPlayer`.

### `lib/audio/audio_provider.dart`

`AudioProvider` es el estado de reproducción y observa el ciclo de vida.

Estado público relevante:

- `queue`, `currentIndex`, `currentSong`.
- `isPlaying`, `isShuffleOn`, `repeatMode`.
- `positionNotifier`, `durationNotifier` y `sleepRemainingNotifier`.
- `animationStyle` y `visualizerService`.
- `androidAudioSessionId` para abrir efectos de audio Android.

La reproducción valida la ruta del archivo, espera cambios de pista pendientes,
actualiza la MediaSession, carga el archivo con timeout de 12 segundos y
restaura la posición/estado de la sesión cuando la biblioteca está lista.
Guarda la sesión con debounce de 700 ms usando la clave `audio_session_v1`.

También implementa historial de shuffle (máximo 50), temporizador de sueño,
conteo de reproducción a través de `LibraryProvider` y arranque/parada del
visualizador según estado, foreground y sesión Android.

## Biblioteca y persistencia

### `lib/library/library_provider.dart`

Consulta `on_audio_query` ordenando por título. Solo conserva archivos que:

- tengan `isMusic == true`;
- duren al menos 10 segundos;
- no estén en rutas que contengan `whatsapp`, `telegram`, `voice` o
  `audio-record`.

Expone canciones, recién añadidas (máximo 50 por `dateModified`), álbumes,
artistas, favoritos, recién reproducidas, playlists y más escuchadas (máximo
50 con contador mayor que cero). `search()` busca por título, artista y álbum.

Las claves actuales de `SharedPreferences` son:

| Clave | Tipo/contenido |
|---|---|
| `favorites_ids` | `List<String>` con IDs de canciones |
| `recently_played_ids` | `List<String>` con IDs de canciones |
| `custom_playlists_v2` | JSON de `List<CustomPlaylist>` |
| `play_counts` | JSON de `Map<String, int>` |
| `playlist_sort_mode_<id>` | Orden elegido para una playlist |
| `audio_session_v1` | Sesión de reproducción y cola |
| `visualizer_style_v1` | Nombre del visualizador seleccionado |
| `last_crash_log` | Último diagnóstico capturado |

La playlist personalizada usa IDs de canción `int` y un ID de playlist `String`
basado en milisegundos. `getSongsForPlaylist(String)` conserva el orden de
`songIds`; `getSongsFromPlaylist(Object)` es un adaptador async que mantiene
compatibilidad con `PlaylistDetailScreen`.

## Pantallas y widgets

### Biblioteca y listas

- `library_screen.dart`: tabs de Pistas, Álbumes, Artistas y Carpetas; índice
  alfabético en Pistas; reproducción aleatoria; opciones de favorito y
  playlist.
- `playlists_screen.dart`: tarjetas de Recién añadidas, Más escuchadas,
  Favoritos y Escuchadas recientemente; creación, renombrado y eliminación de
  playlists personales.
- `song_list_screen.dart`: recibe `String? playlistId`; soporta orden
  personalizado, A-Z y recién añadidas. En orden personalizado permite drag &
  drop y persiste la nueva secuencia.
- `playlist_detail_screen.dart`: pantalla legacy que recibe `int playlistId`
  y usa el adaptador `getSongsFromPlaylist`. Los textos y acciones de esta
  pantalla todavía conservan partes en inglés.

### Explorar y reproductor

- `explore_screen.dart`: búsqueda en tiempo real, resultados, carrusel de
  escuchadas recientemente y tarjetas de géneros decorativas.
- `player_screen.dart`: vista portrait/landscape, portada, colores dinámicos
  con `PaletteGenerator`, cola, progreso, controles, favorito, agregar a
  playlist, temporizador, ecualizador y selector de visualizador.
- `mini_player.dart`: acceso persistente al reproductor completo y controles
  de pausa/reproducción con barra de progreso ligera.
- `library/widgets/track_tile.dart`: tile reutilizable con arte, color de
  acento derivado de la portada, estado de pista activa y menú contextual.

### Ajustes

`settings_screen.dart` muestra temporizador de sueño, selector de animación,
calidad/efectos de sonido y diálogo Acerca de. El selector de animación guarda
uno de estos valores:

| Valor | Implementación |
|---|---|
| `vinyl` | `VinylRecord` giratorio |
| `barVisualizer` | `BarVisualizer` con barras FFT |
| `radialVisualizer` | `RadialVisualizer` circular |
| `minimalist` | `MinimalistVisualizer` con portada |

## Visualizador y código Android nativo

`VisualizerService` comunica Dart con Android por:

- MethodChannel `com.acar.music/visualizer`.
- EventChannel `com.acar.music/visualizer_fft`.

`android/app/src/main/kotlin/com/acar/music/VisualizerPlugin.kt` intenta crear
un `android.media.audiofx.Visualizer` para el `audioSessionId`. Si el DSP o el
dispositivo no lo permite, devuelve `false` y Dart genera un stream FFT
simulado. Cuando la reproducción está pausada, emite frames silenciosos.

`MainActivity.kt` también registra el MethodChannel
`com.acar.music/equalizer`. `openEqualizer` abre el panel de efectos del
dispositivo con el audio session ID; si Android no tiene una actividad
compatible, la UI informa que no está disponible.

## Permisos y configuración Android

`android/app/src/main/AndroidManifest.xml` declara:

- `READ_EXTERNAL_STORAGE` hasta API 32 y `READ_MEDIA_AUDIO` desde API 33.
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` y `WAKE_LOCK`.
- `POST_NOTIFICATIONS`.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- `RECORD_AUDIO` para el visualizador FFT.

También registra el servicio `com.ryanheise.audioservice.AudioService` con
`foregroundServiceType="mediaPlayback"` y el receptor de botones de medios.

## Tema y rendimiento

`lib/theme/app_theme.dart` define Material 3 oscuro. Colores principales:

| Token | Hex |
|---|---|
| `background` | `#000000` |
| `surface` | `#0E0E0E` |
| `surfaceContainerLow` | `#131313` |
| `surfaceContainerHigh` | `#1F1F1F` |
| `surfaceVariant` | `#262626` |
| `primary` | `#C6C6C7` |
| `tertiary` | `#FAF9F9` |
| `onSurface` | `#E5E5E5` |
| `onSurfaceVariant` | `#ABABAB` |

Optimizaciones actuales:

- `TickerMode` y observers de ciclo de vida pausan animaciones en background.
- `Selector` limita reconstrucciones de Provider.
- `ValueNotifier` actualiza posición/duración sin reconstruir toda la pantalla.
- `RepaintBoundary` y arte persistente reducen parpadeos de portadas.
- `itemExtent`/alturas fijas se usan en listas críticas.
- `suppressBroadcast` reduce llamadas al canal de plataforma durante cambios de
  pista.
- La fuente Manrope se empaqueta en `assets/google_fonts/`; no se requiere red.

## Flujo principal

```text
main.dart
  ├─ permisos
  ├─ AudioService.init → ACARMusicHandler → just_audio.AudioPlayer
  └─ MultiProvider
       ├─ LibraryProvider → on_audio_query → canciones/álbumes/artistas
       └─ AudioProvider → cola/sesión/controles/visualizador

Pantalla → AudioProvider.playSong()
        → ACARMusicHandler MediaItem + AudioPlayer
        → audio local + MediaSession Android
        → notificación / bloqueo / Bluetooth
```

## Archivos de plataforma y recursos importantes

| Ubicación | Responsabilidad |
|---|---|
| `pubspec.yaml` | Dependencias, versión, assets y fuentes |
| `assets/icon/` | Icono de la aplicación |
| `assets/google_fonts/` | Fuentes Manrope bundled |
| `android/app/src/main/AndroidManifest.xml` | Permisos, servicio y receiver |
| `android/app/src/main/kotlin/com/acar/music/MainActivity.kt` | MethodChannel Android |
| `android/app/src/main/kotlin/com/acar/music/VisualizerPlugin.kt` | FFT nativa |
| `android/app/src/main/res/drawable/ic_notification*.xml` | Iconos de controles de notificación |
| `test/widget_test.dart` | Placeholder de pruebas |

## Mantenimiento de esta documentación

Al mover una pantalla o cambiar una clave persistida, actualizar las rutas y
tablas de este archivo en el mismo cambio. Antes de marcar una característica
como implementada, comprobar su flujo desde la pantalla hasta el provider y,
si aplica, hasta el canal Android. Validar con:

```bash
flutter analyze
flutter test
```

**Última revisión:** 12 de septiembre de 2026, basada en el checkout actual de
`CarvaNew`.

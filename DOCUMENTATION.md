# ACARMusic â€” DocumentaciÃ³n TÃ©cnica (Parte 1)

## Resumen del Proyecto

**ACARMusic** es un reproductor de mÃºsica local para Android, desarrollado en Flutter, inspirado en Samsung Music. Permite reproducir pistas almacenadas en el dispositivo con soporte completo de audio en segundo plano, notificaciones del sistema, y gestiÃ³n de playlists personalizadas. Es open source, personalizable y optimizado para rendimiento y baterÃ­a.

- **VersiÃ³n:** 1.0.0+1  
- **SDK Flutter:** `>=3.3.0 <4.0.0`  
- **Dispositivo de prueba:** Samsung S20 FE  
- **Rama activa:** `CarvaNew`  
- **Tema:** Oscuro fijo (Material 3)

---

## Arquitectura General

```
main.dart          â†’ Punto de entrada, permisos, AudioService, providers
app.dart           â†’ Widget raÃ­z, TickerMode (optimiza baterÃ­a en background)
â”‚
â”œâ”€â”€ audio/
â”‚   â””â”€â”€ audio_handler.dart     â†’ Handler de AudioService (notificaciones, MediaSession)
â”‚
â”œâ”€â”€ models/
â”‚   â””â”€â”€ custom_playlist.dart   â†’ Modelo de datos de playlist personalizada
â”‚
â”œâ”€â”€ providers/
â”‚   â”œâ”€â”€ audio_provider.dart    â†’ Estado de reproducciÃ³n (cola, shuffle, repeat, sesiÃ³n)
â”‚   â””â”€â”€ library_provider.dart  â†’ Biblioteca de mÃºsica, favoritos, recientes, playlists
â”‚
â”œâ”€â”€ screens/
â”‚   â”œâ”€â”€ home_screen.dart           â†’ NavegaciÃ³n principal (BottomNav / Rail)
â”‚   â”œâ”€â”€ library_screen.dart        â†’ Biblioteca (Pistas / Ãlbumes / Artistas / Carpetas)
â”‚   â”œâ”€â”€ explore_screen.dart        â†’ Explorar, bÃºsqueda, gÃ©neros, recientes
â”‚   â”œâ”€â”€ playlists_screen.dart      â†’ Listas (favoritos, recientes, personalizadas)
â”‚   â”œâ”€â”€ song_list_screen.dart      â†’ Lista de canciones reutilizable (drag & drop)
â”‚   â”œâ”€â”€ playlist_detail_screen.dartâ†’ Detalle de playlist (versiÃ³n legacy)
â”‚   â”œâ”€â”€ player_screen.dart         â†’ Pantalla completa del reproductor
â”‚   â””â”€â”€ settings_screen.dart       â†’ Ajustes, temporizador de sueÃ±o, ecualizador
â”‚
â”œâ”€â”€ theme/
â”‚   â””â”€â”€ app_theme.dart             â†’ Paleta de colores y ThemeData
â”‚
â””â”€â”€ widgets/
    â”œâ”€â”€ mini_player.dart           â†’ Mini reproductor persistente (bottom)
    â”œâ”€â”€ track_tile.dart            â†’ Tile reutilizable para pistas
    â”œâ”€â”€ vinyl_record.dart          â†’ Disco de vinilo animado
    â””â”€â”€ permission_screen.dart     â†’ Pantalla de solicitud de permisos
```

---

## Dependencias (`pubspec.yaml`)

**UbicaciÃ³n:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\pubspec.yaml`

| Paquete | VersiÃ³n | Uso |
|---|---|---|
| `just_audio` | ^0.9.40 | Motor de reproducciÃ³n de audio |
| `audio_service` | ^0.18.15 | Servicio en segundo plano + notificaciÃ³n MediaSession |
| `audio_session` | ^0.1.21 | GestiÃ³n de sesiÃ³n de audio del sistema |
| `on_audio_query` | ^2.9.0 | Consulta de archivos multimedia locales |
| `provider` | ^6.1.2 | Manejo de estado (ChangeNotifier) |
| `permission_handler` | ^11.3.1 | Solicitud de permisos en runtime |
| `shared_preferences` | ^2.3.2 | Persistencia local (favoritos, sesiÃ³n, playlists) |
| `google_fonts` | ^6.2.1 | TipografÃ­a Manrope |
| `palette_generator` | ^0.3.3+3 | ExtracciÃ³n de colores de portadas de Ã¡lbumes |

---

## Archivos Pendientes de Commit (rama `CarvaNew`)

> Archivos modificados sin hacer commit aÃºn:

| Archivo | Ruta completa |
|---|---|
| `app.dart` | `lib/app.dart` |
| `audio_handler.dart` | `lib/audio/audio_handler.dart` |
| `main.dart` | `lib/main.dart` |
| `audio_provider.dart` | `lib/providers/audio_provider.dart` |
| `library_provider.dart` | `lib/providers/library_provider.dart` |
| `home_screen.dart` | `lib/screens/home_screen.dart` |
| `player_screen.dart` | `lib/screens/player_screen.dart` |
| `song_list_screen.dart` | `lib/screens/song_list_screen.dart` |
| `pubspec.yaml` | `pubspec.yaml` |
# ACARMusic â€” DocumentaciÃ³n TÃ©cnica (Parte 2: Capa de Audio y Entrada)

---

## `lib/main.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\main.dart`
**Estado:** âš ï¸ Pendiente de commit

Punto de entrada de la aplicaciÃ³n. Ejecuta la inicializaciÃ³n completa antes de montar la UI.

### Funciones

| FunciÃ³n | DescripciÃ³n |
|---|---|
| `main()` | FunciÃ³n principal `async`. Inicializa bindings Flutter, orientaciones permitidas, estilo de la barra del sistema, solicita permisos, inicializa `AudioService` y lanza la app con `MultiProvider`. |
| `_requestPermissions()` | Solicita en runtime: notificaciones, audio, almacenamiento, y optimizaciÃ³n de baterÃ­a (`ignoreBatteryOptimizations`). El bloque de baterÃ­a estÃ¡ envuelto en `try/catch` para evitar fallos en dispositivos que no lo soporten. |

### ConfiguraciÃ³n de `AudioService`
```dart
AudioServiceConfig(
  androidNotificationChannelId: 'com.acar.music.playback',
  androidNotificationChannelName: 'ACARMusic',
  androidStopForegroundOnPause: false,   // mÃºsica sigue si se pausa
  androidNotificationOngoing: true,       // no descartable por el usuario
  androidShowNotificationBadge: true,
)
```

---

## `lib/app.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\app.dart`
**Estado:** âš ï¸ Pendiente de commit

Widget raÃ­z `ACARMusicApp`. Implementa `WidgetsBindingObserver` para detectar el ciclo de vida de la app.

### Clase `_ACARMusicAppState`

| Elemento | DescripciÃ³n |
|---|---|
| `_isForeground` | `bool` que indica si la app estÃ¡ en primer plano. |
| `didChangeAppLifecycleState()` | Detecta transiciones de estado (resumed / paused / hidden). Actualiza `_isForeground`. |
| `build()` | Envuelve `MaterialApp` en `TickerMode(enabled: _isForeground)`. **Clave de optimizaciÃ³n:** detiene TODOS los `AnimationController` cuando la app pasa a segundo plano, ahorrando CPU y baterÃ­a sin interrumpir el audio. |

---

## `lib/audio/audio_handler.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\audio\audio_handler.dart`
**Estado:** âš ï¸ Pendiente de commit

Handler central del audio. Extiende `BaseAudioHandler with SeekHandler` de `audio_service`, lo que habilita el control desde la notificaciÃ³n del sistema, auriculares Bluetooth y pantalla de bloqueo.

### Clase `ACARMusicHandler`

| Elemento | DescripciÃ³n |
|---|---|
| `_player` | Instancia de `AudioPlayer` (just_audio). Motor real de reproducciÃ³n. |
| `onSkipToNext` | Callback asignable desde `AudioProvider`. Desacopla la lÃ³gica de saltar al siguiente. |
| `onSkipToPrevious` | Callback asignable desde `AudioProvider`. |
| `onPlaybackStateChanged` | Callback que se llama en cada cambio de estado del player; notifica al provider. |
| `_init()` | Configura `AudioSession` con el perfil `.music()` y lo activa. |
| `setCurrentSong(SongModel)` | Publica el `MediaItem` al sistema (tÃ­tulo, artista, Ã¡lbum, portada, duraciÃ³n). Esto actualiza la notificaciÃ³n de Android y la pantalla de bloqueo. |
| `_broadcastState(PlaybackEvent)` | Sincroniza el `playbackState` del handler con el estado real del `AudioPlayer` (posiciÃ³n, buffer, controles, processingState). |
| `play()` / `pause()` / `seek()` | Delegados directamente al `AudioPlayer`. |
| `skipToNext()` / `skipToPrevious()` | Invocan los callbacks asignados por el `AudioProvider`. |
| `stop()` | Detiene el player y llama a `super.stop()` para limpiar el servicio. |
| `onTaskRemoved()` | Al deslizar la app del recents: detiene el audio **solo si estaba pausado**, preservando la reproducciÃ³n activa. |

---

## `lib/providers/audio_provider.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\providers\audio_provider.dart`
**Estado:** âš ï¸ Pendiente de commit

Cerebro del reproductor. `ChangeNotifier` que centraliza toda la lÃ³gica de estado de reproducciÃ³n.

### Enum `AppRepeatState`
```dart
enum AppRepeatState { off, all, one }
```

### Estado interno

| Campo | Tipo | DescripciÃ³n |
|---|---|---|
| `_queue` | `List<SongModel>` | Cola de reproducciÃ³n activa |
| `_currentIndex` | `int` | Ãndice de la canciÃ³n actual en la cola |
| `_isShuffleOn` | `bool` | Modo aleatorio activado |
| `_repeatMode` | `AppRepeatState` | Modo de repeticiÃ³n actual |
| `positionNotifier` | `ValueNotifier<Duration>` | PosiciÃ³n en tiempo real (no rebuild completo) |
| `durationNotifier` | `ValueNotifier<Duration>` | DuraciÃ³n de la pista actual |
| `sleepRemainingNotifier` | `ValueNotifier<Duration>` | Tiempo restante del temporizador de sueÃ±o |

### MÃ©todos principales

| MÃ©todo | DescripciÃ³n |
|---|---|
| `_init()` | Conecta los streams del player: posiciÃ³n, duraciÃ³n y estado. |
| `bindLibrary()` | Llamado desde la UI cuando la biblioteca carga; dispara `_restoreSessionIfPossible`. |
| `playSong(song, queue, index)` | Carga y reproduce una pista. Actualiza cola, Ã­ndice y `MediaItem`. |
| `togglePlayPause()` | Alterna entre play y pause. |
| `seekTo(double progress)` | Mueve la posiciÃ³n a `progress * duration`. |
| `skipNext()` | Salta a la siguiente pista respetando shuffle y repeat. |
| `skipPrevious()` | Si `position > 3s`, reinicia la pista; si no, retrocede. |
| `_onTrackCompleted()` | Maneja el fin de pista segÃºn el modo de repeticiÃ³n. |
| `toggleShuffle()` | Activa/desactiva aleatorio. |
| `toggleRepeat()` | Cicla entre `off â†’ all â†’ one â†’ off`. |
| `setSleepTimer(int minutes)` | Inicia un `Timer` que pausa el audio tras N minutos y un `Timer.periodic` de countdown. |
| `cancelSleepTimer()` | Cancela el temporizador. |
| `_saveSession()` | Persiste en `SharedPreferences`: canciÃ³n actual, posiciÃ³n, cola, shuffle, repeat. |
| `_restoreSessionIfPossible()` | Al arrancar, reconstruye la cola y posiciÃ³n desde la sesiÃ³n guardada. Busca por ID y luego por path para robustez. |
| `_scheduleSessionSave()` | Debounce de 700ms para no escribir en disco en cada frame de posiciÃ³n. |
| `formatDuration(Duration)` | Convierte duraciÃ³n a `"m:ss"`. |
# ACARMusic â€” DocumentaciÃ³n TÃ©cnica (Parte 3: Providers, Models y Theme)

---

## `lib/providers/library_provider.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\providers\library_provider.dart`
**Estado:** âš ï¸ Pendiente de commit

Gestiona la biblioteca musical: carga, filtrado, favoritos, historial, playlists y conteo de reproducciones. Toda la persistencia usa `SharedPreferences`.

### Estado interno

| Campo | DescripciÃ³n |
|---|---|
| `_songs` | Lista completa de canciones filtradas (excluye WhatsApp, Telegram, notas de voz, < 10s) |
| `_recentlyAdded` | Las 50 mÃ¡s nuevas por `dateModified` |
| `_albums` / `_artists` | Ãlbumes y artistas del dispositivo |
| `_filteredSongs` | Resultado de bÃºsqueda activa |
| `_favorites` | Canciones marcadas como favoritas |
| `_recentlyPlayed` | Historial de reproducciÃ³n (mÃ¡x. 50) |
| `_playlists` | Playlists personalizadas (`CustomPlaylist`) |
| `_playCounts` | Mapa `songId â†’ count` para "MÃ¡s escuchadas" |

### Claves de persistencia (`SharedPreferences`)

| Clave | Contenido |
|---|---|
| `favorites_ids` | `List<String>` de IDs |
| `recently_played_ids` | `List<String>` de IDs |
| `custom_playlists_v2` | JSON de `List<CustomPlaylist>` |
| `play_counts` | JSON de `Map<String, int>` |

### MÃ©todos principales

| MÃ©todo | DescripciÃ³n |
|---|---|
| `loadLibrary()` | Consulta `on_audio_query` para pistas, Ã¡lbumes y artistas. Filtra rutas de apps de mensajerÃ­a. |
| `search(String)` | Filtra por tÃ­tulo, artista y Ã¡lbum (case-insensitive). |
| `clearSearch()` | Limpia el query y regresa a la lista completa. |
| `addToFavorites(song)` / `removeFromFavorites(song)` | Gestiona la lista de favoritos y persiste. |
| `isFavorite(song)` | Retorna `bool` para mostrar el Ã­cono de corazÃ³n. |
| `addToRecentlyPlayed(song)` | Inserta al inicio, elimina duplicados, limita a 50. |
| `incrementPlayCount(int)` | Incrementa silenciosamente el contador (sin `notifyListeners`). |
| `createPlaylist(String)` | Crea playlist con ID = timestamp actual. |
| `deletePlaylist(String)` | Elimina por ID. |
| `renamePlaylist(String, String)` | Renombra usando `copyWith`. |
| `addSongToPlaylist(playlistId, songId)` | Agrega si no existe ya. |
| `removeSongFromPlaylist(playlistId, songId)` | Elimina de la lista de IDs. |
| `reorderPlaylist(playlistId, List<int>)` | Guarda el nuevo orden (drag & drop). Sin `notifyListeners` porque la UI ya actualizÃ³ el estado local. |
| `getSongsForPlaylist(playlistId)` | Devuelve canciones en el orden exacto de `songIds` usando un mapa O(1). |
| `getSongsByAlbum(albumId)` | Filtra por Ã¡lbum. |
| `getSongsByArtist(artistId)` | Filtra por artista. |
| `mostPlayed` (getter) | Ordena por `_playCounts` descendente, retorna top 50. |

---

## `lib/models/custom_playlist.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\models\custom_playlist.dart`

Modelo de datos para playlists personalizadas.

### Clase `CustomPlaylist`

| Campo | Tipo | DescripciÃ³n |
|---|---|---|
| `id` | `String` | Timestamp en ms (Ãºnico) |
| `name` | `String` | Nombre de la playlist |
| `songIds` | `List<int>` | IDs de canciones en orden personalizado |

### MÃ©todos

| MÃ©todo | DescripciÃ³n |
|---|---|
| `toJson()` | Serializa a `Map<String, dynamic>` |
| `fromJson(Map)` | Factory de deserializaciÃ³n |
| `copyWith({name, songIds})` | Inmutabilidad: genera copia con campos actualizados |
| `decodeList(String)` | Deserializa JSON â†’ `List<CustomPlaylist>` |
| `encodeList(List)` | Serializa `List<CustomPlaylist>` â†’ JSON String |

---

## `lib/theme/app_theme.dart`
**Ruta:** `c:\Users\Andres\Desktop\Desarrollo\ACAR\ACARMusic\v2\ACARMusic\lib\theme\app_theme.dart`

Define el sistema de diseÃ±o completo de la app. Solo tiene un tema oscuro (no existe tema claro activo).

### Paleta "Sonic Monolith / ACARMusic"

| Token | Hex | Uso |
|---|---|---|
| `background` | `#000000` | Fondo de todos los Scaffolds |
| `surface` | `#0E0E0E` | Superficies de tarjetas / tiles |
| `surfaceContainerLow` | `#131313` | Tiles activos (pista sonando) |
| `surfaceContainerHigh` | `#1F1F1F` | Modales y bottom sheets |
| `surfaceVariant` | `#262626` | Elementos secundarios |
| `primary` | `#C6C6C7` | Color de acento principal (gris platino) |
| `tertiary` | `#FAF9F9` | BotÃ³n play, barra de progreso |
| `onSurface` | `#E5E5E5` | Texto principal |
| `onSurfaceVariant` | `#ABABAB` | Texto secundario |
| `outline` | `#757575` | Bordes y elementos inactivos |

### `darkTheme` (getter)
Construye `ThemeData` con `useMaterial3: true`, `splashColor: transparent` (quita el ripple) y el `ColorScheme` personalizado.
# ACARMusic â€” DocumentaciÃ³n TÃ©cnica (Parte 4: Screens)

---

## `lib/screens/home_screen.dart`
**Ruta:** `lib/screens/home_screen.dart`  **Estado:** âš ï¸ Pendiente de commit

Shell de navegaciÃ³n principal. Muestra la pantalla correcta segÃºn permisos y orientaciÃ³n.

| Elemento | DescripciÃ³n |
|---|---|
| `_screens` | `IndexedStack` con las 4 pestaÃ±as: Biblioteca, Explorar, Listas, Ajustes |
| `_buildPortrait()` | Layout vertical: `BottomNavigationBar` personalizado + `MiniPlayer` sobre el contenido |
| `_buildLandscape()` | Layout horizontal: rail lateral de 64px + contenido expandido |
| `_buildBottomNav()` | Nav bar con 4 iconos, animaciÃ³n `AnimatedContainer` de 200ms al seleccionar |
| `_buildSideNav()` | Rail lateral en landscape con los mismos iconos |
| Guardia de permisos | Si `!library.hasPermission` â†’ muestra `PermissionScreen` en vez del Scaffold |
| `PopScope` | Intercepta el botÃ³n "atrÃ¡s" fÃ­sico para mover la app al background (`SystemNavigator.pop()`) en lugar de cerrarla |

---

## `lib/screens/library_screen.dart`
**Ruta:** `lib/screens/library_screen.dart`

Biblioteca musical con tabs y sidebar alfabÃ©tico. Usa `NestedScrollView` para que el header colapse al hacer scroll.

| MÃ©todo / Widget | DescripciÃ³n |
|---|---|
| `TabController` (4 tabs) | Pistas / Ãlbumes / Artistas / Carpetas |
| `_buildLetterIndex()` | Construye un mapa `letra â†’ Ã­ndice` para el sidebar alfabÃ©tico |
| `_scrollToLetter()` | `animateTo(idx * 72.0)` para saltar a la letra tocada |
| `_buildTracksTab()` | `ListView.builder` + sidebar derecho de 22px con letras A-Z. Usa `Selector` para evitar rebuilds globales. |
| `_buildAlbumsTab()` | `GridView` 2 columnas con portadas de Ã¡lbum y opciÃ³n de reproducir al tocar |
| `_buildArtistsTab()` | `ListView` de artistas con avatar circular y contador de canciones |
| `_buildFoldersTab()` | Agrupa canciones por carpeta del sistema y muestra como lista |
| `_buildEmpty()` | Widget vacÃ­o genÃ©rico (Ã­cono + mensaje) |
| `_showTrackOptions()` | Bottom sheet: Agregar a Favoritos / Agregar a Lista |
| `_StickyTabBarDelegate` | `SliverPersistentHeaderDelegate` para mantener el `TabBar` pegado debajo del `SliverAppBar` |
| BotÃ³n "Mezclar" | En el header expandido; reproduce una canciÃ³n aleatoria de la biblioteca |

---

## `lib/screens/explore_screen.dart`
**Ruta:** `lib/screens/explore_screen.dart`

Pantalla de descubrimiento con buscador en tiempo real, historial y tarjetas de gÃ©neros.

| Elemento | DescripciÃ³n |
|---|---|
| `_searchCtrl` | `TextEditingController` del campo de bÃºsqueda |
| `_buildSearchBar()` | Campo de texto con `prefixIcon` lupa y `suffixIcon` Ã— para limpiar. Llama a `library.search(v)` en `onChanged`. |
| `_buildSearchResults()` | `SliverList` de `TrackTile` filtrado por el query activo |
| `_buildRecentlyPlayed()` | Carrusel horizontal de 148Ã—148px de las Ãºltimas pistas escuchadas |
| `_buildGenres()` | Grid 2Ã—3 de tarjetas de gÃ©neros con gradiente. Actualmente decorativo (sin filtrado real por gÃ©nero). |
| `_Genre` / `_GenreCard` | Modelo interno y widget de tarjeta de gÃ©nero con Ã­cono en `Stack` semitransparente |

---

## `lib/screens/playlists_screen.dart`
**Ruta:** `lib/screens/playlists_screen.dart`

Hub de listas de reproducciÃ³n. Muestra colecciones inteligentes y playlists personalizadas.

| Elemento | DescripciÃ³n |
|---|---|
| `_buildTopCards()` | 4 tarjetas con gradiente (2Ã—2): ReciÃ©n aÃ±adidas, MÃ¡s escuchadas, Favoritos, Escuchadas recientemente. Cada una navega a `SongListScreen`. |
| `_buildPlaylistsList()` | `SliverList` de las playlists del usuario. Cada item tiene botÃ³n `â‹®` con opciones. |
| `_showCreatePlaylistDialog()` | `AlertDialog` con `TextField` para nombre. Llama a `library.createPlaylist()`. |
| `_showPlaylistOptions()` | Bottom sheet con opciones: Renombrar / Eliminar lista |
| `_showRenameDialog()` | `AlertDialog` pre-rellenado con el nombre actual |
| `_TopCard` | Widget reutilizable de tarjeta con gradiente, Ã­cono decorativo y conteo de canciones |

---

## `lib/screens/song_list_screen.dart`
**Ruta:** `lib/screens/song_list_screen.dart`  **Estado:** âš ï¸ Pendiente de commit

Pantalla genÃ©rica de lista de canciones. Usada por favoritos, recientes, mÃ¡s escuchadas y playlists personalizadas.

| Elemento | DescripciÃ³n |
|---|---|
| `playlistId` (param.) | Si no es `null`, habilita modo editable con drag & drop |
| `_SortMode` | Enum: `custom` (orden propio) / `az` (A-Z) / `recentlyAdded` |
| `_applySort()` | Reordena `_sorted` segÃºn el modo activo |
| `_onReorder()` | Callback del drag & drop; llama a `library.reorderPlaylist()` para persistir |
| `SliverReorderableList` | Lista con drag & drop (solo playlists en modo `custom`). El handle es un Ã­cono separado (`ReorderableDragStartListener`) para no interferir con el scroll. |
| `_buildSortMenu()` | `PopupMenuButton` con las opciones de orden |
| `_BackgroundArt` | Header visual: si hay 1 canciÃ³n muestra su portada, si hay mÃ¡s muestra un grid 2Ã—2, si no hay ninguna muestra el Ã­cono de lista |
| `_showOptions()` | Bottom sheet: Favoritos / Quitar de esta lista (si es playlist) |
| `MiniPlayer` en `bottomNavigationBar` | El mini player se ancla como `bottomNavigationBar` del Scaffold en esta pantalla |

---

## `lib/screens/player_screen.dart`
**Ruta:** `lib/screens/player_screen.dart`  **Estado:** âš ï¸ Pendiente de commit

Pantalla completa del reproductor. La mÃ¡s compleja del proyecto (759 lÃ­neas).

| Elemento | DescripciÃ³n |
|---|---|
| `_colorA`, `_colorB`, `_glowColor` | Colores dinÃ¡micos extraÃ­dos de la portada del Ã¡lbum |
| `_bgCtrl` | `AnimationController` de 6 segundos en loop para el fondo degradado animado |
| `_showQueue` | `bool` que alterna entre vista del vinilo y panel de cola |
| `_queueScrollCtrl` | Scroll automÃ¡tico a la canciÃ³n actual al abrir la cola |
| `didChangeAppLifecycleState()` | Pausa `_bgCtrl` cuando la app estÃ¡ en background (ahorra CPU) |
| `_extractPalette(song)` | Usa `PaletteGenerator` sobre la portada JPEG del Ã¡lbum para extraer `vibrantColor`, `dominantColor` y `mutedColor`. Actualiza el fondo animado. |
| `_fallback(song)` | Si no hay portada, genera colores por HSL a partir del `albumId`. |
| `_buildPortrait()` | Layout vertical: header, tÃ­tulo/artista (72px fijo), vinilo/cola (Expanded), Ã¡lbum, progreso, controles, botones de acciÃ³n |
| `_buildLandscape()` | Layout horizontal 2 columnas: izquierda vinilo, derecha controles |
| `_buildQueuePanel()` | `ListView.builder` con altura fija (`itemExtent: 60`). Resalta la canciÃ³n actual. |
| `_progressBar()` | `ValueListenableBuilder` anidado para posiciÃ³n y duraciÃ³n. `Slider` personalizado. |
| `_controls()` | `Selector` de `(isPlaying, shuffleOn, repeatMode)`. Botones: shuffle, anterior, play/pause, siguiente, repeat. |
| `_actionButtons()` | 3 botones: LIKE (favorito), LISTA (agregar a playlist), COLA (toggle panel) |
| `_addToPlaylistSheet()` | Modal para seleccionar a quÃ© playlist agregar la canciÃ³n actual |
| `_ActionBtn` | Widget privado: Ã­cono + etiqueta en columna |
| `_PressableScale` | Widget de micro-animaciÃ³n: escala a 0.92 al presionar (110ms) |

---

## `lib/screens/settings_screen.dart`
**Ruta:** `lib/screens/settings_screen.dart`

| Elemento | DescripciÃ³n |
|---|---|
| `_buildSleepTimerTile()` | Tile especial con `ValueListenableBuilder` para mostrar el countdown en tiempo real |
| `_showSleepTimerSheet()` | Bottom sheet con presets (15, 30, 45, 60, 90, 120 min) y campo personalizado |
| `_showEqualizer()` | Informa que el ecualizador requiere integraciÃ³n del sistema (no implementado) |
| `_showAbout()` | `showAboutDialog` nativo con info de la app |
| `_buildSection()` | Contenedor de grupo de ajustes con etiqueta en mayÃºsculas |
| `_buildSettingTile()` | Tile reutilizable con Ã­cono circular, tÃ­tulo, subtÃ­tulo y trailing |
| `_fmt(Duration)` | Formatea duraciÃ³n en `"Xm Ys"` o `"Xh Ym"` |

---

## `lib/screens/playlist_detail_screen.dart`
**Ruta:** `lib/screens/playlist_detail_screen.dart`

> âš ï¸ Pantalla **legacy** â€” Recibe un `playlistId` de tipo `int` (playlists del sistema de `on_audio_query`, no las playlists personalizadas del app). La funciÃ³n `getSongsFromPlaylist` que referencia no existe en `LibraryProvider` actual. EstÃ¡ siendo reemplazada por `SongListScreen` + `playlistId` de tipo `String`. La opciÃ³n "Remove from Playlist" tiene un TODO pendiente de implementaciÃ³n.

---
# ACARMusic â€” DocumentaciÃ³n TÃ©cnica (Parte 5: Widgets, Optimizaciones y Notas)

---

## `lib/widgets/mini_player.dart`
**Ruta:** `lib/widgets/mini_player.dart`

Mini reproductor flotante que aparece en la parte inferior cuando hay una canciÃ³n activa.

| Elemento | DescripciÃ³n |
|---|---|
| `MiniPlayer` | `StatelessWidget`. Usa `context.select` solo para el ID de canciÃ³n (evita rebuilds por posiciÃ³n). Lee el resto con `context.read`. |
| NavegaciÃ³n | Al tocar, abre `PlayerScreen` con animaciÃ³n de slide desde abajo (`SlideTransition` + `PageRouteBuilder`). |
| `_ProgressBar` | Widget separado con `ValueListenableBuilder<Duration>`. Dibuja manualmente la barra (3px de alto, sin `Slider`) para rendimiento Ã³ptimo. |
| `_PressableIconButton` | BotÃ³n Ã­cono con efecto de escala al presionar. |
| `_PressableScale` | Escala a 0.9 en 110ms (idÃ©ntico al del `PlayerScreen`). |
| Portada | `QueryArtworkWidget` con `keepOldArtwork: true` y `RepaintBoundary` para evitar repaints al cambiar la posiciÃ³n. |
| Controles | `Selector<AudioProvider, bool>` solo para `isPlaying` â†’ solo el botÃ³n play/pause re-renderiza. |

---

## `lib/widgets/track_tile.dart`
**Ruta:** `lib/widgets/track_tile.dart`

Tile reutilizable para mostrar una pista en cualquier lista.

| Prop | Tipo | DescripciÃ³n |
|---|---|---|
| `song` | `SongModel` | Datos de la pista |
| `isPlaying` | `bool` | Si esta pista estÃ¡ sonando ahora |
| `onTap` | `VoidCallback` | AcciÃ³n al tocar el tile |
| `onMore` | `VoidCallback?` | AcciÃ³n del botÃ³n `â‹¯` |
| `trailingOverride` | `Widget?` | Reemplaza el `â‹¯` por un widget custom (usado para el drag handle en playlists) |

**Comportamiento visual:**
- Si `isPlaying`: fondo `surfaceContainerLow`, tÃ­tulo en `tertiary`, Ã­cono de ecualizador sobre la portada.
- Si no: fondo transparente, tÃ­tulo en `onSurface`.

---

## `lib/widgets/vinyl_record.dart`
**Ruta:** `lib/widgets/vinyl_record.dart`

Disco de vinilo animado que gira mientras se reproduce mÃºsica.

| Elemento | DescripciÃ³n |
|---|---|
| `_ctrl` | `AnimationController` de 8 segundos en loop continuo |
| `didChangeAppLifecycleState()` | Pausa el `AnimationController` cuando la app va al background. **El audio NO se interrumpe.** |
| `didUpdateWidget()` | Arranca o detiene la animaciÃ³n segÃºn `isPlaying`, pero solo si la app estÃ¡ en foreground. |
| `_buildDisc()` | Stack de 4 capas: halo de glow exterior, cuerpo negro con `SweepGradient`, portada del Ã¡lbum centrada (clip circular), punto negro central. |
| `_GroovesPainter` | `CustomPainter` que dibuja surcos concÃ©ntricos alternando colores blancos/negros cada 3.5px. `shouldRepaint â†’ false` (estÃ¡tico). |
| `glowColor` | Color dinÃ¡mico recibido del `PlayerScreen` (extraÃ­do con `PaletteGenerator`). |
| `size` | TamaÃ±o del disco en px, calculado por `LayoutBuilder` en el player para ser responsivo. |

---

## `lib/widgets/permission_screen.dart`
**Ruta:** `lib/widgets/permission_screen.dart`

Pantalla que se muestra si la app no tiene permisos de almacenamiento/audio.

> âš ï¸ El texto estÃ¡ en inglÃ©s ("Music Library Access", "Grant Permission"). Pendiente de traducir al espaÃ±ol para mantener consistencia con el resto de la UI.

Contiene un Ãºnico botÃ³n que llama a `library.requestPermissionAndLoad()`.

---

## Optimizaciones de Rendimiento y BaterÃ­a

| TÃ©cnica | DÃ³nde | Efecto |
|---|---|---|
| `TickerMode(enabled: _isForeground)` | `app.dart` | Detiene TODOS los `AnimationController` en background |
| `WidgetsBindingObserver` en `VinylRecord` | `vinyl_record.dart` | Pausa el giro del vinilo en background |
| `WidgetsBindingObserver` en `_PlayerContentState` | `player_screen.dart` | Pausa el fondo degradado animado en background |
| `Selector` en vez de `Consumer` | Mini player, Home, Player | Solo rebuilda el widget especÃ­fico que cambiÃ³ |
| `ValueListenableBuilder` para posiciÃ³n | Mini player, Player | La barra de progreso no usa el Ã¡rbol de Provider |
| `RepaintBoundary` en portadas | Todos los `QueryArtworkWidget` | Las imÃ¡genes no fuerzan repaints de sus vecinos |
| `itemExtent` fijo en listas | Library, Queue panel | Flutter no calcula tamaÃ±o de items â†’ scroll mÃ¡s rÃ¡pido |
| `keepOldArtwork: true` | Todos los `QueryArtworkWidget` | No parpadea al cambiar de canciÃ³n |
| Debounce de 700ms para guardar sesiÃ³n | `audio_provider.dart` | Evita escrituras en disco en cada frame de posiciÃ³n |
| `_scheduleSessionSave()` solo si hay canciÃ³n | `audio_provider.dart` | No escribe sesiÃ³n vacÃ­a innecesariamente |
| `onTaskRemoved()` condicional | `audio_handler.dart` | Solo detiene el servicio si el audio ya estaba pausado |

---

## Flujo de Datos Principal

```
Dispositivo
    â†“ on_audio_query
LibraryProvider (_songs, _albums, _artists)
    â†“ bindLibrary()
AudioProvider (_restoreSessionIfPossible)
    â†“ playSong()
ACARMusicHandler (setCurrentSong â†’ MediaItem â†’ NotificaciÃ³n)
    â†“ just_audio AudioPlayer
Speaker / Auriculares

NotificaciÃ³n Android / Pantalla de bloqueo / Auriculares Bluetooth
    â†“ skipToNext / skipToPrevious / play / pause
ACARMusicHandler (callbacks â†’ AudioProvider)
    â†“
AudioProvider (skipNext, skipPrevious, togglePlayPause)
```

---

## Notas de Pendientes Conocidos

| Ãtem | Archivo | DescripciÃ³n |
|---|---|---|
| `playlist_detail_screen.dart` | `lib/screens/` | Pantalla legacy; `getSongsFromPlaylist(int)` no existe en el provider actual. Reemplazar con `SongListScreen`. |
| GÃ©neros sin filtrado | `explore_screen.dart` | Las tarjetas de gÃ©neros son decorativas; no filtran canciones por gÃ©nero real. |
| Ecualizador | `settings_screen.dart` | Muestra mensaje de que requiere integraciÃ³n del sistema. No implementado. |
| Permisos en inglÃ©s | `permission_screen.dart` | Texto en inglÃ©s ("Grant Permission", "Music Library Access"). |
| Switch de tema | `settings_screen.dart` | El `Switch` de "Tema oscuro" tiene estado local pero no cambia el `ThemeMode` real de la app (siempre oscuro). |
| BotÃ³n `â‹®` en player | `player_screen.dart` | El `IconButton` de "MÃ¡s opciones" no hace nada aÃºn (`onPressed: () {}`). |

---

*DocumentaciÃ³n generada el 4 de mayo de 2026. Rama: `CarvaNew`. Dispositivo de prueba: Samsung S20 FE.*

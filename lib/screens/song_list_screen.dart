import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/track_tile.dart';
import '../widgets/mini_player.dart';

// ─── Modos de ordenación ──────────────────────────────────────────────────────
enum _SortMode { custom, az, recentlyAdded }

class SongListScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<SongModel> songs;
  final String? playlistId; // si es playlist editable (soporta reordenar)

  const SongListScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.songs,
    this.playlistId,
  });

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  _SortMode _sortMode = _SortMode.custom;
  late List<SongModel> _sorted;

  @override
  void initState() {
    super.initState();
    _sorted = List.from(widget.songs);
  }

  @override
  void didUpdateWidget(SongListScreen old) {
    super.didUpdateWidget(old);
    if (old.songs != widget.songs) {
      _sorted = List.from(widget.songs);
      _applySort();
    }
  }

  void _applySort() {
    setState(() {
      switch (_sortMode) {
        case _SortMode.az:
          _sorted.sort((a, b) => (a.title ?? '')
              .toLowerCase()
              .compareTo((b.title ?? '').toLowerCase()));
          break;
        case _SortMode.recentlyAdded:
          // index original = orden de adición
          _sorted = List.from(widget.songs);
          break;
        case _SortMode.custom:
          // respeta el orden guardado en widget.songs (que es el orden de songIds en CustomPlaylist)
          _sorted = List.from(widget.songs);
          break;
      }
    });
  }

  // ─── Drag & drop para "orden propio" ──────────────────────────────────────
  void _onReorder(int oldIndex, int newIndex, LibraryProvider library) {
    if (widget.playlistId == null) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final song = _sorted.removeAt(oldIndex);
      _sorted.insert(newIndex, song);
    });
    // Persistir nuevo orden
    library.reorderPlaylist(
        widget.playlistId!, _sorted.map((s) => s.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final library = context.read<LibraryProvider>();
    final isPlaylist = widget.playlistId != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      // ── MiniPlayer anclado en el fondo de esta pantalla ────────────────
      bottomNavigationBar: Selector<AudioProvider, int?>(
        selector: (_, a) => a.currentSong?.id,
        builder: (_, songId, __) {
          if (songId == null) return const SizedBox.shrink();
          return const MiniPlayer();
        },
      ),
      body: CustomScrollView(
        slivers: [
          // ── AppBar con portadas ──────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.background,
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppTheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.title,
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              background: _BackgroundArt(songs: widget.songs),
            ),
            actions: [
              if (_sorted.isNotEmpty)
                IconButton(
                  onPressed: () {
                    final rand =
                        DateTime.now().millisecondsSinceEpoch % _sorted.length;
                    audio.playSong(_sorted[rand], _sorted, rand);
                  },
                  icon: const Icon(Icons.shuffle_rounded,
                      color: AppTheme.primary, size: 26),
                ),
              if (_sorted.isNotEmpty)
                IconButton(
                  onPressed: () => audio.playSong(_sorted.first, _sorted, 0),
                  icon: const Icon(Icons.play_circle_rounded,
                      color: AppTheme.primary, size: 30),
                ),
              // Menú de ordenación
              _buildSortMenu(isPlaylist),
            ],
          ),

          // ── Barra: contador + modo de orden activo ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text(widget.subtitle ?? '${_sorted.length} canciones',
                      style: GoogleFonts.manrope(
                          color: AppTheme.onSurfaceVariant, fontSize: 13)),
                  const Spacer(),
                  // Chip del modo activo
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(99)),
                    child: Row(children: [
                      Icon(_sortIcon(_sortMode),
                          size: 12, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(_sortLabel(_sortMode),
                          style: GoogleFonts.manrope(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista / ReorderableList ───────────────────────────────────
          if (_sorted.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off_rounded,
                          color: AppTheme.outline, size: 64),
                      const SizedBox(height: 16),
                      Text('Esta lista está vacía',
                          style: GoogleFonts.manrope(
                              color: AppTheme.onSurfaceVariant, fontSize: 16)),
                    ]),
              ),
            )
          // Modo arrastrar (solo en playlists, solo en orden propio)
          else if (isPlaylist && _sortMode == _SortMode.custom)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 8),
              sliver: SliverReorderableList(
                itemCount: _sorted.length,
                onReorder: (o, n) => _onReorder(o, n, library),
                itemBuilder: (context, i) {
                  final song = _sorted[i];
                  // key en Material (no en el listener) para que el scroll funcione
                  // ReorderableDragStartListener SOLO en el ícono de handle
                  return Material(
                    key: ValueKey(song.id),
                    color: Colors.transparent,
                    child: Selector<AudioProvider, bool>(
                      selector: (_, a) => a.currentSong?.id == song.id,
                      builder: (context, isPlaying, _) => TrackTile(
                        song: song,
                        isPlaying: isPlaying,
                        onTap: () {
                          library.addToRecentlyPlayed(song);
                          library.incrementPlayCount(song.id);
                          audio.playSong(song, _sorted, i);
                        },
                        onMore: () => _showOptions(context, song, library),
                        trailingOverride:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              onPressed: () =>
                                  _showOptions(context, song, library),
                              icon: const Icon(Icons.more_horiz_rounded,
                                  color: AppTheme.onSurfaceVariant)),
                          // Solo el handle inicia el drag — el resto del tile scrollea normalmente
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.drag_handle_rounded,
                                  color: AppTheme.outline, size: 22),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            )
          // Lista normal (sin drag)
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = _sorted[i];
                  return Selector<AudioProvider, bool>(
                    selector: (_, a) => a.currentSong?.id == song.id,
                    builder: (context, isPlaying, _) => TrackTile(
                      song: song,
                      isPlaying: isPlaying,
                      onTap: () {
                        library.addToRecentlyPlayed(song);
                        library.incrementPlayCount(song.id);
                        audio.playSong(song, _sorted, i);
                      },
                      onMore: () => _showOptions(context, song, library),
                    ),
                  );
                },
                childCount: _sorted.length,
              ),
            ),

          // Espacio final (MiniPlayer ya está en bottomNavigationBar)
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  // ─── Menú de ordenación ──────────────────────────────────────────────────
  Widget _buildSortMenu(bool isPlaylist) {
    return PopupMenuButton<_SortMode>(
      icon: const Icon(Icons.sort_rounded, color: AppTheme.onSurface),
      color: AppTheme.surfaceContainerHigh,
      onSelected: (mode) {
        _sortMode = mode;
        _applySort();
      },
      itemBuilder: (_) => [
        if (isPlaylist)
          PopupMenuItem(
            value: _SortMode.custom,
            child: _SortOption(
                icon: Icons.drag_indicator_rounded,
                label: 'Orden propio',
                active: _sortMode == _SortMode.custom),
          ),
        PopupMenuItem(
          value: _SortMode.az,
          child: _SortOption(
              icon: Icons.sort_by_alpha_rounded,
              label: 'A — Z',
              active: _sortMode == _SortMode.az),
        ),
        PopupMenuItem(
          value: _SortMode.recentlyAdded,
          child: _SortOption(
              icon: Icons.new_releases_rounded,
              label: 'Recién añadidas',
              active: _sortMode == _SortMode.recentlyAdded),
        ),
      ],
    );
  }

  IconData _sortIcon(_SortMode m) => switch (m) {
        _SortMode.az => Icons.sort_by_alpha_rounded,
        _SortMode.recentlyAdded => Icons.new_releases_rounded,
        _SortMode.custom => Icons.drag_indicator_rounded,
      };

  String _sortLabel(_SortMode m) => switch (m) {
        _SortMode.az => 'A — Z',
        _SortMode.recentlyAdded => 'Recientes',
        _SortMode.custom => 'Mi orden',
      };

  void _showOptions(
      BuildContext context, SongModel song, LibraryProvider library) {
    final isFav = library.isFavorite(song);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : AppTheme.onSurface),
            title: Text(isFav ? 'Quitar de Favoritos' : 'Agregar a Favoritos',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            onTap: () {
              isFav
                  ? library.removeFromFavorites(song)
                  : library.addToFavorites(song);
              Navigator.pop(context);
            },
          ),
          if (widget.playlistId != null)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded,
                  color: Colors.redAccent),
              title: Text('Quitar de esta lista',
                  style: GoogleFonts.manrope(
                      color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () {
                library.removeSongFromPlaylist(widget.playlistId!, song.id);
                setState(() => _sorted.removeWhere((s) => s.id == song.id));
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Opción en el menú de sort ────────────────────────────────────────────────
class _SortOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _SortOption(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              color: active ? AppTheme.primary : AppTheme.onSurfaceVariant,
              size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.manrope(
                  color: active ? AppTheme.primary : AppTheme.onSurface,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          if (active) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, color: AppTheme.primary, size: 16),
          ],
        ],
      );
}

// ─── Fondo del AppBar: grid de portadas ───────────────────────────────────────
class _BackgroundArt extends StatelessWidget {
  final List<SongModel> songs;
  const _BackgroundArt({required this.songs});

  @override
  Widget build(BuildContext context) {
    final items = songs.take(4).toList();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (items.length == 1)
          RepaintBoundary(
            child: QueryArtworkWidget(
              id: items[0].id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              keepOldArtwork: true,
              nullArtworkWidget:
                  Container(color: AppTheme.surfaceContainerHigh),
            ),
          )
        else if (items.isNotEmpty)
          GridView.count(
            crossAxisCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: items
                .map((s) => RepaintBoundary(
                      child: QueryArtworkWidget(
                        id: s.id,
                        type: ArtworkType.AUDIO,
                        artworkFit: BoxFit.cover,
                        keepOldArtwork: true,
                        nullArtworkWidget:
                            Container(color: AppTheme.surfaceContainerHigh),
                      ),
                    ))
                .toList(),
          )
        else
          Container(
              color: AppTheme.surfaceContainerLow,
              child: const Icon(Icons.queue_music_rounded,
                  size: 80, color: AppTheme.primary)),
        // Degradado para legibilidad
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
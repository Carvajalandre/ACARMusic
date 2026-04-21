import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _tracksScrollCtrl = ScrollController();
  Map<String, int> _letterIndex = {};
  static const double _tileHeight = 72.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tracksScrollCtrl.dispose();
    super.dispose();
  }

  void _buildLetterIndex(List<SongModel> songs) {
    _letterIndex = {};
    for (int i = 0; i < songs.length; i++) {
      final raw = songs[i].title ?? '';
      final letter = raw.isEmpty ? '#' : raw[0].toUpperCase();
      final key = RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
      _letterIndex.putIfAbsent(key, () => i);
    }
  }

  void _scrollToLetter(String letter) {
    final idx = _letterIndex[letter];
    if (idx == null) return;
    _tracksScrollCtrl.animateTo(
      idx * _tileHeight,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    _buildLetterIndex(library.songs);

    return Scaffold(
      backgroundColor: AppTheme.background,
      // ✅ NestedScrollView: header colapsa al hacer scroll, tabs quedan fijos
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── SliverAppBar (título + botón Mezclar) ──────────────────
          SliverAppBar(
            backgroundColor: Colors.black,
            pinned: true,
            floating: false,
            expandedHeight: 70,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            // Cuando está colapsado solo muestra título pequeño
            title: AnimatedOpacity(
              opacity: innerBoxIsScrolled ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Text('Biblioteca',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            // Cuando está expandido muestra el título grande
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Biblioteca',
                          style: GoogleFonts.manrope(
                              color: AppTheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      const Spacer(),
                      if (library.songs.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            final songs = library.songs;
                            final rand = DateTime.now().millisecondsSinceEpoch %
                                songs.length;
                            context
                                .read<AudioProvider>()
                                .playSong(songs[rand], songs, rand);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(999)),
                            child: Row(children: [
                              const Icon(Icons.shuffle_rounded,
                                  color: AppTheme.onPrimary, size: 16),
                              const SizedBox(width: 6),
                              Text('Mezclar',
                                  style: GoogleFonts.manrope(
                                      color: AppTheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert_rounded,
                              color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── TabBar fija — siempre visible ──────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.onSurface,
                indicatorWeight: 2,
                labelColor: AppTheme.onSurface,
                unselectedLabelColor: AppTheme.outline,
                labelStyle: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
                unselectedLabelStyle: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: 'Pistas'),
                  Tab(text: 'Álbumes'),
                  Tab(text: 'Artistas'),
                  Tab(text: 'Carpetas'),
                ],
              ),
            ),
          ),
        ],
        body: library.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTracksTab(library),
                  _buildAlbumsTab(library),
                  _buildArtistsTab(library),
                  _buildFoldersTab(library),
                ],
              ),
      ),
    );
  }

  // ── Tab pistas con sidebar alfabético ─────────────────────────────────────
  Widget _buildTracksTab(LibraryProvider library) {
    final songs = library.songs;
    if (songs.isEmpty)
      return _buildEmpty(
          'No se encontraron canciones', Icons.music_off_rounded);

    final letters = [
      '#',
      ...List.generate(26, (i) => String.fromCharCode(65 + i))
    ];

    return Row(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _tracksScrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 180),
            itemCount: songs.length,
            itemExtent: _tileHeight,
            itemBuilder: (context, i) {
              final song = songs[i];
              return Selector<AudioProvider, bool>(
                selector: (_, a) => a.currentSong?.id == song.id,
                builder: (context, isPlaying, _) => TrackTile(
                  song: song,
                  isPlaying: isPlaying,
                  onTap: () {
                    library.addToRecentlyPlayed(song);
                    library.incrementPlayCount(song.id);
                    context.read<AudioProvider>().playSong(song, songs, i);
                  },
                  onMore: () => _showTrackOptions(context, song, library),
                ),
              );
            },
          ),
        ),
        // Sidebar alfabético
        Container(
          width: 22,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(builder: (_, c) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: letters.map((letter) {
                final enabled = _letterIndex.containsKey(letter);
                return GestureDetector(
                  onTap: enabled ? () => _scrollToLetter(letter) : null,
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppTheme.primary
                          : AppTheme.outline.withAlpha(60),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAlbumsTab(LibraryProvider library) {
    if (library.albums.isEmpty)
      return _buildEmpty('No se encontraron álbumes', Icons.album_rounded);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85),
      itemCount: library.albums.length,
      itemBuilder: (context, i) {
        final album = library.albums[i];
        return GestureDetector(
          onTap: () {
            final songs = library.getSongsByAlbum(album.id);
            if (songs.isNotEmpty)
              context.read<AudioProvider>().playSong(songs.first, songs, 0);
          },
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: RepaintBoundary(
                child: QueryArtworkWidget(
                  id: album.id,
                  type: ArtworkType.ALBUM,
                  artworkBorder: BorderRadius.circular(12),
                  artworkFit: BoxFit.cover,
                  artworkWidth: 200,
                  artworkHeight: 200,
                  keepOldArtwork: true,
                  nullArtworkWidget: Container(
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.album_rounded,
                        color: AppTheme.onSurfaceVariant, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(album.album ?? 'Álbum desconocido',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            Text(album.artist ?? 'Artista desconocido',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurfaceVariant, fontSize: 11)),
          ]),
        );
      },
    );
  }

  Widget _buildArtistsTab(LibraryProvider library) {
    if (library.artists.isEmpty)
      return _buildEmpty('No se encontraron artistas', Icons.person_rounded);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
      itemCount: library.artists.length,
      itemBuilder: (context, i) {
        final artist = library.artists[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.onSurfaceVariant),
          ),
          title: Text(artist.artist ?? 'Artista desconocido',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text('${artist.numberOfTracks ?? 0} canciones',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceVariant, fontSize: 12)),
          onTap: () {
            final songs = library.getSongsByArtist(artist.id);
            if (songs.isNotEmpty)
              context.read<AudioProvider>().playSong(songs.first, songs, 0);
          },
        );
      },
    );
  }

  Widget _buildFoldersTab(LibraryProvider library) {
    final Map<String, List<SongModel>> folders = {};
    for (final song in library.songs) {
      final path = song.data ?? '';
      final folder = path.contains('/')
          ? path.substring(0, path.lastIndexOf('/'))
          : 'Unknown';
      folders.putIfAbsent(folder.split('/').last, () => []).add(song);
    }
    if (folders.isEmpty)
      return _buildEmpty('No se encontraron carpetas', Icons.folder_rounded);
    final keys = folders.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final songs = folders[key]!;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder_rounded, color: AppTheme.primary),
          ),
          title: Text(key,
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text('${songs.length} canciones',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceVariant, fontSize: 12)),
          onTap: () =>
              context.read<AudioProvider>().playSong(songs.first, songs, 0),
        );
      },
    );
  }

  Widget _buildEmpty(String msg, IconData icon) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppTheme.outline, size: 64),
          const SizedBox(height: 16),
          Text(msg,
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceVariant, fontSize: 16)),
        ]),
      );

  void _showTrackOptions(
      BuildContext context, SongModel song, LibraryProvider library) {
    final isFav = library.isFavorite(song);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
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
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded,
                color: AppTheme.onSurface),
            title: Text('Agregar a Lista',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(context, library, song);
            },
          ),
        ]),
      ),
    );
  }

  void _showAddToPlaylistSheet(
      BuildContext context, LibraryProvider library, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Agregar a Lista',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Divider(height: 32),
          if (library.playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Crea primero una lista en la pestaña Listas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: library.playlists.length,
                itemBuilder: (context, i) {
                  final p = library.playlists[i];
                  return ListTile(
                    leading: const Icon(Icons.playlist_add_rounded,
                        color: AppTheme.primary),
                    title: Text(p.name,
                        style: GoogleFonts.manrope(color: AppTheme.onSurface)),
                    onTap: () {
                      library.addSongToPlaylist(p.id, song.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Agregado a ${p.name}')));
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Delegate para mantener el TabBar pegado debajo del SliverAppBar ──────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate old) =>
      old.tabBar != tabBar;
}

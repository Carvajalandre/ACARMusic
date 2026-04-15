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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final audio = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(library, audio),
            _buildTabBar(),
            Expanded(
              child: library.isLoading
                  ? _buildLoading()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTracksList(library, audio),
                        _buildAlbumsList(library, audio),
                        _buildArtistsList(library, audio),
                        _buildFoldersList(library, audio),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(LibraryProvider library, AudioProvider audio) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Library',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Shuffle all button
          if (library.songs.isNotEmpty)
            GestureDetector(
              onTap: () {
                final songs = library.songs;
                final rand =
                    DateTime.now().millisecondsSinceEpoch % songs.length;
                audio.playSong(songs[rand], songs, rand);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shuffle_rounded,
                        color: AppTheme.onPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Shuffle',
                      style: GoogleFonts.manrope(
                        color: AppTheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded,
                color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Tracks', 'Albums', 'Artists', 'Folders'];
    return Container(
      color: Colors.black,
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = _tabController.index == i;
            return GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: Container(
                margin: const EdgeInsets.only(right: 28),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppTheme.onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: GoogleFonts.manrope(
                    color: active ? AppTheme.onSurface : AppTheme.outline,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );

  Widget _buildTracksList(LibraryProvider library, AudioProvider audio) {
    if (library.songs.isEmpty) {
      return _buildEmpty('No songs found', Icons.music_off_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
      itemCount: library.songs.length,
      itemBuilder: (context, i) {
        final song = library.songs[i];
        final isPlaying = audio.currentSong?.id == song.id;
        return TrackTile(
          song: song,
          isPlaying: isPlaying,
          onTap: () {
            context.read<LibraryProvider>().addToRecentlyPlayed(song);
            audio.playSong(song, library.songs, i);
          },
          onMore: () => _showTrackOptions(context, song),
        );
      },
    );
  }

  Widget _buildAlbumsList(LibraryProvider library, AudioProvider audio) {
    if (library.albums.isEmpty) {
      return _buildEmpty('No albums found', Icons.album_rounded);
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: library.albums.length,
      itemBuilder: (context, i) {
        final album = library.albums[i];
        return _AlbumCard(
            album: album,
            onTap: () {
              final songs = library.getSongsByAlbum(album.id);
              if (songs.isNotEmpty) audio.playSong(songs.first, songs, 0);
            });
      },
    );
  }

  Widget _buildArtistsList(LibraryProvider library, AudioProvider audio) {
    if (library.artists.isEmpty) {
      return _buildEmpty('No artists found', Icons.person_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
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
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.onSurfaceVariant),
          ),
          title: Text(
            artist.artist ?? 'Unknown Artist',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${artist.numberOfTracks ?? 0} songs',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          onTap: () {
            if (artist.id == null) return;
            final songs = library.getSongsByArtist(artist.id!);
            if (songs.isNotEmpty) audio.playSong(songs.first, songs, 0);
          },
        );
      },
    );
  }

  Widget _buildFoldersList(LibraryProvider library, AudioProvider audio) {
    // Group songs by folder
    final Map<String, List<SongModel>> folders = {};
    for (final song in library.songs) {
      final path = song.data ?? '';
      final folder = path.contains('/')
          ? path.substring(0, path.lastIndexOf('/'))
          : 'Unknown';
      final name = folder.split('/').last;
      folders.putIfAbsent(name, () => []).add(song);
    }

    if (folders.isEmpty)
      return _buildEmpty('No folders found', Icons.folder_rounded);

    final keys = folders.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_rounded, color: AppTheme.primary),
          ),
          title: Text(
            key,
            style: GoogleFonts.manrope(
              color: AppTheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${songs.length} songs',
            style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant, fontSize: 12),
          ),
          onTap: () => audio.playSong(songs.first, songs, 0),
        );
      },
    );
  }

  Widget _buildEmpty(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.outline, size: 64),
            const SizedBox(height: 16),
            Text(msg,
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurfaceVariant, fontSize: 16)),
          ],
        ),
      );

  void _showTrackOptions(BuildContext context, SongModel song) {
    final library = context.read<LibraryProvider>();
    final isFav = library.isFavorite(song);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : AppTheme.onSurface,
              ),
              title: Text(
                isFav ? 'Remove from Favorites' : 'Add to Favorites',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                if (isFav) {
                  library.removeFromFavorites(song);
                } else {
                  library.addToFavorites(song);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: AppTheme.onSurface),
              title: Text(
                'Add to Playlist',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, library, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
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
          Text('Add to Playlist',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Divider(height: 32),
          if (library.playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No playlists found',
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
                    title: Text(p.playlist,
                        style: GoogleFonts.manrope(color: AppTheme.onSurface)),
                    onTap: () {
                      library.addToPlaylist(p.id, song.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to ${p.playlist}')),
                      );
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

class _AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final VoidCallback onTap;
  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RepaintBoundary(
              child: QueryArtworkWidget(
                id: album.id,
                type: ArtworkType.ALBUM,
                artworkBorder: BorderRadius.circular(12),
                artworkFit: BoxFit.cover,
                artworkWidth: 200,
                artworkHeight: 200,
                nullArtworkWidget: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.album_rounded,
                      color: AppTheme.onSurfaceVariant, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.album ?? 'Unknown Album',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppTheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            album.artist ?? 'Unknown Artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppTheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final audio = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, library)),
            SliverToBoxAdapter(child: _buildBentoGrid(library, audio, context)),
            SliverToBoxAdapter(child: _buildCollectionsHeader()),
            _buildCollections(library, audio),
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LibraryProvider library) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: AppTheme.primary, size: 20),
                onPressed: () => _showCreatePlaylistDialog(context, library),
              ),
            ),
          ],
        ),
      );

  Widget _buildBentoGrid(
      LibraryProvider library, AudioProvider audio, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Curated Essentials',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Bento grid — exactly like the HTML
          SizedBox(
            height: 380,
            child: Row(
              children: [
                // Left column — tall favorites card
                Expanded(
                  child: _BentoCard(
                    title: 'Favorites',
                    subtitle: '${library.favorites.length} tracks',
                    label: 'Core Collection',
                    icon: Icons.favorite_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D1B69), Color(0xFF0D0D0D)],
                    ),
                    onTap: () {
                      if (library.favorites.isNotEmpty) {
                        audio.playSong(
                            library.favorites.first, library.favorites, 0);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Right column — two stacked cards
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _BentoCard(
                          title: 'Recently\nPlayed',
                          subtitle: '',
                          label: '',
                          icon: Icons.play_circle_rounded,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A0A00), Color(0xFF3D1A00)],
                          ),
                          onTap: () {
                            if (library.recentlyPlayed.isNotEmpty) {
                              audio.playSong(library.recentlyPlayed.first,
                                  library.recentlyPlayed, 0);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _BentoCard(
                          title: 'All Songs',
                          subtitle: '${library.totalSongs} tracks',
                          label: 'Updated now',
                          icon: Icons.trending_up_rounded,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0A1628), Color(0xFF1B2C4D)],
                          ),
                          onTap: () {
                            if (library.songs.isNotEmpty) {
                              audio.playSong(
                                  library.songs.first, library.songs, 0);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Collections',
              style: GoogleFonts.manrope(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organized by your listening patterns',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );

  SliverList _buildCollections(LibraryProvider library, AudioProvider audio) {
    final List<_CollectionItem> collections = [
      _CollectionItem('Favorites', '${library.favorites.length} tracks',
          Icons.favorite_rounded,
          songs: library.favorites),
      _CollectionItem('Recently Played',
          '${library.recentlyPlayed.length} tracks', Icons.history_rounded,
          songs: library.recentlyPlayed),
      ...library.playlists.map((p) => _CollectionItem(
            p.playlist,
            '${p.numOfSongs} tracks',
            Icons.playlist_play_rounded,
            playlistId: p.id,
          )),
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final c = collections[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              hoverColor: Colors.white.withValues(alpha: 0.05),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.icon, color: AppTheme.primary),
              ),
              title: Text(
                c.title,
                style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                c.subtitle,
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurfaceVariant, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.onSurfaceVariant),
                onPressed: c.playlistId != null
                    ? () => _showPlaylistOptions(
                        ctx, library, c.playlistId!, c.title)
                    : null,
              ),
              onTap: () {
                if (c.songs != null && c.songs!.isNotEmpty) {
                  audio.playSong(c.songs!.first, c.songs!, 0);
                } else if (c.playlistId != null) {
                  _openPlaylist(ctx, library, c.playlistId!, c.title);
                }
              },
            ),
          );
        },
        childCount: collections.length,
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, LibraryProvider library) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: Text('New Playlist',
            style: GoogleFonts.manrope(color: AppTheme.onSurface)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.outline)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                library.createPlaylist(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('Create',
                style: GoogleFonts.manrope(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
      BuildContext context, LibraryProvider library, int id, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(name,
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
            title: Text('Rename Playlist',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(ctx);
              _showRenamePlaylistDialog(context, library, id, name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            title: Text('Delete Playlist',
                style: GoogleFonts.manrope(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              library.deletePlaylist(id);
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, LibraryProvider library,
      int id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: Text('Rename Playlist',
            style: GoogleFonts.manrope(color: AppTheme.onSurface)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.outline)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                library.renamePlaylist(id, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('Rename',
                style: GoogleFonts.manrope(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, LibraryProvider library, int id,
      String name) async {
    final songs = await library.getSongsFromPlaylist(id);
    if (context.mounted) {
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Playlist is empty')));
      } else {
        context.read<AudioProvider>().playSong(songs.first, songs, 0);
      }
    }
  }
}

class _CollectionItem {
  final String title, subtitle;
  final IconData icon;
  final List<SongModel>? songs;
  final int? playlistId;
  const _CollectionItem(this.title, this.subtitle, this.icon,
      {this.songs, this.playlistId});
}

class _BentoCard extends StatelessWidget {
  final String title, subtitle, label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _BentoCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child:
                  Icon(icon, color: Colors.white.withOpacity(0.07), size: 80),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (label.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(icon, color: AppTheme.primary, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            style: GoogleFonts.manrope(
                              color: AppTheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

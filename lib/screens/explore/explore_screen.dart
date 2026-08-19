import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../audio/audio_provider.dart';
import '../../library/library_provider.dart';
import '../../library/widgets/track_tile.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  final List<_Genre> _genres = const [
    _Genre('Electronic', Color(0xFF4338CA), Color(0xFF7C3AED),
        Icons.album_rounded),
    _Genre('Pop', Color(0xFFE11D48), Color(0xFFC2410C), Icons.star_rounded),
    _Genre('Techno', Color(0xFF065F46), Color(0xFF0F766E), Icons.bolt_rounded),
    _Genre(
        'Jazz', Color(0xFFB45309), Color(0xFF92400E), Icons.music_note_rounded),
    _Genre('Hip-Hop', Color(0xFF1D4ED8), Color(0xFF6D28D9),
        Icons.headphones_rounded),
    _Genre('Rock', Color(0xFF9F1239), Color(0xFF7C2D12),
        Icons.electric_bolt_rounded),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final audio = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar(library)),
            if (_isSearching && _searchCtrl.text.isNotEmpty)
              _buildSearchResults(library, audio)
            else ...[
              SliverToBoxAdapter(child: _buildRecentlyPlayed(library, audio)),
              SliverToBoxAdapter(child: _buildGenres()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Text('Explorar',
            style: GoogleFonts.manrope(
                color: AppTheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
      );

  Widget _buildSearchBar(LibraryProvider library) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.manrope(color: AppTheme.onSurface, fontSize: 15),
            onChanged: (v) {
              setState(() => _isSearching = true);
              library.search(v);
            },
            onTap: () => setState(() => _isSearching = true),
            decoration: InputDecoration(
              hintText: 'Artistas, canciones o álbumes',
              hintStyle: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.onSurfaceVariant),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.onSurfaceVariant),
                      onPressed: () {
                        _searchCtrl.clear();
                        library.clearSearch();
                        setState(() => _isSearching = false);
                        FocusScope.of(context).unfocus();
                      })
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      );

  SliverList _buildSearchResults(LibraryProvider library, AudioProvider audio) {
    final results = library.songs;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i >= results.length) return null;
          final song = results[i];
          return Selector<AudioProvider, bool>(
            selector: (_, a) => a.currentSong?.id == song.id,
            builder: (_, isPlaying, __) => TrackTile(
              song: song,
              isPlaying: isPlaying,
              onTap: () => audio.playSong(song, results, i),
            ),
          );
        },
        childCount: results.length,
      ),
    );
  }

  Widget _buildRecentlyPlayed(LibraryProvider library, AudioProvider audio) {
    final recent = library.recentlyPlayed;
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text('Escuchadas recientemente',
              style: GoogleFonts.manrope(
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recent.length,
            itemBuilder: (ctx, i) {
              final song = recent[i];
              return GestureDetector(
                onTap: () => audio.playSong(song, recent, i),
                child: Container(
                  width: 148,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 148,
                          height: 148,
                          child: RepaintBoundary(
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              artworkFit: BoxFit.cover,
                              artworkWidth: 148,
                              artworkHeight: 148,
                              keepOldArtwork: true,
                              nullArtworkWidget: Container(
                                color: AppTheme.surfaceContainerHigh,
                                child: const Center(
                                  child: Icon(Icons.music_note_rounded,
                                      color: AppTheme.onSurfaceVariant,
                                      size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(song.title ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                              color: AppTheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text(song.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                              color: AppTheme.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGenres() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Géneros',
                style: GoogleFonts.manrope(
                    color: AppTheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.9),
              itemCount: _genres.length,
              itemBuilder: (_, i) => _GenreCard(genre: _genres[i]),
            ),
          ),
        ],
      );
}

class _Genre {
  final String name;
  final Color from;
  final Color to;
  final IconData icon;
  const _Genre(this.name, this.from, this.to, this.icon);
}

class _GenreCard extends StatelessWidget {
  final _Genre genre;
  const _GenreCard({required this.genre});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [genre.from, genre.to]),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Text(genre.name.toUpperCase(),
                style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3)),
            Positioned(
                right: -8,
                bottom: -12,
                child: Icon(genre.icon,
                    color: Colors.white.withOpacity(0.1), size: 64)),
          ],
        ),
      ),
    );
  }
}

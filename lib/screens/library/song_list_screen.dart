import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../audio/audio_provider.dart';
import '../../library/library_provider.dart';
import '../../library/widgets/track_tile.dart';
import '../../widgets/mini_player.dart';

class ReorderableCustomDelayDragStartListener
    extends ReorderableDragStartListener {
  const ReorderableCustomDelayDragStartListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: const Duration(milliseconds: 400),
    );
  }
}

enum _SortMode { custom, az, recentlyAdded }

class SongListScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<SongModel> songs;
  final String? playlistId;

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
  final Random _random = Random();

  final ScrollController _scrollController = ScrollController();
  double _sidebarScrollOffset = 0;
  Map<String, int> _letterIndex = {};
  String? _activeLetter;
  bool _showLetterOverlay = false;
  final GlobalKey _sidebarKey = GlobalKey();
  static const double _tileHeight = TrackTile.itemExtent;
  static const double _kExpandedHeader = 200.0;
  static const double _kHeaderInfoHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onSidebarScroll);
    _sorted = List.from(widget.songs);
    if (widget.playlistId != null) {
      final provider = context.read<LibraryProvider>();
      final modeStr = provider.getPlaylistSortMode(widget.playlistId!);
      _sortMode = _SortMode.values
          .firstWhere((e) => e.name == modeStr, orElse: () => _SortMode.custom);
      _applySort();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onSidebarScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSidebarScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if ((offset - _sidebarScrollOffset).abs() > 0.5) {
      setState(() => _sidebarScrollOffset = offset);
    }
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
    final collapsedOffset = _kExpandedHeader - kToolbarHeight;
    final targetOffset =
        collapsedOffset + _kHeaderInfoHeight + (idx * _tileHeight);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _updateLetterFromGlobal(Offset globalPos) {
    final box = _sidebarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localY = box.globalToLocal(globalPos).dy.clamp(0.0, box.size.height);
    final letters = [
      '#',
      ...List.generate(26, (i) => String.fromCharCode(65 + i))
    ];
    final idx = (localY / box.size.height * letters.length)
        .clamp(0, letters.length - 1)
        .toInt();
    final letter = letters[idx];
    if (_activeLetter != letter) {
      setState(() => _activeLetter = letter);
      if (_letterIndex.containsKey(letter)) _scrollToLetter(letter);
    }
  }

  void _syncSorted() {
    if (widget.playlistId == null) return;
    final liveSongs =
        context.read<LibraryProvider>().getSongsForPlaylist(widget.playlistId!);
    final liveIds = liveSongs.map((s) => s.id).toList();
    final sortedIds = _sorted.map((s) => s.id).toList();
    if (listEquals(liveIds, sortedIds)) return;
    _sorted = List.from(liveSongs);
    switch (_sortMode) {
      case _SortMode.az:
        _sorted.sort((a, b) => (a.title ?? '')
            .toLowerCase()
            .compareTo((b.title ?? '').toLowerCase()));
        break;
      case _SortMode.recentlyAdded:
      case _SortMode.custom:
        break;
    }
  }

  void _applySort() {
    _syncSorted();
    setState(() {
      switch (_sortMode) {
        case _SortMode.az:
          _sorted.sort((a, b) => (a.title ?? '')
              .toLowerCase()
              .compareTo((b.title ?? '').toLowerCase()));
          break;
        case _SortMode.recentlyAdded:
        case _SortMode.custom:
          break;
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex, LibraryProvider library) {
    if (widget.playlistId == null) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final song = _sorted.removeAt(oldIndex);
      _sorted.insert(newIndex, song);
    });
    library.reorderPlaylist(
        widget.playlistId!, _sorted.map((s) => s.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isPlaylist = widget.playlistId != null;
    if (isPlaylist) context.watch<LibraryProvider>();

    _syncSorted();

    if (isPlaylist && _sortMode == _SortMode.az) {
      _buildLetterIndex(_sorted);
    }

    final letters = [
      '#',
      ...List.generate(26, (i) => String.fromCharCode(65 + i))
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: Selector<AudioProvider, int?>(
        selector: (_, a) => a.currentSong?.id,
        builder: (_, songId, __) {
          if (songId == null) return const SizedBox.shrink();
          return const MiniPlayer();
        },
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
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
                        final rand = _random.nextInt(_sorted.length);
                        context
                            .read<AudioProvider>()
                            .playSong(_sorted[rand], _sorted, rand);
                      },
                      icon: const Icon(Icons.shuffle_rounded,
                          color: AppTheme.primary, size: 26),
                    ),
                  if (_sorted.isNotEmpty)
                    IconButton(
                      onPressed: () => context
                          .read<AudioProvider>()
                          .playSong(_sorted.first, _sorted, 0),
                      icon: const Icon(Icons.play_circle_rounded,
                          color: AppTheme.primary, size: 30),
                    ),
                  _buildSortMenu(isPlaylist),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Text(widget.subtitle ?? '${_sorted.length} canciones',
                          style: GoogleFonts.manrope(
                              color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 16)),
                        ]),
                  ),
                )
              else if (isPlaylist && _sortMode == _SortMode.custom)
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 8),
                  sliver: SliverReorderableList(
                    itemCount: _sorted.length,
                    onReorder: (o, n) =>
                        _onReorder(o, n, context.read<LibraryProvider>()),
                    itemBuilder: (context, i) {
                      final song = _sorted[i];
                      return ReorderableCustomDelayDragStartListener(
                        key: ValueKey(song.id),
                        index: i,
                        child: Material(
                          color: Colors.transparent,
                          child: Selector<AudioProvider, bool>(
                            selector: (_, a) => a.currentSong?.id == song.id,
                            builder: (context, isPlaying, _) => TrackTile(
                              song: song,
                              isPlaying: isPlaying,
                              onTap: () {
                                context
                                    .read<LibraryProvider>()
                                    .addToRecentlyPlayed(song);
                                context
                                    .read<LibraryProvider>()
                                    .incrementPlayCount(song.id);
                                context
                                    .read<AudioProvider>()
                                    .playSong(song, _sorted, i);
                              },
                              onMore: () => _showOptions(context, song,
                                  context.read<LibraryProvider>()),
                              trailingOverride: IconButton(
                                onPressed: () => _showOptions(context, song,
                                    context.read<LibraryProvider>()),
                                icon: const Icon(Icons.more_horiz_rounded,
                                    color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
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
                            context
                                .read<LibraryProvider>()
                                .addToRecentlyPlayed(song);
                            context
                                .read<LibraryProvider>()
                                .incrementPlayCount(song.id);
                            context
                                .read<AudioProvider>()
                                .playSong(song, _sorted, i);
                          },
                          onMore: () => _showOptions(
                              context, song, context.read<LibraryProvider>()),
                        ),
                      );
                    },
                    childCount: _sorted.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          ),
          if (isPlaylist && _sortMode == _SortMode.az && _sorted.isNotEmpty)
            Positioned(
              right: 0,
              top: max(kToolbarHeight.toDouble(),
                      _kExpandedHeader - _sidebarScrollOffset) +
                  _kHeaderInfoHeight,
              bottom: 40,
              child: Listener(
                onPointerDown: (e) {
                  setState(() => _showLetterOverlay = true);
                  _updateLetterFromGlobal(e.position);
                },
                onPointerMove: (e) {
                  _updateLetterFromGlobal(e.position);
                },
                onPointerUp: (_) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        _showLetterOverlay = false;
                        _activeLetter = null;
                      });
                    }
                  });
                },
                onPointerCancel: (_) {
                  setState(() {
                    _showLetterOverlay = false;
                    _activeLetter = null;
                  });
                },
                child: Container(
                  key: _sidebarKey,
                  width: 36,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: letters.map((letter) {
                      final enabled = _letterIndex.containsKey(letter);
                      final isActive = _activeLetter == letter;
                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 80),
                        style: TextStyle(
                          fontSize: isActive ? 12 : 9,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.tertiary
                              : enabled
                                  ? AppTheme.primary
                                  : AppTheme.outline.withAlpha(60),
                        ),
                        child: Text(letter, textAlign: TextAlign.center),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          if (_showLetterOverlay && _activeLetter != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedScale(
                    scale: _showLetterOverlay ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh.withAlpha(220),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primary.withAlpha(60), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(100),
                            blurRadius: 24,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _activeLetter!,
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: _letterIndex.containsKey(_activeLetter)
                                ? AppTheme.tertiary
                                : AppTheme.outline,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortMenu(bool isPlaylist) {
    return PopupMenuButton<_SortMode>(
      icon: const Icon(Icons.sort_rounded, color: AppTheme.onSurface),
      color: AppTheme.surfaceContainerHigh,
      onSelected: (mode) {
        setState(() {
          _sortMode = mode;
          _applySort();
        });
        if (widget.playlistId != null) {
          context
              .read<LibraryProvider>()
              .setPlaylistSortMode(widget.playlistId!, mode.name);
        }
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

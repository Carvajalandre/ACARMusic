import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_playlist.dart';

class LibraryProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> _songs = [];
  List<SongModel> _recentlyAdded = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  List<SongModel> _filteredSongs = [];
  final List<SongModel> _favorites = [];
  List<SongModel> _recentlyPlayed = [];
  List<CustomPlaylist> _playlists = [];
  Map<int, int> _playCounts = {};

  bool _isLoading = false;
  bool _hasPermission = false;
  String _searchQuery = '';

  static const String _favoritesKey = 'favorites_ids';
  static const String _recentlyKey = 'recently_played_ids';
  static const String _playlistsKey = 'custom_playlists_v2';
  static const String _playCountsKey = 'play_counts';
  static const int _maxRecently = 50;

  List<SongModel> get songs => _searchQuery.isEmpty ? _songs : _filteredSongs;
  List<SongModel> get recentlyAdded => _recentlyAdded;
  List<AlbumModel> get albums => _albums;
  List<ArtistModel> get artists => _artists;
  List<SongModel> get favorites => _favorites;
  List<SongModel> get recentlyPlayed => _recentlyPlayed;
  List<CustomPlaylist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  int get totalSongs => _songs.length;

  List<SongModel> get mostPlayed {
    final sorted = [..._songs];
    sorted.sort(
        (a, b) => (_playCounts[b.id] ?? 0).compareTo(_playCounts[a.id] ?? 0));
    return sorted.where((s) => (_playCounts[s.id] ?? 0) > 0).take(50).toList();
  }

  LibraryProvider() {
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    _hasPermission = await _requestPermission();
    if (_hasPermission) await loadLibrary();
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    if (await Permission.audio.isGranted) return true;
    var status = await Permission.audio.request();
    if (status.isGranted) return true;
    status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> requestPermissionAndLoad() async {
    _hasPermission = await _requestPermission();
    if (_hasPermission) await loadLibrary();
    notifyListeners();
  }

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();
    try {
      final rawSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      _songs = rawSongs.where((s) {
        final path = (s.data ?? '').toLowerCase();
        final dur = s.duration ?? 0;
        return s.isMusic == true &&
            !path.contains('whatsapp') &&
            !path.contains('telegram') &&
            !path.contains('voice') &&
            !path.contains('audio-record') &&
            dur >= 10000;
      }).toList();

      // Recién añadidas (las 50 más nuevas por fecha de modificación)
      final byDate = [..._songs];
      byDate
          .sort((a, b) => (b.dateModified ?? 0).compareTo(a.dateModified ?? 0));
      _recentlyAdded = byDate.take(50).toList();

      _albums = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      _artists = await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      await _loadPersistedData();
    } catch (e) {
      debugPrint('Error cargando biblioteca: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Favoritos
      final favIds = prefs.getStringList(_favoritesKey) ?? [];
      _favorites.clear();
      for (final id in favIds) {
        final song = _songs.where((s) => s.id.toString() == id).firstOrNull;
        if (song != null) _favorites.add(song);
      }

      // Recientes
      final recentIds = prefs.getStringList(_recentlyKey) ?? [];
      _recentlyPlayed.clear();
      for (final id in recentIds) {
        final song = _songs.where((s) => s.id.toString() == id).firstOrNull;
        if (song != null) _recentlyPlayed.add(song);
      }

      // Playlists personalizadas
      final playlistsJson = prefs.getString(_playlistsKey);
      if (playlistsJson != null) {
        _playlists = CustomPlaylist.decodeList(playlistsJson);
      }

      // Conteo de reproducciones
      final playCountsJson = prefs.getString(_playCountsKey);
      if (playCountsJson != null) {
        final map = jsonDecode(playCountsJson) as Map<String, dynamic>;
        _playCounts = map.map((k, v) => MapEntry(int.parse(k), v as int));
      }
    } catch (e) {
      debugPrint('Error cargando datos persistidos: $e');
    }
  }

  // ── Búsqueda ──────────────────────────────────────────────────────────────
  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
    _filteredSongs = _searchQuery.isEmpty
        ? []
        : _songs
            .where((s) =>
                (s.title.toLowerCase().contains(_searchQuery) ?? false) ||
                (s.artist?.toLowerCase().contains(_searchQuery) ?? false) ||
                (s.album?.toLowerCase().contains(_searchQuery) ?? false))
            .toList();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSongs = [];
    notifyListeners();
  }

  // ── Favoritos ─────────────────────────────────────────────────────────────
  void addToFavorites(SongModel song) {
    if (!_favorites.any((s) => s.id == song.id)) {
      _favorites.add(song);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFromFavorites(SongModel song) {
    _favorites.removeWhere((s) => s.id == song.id);
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(SongModel song) => _favorites.any((s) => s.id == song.id);

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _favoritesKey, _favorites.map((s) => s.id.toString()).toList());
  }

  // ── Recientes ─────────────────────────────────────────────────────────────
  void addToRecentlyPlayed(SongModel song) {
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > _maxRecently) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, _maxRecently);
    }
    _saveRecentlyPlayed();
    notifyListeners();
  }

  Future<void> _saveRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _recentlyKey, _recentlyPlayed.map((s) => s.id.toString()).toList());
  }

  // ── Conteo de reproducciones ──────────────────────────────────────────────
  void incrementPlayCount(int songId) {
    _playCounts[songId] = (_playCounts[songId] ?? 0) + 1;
    _savePlayCounts();
    // No notifyListeners: es silencioso para no triggerar rebuilds frecuentes
  }

  Future<void> _savePlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _playCounts.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_playCountsKey, jsonEncode(map));
  }

  // ── Playlists personalizadas ───────────────────────────────────────────────
  Future<void> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _playlists.add(CustomPlaylist(id: id, name: name));
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final idx = _playlists.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _playlists[idx] = _playlists[idx].copyWith(name: newName);
      await _savePlaylists();
      notifyListeners();
    }
  }

  void addSongToPlaylist(String playlistId, int songId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx >= 0 && !_playlists[idx].songIds.contains(songId)) {
      _playlists[idx].songIds.add(songId);
      _savePlaylists();
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(String playlistId, int songId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx >= 0) {
      _playlists[idx].songIds.remove(songId);
      _savePlaylists();
      notifyListeners();
    }
  }

  /// Guarda el nuevo orden de canciones en una playlist (drag & drop)
  void reorderPlaylist(String playlistId, List<int> newOrder) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx >= 0) {
      _playlists[idx] = _playlists[idx].copyWith(songIds: newOrder);
      _savePlaylists();
      // No notifyListeners: la UI ya actualizó el estado local
    }
  }

  List<SongModel> getSongsForPlaylist(String playlistId) {
    final pl = _playlists.where((p) => p.id == playlistId).firstOrNull;
    if (pl == null) return [];
    // Mapa para O(1) lookup — devuelve en el orden exacto de songIds (respeta drag & drop)
    final songMap = {for (final s in _songs) s.id: s};
    return pl.songIds.map((id) => songMap[id]).whereType<SongModel>().toList();
  }

  Future<List<SongModel>> getSongsFromPlaylist(Object playlistId) async =>
      getSongsForPlaylist(playlistId.toString());

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playlistsKey, CustomPlaylist.encodeList(_playlists));
  }

  // ── Por álbum / artista ───────────────────────────────────────────────────
  List<SongModel> getSongsByAlbum(int albumId) =>
      _songs.where((s) => s.albumId == albumId).toList();

  List<SongModel> getSongsByArtist(int artistId) =>
      _songs.where((s) => s.artistId == artistId).toList();
}

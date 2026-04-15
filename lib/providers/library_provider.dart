import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  List<SongModel> _filteredSongs = [];
  final List<SongModel> _favorites = [];
  List<SongModel> _recentlyPlayed = [];
  List<PlaylistModel> _playlists = [];

  bool _isLoading = false;
  bool _hasPermission = false;
  String _searchQuery = '';

  static const String _favoritesKey = 'favorites_ids';
  static const String _recentlyKey = 'recently_played_ids';
  static const int _maxRecently = 50;

  List<SongModel> get songs => _searchQuery.isEmpty ? _songs : _filteredSongs;
  List<AlbumModel> get albums => _albums;
  List<ArtistModel> get artists => _artists;
  List<SongModel> get favorites => _favorites;
  List<SongModel> get recentlyPlayed => _recentlyPlayed;
  List<PlaylistModel> get playlists => _playlists;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  int get totalSongs => _songs.length;

  LibraryProvider() {
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    _hasPermission = await _requestPermission();
    if (_hasPermission) {
      await loadLibrary();
    }
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    // Android 13+ uses READ_MEDIA_AUDIO, older uses READ_EXTERNAL_STORAGE
    PermissionStatus status;
    if (await Permission.audio.isGranted) {
      return true;
    }
    status = await Permission.audio.request();
    if (status.isGranted) return true;

    // Fallback for older Android
    status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> requestPermissionAndLoad() async {
    _hasPermission = await _requestPermission();
    if (_hasPermission) {
      await loadLibrary();
    }
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
        final duration = s.duration ?? 0;
        final isWhatsApp = path.contains('whatsapp');
        final isTelegram = path.contains('telegram');
        final isVoice = path.contains('voice') || path.contains('audio-record');
        final isShort = duration < 10000;

        return s.isMusic == true &&
            !isWhatsApp &&
            !isTelegram &&
            !isVoice &&
            !isShort;
      }).toList();

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

      await loadPlaylists();
      await _loadPersistedData();
    } catch (e) {
      debugPrint('Error loading library: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final favIds = prefs.getStringList(_favoritesKey) ?? [];
      _favorites.clear();
      for (final id in favIds) {
        final song = _songs.where((s) => s.id.toString() == id).firstOrNull;
        if (song != null) _favorites.add(song);
      }

      final recentIds = prefs.getStringList(_recentlyKey) ?? [];
      _recentlyPlayed.clear();
      for (final id in recentIds) {
        final song = _songs.where((s) => s.id.toString() == id).firstOrNull;
        if (song != null) _recentlyPlayed.add(song);
      }
    } catch (e) {
      debugPrint('Error loading persisted data: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _favorites.map((s) => s.id.toString()).toList();
      await prefs.setStringList(_favoritesKey, ids);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _saveRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _recentlyPlayed.map((s) => s.id.toString()).toList();
      await prefs.setStringList(_recentlyKey, ids);
    } catch (e) {
      debugPrint('Error saving recently played: $e');
    }
  }

  Future<void> loadPlaylists() async {
    try {
      _playlists = await _audioQuery.queryPlaylists(
        sortType: PlaylistSortType.PLAYLIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      await _audioQuery.createPlaylist(name);
      await loadPlaylists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating playlist: $e');
    }
  }

  Future<void> deletePlaylist(int id) async {
    try {
      await _audioQuery.removePlaylist(id);
      await loadPlaylists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
    }
  }

  Future<void> renamePlaylist(int id, String newName) async {
    try {
      await _audioQuery.renamePlaylist(id, newName);
      await loadPlaylists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error renaming playlist: $e');
    }
  }

  Future<void> addToPlaylist(int playlistId, int songId) async {
    try {
      await _audioQuery.addToPlaylist(playlistId, songId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to playlist: $e');
    }
  }

  Future<List<SongModel>> getSongsFromPlaylist(int playlistId) async {
    try {
      return await _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
      );
    } catch (e) {
      debugPrint('Error getting songs from playlist: $e');
      return [];
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
    if (_searchQuery.isEmpty) {
      _filteredSongs = [];
    } else {
      _filteredSongs = _songs.where((s) {
        return (s.title?.toLowerCase().contains(_searchQuery) ?? false) ||
            (s.artist?.toLowerCase().contains(_searchQuery) ?? false) ||
            (s.album?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSongs = [];
    notifyListeners();
  }

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

  void addToRecentlyPlayed(SongModel song) {
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > _maxRecently) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, _maxRecently);
    }
    _saveRecentlyPlayed();
    notifyListeners();
  }

  List<SongModel> getSongsByAlbum(int albumId) =>
      _songs.where((s) => s.albumId == albumId).toList();

  List<SongModel> getSongsByArtist(int artistId) =>
      _songs.where((s) => s.artistId == artistId).toList();
}

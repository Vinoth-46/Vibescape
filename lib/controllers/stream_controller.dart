import 'package:flutter/foundation.dart';
import '../models/stream_song_model.dart';
import '../services/youtube_music_service.dart';
import '../services/cache_service.dart';


/// Controller for managing streaming songs
class StreamController extends ChangeNotifier {
  final YouTubeMusicService _youtubeService = YouTubeMusicService();
  final CacheService _cacheService = CacheService();

  List<StreamSongModel> _searchResults = [];
  List<StreamSongModel> _trendingSongs = [];
  List<StreamSongModel> _cachedSongs = [];
  
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  bool _isDownloading = false;
  String? _currentDownloadId;
  String _searchQuery = '';

  // Getters
  List<StreamSongModel> get searchResults => _searchResults;
  List<StreamSongModel> get trendingSongs => _trendingSongs;
  List<StreamSongModel> get cachedSongs => _cachedSongs;
  bool get isSearching => _isSearching;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isDownloading => _isDownloading;
  String? get currentDownloadId => _currentDownloadId;
  String get searchQuery => _searchQuery;
  YouTubeMusicService get youtubeService => _youtubeService;
  CacheService get cacheService => _cacheService;

  /// Initialize the controller
  Future<void> init() async {
    await _cacheService.init();
    await loadCachedSongs();
    await loadTrendingSongs();
  }

  /// Search for songs
  Future<void> searchSongs(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      _searchResults = await _youtubeService.searchSongs(query);
    } catch (e) {
      debugPrint('StreamController: Search error: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Load trending songs
  Future<void> loadTrendingSongs() async {
    _isLoadingTrending = true;
    notifyListeners();

    try {
      _trendingSongs = await _youtubeService.getTrendingMusic();
    } catch (e) {
      debugPrint('StreamController: Trending error: $e');
      _trendingSongs = [];
    }

    _isLoadingTrending = false;
    notifyListeners();
  }

  /// Load cached songs
  Future<void> loadCachedSongs() async {
    try {
      _cachedSongs = await _cacheService.getCachedSongs();
      notifyListeners();
    } catch (e) {
      debugPrint('StreamController: Load cached error: $e');
    }
  }

  /// Get stream URL for a song
  Future<String?> getStreamUrl(StreamSongModel song) async {
    // First check if it's cached
    if (_cacheService.isCached(song.id)) {
      return _cacheService.getCachedPath(song.id);
    }
    
    // Otherwise get the stream URL
    return await _youtubeService.getStreamUrl(song.id);
  }

  /// Download and cache a song
  Future<bool> downloadSong(StreamSongModel song) async {
    if (_isDownloading) return false;
    
    _isDownloading = true;
    _currentDownloadId = song.id;
    notifyListeners();

    try {
      final streamUrl = await _youtubeService.getStreamUrl(song.id);
      if (streamUrl == null) {
        _isDownloading = false;
        _currentDownloadId = null;
        notifyListeners();
        return false;
      }

      final cachedPath = await _cacheService.cacheSong(song, streamUrl);
      
      if (cachedPath != null) {
        await loadCachedSongs();
        _isDownloading = false;
        _currentDownloadId = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('StreamController: Download error: $e');
    }

    _isDownloading = false;
    _currentDownloadId = null;
    notifyListeners();
    return false;
  }

  /// Check if a song is cached
  bool isCached(String songId) {
    return _cacheService.isCached(songId);
  }

  /// Delete a cached song
  Future<void> deleteCachedSong(String songId) async {
    await _cacheService.deleteCachedSong(songId);
    await loadCachedSongs();
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _cacheService.clearCache();
    await loadCachedSongs();
  }

  /// Get cache size
  Future<String> getCacheSizeFormatted() async {
    final size = await _cacheService.getCacheSize();
    return _cacheService.formatCacheSize(size);
  }

  /// Set streaming quality
  void setStreamingQuality(StreamingQuality quality) {
    _youtubeService.setQuality(quality);
    notifyListeners();
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}

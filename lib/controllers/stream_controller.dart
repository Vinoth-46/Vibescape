import 'package:flutter/foundation.dart';
import '../models/stream_song_model.dart';
import '../services/youtube_music_service.dart';
import '../services/jiosaavn_music_service.dart';
import '../services/gaana_music_service.dart';
import '../models/stream_song_model.dart';
import '../services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';


/// Controller for managing streaming songs
class StreamController extends ChangeNotifier {
  final YouTubeMusicService _youtubeService = YouTubeMusicService();
  final JioSaavnMusicService _jiosaavnService = JioSaavnMusicService();
  final GaanaMusicService _gaanaService = GaanaMusicService();
  final CacheService _cacheService = CacheService();

  List<StreamSongModel> _searchResults = [];
  List<StreamSongModel> _trendingSongs = [];
  List<StreamSongModel> _newReleases = [];
  List<StreamSongModel> _topCharts = [];
  List<StreamSongModel> _cachedSongs = [];
  
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  bool _isDownloading = false;
  String? _currentDownloadId;
  String _searchQuery = '';
  String _selectedLanguage = 'hindi';

  // Getters
  List<StreamSongModel> get searchResults => _searchResults;
  List<StreamSongModel> get trendingSongs => _trendingSongs;
  List<StreamSongModel> get newReleases => _newReleases;
  List<StreamSongModel> get topCharts => _topCharts;
  List<StreamSongModel> get cachedSongs => _cachedSongs;
  bool get isSearching => _isSearching;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isDownloading => _isDownloading;
  String? get currentDownloadId => _currentDownloadId;
  String get searchQuery => _searchQuery;
  YouTubeMusicService get youtubeService => _youtubeService;
  JioSaavnMusicService get jiosaavnService => _jiosaavnService;
  CacheService get cacheService => _cacheService;
  String get selectedLanguage => _selectedLanguage;

  /// Initialize the controller
  Future<void> init() async {
    await _cacheService.init();
    
    // Load language preference
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString('explore_language') ?? 'hindi';
    
    await loadCachedSongs();
    await loadTrendingSongs();
  }

  /// Change explore language and reload
  Future<void> setLanguage(String language) async {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('explore_language', language);
    
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
      final saavnSongs = await _jiosaavnService.searchSongs(query);
      
      if (saavnSongs.isNotEmpty) {
        _searchResults = saavnSongs;
      } else {
        debugPrint('StreamController: JioSaavn returned empty, falling back to YouTube');
        _searchResults = await _youtubeService.searchSongs(query);
      }
    } catch (e) {
      debugPrint('StreamController: Search error: $e');
      // If JioSaavn crashes entirely, try YouTube
       _searchResults = await _youtubeService.searchSongs(query);
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Load trending songs
  Future<void> loadTrendingSongs() async {
    _isLoadingTrending = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _fetchCombined('latest trending $_selectedLanguage songs'),
        _fetchCombined('latest $_selectedLanguage hits 2024'),
        _fetchCombined('top 50 $_selectedLanguage songs'),
      ]);
      
      _trendingSongs = futures[0];
      _newReleases = futures[1];
      _topCharts = futures[2];
    } catch (e) {
      debugPrint('StreamController: Trending error: $e');
      _trendingSongs = [];
      _newReleases = [];
      _topCharts = [];
    }

    _isLoadingTrending = false;
    notifyListeners();
  }

  Future<List<StreamSongModel>> _fetchCombined(String query) async {
      try {
        final futures = await Future.wait([
            _jiosaavnService.searchSongs(query),
            _gaanaService.searchSongs(query),
        ]);
        
        final saavnSongs = futures[0];
        final gaanaSongs = futures[1];
        
        // Interleave the arrays directly to keep variety high (e.g. [Saavn 1, Gaana 1, Saavn 2, Gaana 2...])
        // And shuffle the result to guarantee the Explore page feels physically fresh every single launch!
        List<StreamSongModel> combined = [];
        final maxLength = [saavnSongs.length, gaanaSongs.length].reduce(max);
        
        for (int i = 0; i < maxLength; i++) {
           if (i < saavnSongs.length) combined.add(saavnSongs[i]);
           if (i < gaanaSongs.length) combined.add(gaanaSongs[i]);
        }
        
        if (combined.isNotEmpty) {
           combined.shuffle(); // Prevent repetition!
           return combined;
        }
        
        debugPrint('StreamController: Dual-fetch trending returned empty, falling back to YouTube');
        return await _youtubeService.searchSongs(query);
      } catch (e) {
        debugPrint('StreamController: Fetch combined error: $e');
        return await _youtubeService.searchSongs(query);
      }
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
    
    // Otherwise get the stream URL based on source
    try {
      String? streamUrl;
      if (song.source == 'gaana') {
        streamUrl = await _gaanaService.getStreamUrl(song.id);
      } else if (song.source == 'jiosaavn') {
        streamUrl = await _jiosaavnService.getStreamUrl(song.id);
      } else {
        streamUrl = await _youtubeService.getStreamUrl(song.id);
      }
      
      // Fallback: If JioSaavn failed or empty, try formatting a youtube search query to find it
      if (streamUrl == null && song.source == 'jiosaavn') {
         debugPrint('StreamController: JioSaavn stream failed, falling back to YouTube for: ${song.title}');
         final ytResults = await _youtubeService.searchSongs('${song.title} ${song.artist}');
         if (ytResults.isNotEmpty) {
            streamUrl = await _youtubeService.getStreamUrl(ytResults.first.id);
         }
      }
      
      return streamUrl;
    } catch (e) {
      debugPrint('StreamController: getStreamUrl error: $e');
      return null;
    }
  }

  /// Download and cache a song
  Future<bool> downloadSong(StreamSongModel song) async {
    if (_isDownloading) return false;
    
    _isDownloading = true;
    _currentDownloadId = song.id;
    notifyListeners();

    try {
      String? streamUrl;
      if (song.source == 'jiosaavn') {
        streamUrl = await _jiosaavnService.getStreamUrl(song.id);
      } else {
        streamUrl = await _youtubeService.getStreamUrl(song.id);
      }
      
      if (streamUrl == null && song.source == 'jiosaavn') {
         final ytResults = await _youtubeService.searchSongs('${song.title} ${song.artist}');
         if (ytResults.isNotEmpty) {
            streamUrl = await _youtubeService.getStreamUrl(ytResults.first.id);
         }
      }
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
    _jiosaavnService.setQuality(quality);
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

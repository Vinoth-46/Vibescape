import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../models/stream_song_model.dart';

/// Service for caching streamed songs for offline playback
class CacheService {
  static const String _metadataBoxName = 'song_metadata';
  
  Box<Map>? _metadataBox;
  String? _cacheDir;

  /// Initialize the cache service
  Future<void> init() async {
    await Hive.initFlutter();
    
    _metadataBox = await Hive.openBox<Map>(_metadataBoxName);
    
    if (kIsWeb) {
      debugPrint('CacheService: Caching not supported on web');
      return;
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = p.join(appDir.path, 'music_cache');
    
    // Create cache directory if it doesn't exist
    final cacheDirectory = Directory(_cacheDir!);
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    
    debugPrint('CacheService: Initialized at $_cacheDir');
  }

  /// Cache a song from a stream URL
  Future<String?> cacheSong(StreamSongModel song, String streamUrl) async {
    if (kIsWeb) return null;
    if (_cacheDir == null) await init();
    if (_cacheDir == null) return null;
    
    try {
      final filePath = p.join(_cacheDir!, '${song.id}.m4a');
      final file = File(filePath);
      
      // Download the audio file
      debugPrint('CacheService: Downloading ${song.title}...');
      final response = await http.get(Uri.parse(streamUrl));
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        // Save metadata
        await _metadataBox?.put(song.id, {
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
          'thumbnailUrl': song.thumbnailUrl,
          'duration': song.duration.inMilliseconds,
          'cachedPath': filePath,
          'cachedAt': DateTime.now().toIso8601String(),
        });
        
        debugPrint('CacheService: Cached ${song.title} at $filePath');
        return filePath;
      } else {
        debugPrint('CacheService: Failed to download - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('CacheService: Cache error: $e');
      return null;
    }
  }

  /// Check if a song is cached
  bool isCached(String songId) {
    if (kIsWeb) return false;
    final metadata = _metadataBox?.get(songId);
    if (metadata == null) return false;
    
    final cachedPath = metadata['cachedPath'] as String?;
    if (cachedPath == null) return false;
    
    return File(cachedPath).existsSync();
  }

  /// Get cached file path for a song
  String? getCachedPath(String songId) {
    if (kIsWeb) return null;
    final metadata = _metadataBox?.get(songId);
    if (metadata == null) return null;
    
    final cachedPath = metadata['cachedPath'] as String?;
    if (cachedPath == null) return null;
    
    if (File(cachedPath).existsSync()) {
      return cachedPath;
    }
    return null;
  }

  /// Get all cached songs
  Future<List<StreamSongModel>> getCachedSongs() async {
    if (kIsWeb) return [];
    if (_metadataBox == null) await init();
    
    final songs = <StreamSongModel>[];
    
    for (final key in _metadataBox?.keys ?? []) {
      final metadata = _metadataBox?.get(key);
      if (metadata == null) continue;
      
      final cachedPath = metadata['cachedPath'] as String?;
      if (cachedPath == null || !File(cachedPath).existsSync()) continue;
      
      songs.add(StreamSongModel(
        id: metadata['id'] as String,
        title: metadata['title'] as String,
        artist: metadata['artist'] as String,
        album: metadata['album'] as String?,
        thumbnailUrl: metadata['thumbnailUrl'] as String?,
        duration: Duration(milliseconds: metadata['duration'] as int),
        isLocal: false,
        cachedPath: cachedPath,
        cachedAt: DateTime.parse(metadata['cachedAt'] as String),
      ));
    }
    
    // Sort by cached date (most recent first)
    songs.sort((a, b) => (b.cachedAt ?? DateTime(0)).compareTo(a.cachedAt ?? DateTime(0)));
    
    return songs;
  }

  /// Delete a cached song
  Future<void> deleteCachedSong(String songId) async {
    if (kIsWeb) return;
    final metadata = _metadataBox?.get(songId);
    if (metadata == null) return;
    
    final cachedPath = metadata['cachedPath'] as String?;
    if (cachedPath != null) {
      final file = File(cachedPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    await _metadataBox?.delete(songId);
    debugPrint('CacheService: Deleted cached song $songId');
  }

  /// Clear all cached songs
  Future<void> clearCache() async {
    if (kIsWeb) return;
    if (_cacheDir == null) await init();
    if (_cacheDir == null) return;
    
    final cacheDirectory = Directory(_cacheDir!);
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
      await cacheDirectory.create(recursive: true);
    }
    
    await _metadataBox?.clear();
    debugPrint('CacheService: Cache cleared');
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    if (kIsWeb) return 0;
    if (_cacheDir == null) await init();
    if (_cacheDir == null) return 0;
    
    int totalSize = 0;
    final cacheDirectory = Directory(_cacheDir!);
    
    if (await cacheDirectory.exists()) {
      await for (final file in cacheDirectory.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }
    
    return totalSize;
  }

  /// Format cache size for display
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

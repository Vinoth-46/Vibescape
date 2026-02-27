import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/stream_song_model.dart';
import 'youtube_music_service.dart'; // For StreamingQuality

class JioSaavnMusicService {
  static const String baseUrl = 'https://saavn.sumit.co/api';
  StreamingQuality _preferredQuality = StreamingQuality.high;

  void setQuality(StreamingQuality quality) {
    _preferredQuality = quality;
  }

  StreamingQuality get quality => _preferredQuality;

  /// Search for songs on JioSaavn
  Future<List<StreamSongModel>> searchSongs(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/songs?query=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final results = data['data']['results'] as List<dynamic>? ?? [];
          return results.map((song) => _parseSong(song)).whereType<StreamSongModel>().toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('JioSaavnMusicService: Search error: $e');
      return [];
    }
  }

  /// Get trending/popular music
  Future<List<StreamSongModel>> getTrendingMusic() async {
    try {
      // The saavn API doesn't have a direct "trending" endpoint in V4 readily evident,
      // so we use a popular search term to fetch default popular results, or search for "latest hits".
      final response = await http.get(
        Uri.parse('$baseUrl/search/songs?query=latest+hits'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final results = data['data']['results'] as List<dynamic>? ?? [];
          return results.map((song) => _parseSong(song)).whereType<StreamSongModel>().toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('JioSaavnMusicService: Trending error: $e');
      return [];
    }
  }

  /// Get recommended/similar music based on a song ID (For Auto-Radio Queue)
  Future<List<StreamSongModel>> getSimilarSongs(String songId) async {
    try {
      final response = await http.get(
        // API v4 uses /songs/{id}/suggestions for recommended songs
        Uri.parse('$baseUrl/songs/$songId/suggestions'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final results = data['data'] as List<dynamic>? ?? [];
          return results.map((song) => _parseSong(song)).whereType<StreamSongModel>().toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('JioSaavnMusicService: Auto-Radio recommendations error: $e');
      return [];
    }
  }

  /// Get the direct audio stream URL for a song
  Future<String?> getStreamUrl(String songId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/songs/$songId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null && data['data'].isNotEmpty) {
          final songData = data['data'][0];
          final downloadUrls = songData['downloadUrl'] as List<dynamic>? ?? [];
          if (downloadUrls.isEmpty) return null;

          return _selectStreamByQuality(downloadUrls);
        }
      }
      return null;
    } catch (e) {
      debugPrint('JioSaavnMusicService: Stream URL error: $e');
      return null;
    }
  }

  /// Parse individual song JSON into StreamSongModel
  StreamSongModel? _parseSong(Map<String, dynamic> song) {
    try {
      final id = song['id']?.toString() ?? '';
      final title = _unescapeHtml(song['name']?.toString() ?? 'Unknown Title');
      
      // Parse artists
      String artist = 'Unknown Artist';
      if (song['artists'] != null && song['artists']['primary'] != null) {
        final primaryArtists = song['artists']['primary'] as List<dynamic>;
        if (primaryArtists.isNotEmpty) {
          artist = _unescapeHtml(primaryArtists.map((a) => a['name']).join(', '));
        }
      } else if (song['primaryArtists'] != null) {
         artist = _unescapeHtml(song['primaryArtists'].toString());
      }

      // Parse image
      String? thumbnailUrl;
      final images = song['image'] as List<dynamic>? ?? [];
      if (images.isNotEmpty) {
        // Find highest quality image, usually 500x500
        final sortedImages = List.from(images)..sort((a, b) {
          final qualityA = a['quality']?.toString() ?? '';
          final qualityB = b['quality']?.toString() ?? '';
          return qualityB.compareTo(qualityA); // simple descending sort for 500x500 vs 150x150
        });
        thumbnailUrl = sortedImages.first['url']?.toString();
      }

      // Parse duration
      final durationSeconds = int.tryParse(song['duration']?.toString() ?? '0') ?? 0;

      // We don't populate downloadUrl here directly unless caching, getStreamUrl will fetch it fresh.
      // But we can store it temporarily if the API provides it in search results to avoid a second call.
      // The API often includes `downloadUrl` in search results.
      
      return StreamSongModel.fromJioSaavn(
        songId: id,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        duration: Duration(seconds: durationSeconds),
      );
    } catch (e) {
      debugPrint('JioSaavnMusicService: Parse song error: $e');
      return null;
    }
  }

  /// Select the appropriate stream based on preferred quality settings
  String? _selectStreamByQuality(List<dynamic> urls) {
    if (urls.isEmpty) return null;

    final targetKbps = switch (_preferredQuality) {
      StreamingQuality.low => 48, // JioSaavn has 12, 48, 96, 160, 320
      StreamingQuality.normal => 96,
      StreamingQuality.high => 160,
      StreamingQuality.best => 320,
    };

    dynamic selectedUrl;
    int minDiff = 100000;

    for (final urlObj in urls) {
      final qualityStr = urlObj['quality']?.toString().replaceAll('kbps', '') ?? '0';
      final kbps = int.tryParse(qualityStr) ?? 0;
      
      final diff = (kbps - targetKbps).abs();
      if (diff < minDiff) {
        minDiff = diff;
        selectedUrl = urlObj;
      }
    }

    return selectedUrl != null ? selectedUrl['url']?.toString() : urls.first['url']?.toString();
  }

  String _unescapeHtml(String text) {
    return text.replaceAll('&amp;', '&')
               .replaceAll('&quot;', '"')
               .replaceAll('&#039;', "'")
               .replaceAll('&#39;', "'")
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>');
  }
}

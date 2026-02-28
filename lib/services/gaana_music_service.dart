import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/stream_song_model.dart';
import 'dart:math';

class GaanaMusicService {
  final String baseUrl = 'https://gaana-music-api.vercel.app/api';

  /// Search for songs and map to StreamSongModel
  Future<List<StreamSongModel>> searchSongs(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('$baseUrl/search?q=$encodedQuery&type=song'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final songsData = data['data']['songs'] as List<dynamic>? ?? [];
          final songs = songsData
              .map((song) => _parseSong(song))
              .where((song) => song != null)
              .cast<StreamSongModel>()
              .toList();
          return songs;
        }
      }
      return [];
    } catch (e) {
      debugPrint('GaanaMusicService: Search error: $e');
      return [];
    }
  }

  /// Get Trending Music 
  Future<List<StreamSongModel>> getTrendingMusic() async {
      // The wrapper doesn't have a direct 'trending' endpoint, so we simulate it 
      // by searching for popular generic keywords and shuffling the results
      final List<String> buzzwords = ['latest', 'hits', 'trending', 'top', 'new', 'dj'];
      final word = buzzwords[Random().nextInt(buzzwords.length)];
      
      final results = await searchSongs(word);
      return results;
  }

  /// Get Stream URL 
  Future<String?> getStreamUrl(String songId) async {
    // Due to DRM, direct MP4 scraping from the unofficial API might fail inside the player.
    // For now, returning the raw API decrypt endpoint, but we will fallback to 
    // YouTube scraping in the stream_controller if this returns null or breaks in ExoPlayer.
    try {
        debugPrint("GaanaMusicService: Getting stream URL for $songId");
        final uri = Uri.parse('$baseUrl/songs/$songId/stream');
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
            return uri.toString(); // Just hand the player the stream redirect
        } else {
            return null;
        }
    } catch (e) {
      debugPrint('GaanaMusicService: Stream URL error: $e');
      return null;
    }
  }

  /// Parse individual song JSON into StreamSongModel
  StreamSongModel? _parseSong(Map<String, dynamic> song) {
    try {
      final id = song['id']?.toString() ?? '';
      if (id.isEmpty) return null;
      
      final title = _unescapeHtml(song['title']?.toString() ?? 'Unknown Title');
      
      final artistsList = song['artists'] as List<dynamic>? ?? [];
      String artist = 'Unknown Artist';
      if (artistsList.isNotEmpty) {
          artist = artistsList.map((a) => a['name']).join(', ');
      }
      
      String thumbnailUrl = song['artworkUrl']?.toString() ?? '';
      if (thumbnailUrl.isEmpty) {
          thumbnailUrl = song['image']?.toString() ?? '';
      }
      // Upscale 150x150 to 500x500
      thumbnailUrl = thumbnailUrl.replaceAll('150x150', '500x500');

      final durationSeconds = int.tryParse(song['duration']?.toString() ?? '0') ?? 0;

      return StreamSongModel(
        id: id,
        title: title,
        artist: artist,
        album: song['album']?.toString(),
        thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
        duration: Duration(seconds: durationSeconds),
        isLocal: false,
        source: 'gaana', // Tag as gaana
      );
    } catch (e) {
      debugPrint('GaanaMusicService: Parse error: $e');
      return null;
    }
  }

  String _unescapeHtml(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}

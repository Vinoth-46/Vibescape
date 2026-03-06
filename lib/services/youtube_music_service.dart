import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/stream_song_model.dart';

/// Quality levels for streaming based on network conditions
enum StreamingQuality {
  low,    // 64 kbps - for 2G
  normal, // 128 kbps - for 3G
  high,   // 192 kbps - for 4G
  best,   // 256+ kbps - for 5G/WiFi
}

/// Service for interacting with YouTube Music
class YouTubeMusicService {
  final YoutubeExplode _yt = YoutubeExplode();
  StreamingQuality _preferredQuality = StreamingQuality.high;
  static const String _youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
  
  /// Set preferred streaming quality
  void setQuality(StreamingQuality quality) {
    _preferredQuality = quality;
  }

  /// Get current streaming quality
  StreamingQuality get quality => _preferredQuality;

  /// Search for songs on YouTube using Data API v3
  Future<List<StreamSongModel>> searchSongs(String query) async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=${Uri.encodeComponent(query)}&type=video&key=$_youtubeApiKey&maxResults=20&videoCategoryId=10')).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List<dynamic>? ?? [];

        final songs = <StreamSongModel>[];
        for (final item in items) {
          final snippet = item['snippet'];
          String title = snippet['title']?.toString() ?? '';
          title = _unescapeHtml(title);
          String artist = snippet['channelTitle']?.toString() ?? '';
          artist = _unescapeHtml(artist);
          
          songs.add(StreamSongModel.fromYouTube(
            videoId: item['id']['videoId'],
            title: title,
            artist: snippet['channelTitle'] ?? '',
            thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? snippet['thumbnails']?['default']?['url'],
            duration: Duration.zero, // Fast search doesn't return duration, default to zero
          ));
        }
        return songs;
      } else {
        debugPrint('YouTubeMusicService: API search failed with ${response.statusCode}, falling back to scraping.');
      }
    } catch (e) {
      debugPrint('YouTubeMusicService: API Search error: $e');
    }

    // Fallback to youtube_explode if API returns error
    try {
      final searchResults = await _yt.search.search('$query music').timeout(const Duration(seconds: 10));
      final songs = <StreamSongModel>[];
      for (final video in searchResults.take(20)) {
        songs.add(StreamSongModel.fromYouTube(
          videoId: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.highResUrl,
          duration: video.duration ?? Duration.zero,
        ));
      }
      return songs;
    } catch (e) {
      debugPrint('YouTubeMusicService: Scraping search error: $e');
      return [];
    }
  }

  /// Get trending music videos using Data API v3
  Future<List<StreamSongModel>> getTrendingMusic() async {
    try {
      // Use YouTube API for popular music videos in US or IN
      final response = await http.get(Uri.parse(
          'https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&chart=mostPopular&regionCode=IN&videoCategoryId=10&key=$_youtubeApiKey&maxResults=15')).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List<dynamic>? ?? [];

        final songs = <StreamSongModel>[];
        for (final item in items) {
          final snippet = item['snippet'];
          
          // Parse duration (ISO 8601 format like PT1M45S)
          Duration parsedDuration = Duration.zero;
          try {
            final durationStr = item['contentDetails']?['duration'] as String?;
            if (durationStr != null) {
              parsedDuration = _parseIsoDuration(durationStr);
            }
          } catch (_) {}

          songs.add(StreamSongModel.fromYouTube(
            videoId: item['id'],
            title: _unescapeHtml(snippet['title']?.toString() ?? ''),
            artist: _unescapeHtml(snippet['channelTitle']?.toString() ?? ''),
            thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? snippet['thumbnails']?['default']?['url'],
            duration: parsedDuration,
          ));
        }
        return songs;
      }
    } catch (e) {
      debugPrint('YouTubeMusicService: API Trending error: $e');
    }

    // Fallback to youtube_explode
    try {
      final searchResults = await _yt.search.search('trending music 2024').timeout(const Duration(seconds: 10));
      final songs = <StreamSongModel>[];
      for (final video in searchResults.take(15)) {
        songs.add(StreamSongModel.fromYouTube(
          videoId: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.highResUrl,
          duration: video.duration ?? Duration.zero,
        ));
      }
      return songs;
    } catch (e) {
      debugPrint('YouTubeMusicService: Scraping Trending error: $e');
      return [];
    }
  }

  /// Parse YouTube ISO 8601 duration (PT#M#S) into Duration
  Duration _parseIsoDuration(String isoDuration) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    
    final RegExp regExp = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regExp.firstMatch(isoDuration);
    
    if (match != null) {
      if (match.group(1) != null) hours = int.parse(match.group(1)!);
      if (match.group(2) != null) minutes = int.parse(match.group(2)!);
      if (match.group(3) != null) seconds = int.parse(match.group(3)!);
    }
    
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  /// Get stream URL for a video
  Future<String?> getStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 15));
      
      // Get audio-only streams for efficient streaming
      final audioStreams = manifest.audioOnly.toList();
      
      if (audioStreams.isEmpty) {
        debugPrint('YouTubeMusicService: No audio streams available');
        return null;
      }
      
      // Sort by bitrate
      audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      
      // Select quality based on preference
      final selectedStream = _selectStreamByQuality(audioStreams);
      
      debugPrint('YouTubeMusicService: Selected stream: ${selectedStream.bitrate} bps');
      return selectedStream.url.toString();
    } catch (e) {
      debugPrint('YouTubeMusicService: Stream URL error: $e');
      return null;
    }
  }

  /// Select appropriate stream based on quality preference
  AudioOnlyStreamInfo _selectStreamByQuality(List<AudioOnlyStreamInfo> streams) {
    // Target bitrates for each quality level
    final targetBitrate = switch (_preferredQuality) {
      StreamingQuality.low => 64000,
      StreamingQuality.normal => 128000,
      StreamingQuality.high => 192000,
      StreamingQuality.best => 320000,
    };

    // Find the closest match
    streams.sort((a, b) {
      final diffA = (a.bitrate.bitsPerSecond - targetBitrate).abs();
      final diffB = (b.bitrate.bitsPerSecond - targetBitrate).abs();
      return diffA.compareTo(diffB);
    });

    return streams.first;
  }

  String _unescapeHtml(String text) {
    return text.replaceAll('&amp;', '&')
               .replaceAll('&quot;', '"')
               .replaceAll('&#039;', "'")
               .replaceAll('&#39;', "'")
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>');
  }
  
  /// Auto-detect quality based on network
  Future<StreamingQuality> detectNetworkQuality() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return StreamingQuality.best;
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        // Default to high for mobile, user can adjust in settings
        return StreamingQuality.high;
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return StreamingQuality.best;
      }
      
      return StreamingQuality.normal;
    } catch (e) {
      return StreamingQuality.normal;
    }
  }

  /// Get video details
  Future<StreamSongModel?> getVideoDetails(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId).timeout(const Duration(seconds: 15));
      return StreamSongModel.fromYouTube(
        videoId: video.id.value,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
      );
    } catch (e) {
      debugPrint('YouTubeMusicService: Video details error: $e');
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _yt.close();
  }
}

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
  
  /// Set preferred streaming quality
  void setQuality(StreamingQuality quality) {
    _preferredQuality = quality;
  }

  /// Get current streaming quality
  StreamingQuality get quality => _preferredQuality;

  /// Search for songs on YouTube
  Future<List<StreamSongModel>> searchSongs(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      
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
      debugPrint('YouTubeMusicService: Search error: $e');
      return [];
    }
  }

  /// Get trending music videos
  Future<List<StreamSongModel>> getTrendingMusic() async {
    try {
      // Search for popular music to simulate trending
      final searchResults = await _yt.search.search('trending music 2024');
      
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
      debugPrint('YouTubeMusicService: Trending error: $e');
      return [];
    }
  }

  /// Get stream URL for a video
  Future<String?> getStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
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
      final video = await _yt.videos.get(videoId);
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

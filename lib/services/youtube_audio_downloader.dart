import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Service that downloads YouTube audio to a temp file using
/// youtube_explode_dart's authenticated stream client, then
/// returns the local file path for just_audio to play.
///
/// This bypasses ExoPlayer's HTTP client entirely — no 403, no timeouts.
class YoutubeAudioDownloader {
  static final YoutubeExplode _yt = YoutubeExplode();
  static String? _tempDir;

  /// Initialize the temp directory
  static Future<void> init() async {
    final dir = await getTemporaryDirectory();
    _tempDir = '${dir.path}/yt_audio_cache';
    await Directory(_tempDir!).create(recursive: true);
    debugPrint('YoutubeAudioDownloader: Cache dir at $_tempDir');
  }

  /// Download the audio for a video and return the local file path.
  /// Returns null if download fails.
  /// If file is already cached, returns immediately.
  static Future<String?> download(String videoId, {
    Function(double)? onProgress,
  }) async {
    if (_tempDir == null) await init();
    
    // Check if already cached
    final cachedFile = _getCachedFile(videoId);
    if (cachedFile != null) {
      debugPrint('YoutubeAudioDownloader: Cache hit for $videoId');
      return cachedFile;
    }

    try {
      debugPrint('YoutubeAudioDownloader: Downloading $videoId...');

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.toList();

      if (audioStreams.isEmpty) {
        debugPrint('YoutubeAudioDownloader: No audio streams for $videoId');
        return null;
      }

      // Sort by bitrate ascending, pick ~128kbps for fast download
      audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
      AudioOnlyStreamInfo? selected;
      for (final s in audioStreams) {
        if (s.bitrate.bitsPerSecond >= 96000) {
          selected = s;
          break;
        }
      }
      selected ??= audioStreams.last;

      debugPrint('YoutubeAudioDownloader: Selected ${selected.bitrate} bps, '
          'codec: ${selected.codec.subtype}, '
          'size: ${selected.size}');

      // Determine file extension
      final ext = selected.container.name == 'webm' ? 'webm' : 'm4a';
      final filePath = '$_tempDir/$videoId.$ext';
      final file = File(filePath);

      // Download using youtube_explode_dart's authenticated stream
      final byteStream = _yt.videos.streamsClient.get(selected);
      final sink = file.openWrite();
      
      var downloaded = 0;
      final totalBytes = selected.size.totalBytes;

      await for (final chunk in byteStream) {
        sink.add(chunk);
        downloaded += chunk.length;
        
        if (onProgress != null && totalBytes > 0) {
          onProgress(downloaded / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      debugPrint('YoutubeAudioDownloader: Downloaded $downloaded bytes to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('YoutubeAudioDownloader: Error downloading $videoId: $e');
      return null;
    }
  }

  /// Check if a video is already cached
  static String? _getCachedFile(String videoId) {
    if (_tempDir == null) return null;
    
    for (final ext in ['m4a', 'webm']) {
      final file = File('$_tempDir/$videoId.$ext');
      if (file.existsSync() && file.lengthSync() > 0) {
        return file.path;
      }
    }
    return null;
  }

  /// Clear all cached audio files
  static Future<void> clearCache() async {
    if (_tempDir == null) return;
    final dir = Directory(_tempDir!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    debugPrint('YoutubeAudioDownloader: Cache cleared');
  }
}

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A local proxy server that uses youtube_explode_dart's own
/// stream client to fetch raw audio bytes and serve them to
/// ExoPlayer via localhost — completely bypassing 403 errors.
///
/// Supports HTTP Range requests which ExoPlayer needs for seeking
/// and reading MP4/M4A container metadata (moov atom).
class LocalStreamProxy {
  static HttpServer? _server;
  static int? _port;
  static YoutubeExplode? _yt;

  // Cache stream info to avoid re-fetching manifests for range requests
  static final Map<String, _CachedStreamInfo> _streamInfoCache = {};

  /// Start the local proxy server
  static Future<void> start() async {
    if (_server != null) return;

    try {
      _yt = YoutubeExplode();
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;

      debugPrint('LocalStreamProxy: Started on port $_port');

      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      });
    } catch (e) {
      debugPrint('LocalStreamProxy: Error starting server: $e');
    }
  }

  /// Stop the local proxy server
  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
    _yt?.close();
    _yt = null;
    _streamInfoCache.clear();
    debugPrint('LocalStreamProxy: Stopped');
  }

  /// Get the proxy URL for a given video ID
  static String getProxyUrl(String videoId) {
    if (_port == null) {
      debugPrint('LocalStreamProxy: Server not started!');
      return '';
    }
    return 'http://127.0.0.1:$_port/stream?id=$videoId';
  }

  /// Get or fetch cached stream info for a video
  static Future<_CachedStreamInfo?> _getStreamInfo(String videoId) async {
    // Check cache (valid for 5 minutes)
    final cached = _streamInfoCache[videoId];
    if (cached != null && DateTime.now().difference(cached.fetchedAt).inMinutes < 5) {
      return cached;
    }

    try {
      final yt = _yt ?? YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(videoId);

      final audioStreams = manifest.audioOnly.toList();
      if (audioStreams.isEmpty) {
        debugPrint('LocalStreamProxy: No audio streams found for $videoId');
        return null;
      }

      // Sort by bitrate - pick a moderate quality stream
      audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      final selectedStream = audioStreams.length > 1 ? audioStreams[1] : audioStreams[0];

      debugPrint('LocalStreamProxy: Selected ${selectedStream.bitrate} bps, '
          'codec: ${selectedStream.codec.subtype}, '
          'size: ${selectedStream.size}');

      final info = _CachedStreamInfo(
        streamInfo: selectedStream,
        totalBytes: selectedStream.size.totalBytes,
        contentType: selectedStream.codec.subtype == 'opus' ? 'audio/webm' : 'audio/mp4',
        fetchedAt: DateTime.now(),
      );

      _streamInfoCache[videoId] = info;
      return info;
    } catch (e) {
      debugPrint('LocalStreamProxy: Error fetching manifest for $videoId: $e');
      return null;
    }
  }

  /// Handle incoming requests from the audio player
  static Future<void> _handleRequest(HttpRequest request) async {
    final videoId = request.uri.queryParameters['id'];

    if (videoId == null || videoId.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing id parameter');
      await request.response.close();
      return;
    }

    try {
      debugPrint('LocalStreamProxy: Request for video: $videoId');

      final streamInfo = await _getStreamInfo(videoId);
      if (streamInfo == null) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('No audio streams available');
        await request.response.close();
        return;
      }

      final totalBytes = streamInfo.totalBytes;
      final yt = _yt ?? YoutubeExplode();

      // Parse Range header from ExoPlayer
      final rangeHeader = request.headers.value('Range');
      int startByte = 0;
      int endByte = totalBytes > 0 ? totalBytes - 1 : 0;

      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final rangeSpec = rangeHeader.substring(6); // Remove "bytes="
        final parts = rangeSpec.split('-');
        if (parts[0].isNotEmpty) {
          startByte = int.parse(parts[0]);
        }
        if (parts.length > 1 && parts[1].isNotEmpty) {
          endByte = int.parse(parts[1]);
        }

        debugPrint('LocalStreamProxy: Range request: bytes=$startByte-$endByte/$totalBytes');

        // Respond with 206 Partial Content
        request.response.statusCode = HttpStatus.partialContent;
        final contentLength = endByte - startByte + 1;
        request.response.headers.set('Content-Range', 'bytes $startByte-$endByte/$totalBytes');
        request.response.headers.set('Content-Length', contentLength.toString());
      } else {
        // Full response
        request.response.statusCode = HttpStatus.ok;
        if (totalBytes > 0) {
          request.response.headers.set('Content-Length', totalBytes.toString());
        }
      }

      // Set common headers
      request.response.headers.set('Content-Type', streamInfo.contentType);
      request.response.headers.set('Accept-Ranges', 'bytes');
      request.response.headers.set('Connection', 'keep-alive');

      // Use youtube_explode_dart's stream client with range support
      final audioStream = yt.videos.streamsClient.get(
        streamInfo.streamInfo,
        startByteOffset: startByte,
        endByteOffset: endByte + 1, // youtube_explode uses exclusive end
      );

      // Pipe bytes to ExoPlayer
      await audioStream.pipe(request.response);

      debugPrint('LocalStreamProxy: Stream completed for $videoId ($startByte-$endByte)');
    } catch (e) {
      debugPrint('LocalStreamProxy: Error streaming $videoId: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
      } catch (_) {}
      try {
        await request.response.close();
      } catch (_) {}
    }
  }
}

class _CachedStreamInfo {
  final AudioOnlyStreamInfo streamInfo;
  final int totalBytes;
  final String contentType;
  final DateTime fetchedAt;

  _CachedStreamInfo({
    required this.streamInfo,
    required this.totalBytes,
    required this.contentType,
    required this.fetchedAt,
  });
}

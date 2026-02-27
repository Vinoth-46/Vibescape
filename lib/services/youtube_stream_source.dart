import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A custom StreamAudioSource that streams YouTube audio bytes
/// directly to just_audio's native player via youtube_explode_dart.
///
/// This completely bypasses ExoPlayer's DefaultHttpDataSource (which
/// causes 403/timeout errors) by feeding bytes directly to the player.
class YoutubeStreamAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode _yt;
  AudioOnlyStreamInfo? _cachedStreamInfo;
  int _cachedContentLength = 0;
  Uint8List? _cachedBytes;

  YoutubeStreamAudioSource({
    required this.videoId,
    YoutubeExplode? yt,
    super.tag,
  }) : _yt = yt ?? YoutubeExplode();

  /// Download all bytes for the stream (cached after first call)
  Future<Uint8List> _getBytes() async {
    if (_cachedBytes != null) return _cachedBytes!;

    try {
      debugPrint('YoutubeStreamAudioSource: Fetching manifest for $videoId...');
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.toList();

      if (audioStreams.isEmpty) {
        throw Exception('No audio streams available for $videoId');
      }

      // Sort by bitrate ascending, pick the one closest to ~128kbps
      audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
      AudioOnlyStreamInfo? selected;
      for (final s in audioStreams) {
        if (s.bitrate.bitsPerSecond >= 96000) {
          selected = s;
          break;
        }
      }
      selected ??= audioStreams.last;
      _cachedStreamInfo = selected;

      debugPrint('YoutubeStreamAudioSource: Selected ${selected.bitrate} bps, '
          'codec: ${selected.codec.subtype}, '
          'size: ${selected.size}, '
          'container: ${selected.container.name}');

      // Collect all bytes from the stream
      final byteStream = _yt.videos.streamsClient.get(selected);
      final List<int> allBytes = [];
      
      await for (final chunk in byteStream) {
        allBytes.addAll(chunk);
      }

      _cachedBytes = Uint8List.fromList(allBytes);
      _cachedContentLength = _cachedBytes!.length;
      
      debugPrint('YoutubeStreamAudioSource: Downloaded ${_cachedContentLength} bytes for $videoId');
      return _cachedBytes!;
    } catch (e) {
      debugPrint('YoutubeStreamAudioSource: Error: $e');
      rethrow;
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final bytes = await _getBytes();
    
    int startByte = start ?? 0;
    if (startByte < 0) startByte = 0;
    
    int endByte = end ?? bytes.length;
    if (endByte > bytes.length) endByte = bytes.length;
    if (startByte > endByte) startByte = endByte;

    debugPrint('YoutubeStreamAudioSource: request($startByte-$endByte / ${bytes.length}) for $videoId');

    // Determine content type
    String contentType = 'audio/mp4';
    if (_cachedStreamInfo != null) {
      if (_cachedStreamInfo!.container.name == 'webm') {
        contentType = 'audio/webm';
      }
    }

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: endByte - startByte,
      offset: startByte,
      stream: Stream.value(bytes.sublist(startByte, endByte)),
      contentType: contentType,
    );
  }
}

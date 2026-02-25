/// Unified song model for both local and streaming songs
class StreamSongModel {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnailUrl;
  final Duration duration;
  final bool isLocal;
  final String? localPath;
  final String? cachedPath;
  final DateTime? cachedAt;

  const StreamSongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnailUrl,
    required this.duration,
    this.isLocal = false,
    this.localPath,
    this.cachedPath,
    this.cachedAt,
  });

  /// Check if this song is available offline (local or cached)
  bool get isAvailableOffline => isLocal || cachedPath != null;

  /// Check if this is a streaming song
  bool get isStreaming => !isLocal;

  /// Copy with method for immutability
  StreamSongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    Duration? duration,
    bool? isLocal,
    String? localPath,
    String? cachedPath,
    DateTime? cachedAt,
  }) {
    return StreamSongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      isLocal: isLocal ?? this.isLocal,
      localPath: localPath ?? this.localPath,
      cachedPath: cachedPath ?? this.cachedPath,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  /// Create from YouTube search result
  factory StreamSongModel.fromYouTube({
    required String videoId,
    required String title,
    required String artist,
    String? thumbnailUrl,
    required Duration duration,
  }) {
    return StreamSongModel(
      id: videoId,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      isLocal: false,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration.inMilliseconds,
      'isLocal': isLocal,
      'localPath': localPath,
      'cachedPath': cachedPath,
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory StreamSongModel.fromJson(Map<String, dynamic> json) {
    return StreamSongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: Duration(milliseconds: json['duration'] as int),
      isLocal: json['isLocal'] as bool? ?? false,
      localPath: json['localPath'] as String?,
      cachedPath: json['cachedPath'] as String?,
      cachedAt: json['cachedAt'] != null 
          ? DateTime.parse(json['cachedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamSongModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StreamSongModel{id: $id, title: $title, artist: $artist, isLocal: $isLocal}';
  }
}

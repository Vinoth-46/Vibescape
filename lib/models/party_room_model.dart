import 'package:offline_music_player/models/stream_song_model.dart';

class PartyRoomModel {
  final String roomId;
  final String hostId;
  final List<String> memberIds;
  final StreamSongModel? currentSong;
  final bool isPlaying;
  final Duration playbackPosition;
  final int lastUpdated;

  PartyRoomModel({
    required this.roomId,
    required this.hostId,
    required this.memberIds,
    this.currentSong,
    required this.isPlaying,
    required this.playbackPosition,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hostId': hostId,
      'memberIds': memberIds,
      'currentSong': currentSong?.toJson(),
      'isPlaying': isPlaying,
      'playbackPosition': playbackPosition.inMilliseconds,
      'lastUpdated': lastUpdated,
    };
  }

  factory PartyRoomModel.fromMap(Map<dynamic, dynamic> map) {
    return PartyRoomModel(
      roomId: map['roomId'] ?? '',
      hostId: map['hostId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      currentSong: map['currentSong'] != null
          ? StreamSongModel.fromJson(Map<String, dynamic>.from(map['currentSong']))
          : null,
      isPlaying: map['isPlaying'] ?? false,
      playbackPosition: Duration(milliseconds: map['playbackPosition'] ?? 0),
      lastUpdated: map['lastUpdated'] ?? 0,
    );
  }

  PartyRoomModel copyWith({
    String? roomId,
    String? hostId,
    List<String>? memberIds,
    StreamSongModel? currentSong,
    bool? isPlaying,
    Duration? playbackPosition,
    int? lastUpdated,
  }) {
    return PartyRoomModel(
      roomId: roomId ?? this.roomId,
      hostId: hostId ?? this.hostId,
      memberIds: memberIds ?? this.memberIds,
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

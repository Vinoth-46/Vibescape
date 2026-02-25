import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/stream_song_model.dart';

// Enhanced playlist model that supports both local and streaming songs
class Playlist {
  final String name;
  final List<String> songIds;  // Local song IDs
  final List<StreamSongModel> streamSongs;  // Streaming songs with metadata

  Playlist({
    required this.name, 
    required this.songIds,
    List<StreamSongModel>? streamSongs,
  }) : streamSongs = streamSongs ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'songIds': songIds,
    'streamSongs': streamSongs.map((s) => s.toJson()).toList(),
  };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'],
      songIds: List<String>.from(json['songIds'] ?? []),
      streamSongs: json['streamSongs'] != null
          ? (json['streamSongs'] as List)
              .map((e) => StreamSongModel.fromJson(e))
              .toList()
          : [],
    );
  }

  // Check if playlist has any songs
  bool get isEmpty => songIds.isEmpty && streamSongs.isEmpty;
  
  // Total song count
  int get totalSongs => songIds.length + streamSongs.length;
}

class PlaylistController extends ChangeNotifier {
  static const String _keyPlaylists = 'playlists_v2';  // New key for updated format
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistController() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try loading new format first
    String? playlistsString = prefs.getString(_keyPlaylists);
    
    // Migrate from old format if needed
    if (playlistsString == null) {
      playlistsString = prefs.getString('playlists');
    }
    
    if (playlistsString != null) {
      final List<dynamic> decoded = jsonDecode(playlistsString);
      _playlists = decoded.map((e) => Playlist.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    _playlists.add(Playlist(name: name, songIds: []));
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(int index) async {
    _playlists.removeAt(index);
    await _savePlaylists();
    notifyListeners();
  }

  // Add local song to playlist
  Future<void> addToPlaylist(int playlistIndex, String songId) async {
    if (!_playlists[playlistIndex].songIds.contains(songId)) {
      _playlists[playlistIndex].songIds.add(songId);
      await _savePlaylists();
      notifyListeners();
    }
  }

  // Add streaming song to playlist
  Future<void> addStreamSongToPlaylist(int playlistIndex, StreamSongModel song) async {
    final playlist = _playlists[playlistIndex];
    if (!playlist.streamSongs.any((s) => s.id == song.id)) {
      playlist.streamSongs.add(song);
      await _savePlaylists();
      notifyListeners();
    }
  }

  // Remove local song from playlist
  Future<void> removeFromPlaylist(int playlistIndex, String songId) async {
    _playlists[playlistIndex].songIds.remove(songId);
    await _savePlaylists();
    notifyListeners();
  }

  // Remove streaming song from playlist
  Future<void> removeStreamSongFromPlaylist(int playlistIndex, String songId) async {
    _playlists[playlistIndex].streamSongs.removeWhere((s) => s.id == songId);
    await _savePlaylists();
    notifyListeners();
  }

  // Check if song is in playlist
  bool isInPlaylist(int playlistIndex, String songId) {
    final playlist = _playlists[playlistIndex];
    return playlist.songIds.contains(songId) || 
           playlist.streamSongs.any((s) => s.id == songId);
  }

  Future<void> clearAllPlaylists() async {
    _playlists.clear();
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_playlists.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPlaylists, encoded);
  }
}

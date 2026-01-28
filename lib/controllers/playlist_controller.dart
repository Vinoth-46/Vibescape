import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Simple model for a playlist
class Playlist {
  final String name;
  final List<String> songIds;

  Playlist({required this.name, required this.songIds});

  Map<String, dynamic> toJson() => {
        'name': name,
        'songIds': songIds,
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'],
      songIds: List<String>.from(json['songIds']),
    );
  }
}

class PlaylistController extends ChangeNotifier {
  static const String _keyPlaylists = 'playlists';
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistController() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsString = prefs.getString(_keyPlaylists);
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

  Future<void> addToPlaylist(int playlistIndex, String songId) async {
    if (!_playlists[playlistIndex].songIds.contains(songId)) {
      _playlists[playlistIndex].songIds.add(songId);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> removeFromPlaylist(int playlistIndex, String songId) async {
    _playlists[playlistIndex].songIds.remove(songId);
    await _savePlaylists();
    notifyListeners();
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

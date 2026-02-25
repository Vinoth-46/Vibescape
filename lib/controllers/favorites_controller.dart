import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/stream_song_model.dart';

class FavoritesController extends ChangeNotifier {
  static const String _keyFavorites = 'favorites';
  static const String _keyStreamFavorites = 'stream_favorites';
  
  // Local song favorite IDs
  List<String> _favoriteIds = [];
  
  // Streaming song favorites (stored with full metadata)
  List<StreamSongModel> _streamFavorites = [];

  List<String> get favoriteIds => _favoriteIds;
  List<StreamSongModel> get streamFavorites => _streamFavorites;

  FavoritesController() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load local favorites
    _favoriteIds = prefs.getStringList(_keyFavorites) ?? [];
    
    // Load stream favorites
    final streamFavoritesJson = prefs.getString(_keyStreamFavorites);
    if (streamFavoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(streamFavoritesJson);
      _streamFavorites = decoded.map((e) => StreamSongModel.fromJson(e)).toList();
    }
    
    notifyListeners();
  }

  // Toggle favorite for local songs (by ID)
  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    await _saveFavorites();
    notifyListeners();
  }

  // Toggle favorite for streaming songs
  Future<void> toggleStreamFavorite(StreamSongModel song) async {
    final existingIndex = _streamFavorites.indexWhere((s) => s.id == song.id);
    if (existingIndex >= 0) {
      _streamFavorites.removeAt(existingIndex);
    } else {
      _streamFavorites.add(song);
    }
    await _saveStreamFavorites();
    notifyListeners();
  }

  // Check if local song is favorite
  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  // Check if streaming song is favorite
  bool isStreamFavorite(String id) {
    return _streamFavorites.any((s) => s.id == id);
  }

  Future<void> clearFavorites() async {
    _favoriteIds.clear();
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearStreamFavorites() async {
    _streamFavorites.clear();
    await _saveStreamFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, _favoriteIds);
  }

  Future<void> _saveStreamFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_streamFavorites.map((s) => s.toJson()).toList());
    await prefs.setString(_keyStreamFavorites, encoded);
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';

class FolderController extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Map of folder path -> List of songs
  Map<String, List<SongModel>> _folders = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<String> get folderPaths => _folders.keys.toList();

  FolderController() {
    fetchFolders();
  }

  Future<void> fetchFolders() async {
    _isLoading = true;
    notifyListeners();

    try {
      // We fetch all songs and group them manually to ensure accuracy
      // and availability of SongModel for playback.
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _folders = {};

      for (var song in songs) {
        if (song.data.isEmpty) continue;

        // Get the parent directory
        final File file = File(song.data);
        final String folderPath = file.parent.path;

        if (!_folders.containsKey(folderPath)) {
          _folders[folderPath] = [];
        }
        _folders[folderPath]!.add(song);
      }
    } catch (e) {
      debugPrint("Error fetching folders: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SongModel> getSongsInFolder(String folderPath) {
    return _folders[folderPath] ?? [];
  }

  String getFolderName(String path) {
    return path.split('/').last;
  }
}

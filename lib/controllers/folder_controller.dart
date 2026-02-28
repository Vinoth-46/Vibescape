import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/permission_service.dart';

class FolderController extends ChangeNotifier {
  late final OnAudioQuery _audioQuery;
  late final PermissionService _permissionService;

  // Map of folder path -> List of songs
  Map<String, List<SongModel>> _allFolders = {};
  
  // Set of hidden folder paths (stored in preferences)
  Set<String> _hiddenFolders = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  // Returns only visible folder paths
  List<String> get folderPaths => _allFolders.keys
      .where((path) => !_hiddenFolders.contains(path))
      .toList();
  
  // Returns all folder paths (for settings)
  List<String> get allFolderPaths => _allFolders.keys.toList();
  
  // Check if folder is hidden
  bool isFolderHidden(String path) => _hiddenFolders.contains(path);

  FolderController({OnAudioQuery? audioQuery, PermissionService? permissionService}) {
    _audioQuery = audioQuery ?? OnAudioQuery();
    _permissionService = permissionService ?? PermissionService();
    _init();
  }

  Future<void> _init() async {
    await _loadHiddenFolders();
    await _checkPermissionAndFetch();
  }
  
  Future<void> _loadHiddenFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hidden = prefs.getStringList('hidden_folders') ?? [];
      _hiddenFolders = hidden.toSet();
    } catch (e) {
      debugPrint("FolderController: Error loading hidden folders: $e");
    }
  }
  
  Future<void> _saveHiddenFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_folders', _hiddenFolders.toList());
    } catch (e) {
      debugPrint("FolderController: Error saving hidden folders: $e");
    }
  }
  
  // Toggle folder visibility
  Future<void> toggleFolderVisibility(String folderPath) async {
    if (_hiddenFolders.contains(folderPath)) {
      _hiddenFolders.remove(folderPath);
    } else {
      _hiddenFolders.add(folderPath);
    }
    await _saveHiddenFolders();
    notifyListeners();
  }
  
  // Show all folders
  Future<void> showAllFolders() async {
    _hiddenFolders.clear();
    await _saveHiddenFolders();
    notifyListeners();
  }
  
  // Hide all folders
  Future<void> hideAllFolders() async {
    _hiddenFolders = _allFolders.keys.toSet();
    await _saveHiddenFolders();
    notifyListeners();
  }

  Future<void> _checkPermissionAndFetch() async {
    final hasPermission = await _permissionService.hasPermissions();
    _hasPermission = hasPermission;
    if (hasPermission) {
      await fetchFolders();
    } else {
      notifyListeners();
    }
  }
  
  // Called when permission is granted
  Future<void> onPermissionGranted() async {
    _hasPermission = true;
    await fetchFolders();
  }

  Future<void> fetchFolders() async {
    // Double-check permission before querying
    final hasPermission = await _permissionService.hasPermissions();
    if (!hasPermission) {
      debugPrint("FolderController: No permission to query songs");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("FolderController: Fetching songs for folder grouping...");
      
      // We fetch all songs and group them manually to ensure accuracy
      // and availability of SongModel for playback.
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      debugPrint("FolderController: Found ${songs.length} total songs");
      
      _allFolders = {};

      for (var song in songs) {
        if (song.data.isEmpty) continue;

        try {
          // Get the parent directory
          final File file = File(song.data);
          final String folderPath = file.parent.path;

          if (!_allFolders.containsKey(folderPath)) {
            _allFolders[folderPath] = [];
          }
          _allFolders[folderPath]!.add(song);
        } catch (e) {
          debugPrint("FolderController: Error processing song ${song.title}: $e");
        }
      }
      
      debugPrint("FolderController: Found ${_allFolders.length} folders");
      
    } catch (e) {
      debugPrint("FolderController: Error fetching folders: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SongModel> getSongsInFolder(String folderPath) {
    return _allFolders[folderPath] ?? [];
  }

  String getFolderName(String path) {
    return p.basename(path);
  }
  
  // Refresh folders
  Future<void> refresh() async {
    await fetchFolders();
  }
}

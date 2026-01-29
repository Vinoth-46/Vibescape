import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage which folders are selected for music scanning.
/// Users can choose specific folders to include in their library,
/// allowing them to exclude call recordings and other unwanted audio.
class FolderSelectionService {
  static const String _selectedFoldersKey = 'selected_music_folders';
  
  /// Get all selected folder paths.
  /// Returns empty list if no folders selected (means scan all folders).
  Future<List<String>> getSelectedFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final folders = prefs.getStringList(_selectedFoldersKey);
    return folders ?? [];
  }
  
  /// Save selected folder paths.
  Future<void> saveSelectedFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedFoldersKey, folders);
  }
  
  /// Add a folder to selection.
  Future<void> addFolder(String folderPath) async {
    final folders = await getSelectedFolders();
    if (!folders.contains(folderPath)) {
      folders.add(folderPath);
      await saveSelectedFolders(folders);
    }
  }
  
  /// Remove a folder from selection.
  Future<void> removeFolder(String folderPath) async {
    final folders = await getSelectedFolders();
    folders.remove(folderPath);
    await saveSelectedFolders(folders);
  }
  
  /// Check if a folder is selected.
  Future<bool> isFolderSelected(String folderPath) async {
    final folders = await getSelectedFolders();
    return folders.contains(folderPath);
  }
  
  /// Check if folder filtering is enabled (at least one folder selected).
  Future<bool> isFilteringEnabled() async {
    final folders = await getSelectedFolders();
    return folders.isNotEmpty;
  }
  
  /// Clear all selected folders (scan all).
  Future<void> clearSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedFoldersKey);
  }
}

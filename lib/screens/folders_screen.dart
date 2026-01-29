import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/folder_controller.dart';
import '../controllers/audio_player_controller.dart';
import 'player_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredFolders(List<String> folders, FolderController controller) {
    if (_searchQuery.isEmpty) return folders;
    
    final query = _searchQuery.toLowerCase();
    return folders.where((path) {
      final folderName = controller.getFolderName(path).toLowerCase();
      return folderName.contains(query);
    }).toList();
  }

  void _showFolderSettingsDialog(BuildContext context, FolderController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<FolderController>(
              builder: (context, ctrl, child) {
                final allFolders = ctrl.allFolderPaths;
                
                return Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Select Folders to Show",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => ctrl.showAllFolders(),
                                child: const Text("Show All"),
                              ),
                              TextButton(
                                onPressed: () => ctrl.hideAllFolders(),
                                child: const Text("Hide All"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Folder list
                    Expanded(
                      child: allFolders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No folders found",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => ctrl.refresh(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Refresh"),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: allFolders.length,
                              itemBuilder: (context, index) {
                                final path = allFolders[index];
                                final folderName = ctrl.getFolderName(path);
                                final songCount = ctrl.getSongsInFolder(path).length;
                                final isHidden = ctrl.isFolderHidden(path);
                                
                                return CheckboxListTile(
                                  value: !isHidden,
                                  onChanged: (value) {
                                    ctrl.toggleFolderVisibility(path);
                                  },
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isHidden 
                                          ? Colors.grey.withOpacity(0.2)
                                          : Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.folder,
                                      color: isHidden ? Colors.grey : Colors.teal,
                                    ),
                                  ),
                                  title: Text(
                                    folderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isHidden ? Colors.grey : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "$songCount songs • ${_shortenPath(path)}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  activeColor: Colors.teal,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
  
  String _shortenPath(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    if (parts.length > 3) {
      return ".../${parts.sublist(parts.length - 3).join('/')}";
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search folders...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Folders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            Consumer<FolderController>(
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.folder_special),
                  tooltip: 'Select Folders',
                  onPressed: () => _showFolderSettingsDialog(context, controller),
                );
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      body: Consumer<FolderController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allFolders = controller.folderPaths; // Only visible folders
          final filteredFolders = _getFilteredFolders(allFolders, controller);

          if (controller.allFolderPaths.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No Music Folders Found",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Make sure you have granted storage permission",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
                  ),
                ],
              ),
            );
          }

          if (allFolders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "All folders are hidden",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showFolderSettingsDialog(context, controller),
                    icon: const Icon(Icons.folder_special),
                    label: const Text("Select Folders"),
                  ),
                ],
              ),
            );
          }

          if (filteredFolders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No folders found",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Try a different search term",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "${filteredFolders.length} folders found",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFolders.length,
                  itemBuilder: (context, index) {
                    final path = filteredFolders[index];
                    final folderName = controller.getFolderName(path);
                    final songCount = controller.getSongsInFolder(path).length;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder, color: Colors.teal),
                      ),
                      title: Text(folderName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("$songCount Songs",
                          style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderDetailScreen(
                              folderPath: path,
                              folderName: folderName,
                              songs: controller.getSongsInFolder(path),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FolderDetailScreen extends StatefulWidget {
  final String folderPath;
  final String folderName;
  final List<SongModel> songs;

  const FolderDetailScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
    required this.songs,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SongModel> _getFilteredSongs() {
    if (_searchQuery.isEmpty) return widget.songs;
    
    final query = _searchQuery.toLowerCase();
    return widget.songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          (song.artist?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _getFilteredSongs();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.folderName}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(widget.folderName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.play_arrow),
        onPressed: () {
          if (filteredSongs.isNotEmpty) {
            Provider.of<AudioPlayerController>(context, listen: false)
                .playPlaylist(filteredSongs, 0);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()));
          }
        },
      ),
      body: filteredSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No songs found",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Try a different search term",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "${filteredSongs.length} songs found",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return ListTile(
                        leading: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget:
                              const Icon(Icons.music_note, color: Colors.grey),
                        ),
                        title:
                            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist ?? "Unknown", maxLines: 1),
                        onTap: () {
                          Provider.of<AudioPlayerController>(context, listen: false)
                              .playPlaylist(filteredSongs, index);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PlayerScreen()));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

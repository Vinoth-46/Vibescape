import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/audio_player_controller.dart';
import '../services/permission_service.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Filter state
  String _sortBy = 'title'; // title, artist, album, duration
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndLoad();
    });
  }

  Future<void> _checkAndLoad() async {
    final hasPermission = await _permissionService.hasPermissions();
    if (hasPermission && mounted) {
      context.read<AudioPlayerController>().onPermissionGranted();
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _permissionService.requestPermissions();
    if (granted && mounted) {
      context.read<AudioPlayerController>().onPermissionGranted();
    } else {
      // If denied permanently, open settings (optional, logic inside service?)
      // The UI button usually handles the "Try Again" flow.
      if (!await _permissionService.hasPermissions()) {
        // Optional: Show snackbar or dialog if needed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Permissions are required to play music.")));
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User came back to app, re-check permissions
      _checkAndLoad();
    }
  }

  // Filter and sort songs based on current state
  List<SongModel> _getFilteredSongs(List<SongModel> songs) {
    List<SongModel> filtered = songs;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = songs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            (song.artist?.toLowerCase().contains(query) ?? false) ||
            (song.album?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'artist':
          comparison = (a.artist ?? '').compareTo(b.artist ?? '');
          break;
        case 'album':
          comparison = (a.album ?? '').compareTo(b.album ?? '');
          break;
        case 'duration':
          comparison = (a.duration ?? 0).compareTo(b.duration ?? 0);
          break;
        case 'latest':
          // Sort by dateAdded - newer first by default
          comparison = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
          break;
        case 'title':
        default:
          comparison = a.title.compareTo(b.title);
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    "Sort & Filter",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Sort by",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('Title', 'title', setModalState),
                      _buildSortChip('Artist', 'artist', setModalState),
                      _buildSortChip('Album', 'album', setModalState),
                      _buildSortChip('Duration', 'duration', setModalState),
                      _buildSortChip('Latest', 'latest', setModalState),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "Order: ",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward, size: 16),
                            SizedBox(width: 4),
                            Text("Ascending"),
                          ],
                        ),
                        selected: _sortAscending,
                        onSelected: (selected) {
                          setModalState(() => _sortAscending = true);
                          setState(() {});
                        },
                        selectedColor: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward, size: 16),
                            SizedBox(width: 4),
                            Text("Descending"),
                          ],
                        ),
                        selected: !_sortAscending,
                        onSelected: (selected) {
                          setModalState(() => _sortAscending = false);
                          setState(() {});
                        },
                        selectedColor: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setModalState) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortBy == value,
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _sortBy = value);
          setState(() {});
        }
      },
      selectedColor: Colors.teal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AudioPlayerController>(context);
    final allSongs = controller.songs;
    final filteredSongs = _getFilteredSongs(allSongs);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
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
            : const Text("Library"),
        centerTitle: !_isSearching,
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
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterBottomSheet,
            ),
          ] else ...[
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
        ],
      ),
      body: !controller.hasPermission
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 80, color: Colors.teal),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "We need storage permission to access your music.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _requestPermissions, // Use local method
                    icon: const Icon(Icons.security),
                    label: const Text("Grant Permission"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  TextButton(
                      onPressed: () => _permissionService.openSettings(),
                      child: const Text("Open Settings"))
                ],
              ),
            )
          : allSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        "No Music Found",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try changing the duration filter in Settings",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<AudioPlayerController>()
                              .refreshLibrary();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh Library"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : filteredSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "No results found",
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
                        // Results count
                        if (_searchQuery.isNotEmpty || _sortBy != 'title')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  "${filteredSongs.length} songs",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_sortBy != 'title') ...[
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      "Sorted by ${_sortBy[0].toUpperCase()}${_sortBy.substring(1)}",
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredSongs.length,
                            itemBuilder: (context, index) {
                              SongModel song = filteredSongs[index];
                              return ListTile(
                                title: Text(song.title,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle:
                                    Text(song.artist ?? "Unknown Artist", maxLines: 1),
                                trailing: const Icon(Icons.play_arrow_rounded),
                                leading: QueryArtworkWidget(
                                  id: song.id,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget:
                                      const Icon(Icons.music_note, size: 32),
                                ),
                                onTap: () {
                                  // Play from filtered list at correct index
                                  controller.playPlaylist(filteredSongs, index);
                                  // Navigate to Player Screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const PlayerScreen()),
                                  );
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

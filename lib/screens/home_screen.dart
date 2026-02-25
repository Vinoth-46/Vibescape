import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/audio_player_controller.dart';
import '../services/permission_service.dart';
import '../widgets/glass_container.dart';
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
      if (!await _permissionService.hasPermissions()) {
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
      _checkAndLoad();
    }
  }

  List<SongModel> _getFilteredSongs(List<SongModel> songs) {
    List<SongModel> filtered = songs;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = songs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            (song.artist?.toLowerCase().contains(query) ?? false) ||
            (song.album?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        "Sort & Filter",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Sort by",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildSortChip('Title', 'title', setModalState),
                          _buildSortChip('Artist', 'artist', setModalState),
                          _buildSortChip('Album', 'album', setModalState),
                          _buildSortChip('Duration', 'duration', setModalState),
                          _buildSortChip('Latest', 'latest', setModalState),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            "Order: ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildOrderChip(Icons.arrow_upward_rounded, "Ascending", true, setModalState),
                          const SizedBox(width: 12),
                          _buildOrderChip(Icons.arrow_downward_rounded, "Descending", false, setModalState),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setModalState(() => _sortBy = value);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderChip(IconData icon, String label, bool isAscending, StateSetter setModalState) {
    final isSelected = _sortAscending == isAscending;
    return InkWell(
      onTap: () {
        setModalState(() => _sortAscending = isAscending);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF007AFF) : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF007AFF) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AudioPlayerController>(context);
    final allSongs = controller.songs;
    final filteredSongs = _getFilteredSongs(allSongs);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 2026 Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1A1C29),
                          const Color(0xFF0F1016),
                          const Color(0xFF001A33).withOpacity(0.5),
                        ]
                      : [
                          const Color(0xFFF2F6FA),
                          const Color(0xFFE8F0F8),
                          const Color(0xFFD1E3F6).withOpacity(0.5),
                        ],
                ),
              ),
            ),
          ),
          // Background Glow Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      title: _isSearching
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'Search songs...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey.withOpacity(0.8),
                                  fontSize: 20,
                                ),
                              ),
                              onChanged: (value) => setState(() => _searchQuery = value),
                            )
                          : const Text(
                              'Library',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  fontSize: 28),
                            ),
                      background: Container(color: Colors.transparent),
                    ),
                  ),
                ),
                actions: [
                  if (!_isSearching) ...[
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list_rounded),
                      onPressed: _showFilterBottomSheet,
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
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
              
              if (!controller.hasPermission)
                SliverFillRemaining(
                  child: Center(
                    child: GlassContainer(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      borderRadius: BorderRadius.circular(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF007AFF)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Storage Access Required",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "We need local storage permission to discover and play your music library.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, height: 1.5),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            onPressed: _requestPermissions,
                            child: const Text("Grant Permission", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => _permissionService.openSettings(),
                            child: const Text("Open OS Settings", style: TextStyle(color: Colors.grey)),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              else if (allSongs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: GlassContainer(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      borderRadius: BorderRadius.circular(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_off_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 24),
                          const Text("No Music Found",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text("Try syncing missing folders or changing the duration filter in Preferences.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, height: 1.5)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.read<AudioPlayerController>().refreshLibrary(),
                            icon: const Icon(Icons.autorenew_rounded),
                            label: const Text("Rescan Library"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filteredSongs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No results found",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Try a different search term",
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), // Bottom padding for navbar
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        bool showSortInfo = _searchQuery.isNotEmpty || _sortBy != 'title';
                        
                        if (index == 0 && showSortInfo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 8),
                            child: Row(
                              children: [
                                Text(
                                  "${filteredSongs.length} tracks found",
                                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (_sortBy != 'title') ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "By ${_sortBy[0].toUpperCase()}${_sortBy.substring(1)}",
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          );
                        }
                        
                        final itemIndex = showSortInfo ? index - 1 : index;
                        SongModel song = filteredSongs[itemIndex];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Hero(
                                tag: 'artwork_${song.id}',
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: QueryArtworkWidget(
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      artworkFit: BoxFit.cover,
                                      nullArtworkWidget: Container(
                                        color: const Color(0xFF007AFF).withOpacity(0.2),
                                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                song.artist ?? "Unknown Artist",
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                              ),
                              onTap: () {
                                controller.playPlaylist(filteredSongs, itemIndex);
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      childCount: filteredSongs.length + ((_searchQuery.isNotEmpty || _sortBy != 'title') ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

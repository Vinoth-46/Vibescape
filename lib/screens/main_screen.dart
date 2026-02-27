import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';
import '../controllers/stream_controller.dart' as stream;
import '../widgets/mini_player.dart';
import '../widgets/glass_container.dart';
import '../services/app_update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize stream controller after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final streamCtrl = Provider.of<stream.StreamController>(context, listen: false);
      streamCtrl.init();
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final update = await AppUpdateService.checkForUpdate();
    if (update != null && mounted) {
      AppUpdateService.showUpdateDialog(context, update);
    }
  }

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ExploreScreen(),    // Streaming - YouTube Music
    const HomeScreen(),       // Library - Local songs
    const FavoritesScreen(),
    const PlaylistsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          FadeIndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedIndex != 4) const MiniPlayer(),
                _buildFloatingNavBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: GlassContainer(
        height: 70,
        color: Colors.white,
        opacity: 0.6,
        blur: 20,
        borderRadius: BorderRadius.circular(35),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = constraints.maxWidth / 5; // 5 items
            return Stack(
              children: [
                // Sliding animated background indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: _selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Center(
                    child: Container(
                      width: itemWidth * 0.8, // Slightly smaller than the full segment
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                // Navigation icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.explore_outlined, Icons.explore, 'Explore', 0, itemWidth),
                    _buildNavItem(Icons.library_music_outlined, Icons.library_music, 'Library', 1, itemWidth),
                    _buildNavItem(Icons.favorite_border, Icons.favorite, 'Favorites', 2, itemWidth),
                    _buildNavItem(Icons.playlist_play_outlined, Icons.playlist_play, 'Playlists', 3, itemWidth),
                    _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 4, itemWidth),
                  ],
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, double width) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF007AFF) : Colors.black45;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: color,
                size: isSelected ? 28 : 24, // Slight bounce effect on size
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}


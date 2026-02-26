import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/stream_controller.dart' as stream;
import '../controllers/audio_player_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../models/stream_song_model.dart';
import '../widgets/glass_container.dart';
import 'player_screen.dart';
import 'party_mode_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<stream.StreamController>();
      controller.init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B00FF).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B00FF).withOpacity(0.1),
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
                              focusNode: _searchFocusNode,
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
                              onChanged: (value) {
                                final controller = context.read<stream.StreamController>();
                                if (value.isNotEmpty) {
                                  controller.searchSongs(value);
                                } else {
                                  controller.clearSearch();
                                }
                              },
                              onSubmitted: (value) {
                                final controller = context.read<stream.StreamController>();
                                controller.searchSongs(value);
                              },
                            )
                          : const Text(
                              'Explore',
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
                      icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF007AFF)),
                      tooltip: 'Party Mode',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PartyModeScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                        context.read<stream.StreamController>().clearSearch();
                      },
                    ),
                  ],
                ],
              ),
              Consumer<stream.StreamController>(
                builder: (context, controller, _) {
                  if (controller.searchQuery.isNotEmpty || _isSearching && _searchController.text.isNotEmpty) {
                    return _buildSearchResults(controller);
                  }
                  return _buildTrendingSection(controller);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(stream.StreamController controller) {
    if (controller.isSearching) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF007AFF)),
              SizedBox(height: 16),
              Text('Searching the cosmos...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (controller.searchResults.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Try tweaking your search term',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = controller.searchResults[index];
            return _buildSongTile(song, controller);
          },
          childCount: controller.searchResults.length,
        ),
      ),
    );
  }

  Widget _buildTrendingSection(stream.StreamController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Play Genre Chips ──
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickChip('Energize', Icons.bolt_rounded, const Color(0xFFFF6B35)),
                _buildQuickChip('Relax', Icons.spa_rounded, const Color(0xFF4CAF50)),
                _buildQuickChip('Workout', Icons.fitness_center_rounded, const Color(0xFFE91E63)),
                _buildQuickChip('Focus', Icons.headphones_rounded, const Color(0xFF7C4DFF)),
                _buildQuickChip('Commute', Icons.directions_car_rounded, const Color(0xFF00BCD4)),
                _buildQuickChip('Party', Icons.celebration_rounded, const Color(0xFFFF9800)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Recently Played ──
          if (controller.cachedSongs.isNotEmpty) ...[
            _buildYTMusicHeader('Recently Played', Icons.history_rounded),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.cachedSongs.length,
                itemBuilder: (context, index) {
                  final song = controller.cachedSongs[index];
                  return _buildRecentCard(song, controller, isDark);
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Trending Now ──
          _buildYTMusicHeader('Trending Now 🔥', Icons.trending_up_rounded),
          const SizedBox(height: 12),
          if (controller.isLoadingTrending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
            )
          else if (controller.trendingSongs.isEmpty)
            _buildEmptyState(controller)
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.trendingSongs.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final song = controller.trendingSongs[index];
                  return _buildTrendingCard(song, controller, isDark, index);
                },
              ),
            ),
          const SizedBox(height: 28),

          // ── Suggested For You ──
          if (controller.trendingSongs.length > 5) ...[
            _buildYTMusicHeader('Suggested For You', Icons.auto_awesome_rounded),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: controller.trendingSongs
                    .skip(5)
                    .take(8)
                    .map((song) => _buildSuggestedTile(song, controller, isDark))
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Browse & Discover ──
          _buildYTMusicHeader('Browse & Discover', Icons.explore_rounded),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                _buildBrowseCard('Pop Hits', Icons.star_rounded, const Color(0xFFFF6B6B), const Color(0xFFEE5A24)),
                _buildBrowseCard('Hip Hop', Icons.mic_rounded, const Color(0xFF7C4DFF), const Color(0xFF536DFE)),
                _buildBrowseCard('Rock', Icons.electric_bolt_rounded, const Color(0xFFFF9800), const Color(0xFFFF5722)),
                _buildBrowseCard('Classical', Icons.piano_rounded, const Color(0xFF26C6DA), const Color(0xFF0097A7)),
                _buildBrowseCard('EDM', Icons.headphones_rounded, const Color(0xFFE040FB), const Color(0xFFAB47BC)),
                _buildBrowseCard('Chill', Icons.spa_rounded, const Color(0xFF66BB6A), const Color(0xFF388E3C)),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildYTMusicHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF007AFF)),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        final controller = context.read<stream.StreamController>();
        _searchController.text = label;
        setState(() => _isSearching = true);
        controller.searchSongs(label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(StreamSongModel song, stream.StreamController controller, bool isDark) {
    return GestureDetector(
      onTap: () => _playSong(song, controller),
      onLongPress: () => _showSongOptions(song, controller),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    song.thumbnailUrl != null
                        ? CachedNetworkImage(imageUrl: song.thumbnailUrl!, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Center(child: Icon(Icons.music_note_rounded, size: 30))),
                            errorWidget: (_, __, ___) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Center(child: Icon(Icons.music_note_rounded, size: 30))))
                        : Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Center(child: Icon(Icons.music_note_rounded, size: 30))),
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.download_done_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard(StreamSongModel song, stream.StreamController controller, bool isDark, int index) {
    return GestureDetector(
      onTap: () => _playSong(song, controller),
      onLongPress: () => _showSongOptions(song, controller),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: 165,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    song.thumbnailUrl != null
                        ? CachedNetworkImage(imageUrl: song.thumbnailUrl!, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007AFF)))),
                            errorWidget: (_, __, ___) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Center(child: Icon(Icons.music_note_rounded, size: 40))))
                        : Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Center(child: Icon(Icons.music_note_rounded, size: 40))),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)]),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(10)),
                        child: Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3))),
                        child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 2),
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedTile(StreamSongModel song, stream.StreamController controller, bool isDark) {
    final isCached = controller.isCached(song.id);
    return GestureDetector(
      onTap: () => _playSong(song, controller),
      onLongPress: () => _showSongOptions(song, controller),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52, height: 52,
                child: song.thumbnailUrl != null
                    ? CachedNetworkImage(imageUrl: song.thumbnailUrl!, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Icon(Icons.music_note_rounded, size: 20)),
                        errorWidget: (_, __, ___) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Icon(Icons.music_note_rounded, size: 20)))
                    : Container(color: isDark ? Colors.grey[850] : Colors.grey[200], child: const Icon(Icons.music_note_rounded, size: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 3),
                  Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
                ],
              ),
            ),
            if (isCached) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.download_done_rounded, size: 18, color: Color(0xFF007AFF))),
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white30 : Colors.black26, size: 20),
              onPressed: () => _showSongOptions(song, controller),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseCard(String label, IconData icon, Color color1, Color color2) {
    return GestureDetector(
      onTap: () {
        final controller = context.read<stream.StreamController>();
        _searchController.text = label;
        setState(() => _isSearching = true);
        controller.searchSongs(label);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color1, color2]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color1.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(right: -8, bottom: -8, child: Icon(icon, size: 50, color: Colors.white.withOpacity(0.15))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(stream.StreamController controller) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Unable to load trending songs', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                foregroundColor: const Color(0xFF007AFF),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: controller.loadTrendingSongs,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF007AFF)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(StreamSongModel song, stream.StreamController controller, {bool isCached = false}) {
    return GestureDetector(
      onTap: () => _playSong(song, controller),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: 140,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: song.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl!,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.withOpacity(0.1),
                              child: const Center(child: Icon(Icons.music_note_rounded)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.withOpacity(0.1),
                              child: const Center(child: Icon(Icons.music_note_rounded)),
                            ),
                          )
                        : Container(
                            color: Colors.grey.withOpacity(0.1),
                            child: const Center(child: Icon(Icons.music_note_rounded)),
                          ),
                  ),
                  // Play overlay gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isCached)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.download_done_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Artist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(StreamSongModel song, stream.StreamController controller) {
    final isCached = controller.isCached(song.id);
    final isDownloading = controller.isDownloading && controller.currentDownloadId == song.id;
    final favorites = context.watch<FavoritesController>();
    final isFavorite = favorites.isStreamFavorite(song.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.all(4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Hero(
            tag: 'explore_artwork_${song.id}',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: song.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                          child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                          child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
                      ),
              ),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : Colors.grey,
                ),
                onPressed: () => favorites.toggleStreamFavorite(song),
                iconSize: 22,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onPressed: () => _showSongOptions(song, controller),
                iconSize: 22,
              ),
              if (isDownloading)
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: Padding(
                    padding: EdgeInsets.all(6.0),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007AFF)),
                  ),
                )
              else if (isCached)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.download_done_rounded, color: Color(0xFF007AFF), size: 24),
                )
              else
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.grey),
                  onPressed: () => _downloadSong(song, controller),
                  iconSize: 24,
                ),
            ],
          ),
          onTap: () => _playSong(song, controller),
        ),
      ),
    );
  }

  void _showSongOptions(StreamSongModel song, stream.StreamController controller) {
    final favorites = context.read<FavoritesController>();
    final playlists = context.read<PlaylistController>();
    final isFavorite = favorites.isStreamFavorite(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: song.thumbnailUrl != null
                            ? CachedNetworkImage(
                                imageUrl: song.thumbnailUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFF007AFF).withOpacity(0.1),
                                child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(song.artist,
                                maxLines: 1,
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.withOpacity(0.2), height: 32),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: (isFavorite ? Colors.redAccent : const Color(0xFF007AFF)).withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.redAccent : const Color(0xFF007AFF),
                    ),
                  ),
                  title: Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites', style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    favorites.toggleStreamFavorite(song);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
                        backgroundColor: isFavorite ? Colors.grey.shade800 : const Color(0xFF007AFF),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.playlist_add_rounded, color: Color(0xFF007AFF)),
                  ),
                  title: const Text('Add to Playlist', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistDialog(song, playlists);
                  },
                ),
                if (!controller.isCached(song.id))
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.download_rounded, color: Color(0xFF007AFF)),
                    ),
                    title: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _downloadSong(song, controller);
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(StreamSongModel song, PlaylistController playlists) {
    if (playlists.playlists.isEmpty) {
      _showCreatePlaylistDialog(song, playlists);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add to Playlist',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF007AFF)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreatePlaylistDialog(song, playlists);
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.withOpacity(0.2)),
                ...playlists.playlists.asMap().entries.map((entry) {
                  final index = entry.key;
                  final playlist = entry.value;
                  final isInPlaylist = playlists.isInPlaylist(index, song.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
                    ),
                    title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${playlist.totalSongs} tracks', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    trailing: isInPlaylist
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF))
                        : null,
                    onTap: () {
                      if (!isInPlaylist) {
                        playlists.addStreamSongToPlaylist(index, song);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${playlist.name}'),
                            backgroundColor: const Color(0xFF007AFF),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      } else {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Already in ${playlist.name}'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(StreamSongModel song, PlaylistController playlists) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Name your playlist',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF007AFF)),
            ),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await playlists.createPlaylist(controller.text.trim());
                final newIndex = playlists.playlists.length - 1;
                await playlists.addStreamSongToPlaylist(newIndex, song);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "${controller.text.trim()}" and added song'),
                      backgroundColor: const Color(0xFF007AFF),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Consumer<stream.StreamController>(
      builder: (context, controller, _) {
        return InkWell(
          onTap: () {
            setState(() {
              _isSearching = true;
              _searchController.text = label;
            });
            controller.searchSongs(label);
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF007AFF)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _playSong(
      StreamSongModel song, stream.StreamController controller) async {
    final audioController = context.read<AudioPlayerController>();
    
    // Get the stream URL or cached path
    final url = await controller.getStreamUrl(song);
    
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to play this song. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
      return;
    }

    // Play using the audio controller
    await audioController.playStreamSong(song, streamUrl: url);
    
    // Navigate to player 
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  Future<void> _downloadSong(
      StreamSongModel song, stream.StreamController controller) async {
    final success = await controller.downloadSong(song);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${song.title} downloaded successfully!'
                : 'Failed to download ${song.title}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: success ? const Color(0xFF1DB954) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

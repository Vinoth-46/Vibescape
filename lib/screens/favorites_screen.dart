import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/stream_controller.dart' as stream;
import '../models/stream_song_model.dart';
import '../widgets/glass_container.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF007AFF),
            indicatorWeight: 3,
            labelColor: isDarkMode ? Colors.white : Colors.black87,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: 'Local', icon: Icon(Icons.folder_rounded)),
              Tab(text: 'Streaming', icon: Icon(Icons.cloud_rounded)),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background Gradient
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
            // Glow Orbs
            Positioned(
              top: 0,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 100, spreadRadius: 50),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: TabBarView(
                children: [
                  _buildLocalFavorites(context),
                  _buildStreamFavorites(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalFavorites(BuildContext context) {
    return Consumer2<FavoritesController, AudioPlayerController>(
      builder: (context, favorites, audioController, child) {
        final favoriteSongs = audioController.songs
            .where((song) => favorites.isFavorite(song.id.toString()))
            .toList();

        if (favoriteSongs.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.favorite_border_rounded,
            title: 'No Local Favorites',
            subtitle: 'Tap the heart icon on local songs to add them to your collection.',
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildPlayAllButton(context, () {
              audioController.playPlaylist(favoriteSongs, 0);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
            }),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                physics: const BouncingScrollPhysics(),
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(song.artist ?? "Unknown Artist", maxLines: 1, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                        onPressed: () => favorites.toggleFavorite(song.id.toString()),
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: Container(color: const Color(0xFF007AFF).withOpacity(0.2), child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF))),
                          ),
                        ),
                      ),
                      onTap: () {
                        audioController.playPlaylist(favoriteSongs, index);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreamFavorites(BuildContext context) {
    return Consumer3<FavoritesController, AudioPlayerController, stream.StreamController>(
      builder: (context, favorites, audioController, streamController, child) {
        final streamFavorites = favorites.streamFavorites;

        if (streamFavorites.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.cloud_off_rounded,
            title: 'No Streaming Favorites',
            subtitle: 'Explore the cloud and heart your favorite cosmic tunes.',
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildPlayAllButton(context, () async {
              if (streamFavorites.isNotEmpty) {
                final song = streamFavorites.first;
                final url = await streamController.getStreamUrl(song);
                if (url != null) {
                  await audioController.playStreamSong(song, streamUrl: url);
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
                  }
                }
              }
            }),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                physics: const BouncingScrollPhysics(),
                itemCount: streamFavorites.length,
                itemBuilder: (context, index) {
                  final song = streamFavorites[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.thumbnailUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: song.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _buildPlaceholder(),
                                  errorWidget: (_, __, ___) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('STREAM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Expanded(child: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                        onPressed: () => favorites.toggleStreamFavorite(song),
                      ),
                      onTap: () async {
                        final url = await streamController.getStreamUrl(song);
                        if (url != null) {
                          await audioController.playStreamSong(song, streamUrl: url);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayAllButton(BuildContext context, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
        label: const Text('Play All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF007AFF).withOpacity(0.2),
      child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF)),
    );
  }
}

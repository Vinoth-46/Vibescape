import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/audio_player_controller.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove hardcoded background - uses theme
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer2<FavoritesController, AudioPlayerController>(
        builder: (context, favorites, audioController, child) {
          final favoriteSongs = audioController.songs
              .where((song) => favorites.isFavorite(song.id.toString()))
              .toList();

          if (favoriteSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 80, color: Colors.teal),
                  const SizedBox(height: 16),
                  Text(
                    'No Favorites Yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on the player to add favorites',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              return ListTile(
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist ?? "Unknown Artist", maxLines: 1),
                trailing: const Icon(Icons.play_arrow_rounded),
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: const Icon(Icons.music_note, size: 32),
                ),
                onTap: () {
                  audioController.playPlaylist(favoriteSongs, index);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlayerScreen()),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer2<FavoritesController, AudioPlayerController>(
        builder: (context, favorites, audioController, child) {
          final favoriteSongs = audioController.songs
              .where((song) => favorites.isFavorite(song.id.toString()))
              .toList();

          if (favoriteSongs.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              audioController.playPlaylist(favoriteSongs, 0);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            },
            backgroundColor: Colors.teal,
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text("Play All", style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}


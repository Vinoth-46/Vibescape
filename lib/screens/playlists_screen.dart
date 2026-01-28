import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/audio_player_controller.dart';
import 'player_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        centerTitle: true,
      ),
      body: Consumer<PlaylistController>(
        builder: (context, playlistController, child) {
          final playlists = playlistController.playlists;

          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_play, size: 80, color: Colors.teal),
                  const SizedBox(height: 16),
                  Text('No Playlists Yet',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Create one from the Player screen',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), // Space for MiniPlayer
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.teal),
                ),
                title: Text(playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${playlist.songIds.length} Songs'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () {
                    playConfirmDelete(context, playlistController, index);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: playlist),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void playConfirmDelete(
      BuildContext context, PlaylistController controller, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Playlist?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                controller.deletePlaylist(index);
                Navigator.pop(ctx);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final audioController =
        Provider.of<AudioPlayerController>(context, listen: false);
    final allSongs = audioController.songs;

    // Filter songs that are in this playlist
    // We Map IDs to SongModels. If a song ID is not found (deleted), it's skipped.
    final playlistSongs = playlist.songIds
        .map((id) => allSongs.firstWhere(
              (s) => s.id.toString() == id,
              orElse: () => SongModel({'_id': -1}), // Dummy
            ))
        .where((s) => s.id != -1) // Filter out dummys
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
      ),
      body: playlistSongs.isEmpty
          ? const Center(child: Text("Empty Playlist"))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: playlistSongs.length,
              itemBuilder: (context, index) {
                final song = playlistSongs[index];
                return ListTile(
                  leading: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(Icons.music_note, size: 32),
                  ),
                  title: Text(song.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist ?? "Unknown", maxLines: 1),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () {
                    // This creates a queue ONLY with these songs
                    audioController.playPlaylist(playlistSongs, index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  },
                );
              },
            ),
    );
  }
}

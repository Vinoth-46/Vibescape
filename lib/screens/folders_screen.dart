import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/folder_controller.dart';
import '../controllers/audio_player_controller.dart';
import 'player_screen.dart';

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FolderController(),
      child: Scaffold(
        // Remove hardcoded background - uses theme
        appBar: AppBar(
          title: const Text('Folders'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Consumer<FolderController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final folders = controller.folderPaths;

            if (folders.isEmpty) {
              return Center(
                child: Text(
                  "No Music Folders Found",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            }

            return ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final path = folders[index];
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
            );
          },
        ),
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove hardcoded background - uses theme
      appBar: AppBar(
        title: Text(folderName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.play_arrow),
        onPressed: () {
          if (songs.isNotEmpty) {
            Provider.of<AudioPlayerController>(context, listen: false)
                .playPlaylist(songs, 0);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()));
          }
        },
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
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
                  .playPlaylist(songs, index);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()));
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/audio_player_controller.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerController>(
      builder: (context, controller, child) {
        if (!controller.isServiceInitialized) {
          return const SizedBox.shrink();
        }

        final song = controller.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: Container(
            height: 70,
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkHeight: 50,
                  artworkWidth: 50,
                  artworkBorder: BorderRadius.circular(8),
                  nullArtworkWidget: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        song.artist ?? "Unknown Artist",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlayerState>(
                  stream: controller.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;

                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    } else if (playing != true) {
                      return IconButton(
                        onPressed: controller.play,
                        icon: const Icon(Icons.play_arrow_rounded),
                      );
                    } else if (processingState != ProcessingState.completed) {
                      return IconButton(
                        onPressed: controller.pause,
                        icon: const Icon(Icons.pause_rounded),
                      );
                    } else {
                      // Replay
                      return IconButton(
                        onPressed: () => controller.seek(Duration.zero),
                        icon: const Icon(Icons.replay_rounded),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

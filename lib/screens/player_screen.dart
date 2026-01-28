import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../globals.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We need all these controllers
    final audio = Provider.of<AudioPlayerController>(context);
    final favorites = Provider.of<FavoritesController>(context);
    final playlists = Provider.of<PlaylistController>(context);

    // Guard against uninitialized state
    if (!audio.isServiceInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    final currentSong = audio.currentSong;

    return Scaffold(
      extendBodyBehindAppBar: true, // For transparency
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 30),
        ),
        title: const Text("Now Playing", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          _buildSleepTimerBadge(context, audio),
          IconButton(
            onPressed: () => _showSleepTimerBottomSheet(context, audio),
            icon: const Icon(Icons.access_time_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Blurred Background
          _buildBlurredBackground(currentSong),

          // 2. Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Artwork
                            Container(
                              height: 320,
                              width: 320,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: currentSong != null
                                    ? QueryArtworkWidget(
                                        id: currentSong.id,
                                        type: ArtworkType.AUDIO,
                                        artworkBorder: BorderRadius.circular(24),
                                        artworkFit: BoxFit.cover,
                                        nullArtworkWidget: Container(
                                          color: Colors.grey.shade800,
                                          child: const Icon(Icons.music_note,
                                              size: 150, color: Colors.white24),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.music_note,
                                            size: 150, color: Colors.white24),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title and Info Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentSong?.title ?? "No Song Playing",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentSong?.artist ?? "Unknown Artist",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Action Icons
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (currentSong != null) {
                                          _showAddToPlaylistDialog(
                                              context, playlists, currentSong);
                                        }
                                      },
                                      icon: const Icon(Icons.playlist_add,
                                          color: Colors.white),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (currentSong != null) {
                                          favorites.toggleFavorite(
                                              currentSong.id.toString());
                                        }
                                      },
                                      icon: Icon(
                                        (currentSong != null &&
                                                favorites.isFavorite(
                                                    currentSong.id.toString()))
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: (currentSong != null &&
                                                favorites.isFavorite(
                                                    currentSong.id.toString()))
                                            ? Colors.redAccent
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),

                            const Spacer(flex: 2),

                            // Seek Bar
                            StreamBuilder<Duration>(
                              stream: audio.positionStream,
                              builder: (context, snapshot) {
                                final position =
                                    snapshot.data ?? Duration.zero;
                                final duration = audio.duration;
                                return Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                        trackHeight: 2,
                                        thumbShape:
                                            const RoundSliderThumbShape(
                                                enabledThumbRadius: 6),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 12),
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: duration.inMilliseconds
                                            .toDouble(),
                                        value: position.inMilliseconds
                                            .toDouble()
                                            .clamp(
                                                0,
                                                duration.inMilliseconds
                                                    .toDouble()),
                                        onChanged: (value) {
                                          audio.seek(Duration(
                                              milliseconds: value.toInt()));
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatDuration(position),
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  fontSize: 12)),
                                          Text(_formatDuration(duration),
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const Spacer(flex: 2),

                            // Controls
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Shuffle
                                IconButton(
                                  onPressed: audio.toggleShuffle,
                                  icon: Icon(
                                    Icons.shuffle,
                                    color: audio.isShuffleModeEnabled
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                                // Prev
                                IconButton(
                                  onPressed: audio.hasPrevious
                                      ? audio.playPrevious
                                      : null,
                                  icon: const Icon(
                                      Icons.skip_previous_rounded,
                                      color: Colors.white,
                                      size: 36),
                                ),
                                // Play/Pause
                                StreamBuilder<PlayerState>(
                                  stream: audio.playerStateStream,
                                  builder: (context, snapshot) {
                                    final state = snapshot.data;
                                    final isPlaying =
                                        state?.playing ?? false;
                                    final processing =
                                        state?.processingState ??
                                            ProcessingState.idle;

                                    if (processing ==
                                            ProcessingState.buffering ||
                                        processing ==
                                            ProcessingState.loading) {
                                      return Container(
                                        width: 70,
                                        height: 70,
                                        padding: const EdgeInsets.all(20),
                                        child:
                                            const CircularProgressIndicator(
                                                color: Colors.white),
                                      );
                                    }

                                    return Container(
                                      width: 70,
                                      height: 70,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.greenAccent,
                                      ),
                                      child: IconButton(
                                        icon: Icon(isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow_rounded),
                                        color: Colors.black,
                                        iconSize: 40,
                                        onPressed: isPlaying
                                            ? audio.pause
                                            : audio.play,
                                      ),
                                    );
                                  },
                                ),
                                // Next
                                IconButton(
                                  onPressed: audio.hasNext
                                      ? audio.playNext
                                      : null,
                                  icon: const Icon(Icons.skip_next_rounded,
                                      color: Colors.white,
                                      size: 36),
                                ),
                                // Repeat
                                IconButton(
                                  onPressed: audio.toggleLoopMode,
                                  icon: Icon(
                                    _getLoopIcon(audio.loopMode),
                                    color: audio.loopMode != LoopMode.off
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground(SongModel? song) {
    return Stack(
      children: [
        Container(color: Colors.black), // Fallback
        if (song != null)
          Positioned.fill(
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: const SizedBox.shrink(),
            ),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildSleepTimerBadge(
      BuildContext context, AudioPlayerController audio) {
    return StreamBuilder<Duration?>(
      stream: audio.sleepTimerStream,
      builder: (context, snapshot) {
        final remaining = snapshot.data;
        if (remaining == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 8.0, top: 18),
          child: Text(
            "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
            style: const TextStyle(
                color: Colors.greenAccent, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(
      BuildContext context, PlaylistController _, SongModel song) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey.shade900,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          // Use new context
          return Consumer<PlaylistController>(
            builder: (context, playlists, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Add to Playlist",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.add_box_rounded,
                          color: Colors.greenAccent),
                      title: const Text("New Playlist",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        // Close current sheet, open create dialog
                        Navigator.pop(ctx);
                        _showCreatePlaylistDialog(context, playlists, song);
                      },
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: playlists.playlists.length,
                        itemBuilder: (ctx, i) {
                          final playlist = playlists.playlists[i];
                          final inPlaylist =
                              playlist.songIds.contains(song.id.toString());
                          return ListTile(
                            leading: const Icon(Icons.playlist_play,
                                color: Colors.white70),
                            title: Text(playlist.name,
                                style: const TextStyle(color: Colors.white)),
                            trailing: inPlaylist
                                ? const Icon(Icons.check,
                                    color: Colors.greenAccent)
                                : null,
                            onTap: () {
                              if (!inPlaylist) {
                                playlists.addToPlaylist(i, song.id.toString());
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("Added to ${playlist.name}")));
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

  void _showCreatePlaylistDialog(
      BuildContext context, PlaylistController playlists, SongModel song) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title:
            const Text("New Playlist", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Playlist Name",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                final name = textCtrl.text.trim();
                if (name.isNotEmpty) {
                  // Duplicate Check
                  final exists = playlists.playlists.any((p) => p.name == name);
                  if (exists) {
                    // Show error dialog
                    showDialog(
                      context: ctx,
                      builder: (errorCtx) => AlertDialog(
                        backgroundColor: Colors.grey.shade900,
                        title: const Text("Error", style: TextStyle(color: Colors.redAccent)),
                        content: Text("Playlist '$name' already exists.", style: const TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(errorCtx),
                            child: const Text("OK", style: TextStyle(color: Colors.greenAccent)),
                          )
                        ],
                      ),
                    );
                    return; 
                  }

                  // Prevent double clicks / Close Dialog
                  Navigator.pop(ctx); 
                  
                  try {
                    await playlists.createPlaylist(name);
                    
                    // Find the new playlist (last one added)
                    final index = playlists.playlists.length - 1;
                    if (index >= 0) {
                       // Add song to the new playlist
                       await playlists.addToPlaylist(index, song.id.toString());
                       
                       // Use GLOBAL KEY messenger for guaranteed visibility
                       final messenger = rootScaffoldMessengerKey.currentState;
                       if (messenger != null) {
                         messenger.hideCurrentSnackBar();
                         messenger.showSnackBar(SnackBar(
                            content: Text("Playlist '$name' created and song added!"),
                            backgroundColor: Colors.teal,
                            duration: const Duration(seconds: 2),
                         ));
                       }
                    }
                  } catch (e) {
                    debugPrint("Error creating playlist: $e");
                  }
                }
              },
              child: const Text("Create",
                  style: TextStyle(color: Colors.greenAccent))),
        ],
      ),
    );
  }

  void _showSleepTimerBottomSheet(
      BuildContext context, AudioPlayerController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Sleep Timer",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (var m in [5, 10, 15, 30, 60])
                  _buildTimerButton(context, controller, m),
              ]),
              const SizedBox(height: 20),
              if (controller.isSleepTimerActive)
                TextButton(
                  onPressed: () {
                    controller.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                  child: const Text("Stop Timer",
                      style: TextStyle(color: Colors.redAccent)),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerButton(
      BuildContext context, AudioPlayerController controller, int minutes) {
    return ElevatedButton(
      onPressed: () {
        controller.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
      child: Text("$minutes min", style: const TextStyle(color: Colors.white)),
    );
  }

  IconData _getLoopIcon(LoopMode mode) {
    if (mode == LoopMode.one) return Icons.repeat_one;
    return Icons.repeat;
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return "${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
    }
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}

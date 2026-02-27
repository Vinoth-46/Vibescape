import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/party_controller.dart';
import '../widgets/glass_container.dart';
import '../globals.dart';

class PlayerScreen extends StatefulWidget {
  final bool isFromPartyMode;
  
  const PlayerScreen({super.key, this.isFromPartyMode = false});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Cache last known song info to prevent flicker during skip transitions
  String _lastTitle = "No Song Playing";
  String _lastArtist = "Unknown Artist";
  bool _lastIsStreaming = false;

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerController>(context);
    final favorites = Provider.of<FavoritesController>(context);
    final playlists = Provider.of<PlaylistController>(context);
    final party = Provider.of<PartyController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final isGuest = party.isInRoom && !party.isHost;

    if (!audio.isServiceInitialized) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F1016) : Colors.white,
        body: Center(child: CircularProgressIndicator(color: const Color(0xFF007AFF))),
      );
    }

    final currentSong = audio.currentSong;
    final streamSong = audio.currentStreamSong;
    final isStreaming = streamSong != null;

    // Update cached info when we have valid song data
    if (currentSong != null || streamSong != null) {
      _lastTitle = isStreaming ? streamSong!.title : (currentSong?.title ?? _lastTitle);
      _lastArtist = isStreaming ? streamSong!.artist : (currentSong?.artist ?? _lastArtist);
      _lastIsStreaming = isStreaming;
    }

    // Use cached values for display
    final displayTitle = _lastTitle;
    final displayArtist = _lastArtist;

    // Theme-aware colors
    final textPrimary = isDarkMode ? Colors.white : Colors.black87;
    final textSecondary = isDarkMode ? Colors.white60 : Colors.black54;
    final overlayColor = isDarkMode ? Colors.black : Colors.white;
    final overlayOpacity1 = isDarkMode ? 0.5 : 0.3;
    final overlayOpacity2 = isDarkMode ? 0.8 : 0.6;
    final sliderInactive = isDarkMode ? Colors.white12 : Colors.black12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: textPrimary, size: 30),
        ),
        title: Text("Now Playing", style: TextStyle(color: textPrimary)),
        centerTitle: true,
        actions: [
          _buildSleepTimerBadge(context, audio),
          IconButton(
            onPressed: () => _showSleepTimerBottomSheet(context, audio),
            icon: Icon(Icons.access_time_rounded, color: textPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Blurred Background
          if (isStreaming)
            _buildStreamBlurredBackground(streamSong, overlayColor, overlayOpacity2)
          else
            _buildBlurredBackground(currentSong, overlayColor, overlayOpacity2),

          // 2. Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  overlayColor.withOpacity(overlayOpacity1),
                  overlayColor.withOpacity(overlayOpacity2),
                ],
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Artwork
                            Container(
                              height: 320,
                              width: 320,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: _buildArtwork(isStreaming, streamSong, currentSong, isDarkMode),
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
                                      if (isStreaming)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          margin: const EdgeInsets.only(bottom: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF007AFF),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('STREAMING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      Text(
                                        displayTitle,
                                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displayArtist,
                                        style: TextStyle(fontSize: 18, color: textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (!isStreaming) ...[
                                      IconButton(
                                        onPressed: () {
                                          if (currentSong != null) {
                                            _showAddToPlaylistDialog(context, playlists, currentSong);
                                          }
                                        },
                                        icon: Icon(Icons.playlist_add, color: textPrimary, size: 28),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          if (currentSong != null) {
                                            favorites.toggleFavorite(currentSong.id.toString());
                                          }
                                        },
                                        icon: Icon(
                                          (currentSong != null && favorites.isFavorite(currentSong.id.toString()))
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: (currentSong != null && favorites.isFavorite(currentSong.id.toString()))
                                              ? Colors.redAccent
                                              : textPrimary,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              ],
                            ),
                            
                            const SizedBox(height: 30),

                            // Controls Container (Glassmorphism)
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                              borderRadius: BorderRadius.circular(40),
                              child: Column(
                                children: [
                                  // Seek Bar
                                  StreamBuilder<Duration>(
                                    stream: audio.positionStream,
                                    builder: (context, snapshot) {
                                      final position = snapshot.data ?? Duration.zero;
                                      final duration = audio.duration;
                                      return Column(
                                        children: [
                                          SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: const Color(0xFF007AFF),
                                              inactiveTrackColor: sliderInactive,
                                              thumbColor: const Color(0xFF007AFF),
                                              trackHeight: 4,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                            ),
                                            child: Slider(
                                              min: 0,
                                              max: duration.inMilliseconds.toDouble(),
                                              value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                                              onChanged: isGuest ? null : (value) {
                                                audio.seek(Duration(milliseconds: value.toInt()));
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(_formatDuration(position), style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                                                Text(_formatDuration(duration), style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Controls
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        onPressed: audio.toggleShuffle,
                                        icon: Icon(
                                          Icons.shuffle,
                                          color: audio.isShuffleModeEnabled ? const Color(0xFF007AFF) : textSecondary,
                                          size: 26,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: (audio.hasPrevious && !isGuest) ? audio.playPrevious : null,
                                        icon: Icon(Icons.skip_previous_rounded, color: isGuest ? sliderInactive : textPrimary, size: 40),
                                      ),
                                      StreamBuilder<PlayerState>(
                                        stream: audio.playerStateStream,
                                        builder: (context, snapshot) {
                                          final state = snapshot.data;
                                          final isPlaying = state?.playing ?? false;
                                          final processing = state?.processingState ?? ProcessingState.idle;

                                          if (processing == ProcessingState.buffering || processing == ProcessingState.loading) {
                                            return Container(
                                              width: 80, height: 80,
                                              padding: const EdgeInsets.all(24),
                                              child: const CircularProgressIndicator(color: Color(0xFF007AFF)),
                                            );
                                          }

                                          return Container(
                                            width: 80, height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF007AFF),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF007AFF).withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded),
                                              color: Colors.white,
                                              iconSize: 46,
                                              onPressed: isGuest ? null : (isPlaying ? audio.pause : audio.play),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        onPressed: (audio.hasNext && !isGuest) ? audio.playNext : null,
                                        icon: Icon(Icons.skip_next_rounded, color: isGuest ? sliderInactive : textPrimary, size: 40),
                                      ),
                                      IconButton(
                                        onPressed: audio.toggleLoopMode,
                                        icon: Icon(
                                          _getLoopIcon(audio.loopMode),
                                          color: audio.loopMode != LoopMode.off ? const Color(0xFF007AFF) : textSecondary,
                                          size: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _buildArtwork(bool isStreaming, dynamic streamSong, SongModel? currentSong, bool isDarkMode) {
    if (isStreaming && streamSong?.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: streamSong.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildArtworkPlaceholder(isDarkMode),
        errorWidget: (_, __, ___) => _buildArtworkPlaceholder(isDarkMode),
      );
    } else if (currentSong != null) {
      return QueryArtworkWidget(
        id: currentSong.id,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.circular(30),
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _buildArtworkPlaceholder(isDarkMode),
      );
    }
    return _buildArtworkPlaceholder(isDarkMode);
  }

  Widget _buildArtworkPlaceholder(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF1A1C29) : Colors.white,
      child: const Icon(Icons.music_note_rounded, size: 150, color: Color(0xFF007AFF)),
    );
  }

  Widget _buildBlurredBackground(SongModel? song, Color overlayColor, double overlayOpacity) {
    return Stack(
      children: [
        Container(color: overlayColor),
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
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: overlayColor.withOpacity(overlayOpacity)),
        ),
      ],
    );
  }

  Widget _buildStreamBlurredBackground(dynamic song, Color overlayColor, double overlayOpacity) {
    return Stack(
      children: [
        Container(color: overlayColor), 
        if (song != null && song.thumbnailUrl != null)
          Positioned.fill(
            child: Image.network(
              song.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: overlayColor.withOpacity(overlayOpacity)),
        ),
      ],
    );
  }

  Widget _buildSleepTimerBadge(BuildContext context, AudioPlayerController audio) {
    return StreamBuilder<Duration?>(
      stream: audio.sleepTimerStream,
      builder: (context, snapshot) {
        final remaining = snapshot.data;
        if (remaining == null) return const SizedBox.shrink();
        
        final isEndOfTrack = remaining.inSeconds == -1;
        final displayText = isEndOfTrack 
            ? "End of Track" 
            : "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
            
        return Padding(
          padding: const EdgeInsets.only(right: 8.0, top: 18),
          child: Text(
            displayText,
            style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, PlaylistController _, SongModel song) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
        context: context,
        backgroundColor: isDarkMode ? const Color(0xFF1A1C29) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Consumer<PlaylistController>(
            builder: (context, playlists, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Add to Playlist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.add_box_rounded, color: Color(0xFF007AFF)),
                      title: const Text("New Playlist"),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showCreatePlaylistDialog(context, playlists, song);
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: playlists.playlists.length,
                        itemBuilder: (ctx, i) {
                          final playlist = playlists.playlists[i];
                          final inPlaylist = playlist.songIds.contains(song.id.toString());
                          return ListTile(
                            leading: const Icon(Icons.playlist_play),
                            title: Text(playlist.name),
                            trailing: inPlaylist ? const Icon(Icons.check, color: Color(0xFF007AFF)) : null,
                            onTap: () {
                              if (!inPlaylist) {
                                playlists.addToPlaylist(i, song.id.toString());
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to ${playlist.name}")));
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

  void _showCreatePlaylistDialog(BuildContext context, PlaylistController playlists, SongModel song) {
    final textCtrl = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1C29) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("New Playlist", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textCtrl,
          decoration: InputDecoration(
            hintText: "Playlist Name",
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                final exists = playlists.playlists.any((p) => p.name == name);
                if (exists) {
                  showDialog(
                    context: ctx,
                    builder: (errorCtx) => AlertDialog(
                      title: const Text("Error", style: TextStyle(color: Colors.redAccent)),
                      content: Text("Playlist '$name' already exists."),
                      actions: [TextButton(onPressed: () => Navigator.pop(errorCtx), child: const Text("OK"))],
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await playlists.createPlaylist(name);
                  final index = playlists.playlists.length - 1;
                  if (index >= 0) {
                    await playlists.addToPlaylist(index, song.id.toString());
                    final messenger = rootScaffoldMessengerKey.currentState;
                    if (messenger != null) {
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(SnackBar(content: Text("Playlist '$name' created and song added!"), backgroundColor: const Color(0xFF007AFF), duration: const Duration(seconds: 2)));
                    }
                  }
                } catch (e) {
                  debugPrint("Error creating playlist: $e");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerBottomSheet(BuildContext context, AudioPlayerController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1C29) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Sleep Timer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (var m in [5, 10, 15, 30, 60])
                  _buildTimerButton(context, controller, m),
                
                ElevatedButton(
                  onPressed: () {
                    controller.setSleepTimerEndOfTrack();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("End of Track", style: TextStyle(color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 20),
              if (controller.isSleepTimerActive)
                TextButton(
                  onPressed: () {
                    controller.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                  child: const Text("Stop Timer", style: TextStyle(color: Colors.redAccent)),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerButton(BuildContext context, AudioPlayerController controller, int minutes) {
    return ElevatedButton(
      onPressed: () {
        controller.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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

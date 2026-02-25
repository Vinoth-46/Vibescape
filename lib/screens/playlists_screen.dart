import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/stream_controller.dart' as stream;
import '../models/stream_song_model.dart';
import '../widgets/glass_container.dart';
import 'player_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
          const SizedBox(width: 8),
        ],
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
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.1), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Consumer<PlaylistController>(
              builder: (context, playlistController, child) {
                final playlists = playlistController.playlists;

                if (playlists.isEmpty) {
                  return Center(
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
                            child: const Icon(Icons.playlist_add_rounded, size: 48, color: Color(0xFF007AFF)),
                          ),
                          const SizedBox(height: 24),
                          const Text('No Playlists Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('Curate your vibe. Tap + to create your first playlist.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showCreatePlaylistDialog(context),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text('Create Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  physics: const BouncingScrollPhysics(),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final totalSongs = playlist.totalSongs;
                    final hasStreaming = playlist.streamSongs.isNotEmpty;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: hasStreaming 
                                  ? [const Color(0xFF007AFF), const Color(0xFF00C6FF)]
                                  : [const Color(0xFF6B00FF), const Color(0xFFB100FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: (hasStreaming ? const Color(0xFF007AFF) : const Color(0xFF6B00FF)).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            if (hasStreaming)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3)),
                                ),
                                child: const Text('HYBRID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('$totalSongs Tracks', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _showConfirmDelete(context, playlistController, index),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist, playlistIndex: index)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Name your vibe...',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<PlaylistController>().createPlaylist(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDelete(BuildContext context, PlaylistController controller, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Playlist?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("This spatial collection will be wiped from memory. Cannot be undone.", style: TextStyle(color: Colors.grey, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(foregroundColor: Colors.grey), child: const Text("Keep")),
          ElevatedButton(
            onPressed: () {
              controller.deletePlaylist(index);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  final int playlistIndex;
  
  const PlaylistDetailScreen({
    super.key, 
    required this.playlist,
    required this.playlistIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [const Color(0xFF004488).withOpacity(0.4), const Color(0xFF0F1016), const Color(0xFF0F1016)]
                      : [const Color(0xFF88CCFF).withOpacity(0.5), const Color(0xFFF2F6FA), const Color(0xFFF2F6FA)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Consumer2<AudioPlayerController, stream.StreamController>(
              builder: (context, audioController, streamController, child) {
                final allSongs = audioController.songs;

                // Get local songs
                final localSongs = playlist.songIds
                    .map((id) => allSongs.firstWhere((s) => s.id.toString() == id, orElse: () => SongModel({'_id': -1})))
                    .where((s) => s.id != -1)
                    .toList();

                // Get streaming songs
                final streamingSongs = playlist.streamSongs;

                if (localSongs.isEmpty && streamingSongs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_music_rounded, size: 80, color: const Color(0xFF007AFF).withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text("Empty Canvas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Add tracks from Explore or Library.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Play All Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => _playAll(context, localSongs, streamingSongs, audioController, streamController),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                        label: const Text('Play All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 0,
                          shadowColor: const Color(0xFF007AFF).withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    
                    // Local Songs Section
                    if (localSongs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Local Audio (${localSongs.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      ...localSongs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final song = entry.value;
                        return _buildSongTile(
                          context: context,
                          id: song.id,
                          title: song.title,
                          artist: song.artist,
                          isStream: false,
                          onTap: () {
                            audioController.clearStreamSong();
                            audioController.playPlaylist(localSongs, index);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                          },
                        );
                      }),
                    ],
                    
                    if (localSongs.isNotEmpty && streamingSongs.isNotEmpty)
                      const SizedBox(height: 16),
                    
                    // Streaming Songs Section
                    if (streamingSongs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Cloud Streams (${streamingSongs.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      ...streamingSongs.map((song) {
                        return _buildSongTile(
                          context: context,
                          title: song.title,
                          artist: song.artist,
                          thumbnailUrl: song.thumbnailUrl,
                          isStream: true,
                          onTap: () async {
                            final url = await streamController.getStreamUrl(song);
                            if (url != null && context.mounted) {
                              await audioController.playStreamSong(song, streamUrl: url);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                            }
                          },
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile({
    required BuildContext context,
    int? id,
    String? thumbnailUrl,
    required String title,
    String? artist,
    required bool isStream,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isStream
                ? (thumbnailUrl != null
                    ? CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover, placeholder: (_, __) => _buildPlaceholder(), errorWidget: (_, __, ___) => _buildPlaceholder())
                    : _buildPlaceholder())
                : QueryArtworkWidget(id: id!, type: ArtworkType.AUDIO, artworkFit: BoxFit.cover, nullArtworkWidget: _buildPlaceholder()),
          ),
        ),
        title: Row(
          children: [
            if (isStream)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(4)),
                child: const Text('STREAM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          ],
        ),
        subtitle: Text(artist ?? "Unknown", maxLines: 1, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, size: 20),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _playAll(
    BuildContext context,
    List<SongModel> localSongs,
    List<StreamSongModel> streamingSongs,
    AudioPlayerController audioController,
    stream.StreamController streamController,
  ) async {
    if (localSongs.isNotEmpty) {
      audioController.clearStreamSong();
      audioController.playPlaylist(localSongs, 0);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
    } else if (streamingSongs.isNotEmpty) {
      final song = streamingSongs.first;
      final url = await streamController.getStreamUrl(song);
      if (url != null && context.mounted) {
        await audioController.playStreamSong(song, streamUrl: url);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF007AFF).withOpacity(0.2),
      child: const Icon(Icons.music_note_rounded, color: Color(0xFF007AFF), size: 20),
    );
  }
}

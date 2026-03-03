import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/audio_player_controller.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _hasAppeared = false;

  // Cache last known song info to prevent flicker during transitions
  String? _lastTitle;
  String? _lastArtist;
  String? _lastThumbnailUrl;
  int? _lastLocalSongId;
  bool _lastIsStreaming = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AudioPlayerController>(
      builder: (context, controller, child) {
        if (!controller.isServiceInitialized) {
          return const SizedBox.shrink();
        }

        final streamSong = controller.currentStreamSong;
        final localSong = controller.currentSong;

        // Update cached info when we have valid song data
        if (streamSong != null || localSong != null) {
          final isStreaming = streamSong != null;
          _lastTitle = isStreaming ? streamSong.title : localSong!.title;
          _lastArtist = isStreaming
              ? streamSong.artist
              : (localSong!.artist ?? "Unknown Artist");
          _lastThumbnailUrl = isStreaming ? streamSong.thumbnailUrl : null;
          _lastLocalSongId = isStreaming ? null : localSong!.id;
          _lastIsStreaming = isStreaming;
        }

        // If no song has ever played, hide the mini player
        if (_lastTitle == null) {
          return const SizedBox.shrink();
        }

        // Only animate slide-up on first appearance
        if (!_hasAppeared) {
          _hasAppeared = true;
          _slideController.forward();
        }

        final title = _lastTitle!;
        final artist = _lastArtist ?? "Unknown Artist";
        final thumbnailUrl = _lastThumbnailUrl;
        final localSongId = _lastLocalSongId;
        final isStreaming = _lastIsStreaming;

        return SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const PlayerScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                      child: c,
                    ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1A1C2E).withOpacity(0.95),
                          const Color(0xFF0F1016).withOpacity(0.98),
                        ]
                      : [
                          Colors.white.withOpacity(0.92),
                          const Color(0xFFF0F2F8).withOpacity(0.95),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Progress Bar at top, outside BackdropFilter to prevent battery drain
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: StreamBuilder<Duration>(
                      stream: controller.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = controller.duration;
                        final progress = duration.inMilliseconds > 0
                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final barWidth = constraints.maxWidth * progress;
                            return SizedBox(
                              height: 3,
                              child: Stack(
                                children: [
                                  // Background track
                                  Container(
                                    width: double.infinity,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.04),
                                    ),
                                  ),
                                  // Progress fill — always starts from left
                                  Container(
                                    width: barWidth,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF007AFF),
                                          Color(0xFF00D4FF),
                                        ],
                                      ),
                                      boxShadow: progress > 0
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF007AFF).withOpacity(0.6),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Main content inside BackdropFilter
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Row(
                          children: [
                            // Album Art with glow
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _buildArtwork(isStreaming, thumbnailUrl, localSongId, isDark),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title & Artist
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isStreaming)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF007AFF), Color(0xFF00D4FF)],
                                            ),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : Colors.black87,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Skip Previous
                                _buildControlButton(
                                  icon: Icons.skip_previous_rounded,
                                  size: 22,
                                  onPressed: controller.hasPrevious ? controller.playPrevious : null,
                                  isDark: isDark,
                                ),

                                // Play/Pause (primary)
                                StreamBuilder<PlayerState>(
                                  stream: controller.playerStateStream,
                                  builder: (context, snapshot) {
                                    final state = snapshot.data;
                                    final processing = state?.processingState;
                                    final playing = state?.playing ?? false;

                                    if (processing == ProcessingState.loading ||
                                        processing == ProcessingState.buffering) {
                                      return Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation(Color(0xFF007AFF)),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF007AFF), Color(0xFF0055CC)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF007AFF).withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: playing ? controller.pause : controller.play,
                                          child: Icon(
                                            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Skip Next
                                _buildControlButton(
                                  icon: Icons.skip_next_rounded,
                                  size: 22,
                                  onPressed: controller.hasNext ? controller.playNext : null,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onPressed,
          child: Icon(
            icon,
            size: size,
            color: onPressed != null
                ? (isDark ? Colors.white70 : Colors.black54)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(bool isStreaming, String? thumbnailUrl, int? localSongId, bool isDark) {
    if (isStreaming && thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholder(isDark),
        errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
      );
    } else if (localSongId != null) {
      return QueryArtworkWidget(
        id: localSongId,
        type: ArtworkType.AUDIO,
        artworkHeight: 48,
        artworkWidth: 48,
        artworkBorder: BorderRadius.circular(14),
        nullArtworkWidget: _buildPlaceholder(isDark),
      );
    }
    return _buildPlaceholder(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1C2E), const Color(0xFF2A2D42)]
              : [const Color(0xFFE8EAF0), const Color(0xFFD0D4E0)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: const Color(0xFF007AFF).withOpacity(0.7),
        size: 22,
      ),
    );
  }
}

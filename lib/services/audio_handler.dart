import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../services/jiosaavn_music_service.dart';
import '../services/youtube_music_service.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.vibescape.app.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  
  bool _isStreamingQueue = false;
  List<dynamic>? _streamingPlaylist;

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // Broadcast initial state so the service doesn't get killed
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      processingState: AudioProcessingState.idle,
    ));

    // Listen to playback events and broadcast state
    player.playbackEventStream.listen(_broadcastState);

    // Eagerly resolve next items for seamless gapless playback without ExoPlayer errors
    player.currentIndexStream.listen((index) {
       if (_isStreamingQueue && _streamingPlaylist != null && index != null) {
          if (index + 1 < _streamingPlaylist!.length) {
             _resolveAndReplaceSource(index + 1);
          }
       }
    });

    // Automatically skip to next when song completes
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (player.hasNext) {
          skipToNext();
        } else {
          // If playlist ends, stop.
          stop();
        }
      }
    });

    // Sync Sequence/Queue
    player.sequenceStateStream.listen((state) {
      final sequence = state?.sequence ?? [];
      final queue = sequence.map((s) => s.tag as MediaItem).toList();
      this.queue.add(queue);

      final currentItem = state?.currentSource?.tag as MediaItem?;
      mediaItem.add(currentItem);
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    final queueIndex = event.currentIndex;
    debugPrint("MyAudioHandler: Broadcasting state. Playing: $playing, ProcessingState: ${player.processingState}, Title: ${mediaItem.value?.title}");

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // Prev, Play/Pause, Next
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: queueIndex,
    ));
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    // Reset state to idle/stopped
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> skipToNext() async {
    if (_isStreamingQueue && _streamingPlaylist != null) {
       final currentIndex = player.currentIndex;
       if (currentIndex != null && currentIndex + 1 < _streamingPlaylist!.length) {
          await _resolveAndReplaceSource(currentIndex + 1);
       }
    }
    if (player.hasNext) {
      await player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isStreamingQueue && _streamingPlaylist != null) {
       final currentIndex = player.currentIndex;
       if (currentIndex != null && currentIndex - 1 >= 0) {
          await _resolveAndReplaceSource(currentIndex - 1);
       }
    }
    if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      await player.seek(Duration.zero);
    }
  }

  Future<void> _resolveAndReplaceSource(int index) async {
    try {
      if (_streamingPlaylist == null || index < 0 || index >= _streamingPlaylist!.length) return;
      
      final songData = _streamingPlaylist![index] as Map<String, dynamic>;
      final id = songData['id']?.toString() ?? '';
      final sourceStr = songData['source'] as String?;
      
      final currentSource = player.audioSource;
      if (currentSource is ConcatenatingAudioSource) {
         final item = currentSource.sequence[index];
         if (item is UriAudioSource) {
           final uriString = item.uri.toString();
           // Only resolve if it's our placeholder
           if (uriString.contains('placeholder-for-lazy-load')) {
             debugPrint("MyAudioHandler: Lazily resolving URL for $id...");
             String? newUrl;
             if (sourceStr == 'jiosaavn') {
                newUrl = await JioSaavnMusicService().getStreamUrl(id);
             } else {
                newUrl = await YouTubeMusicService().getStreamUrl(id);
             }
             
             if (newUrl != null) {
                final newSource = AudioSource.uri(Uri.parse(newUrl), tag: item.tag);
                await currentSource.removeAt(index);
                await currentSource.insert(index, newSource);
                debugPrint("MyAudioHandler: Successfully resolved URL for index $index");
             }
           }
         }
      }
    } catch (e) {
      debugPrint("MyAudioHandler: Error lazily resolving source: $e");
    }
  }

  Future<void> setPlaylist(List<AudioSource> sources, int initialIndex) async {
    debugPrint(
        "MyAudioHandler: setPlaylist called with ${sources.length} sources, index $initialIndex");
    if (sources.isEmpty) {
      debugPrint("MyAudioHandler: Empty sources list, returning");
      return;
    }
    
    try {
      final playlist = ConcatenatingAudioSource(children: sources);
      await player.setAudioSource(playlist, initialIndex: initialIndex);
      debugPrint("MyAudioHandler: setAudioSource completed successfully");
    } catch (e, stack) {
      debugPrint("MyAudioHandler: Error setting playlist: $e");
      debugPrint("Stack: $stack");
      // Broadcast error state
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
    }
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'reorder') {
      final oldIndex = extras?['oldIndex'] as int?;
      final newIndex = extras?['newIndex'] as int?;
      if (oldIndex != null && newIndex != null) {
        final currentSource = player.audioSource;
        if (currentSource is ConcatenatingAudioSource) {
           // Move item in the audio source
           await currentSource.move(oldIndex, newIndex);
        }
      }
    } else if (name == 'setStreamingQueue') {
       _isStreamingQueue = extras?['isStreamingQueue'] == true;
       _streamingPlaylist = extras?['playlist'] as List<dynamic>?;
       debugPrint("MyAudioHandler: Received streaming queue of length ${_streamingPlaylist?.length}");
    }
  }

  // Method to support shuffle
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await player.setShuffleModeEnabled(enabled);
  }

  // Method to support repeat
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    LoopMode mode = LoopMode.off;
    switch (repeatMode) {
      case AudioServiceRepeatMode.all:
        mode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.one:
        mode = LoopMode.one;
        break;
      default:
        mode = LoopMode.off;
        break;
    }
    await player.setLoopMode(mode);
  }
}

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.example.offline_music_player.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'ic_launcher',
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

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
    _player.playbackEventStream.listen(_broadcastState);

    // Automatically skip to next when song completes
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_player.hasNext) {
          skipToNext();
        } else {
          // If playlist ends, stop.
          stop();
        }
      }
    });

    // Sync Sequence/Queue
    _player.sequenceStateStream.listen((state) {
      final sequence = state?.sequence ?? [];
      final queue = sequence.map((s) => s.tag as MediaItem).toList();
      this.queue.add(queue);

      final currentItem = state?.currentSource?.tag as MediaItem?;
      mediaItem.add(currentItem);
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final queueIndex = event.currentIndex;
    debugPrint("MyAudioHandler: Broadcasting state. Playing: $playing, ProcessingState: ${_player.processingState}, Title: ${mediaItem.value?.title}");

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
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
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queueIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    // Reset state to idle/stopped
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> setPlaylist(List<AudioSource> sources, int initialIndex) async {
    debugPrint(
        "MyAudioHandler: setPlaylist called with ${sources.length} sources, index $initialIndex");
    try {
      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist, initialIndex: initialIndex);
      debugPrint("MyAudioHandler: setAudioSource completed successfully");
    } catch (e) {
      debugPrint("MyAudioHandler: Error setting playlist: $e");
      // Broadcast error state if possible, or at least stop 'loading'
    }
  }

  // Method to support shuffle
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
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
    await _player.setLoopMode(mode);
  }
}

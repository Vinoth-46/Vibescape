import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_handler.dart';
import '../services/sleep_timer_service.dart';
import '../services/folder_selection_service.dart';
import '../models/stream_song_model.dart';
import '../services/youtube_music_service.dart';
import '../services/jiosaavn_music_service.dart';

class AudioPlayerController extends ChangeNotifier {
  // Lazy initialization of OnAudioQuery
  OnAudioQuery? _audioQueryInstance;
  OnAudioQuery get _audioQuery {
    _audioQueryInstance ??= OnAudioQuery();
    return _audioQueryInstance!;
  }

  // Injected AudioHandler (Nullable for fallback)
  final AudioHandler? _audioHandler;
  AudioHandler? get handler => _audioHandler;

  // Is the service ready?
  bool get isServiceInitialized => _audioHandler != null;

  // Sleep Timer
  final SleepTimerService _sleepTimerService = SleepTimerService();
  Stream<Duration?> get sleepTimerStream =>
      _sleepTimerService.remainingTimeStream;
  bool get isSleepTimerActive => _sleepTimerService.isActive;

  // Permissions & State
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  bool _libraryLoaded = false;

  List<SongModel> _songs = [];
  List<SongModel> get songs => _songs;

  // Streams - Route directly from AudioService (with null safety)
  Stream<Duration>? _positionStream;

  Stream<Duration> get positionStream {
    if (_audioHandler == null) return Stream.value(Duration.zero);
    _positionStream ??= Stream.periodic(
      const Duration(milliseconds: 200),
      (_) => _audioHandler!.playbackState.value.updatePosition,
    ).asBroadcastStream(
      onListen: (sub) => sub.resume(),
      onCancel: (sub) => sub.pause(),
    );
    return _positionStream!;
  }
  
  Duration get position => _audioHandler?.playbackState.value.updatePosition ?? Duration.zero;
  bool get isPlaying => _audioHandler?.playbackState.value.playing ?? false;

  Stream<PlayerState> get playerStateStream {
    if (_audioHandler == null) {
      return Stream.value(PlayerState(false, ProcessingState.idle));
    }
    return _audioHandler!.playbackState.map((state) {
      final processingState = {
            AudioProcessingState.idle: ProcessingState.idle,
            AudioProcessingState.loading: ProcessingState.loading,
            AudioProcessingState.buffering: ProcessingState.buffering,
            AudioProcessingState.ready: ProcessingState.ready,
            AudioProcessingState.completed: ProcessingState.completed,
            AudioProcessingState.error: ProcessingState.idle,
          }[state.processingState] ??
          ProcessingState.idle;
      return PlayerState(state.playing, processingState);
    });
  }

  SongModel? get currentLocalSong {
    final mediaItem = _audioHandler?.mediaItem.value;
    if (mediaItem == null) return null;
    try {
      return _songs.firstWhere((s) => s.id.toString() == mediaItem.id);
    } catch (_) {
      return null;
    }
  }

  // Unified current playing song for UI
  bool get isPlayingStream {
    final mediaItem = _audioHandler?.mediaItem.value;
    if (mediaItem == null) return false;
    return mediaItem.extras?['isStream'] == true;
  }
  
  dynamic get currentPlayingSong => isPlayingStream ? currentStreamSong : currentLocalSong;

  // For backward compatibility until UI is fully swapped
  SongModel? get currentSong => currentLocalSong;

  // Queue/Shuffle/Loop
  Stream<List<MediaItem>> get queueStream =>
      _audioHandler?.queue ?? Stream.value([]);
      
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_audioHandler == null) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    await _audioHandler!.customAction('reorder', {
      'oldIndex': oldIndex,
      'newIndex': newIndex,
    });
  }

  bool _isShuffleModeEnabled = false;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;

  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  bool get hasNext => true;
  bool get hasPrevious => true;

  Duration get duration =>
      _audioHandler?.mediaItem.value?.duration ?? Duration.zero;

  // Primary constructor
  AudioPlayerController(AudioHandler handler, {OnAudioQuery? audioQuery})
      : _audioHandler = handler,
        _audioQueryInstance = audioQuery {
    debugPrint("AudioPlayerController: Created with injected handler");
    _sleepTimerService.onTimerEnd = () => pause();
    // Listen to streams to trigger UI updates immediately
    _audioHandler?.mediaItem.listen((_) => notifyListeners());
    _audioHandler?.playbackState.listen((_) => notifyListeners());

    // Stop at end of track logic
    String? previousMediaId;
    _audioHandler?.mediaItem.listen((item) async {
      if (item != null) {
        if (previousMediaId != null && previousMediaId != item.id) {
          // Track changed
          if (_sleepTimerService.isEndOfTrack) {
            pause();
            cancelSleepTimer();
          }
        }
        previousMediaId = item.id;
        
        // INFINITE RADIO TRIGGER
        if (item.extras?['isStream'] == true && !_isFetchingRadio) {
           final queue = _audioHandler?.queue.value ?? [];
           if (queue.isNotEmpty) {
             final currentIdx = queue.indexWhere((q) => q.id == item.id);
             // If we are at the last or second to last song, fetch radio continuously!
             if (currentIdx != -1 && currentIdx >= queue.length - 2) {
                _isFetchingRadio = true;
                debugPrint("AudioPlayerController: Approaching end of queue, fetching Infinite Radio...");
                try {
                   final recommended = await JioSaavnMusicService().getSimilarSongs(item.id);
                   if (recommended.isNotEmpty) {
                      // Filter out songs already in the queue to prevent looping the exact same songs
                      final existingIds = queue.map((q) => q.id).toSet();
                      final fresh = recommended.where((r) => !existingIds.contains(r.id)).toList();
                      
                      if (fresh.isNotEmpty) {
                         debugPrint("AudioPlayerController: Appending ${fresh.length} fresh similar songs.");
                         final freshJson = fresh.map((s) => s.toJson()).toList();
                         await _audioHandler?.customAction('appendStreamingQueue', {
                            'playlist': freshJson,
                         });
                      }
                   }
                } catch (e) {
                   debugPrint("AudioPlayerController: Radio fetch error: $e");
                } finally {
                   _isFetchingRadio = false;
                }
             }
           }
        }
      }
    });
  }

  bool _isFetchingRadio = false;

  // Dummy factory for when AudioService fails
  AudioPlayerController.dummy() : _audioHandler = null {
    debugPrint(
        "AudioPlayerController: Created in DUMMY mode (no audio service)");
    _sleepTimerService.onTimerEnd = () => pause();
  }

  // CALLED BY UI ONLY AFTER PERMISSION SERVICE CONFIRMS
  Future<void> onPermissionGranted() async {
    _hasPermission = true;
    // Only load if not already loaded
    if (!_libraryLoaded) {
      await _loadSongs();
      _libraryLoaded = true;
    }
    notifyListeners();
  }

  Future<void> _loadSongs() async {
    // Double check just in case, or just trust the caller
    if (!_hasPermission) return;
    final prefs = await SharedPreferences.getInstance();
    final minDuration = prefs.getInt('min_duration') ?? 30000;
    await fetchSongs(minDuration: minDuration);
  }

  Future<void> fetchSongs({int minDuration = 30000}) async {
    if (!_hasPermission) {
      debugPrint("fetchSongs: No permission yet.");
      return;
    }

    if (kIsWeb) {
      debugPrint("fetchSongs: Web detected, returning dummy data.");
      _songs = List.generate(
        10,
        (index) => SongModel({
          "_id": index,
          "title": "Dummy Song ${index + 1}",
          "artist": "Artist ${index + 1}",
          "album": "Album ${index + 1}",
          "duration": 180000,
          // Use a reliable test URL (Luan.xyz example)
          "_data": "https://luan.xyz/files/audio/ambient_c_motion.mp3",
        }),
      );
      notifyListeners();
      return;
    }

    try {
      debugPrint("fetchSongs: Querying songs with minDuration: $minDuration");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('min_duration', minDuration);

      final allSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Filter by duration
      var filteredSongs = allSongs.where((song) => (song.duration ?? 0) > minDuration).toList();
      
      // Filter by selected folders
      final folderService = FolderSelectionService();
      final selectedFolders = await folderService.getSelectedFolders();
      
      if (selectedFolders.isNotEmpty) {
        debugPrint("fetchSongs: Filtering by ${selectedFolders.length} selected folders");
        filteredSongs = filteredSongs.where((song) {
          final songFolder = song.data.substring(0, song.data.lastIndexOf('/'));
          return selectedFolders.contains(songFolder);
        }).toList();
      }
      
      _songs = filteredSongs;
      debugPrint(
          "fetchSongs: Found ${_songs.length} songs (filtered from ${allSongs.length})");
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching songs: $e");
    }
  }

  Future<void> refreshLibrary({int minDuration = 30000}) async {
    debugPrint("refreshLibrary called");
    await fetchSongs(minDuration: minDuration);
  }

  Future<void> playPlaylist(List<SongModel> songs, int index) async {
    if (_audioHandler == null) {
      debugPrint("AudioPlayerController: Handler is null, cannot play");
      return;
    }
    
    if (songs.isEmpty) {
      debugPrint("AudioPlayerController: No songs to play");
      return;
    }

    // Clear any streaming state since we are switching to offline playback
    clearStreamSong();

    try {
      debugPrint("AudioPlayerController: playPlaylist called with ${songs.length} songs, starting at index $index");
      
      final sources = <AudioSource>[];
      
      for (var s in songs) {
        try {
          final String filePath = s.data;
          
          if (filePath.isEmpty) {
            debugPrint("AudioPlayerController: Skipping song with empty path: ${s.title}");
            continue;
          }
          
          // Skip HTTP URLs for local music player - only process local files
          if (filePath.startsWith('http')) {
            debugPrint("AudioPlayerController: Skipping remote URL: ${s.title}");
            continue;
          }
          
          // Validate file exists before adding to playlist
          final file = File(filePath);
          if (!await file.exists()) {
            debugPrint("AudioPlayerController: File not found, skipping: $filePath");
            continue;
          }
          
          Uri? artworkUri;
          if (s.albumId != null) {
            artworkUri = Uri.parse("content://media/external/audio/albumart/${s.albumId}");
          }

          final mediaItem = MediaItem(
            id: s.id.toString(),
            album: s.album ?? "Unknown Album",
            title: s.title,
            artist: s.artist ?? "Unknown Artist",
            duration: Duration(milliseconds: s.duration ?? 0),
            artUri: artworkUri,
            extras: {'url': filePath},
          );

          // Use Uri.file() for proper file:// URI conversion
          final fileUri = Uri.file(filePath);
          debugPrint("AudioPlayerController: Adding file source: $fileUri");
          sources.add(AudioSource.uri(fileUri, tag: mediaItem));
        } catch (e) {
          debugPrint("AudioPlayerController: Error processing song ${s.title}: $e");
          // Continue with next song instead of crashing
          continue;
        }
      }

      if (sources.isEmpty) {
        debugPrint("AudioPlayerController: No valid sources created");
        return;
      }

      // Adjust index if songs were skipped
      final safeIndex = index.clamp(0, sources.length - 1);

      if (_audioHandler is MyAudioHandler) {
        final handler = _audioHandler as MyAudioHandler;
        await handler.setPlaylist(sources, safeIndex);
        await handler.play();
        debugPrint("AudioPlayerController: playPlaylist completed successfully");
      }
    } catch (e, stack) {
      debugPrint("AudioPlayerController: Error playing song: $e");
      debugPrint("Stack trace: $stack");
      // Don't rethrow - just log the error to prevent app crash
    }
  }

  void play() => _audioHandler?.play();

  void pause() {
    _audioHandler?.pause();
    if (isSleepTimerActive) cancelSleepTimer();
  }

  void stop() {
    _audioHandler?.stop();
    if (isSleepTimerActive) cancelSleepTimer();
  }

  void seek(Duration position) => _audioHandler?.seek(position);

  void playNext() => _audioHandler?.skipToNext();

  void playPrevious() => _audioHandler?.skipToPrevious();

  void setSleepTimer(Duration duration) {
    _sleepTimerService.setTimer(duration);
    notifyListeners();
  }

  void setSleepTimerEndOfTrack() {
    _sleepTimerService.setEndOfTrack();
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimerService.cancelTimer();
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    if (_audioHandler is MyAudioHandler) {
      final handler = _audioHandler as MyAudioHandler;
      await handler.setShuffleMode(_isShuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none);
    }
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    const modes = [LoopMode.off, LoopMode.all, LoopMode.one];
    final nextIndex = (modes.indexOf(_loopMode) + 1) % modes.length;
    _loopMode = modes[nextIndex];

    if (_audioHandler is MyAudioHandler) {
      AudioServiceRepeatMode asMode;
      switch (_loopMode) {
        case LoopMode.off:
          asMode = AudioServiceRepeatMode.none;
          break;
        case LoopMode.one:
          asMode = AudioServiceRepeatMode.one;
          break;
        case LoopMode.all:
          asMode = AudioServiceRepeatMode.all;
          break;
      }
      final handler = _audioHandler as MyAudioHandler;
      await handler.setRepeatMode(asMode);
    }
    notifyListeners();
  }

  // Current streaming song for display purposes
  StreamSongModel? get currentStreamSong {
    final mediaItem = _audioHandler?.mediaItem.value;
    if (mediaItem == null || mediaItem.extras?['isStream'] != true) return null;
    
    final src = mediaItem.extras?['source'] as String? ?? 'jiosaavn';
    
    if (src == 'youtube') {
      return StreamSongModel.fromYouTube(
         videoId: mediaItem.id,
         title: mediaItem.title,
         artist: mediaItem.artist ?? "Unknown",
         thumbnailUrl: mediaItem.artUri?.toString(),
         duration: mediaItem.duration ?? Duration.zero,
      );
    }
    
    return StreamSongModel.fromJioSaavn(
       songId: mediaItem.id,
       title: mediaItem.title,
       artist: mediaItem.artist ?? "Unknown",
       thumbnailUrl: mediaItem.artUri?.toString(),
       duration: mediaItem.duration ?? Duration.zero,
    );
  }

  /// Play a streaming song from YouTube
  Future<void> playStreamSong(StreamSongModel song, {String? streamUrl, bool autoPlay = true, List<StreamSongModel>? playlist}) async {
    if (_audioHandler == null) {
      debugPrint("AudioPlayerController: Handler is null, cannot play stream");
      return;
    }

    try {
      debugPrint("AudioPlayerController: Playing stream: ${song.title}");
      notifyListeners();
      
      // Create MediaItem for the stream
      final mediaItem = MediaItem(
        id: song.id,
        album: song.album ?? "Streaming Music",
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: song.thumbnailUrl != null ? Uri.parse(song.thumbnailUrl!) : null,
        extras: {'isStream': true},
      );

      // Determine the audio source to play
      AudioSource source;
      
      String? finalUrl = streamUrl;

      // Get fresh URL if not provided directly (e.g., when a guest joins a Party Room)
      if (finalUrl == null || finalUrl.isEmpty) {
        if (song.source == 'jiosaavn') {
          debugPrint("AudioPlayerController: Fetching stream URL for JioSaavn song ${song.id}...");
          finalUrl = await JioSaavnMusicService().getStreamUrl(song.id);
        } else {
          debugPrint("AudioPlayerController: Fetching stream URL for YouTube song ${song.id}...");
          finalUrl = await YouTubeMusicService().getStreamUrl(song.id);
        }
      }

      if (finalUrl == null) {
        debugPrint("AudioPlayerController: Failed to get stream URL for ${song.title}");
        notifyListeners();
        return;
      }

      // Check if there's a local cached file already provided
      if (!finalUrl.startsWith('http')) {
        debugPrint("AudioPlayerController: Playing from cache: $finalUrl");
        source = AudioSource.uri(Uri.file(finalUrl), tag: mediaItem);
      } else {
        debugPrint("AudioPlayerController: Playing stream directly");
        source = AudioSource.uri(Uri.parse(finalUrl), tag: mediaItem);
      }

      if (_audioHandler is MyAudioHandler) {
        final handler = _audioHandler as MyAudioHandler;
        
        List<StreamSongModel> activeQueue = playlist ?? [song];
        
        // Find index of chosen song in playlist, default 0
        int initialIndex = activeQueue.indexWhere((s) => s.id == song.id);
        if (initialIndex == -1) initialIndex = 0;
        
        debugPrint("AudioPlayerController: Loading playlist of ${activeQueue.length} songs at index $initialIndex");
        
        // CRITICAL FIX: Fetch fresh URLs lazily when skipping
        final sources = activeQueue.map((s) {
          String tempUrl = s.cachedPath ?? 'https://example.com/placeholder-for-lazy-load.mp3';  
          return s.id == song.id 
              ? source 
              : AudioSource.uri(
                  Uri.parse(tempUrl),
                  tag: MediaItem(
                    id: s.id,
                    album: s.album ?? "Streaming Music",
                    artist: s.artist,
                    title: s.title,
                    artUri: s.thumbnailUrl != null ? Uri.parse(s.thumbnailUrl!) : null,
                    extras: {'source': s.source, 'isStream': true},
                  ),
               );
        }).toList();
        
        await handler.setPlaylist(sources, initialIndex);
        
        // Tell handler this is a streaming queue so it can re-fetch URLs lazily on skip
        final playlistJson = activeQueue.map((s) => s.toJson()).toList();
        await handler.customAction('setStreamingQueue', {'isStreamingQueue': true, 'playlist': playlistJson});
        } else {
        if (_audioHandler is MyAudioHandler) {
          final MyAudioHandler h = _audioHandler as MyAudioHandler;
          await h.setPlaylist([source], 0);
          await h.customAction('setStreamingQueue', {'isStreamingQueue': true, 'playlist': [song.toJson()]});
        }
      }
      
      if (autoPlay) {
        await _audioHandler?.play();
      }
      debugPrint("AudioPlayerController: Stream playback started");
      notifyListeners();
      
    } catch (e, stack) {
      debugPrint("AudioPlayerController: Error playing stream: $e");
      debugPrint("Stack trace: $stack");
      notifyListeners();
    }
  }

  /// Clear current stream song (when switching to local)
  void clearStreamSong() {
    notifyListeners();
  }
}

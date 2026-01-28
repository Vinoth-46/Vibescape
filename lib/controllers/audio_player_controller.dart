import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_handler.dart';
import '../services/sleep_timer_service.dart';

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
  Stream<Duration> get positionStream => AudioService.position;

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

  SongModel? get currentSong {
    final mediaItem = _audioHandler?.mediaItem.value;
    if (mediaItem == null) return null;
    try {
      return _songs.firstWhere((s) => s.id.toString() == mediaItem.id);
    } catch (_) {
      return null;
    }
  }

  // Queue/Shuffle/Loop
  Stream<List<MediaItem>> get queueStream =>
      _audioHandler?.queue ?? Stream.value([]);

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
  }

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

      _songs =
          allSongs.where((song) => (song.duration ?? 0) > minDuration).toList();
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
    // Service is always initialized now

    try {
      final sources = songs.map((s) {
        final String filePath = s.data;
        Uri? artworkUri;
        if (s.albumId != null) {
          artworkUri =
              Uri.parse("content://media/external/audio/albumart/${s.albumId}");
        }

        if (filePath.startsWith('http')) {
          return AudioSource.uri(
            Uri.parse(filePath),
            tag: MediaItem(
              id: s.id.toString(),
              album: s.album ?? "Unknown Album",
              title: s.title,
              artist: s.artist ?? "Unknown Artist",
              duration: Duration(milliseconds: s.duration ?? 0),
              artUri: artworkUri,
              extras: {'url': filePath},
            ),
          );
        } else {
          return AudioSource.file(
            filePath,
            tag: MediaItem(
              id: s.id.toString(),
              album: s.album ?? "Unknown Album",
              title: s.title,
              artist: s.artist ?? "Unknown Artist",
              duration: Duration(milliseconds: s.duration ?? 0),
              artUri: artworkUri,
              extras: {'url': filePath},
            ),
          );
        }
      }).toList();

      if (_audioHandler is MyAudioHandler) {
        final handler = _audioHandler as MyAudioHandler;
        await handler.setPlaylist(sources, index);
        await handler.play();
      }
    } catch (e, stack) {
      debugPrint("AudioPlayerController: Error playing song: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  void play() => _audioHandler?.play();

  void pause() {
    _audioHandler?.pause();
    if (isSleepTimerActive) cancelSleepTimer();
  }

  void seek(Duration position) => _audioHandler?.seek(position);

  void playNext() => _audioHandler?.skipToNext();

  void playPrevious() => _audioHandler?.skipToPrevious();

  void setSleepTimer(Duration duration) {
    _sleepTimerService.setTimer(duration);
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
}

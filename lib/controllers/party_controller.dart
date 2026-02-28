import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/party_room_model.dart';
import '../models/stream_song_model.dart';
import '../services/party_service.dart';
import 'audio_player_controller.dart';

class PartyController extends ChangeNotifier {
  final PartyService _partyService = PartyService();
  final AudioPlayerController _audioPlayerController;

  PartyRoomModel? _currentRoom;
  String? _localUserId;
  StreamSubscription? _roomSubscription;
  
  // Flag to prevent recursive updates between local player and remote state
  bool _isProcessingRemoteUpdate = false;
  bool _isLoading = false;
  String? _error;

  PartyController(this._audioPlayerController) {
    _localUserId = _partyService.generateUserId();
    
    // Listen to local player state changes to broadcast to room (if host)
    _audioPlayerController.addListener(_onLocalPlayerStateChanged);
  }

  PartyRoomModel? get currentRoom => _currentRoom;
  bool get isInRoom => _currentRoom != null;
  bool get isHost => isInRoom && _currentRoom!.hostId == _localUserId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get localUserId => _localUserId ?? '';

  Future<void> createRoom() async {
    _setLoading(true);
    try {
      if (_localUserId == null) {
        _localUserId = _partyService.generateUserId();
      }
      _currentRoom = await _partyService.createRoom(_localUserId!);
      _startListeningToRoom();
      
      // Sync current local playback state to new room immediately
      if (_audioPlayerController.isPlayingStream && _audioPlayerController.currentStreamSong != null) {
        _broadcastStateUpdate(
          song: _audioPlayerController.currentStreamSong,
          isPlaying: _audioPlayerController.isPlaying,
          position: _audioPlayerController.position,
        );
      }
    } catch (e) {
      _error = e.toString();
      debugPrint("PartyController Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> joinRoom(String roomId) async {
    _setLoading(true);
    try {
      if (_localUserId == null) {
        _localUserId = _partyService.generateUserId();
      }
      final room = await _partyService.joinRoom(roomId, _localUserId!);
      if (room != null) {
        _currentRoom = room;
        _startListeningToRoom();
        return true;
      } else {
        _error = "Room not found or invalid code";
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint("PartyController Error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> leaveRoom() async {
    if (_currentRoom != null && _localUserId != null) {
      await _partyService.leaveRoom(_currentRoom!.roomId, _localUserId!);
      _roomSubscription?.cancel();
      _currentRoom = null;
      notifyListeners();
    }
  }

  void _startListeningToRoom() {
    _roomSubscription?.cancel();
    _roomSubscription = _partyService.listenToRoom(_currentRoom!.roomId).listen((updatedRoom) {
      if (updatedRoom == null) {
        // Room was deleted
        _currentRoom = null;
        _roomSubscription?.cancel();
        notifyListeners();
        return;
      }

      _currentRoom = updatedRoom;
      notifyListeners();

      // If we are NOT the host, we need to sync our local player with the room state
      if (!isHost) {
        _syncLocalPlayerWithRemoteState(updatedRoom);
      }
    });
  }

  void _syncLocalPlayerWithRemoteState(PartyRoomModel room) async {
    _isProcessingRemoteUpdate = true;
    try {
      // 1. Check if song changed
      final rSong = room.currentSong;
      final autoPlay = room.isPlaying;
      
      if (rSong != null) {
        if (_audioPlayerController.currentStreamSong?.id != rSong.id) {
          // Need to load and play the new song
          await _audioPlayerController.playStreamSong(rSong, autoPlay: autoPlay);
        } else {
           // Song is the same. Check playing state.
           if (room.isPlaying != _audioPlayerController.isPlaying) {
             if (room.isPlaying) {
               _audioPlayerController.play();
             } else {
               _audioPlayerController.pause();
             }
           }
        }
        
        // 2. Sync position if it drifted significantly (tight 500ms tolerance for 'speaker' feel)
        final localPos = _audioPlayerController.position;
        final remotePos = room.playbackPosition;
        
        // Only seek if the difference is more than 0.5 seconds
        if ((localPos.inMilliseconds - remotePos.inMilliseconds).abs() > 500) {
            // Seek directly to the host's raw playbackPosition + minimal buffer to account for hardware execution delay
            // We discarded the DateTime.now() math because local clock skews across devices causes catastrophic sync drifts.
            final predictedPos = remotePos + Duration(milliseconds: room.isPlaying ? 50 : 0);
            _audioPlayerController.seek(predictedPos);
        }
      } else {
        // No song playing in room
        _audioPlayerController.stop();
      }

    } finally {
      // Give the local player a moment to settle before listening to local events again
      Future.delayed(const Duration(milliseconds: 500), () {
        _isProcessingRemoteUpdate = false;
      });
    }
  }

  void _onLocalPlayerStateChanged() {
    // If not in a room, or not the host, or currently applying a remote update, do nothing
    if (!isInRoom || !isHost || _isProcessingRemoteUpdate) return;
    
    // As host, broadcast local changes
    _broadcastStateUpdate(
      song: _audioPlayerController.currentStreamSong,
      isPlaying: _audioPlayerController.isPlaying,
      position: _audioPlayerController.position,
    );
  }

  // Use a short debounce to avoid spamming the database with rapid position updates
  Timer? _broadcastDebounce;
  
  void _broadcastStateUpdate({
    required StreamSongModel? song,
    required bool isPlaying,
    required Duration position,
  }) {
    if (_currentRoom == null) return;

    if (_broadcastDebounce?.isActive ?? false) _broadcastDebounce!.cancel();
    
    _broadcastDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (_currentRoom == null) return;
      
      final updatedRoom = _currentRoom!.copyWith(
        currentSong: song,
        isPlaying: isPlaying,
        playbackPosition: position,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
      
      await _partyService.updateRoom(updatedRoom);
      _currentRoom = updatedRoom; 
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayerController.removeListener(_onLocalPlayerStateChanged);
    _roomSubscription?.cancel();
    _broadcastDebounce?.cancel();
    super.dispose();
  }
}

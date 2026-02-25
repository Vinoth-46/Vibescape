import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/party_room_model.dart';
import '../models/stream_song_model.dart';

class PartyService {
  final _db = FirebaseDatabase.instance.ref();
  
  // Generate a 5-digit room code
  String generateRoomCode() {
    final rand = Random();
    return (10000 + rand.nextInt(90000)).toString();
  }

  // Generate a random user ID for the session
  String generateUserId() {
    final rand = Random();
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(1000)}';
  }

  // Create a new room
  Future<PartyRoomModel> createRoom(String hostId) async {
    final roomId = generateRoomCode();
    final room = PartyRoomModel(
      roomId: roomId,
      hostId: hostId,
      memberIds: [hostId],
      isPlaying: false,
      playbackPosition: Duration.zero,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await _db.child('rooms').child(roomId).set(room.toMap());
    return room;
  }

  // Join an existing room
  Future<PartyRoomModel?> joinRoom(String roomId, String userId) async {
    final snapshot = await _db.child('rooms').child(roomId).get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      var room = PartyRoomModel.fromMap(data);
      
      // Check if room is full (max 5 members including host = 4 guests)
      if (room.memberIds.length >= 5 && !room.memberIds.contains(userId)) {
        throw Exception("Room is full (max 5 members)");
      }
      
      if (!room.memberIds.contains(userId)) {
        final List<String> updatedMembers = List.from(room.memberIds)..add(userId);
        room = room.copyWith(memberIds: updatedMembers);
        await updateRoom(room);
      }
      
      return room;
    }
    return null; // Room not found
  }

  // Leave a room
  Future<void> leaveRoom(String roomId, String userId) async {
    final snapshot = await _db.child('rooms').child(roomId).get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      var room = PartyRoomModel.fromMap(data);
      
      if (room.memberIds.contains(userId)) {
        final List<String> updatedMembers = List.from(room.memberIds)..remove(userId);
        
        // If room is empty, delete it
        if (updatedMembers.isEmpty) {
          await _db.child('rooms').child(roomId).remove();
        } else {
          // If host leaves, reassign host (simple approach: first member becomes host)
          String newHostId = room.hostId;
          if (room.hostId == userId && updatedMembers.isNotEmpty) {
            newHostId = updatedMembers.first;
          }
          
          room = room.copyWith(
            memberIds: updatedMembers, 
            hostId: newHostId,
            lastUpdated: DateTime.now().millisecondsSinceEpoch
          );
          await updateRoom(room);
        }
      }
    }
  }

  // Update room state
  Future<void> updateRoom(PartyRoomModel room) async {
    await _db.child('rooms').child(room.roomId).update(room.toMap());
  }

  // Stream room updates
  Stream<PartyRoomModel?> listenToRoom(String roomId) {
    return _db.child('rooms').child(roomId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return PartyRoomModel.fromMap(data);
      }
      return null;
    });
  }
}

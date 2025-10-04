import 'dart:async';
 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../service/analytics_service.dart';
import 'package:get/get.dart';
import 'package:the_chess/home/controller/matchmaking_controller.dart';
import 'package:the_chess/home/model/chat_model.dart';
import 'package:the_chess/home/model/message_model.dart';

class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();

  StreamSubscription<DocumentSnapshot>? _queueSubscription;
  StreamSubscription<QuerySnapshot>? _waitingUsersSubscription;
  Timer? _timeoutTimer;

  // Stream controller for match events
  final StreamController<String> _matchController =
      StreamController<String>.broadcast();

  // Stream controller for timeout events
  final StreamController<void> _timeoutController =
      StreamController<void>.broadcast();

  Stream<String> get matchStream => _matchController.stream;
  Stream<void> get timeoutStream => _timeoutController.stream;

  // Get number of players currently in the queue
  Future<int> getQueuePlayerCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('matchmaking_queue')
          .where('status', isEqualTo: 'waiting')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting queue player count: $e');
      return 0;
    }
  }

  // Get number of active players (currently in matches)
  Future<int> getActivePlayerCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('matchmaking_queue')
          .where('status', isEqualTo: 'matched')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting active player count: $e');
      return 0;
    }
  }

  // Get both counts in a single call for efficiency
  Future<Map<String, int>> getPlayerCounts() async {
    try {
      final queueCount = await getQueuePlayerCount();
      final activeCount = await getActivePlayerCount();
      return {
        'queue': queueCount,
        'active': activeCount,
      };
    } catch (e) {
      debugPrint('Error getting player counts: $e');
      return {'queue': 0, 'active': 0};
    }
  }

  // Add user to matchmaking queue and start looking for matches
  Future<void> joinQueue() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No authenticated user found');
      return;
    }

    // Cancel any existing timeout timer
    _timeoutTimer?.cancel();

    // Add current user to queue
    await _firestore.collection('matchmaking_queue').doc(user.uid).set({
      'uid': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'displayName': user.displayName ?? 'Anonymous',
    });

    // Record analytics for player joining queue
    await _analytics.recordPlayerJoin(user.uid, 'matchmaking_queue');

    debugPrint('User ${user.uid} joined queue');

    // Start 1-minute timeout timer
    _timeoutTimer = Timer(Duration(seconds: 30), () {
      debugPrint('Matchmaking timeout reached for user ${user.uid}');
      _handleTimeout();
    });

    // Start listening for status changes (when matched by another user)
    _listenForMatch();

    // Also actively look for other waiting users
    _listenForWaitingUsers();
  }

  // Remove user from queue
  Future<void> leaveQueue() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel timeout timer
    _timeoutTimer?.cancel();

    await _firestore.collection('matchmaking_queue').doc(user.uid).delete();
    _queueSubscription?.cancel();
    _waitingUsersSubscription?.cancel();
    debugPrint('User ${user.uid} left queue');
  }

  // Listen for changes in current user's queue status
  void _listenForMatch() {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('Setting up match listener for user: ${user.uid}');

    _queueSubscription = _firestore
        .collection('matchmaking_queue')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      debugPrint('Queue document snapshot received for ${user.uid}');
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String?;

        debugPrint('User status updated: $status');

        if (status == 'matched') {
          final roomId = data['roomId'] as String?;
          if (roomId != null) {
            debugPrint('Match found! Room ID: $roomId');
            _handleMatchFound(roomId);
          } else {
            debugPrint('Status is matched but no roomId found');
          }
        }
      } else {
        debugPrint('Queue document does not exist for user ${user.uid}');
      }
    });
  }

  // Listen for other waiting users and try to match
  void _listenForWaitingUsers() {
    final user = _auth.currentUser;
    if (user == null) return;

    _waitingUsersSubscription = _firestore
        .collection('matchmaking_queue')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .listen((snapshot) {
      debugPrint('Waiting users count: ${snapshot.docs.length}');

      // Find another user to match with (not current user)
      for (var doc in snapshot.docs) {
        if (doc.id != user.uid) {
          debugPrint('Found potential match: ${doc.id}');
          _attemptMatch(doc.id);
          break; // Only match with the first available user
        }
      }
    });
  }

  // Attempt to match with a specific user
  Future<void> _attemptMatch(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Cancel timeout timer immediately when attempting match
      _timeoutTimer?.cancel();
      debugPrint('Timeout timer canceled during match attempt');
      
      // Use a transaction to ensure atomic matching
      await _firestore.runTransaction((transaction) async {
        // Check if both users are still waiting
        final currentUserDoc = await transaction
            .get(_firestore.collection('matchmaking_queue').doc(user.uid));
        final otherUserDoc = await transaction
            .get(_firestore.collection('matchmaking_queue').doc(otherUserId));

        if (!currentUserDoc.exists || !otherUserDoc.exists) {
          debugPrint('One of the users no longer exists in queue');
          return;
        }

        final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
        final otherUserData = otherUserDoc.data() as Map<String, dynamic>;

        if (currentUserData['status'] != 'waiting' ||
            otherUserData['status'] != 'waiting') {
          debugPrint('One of the users is not waiting anymore');
          return;
        }

        // Create chat room
        final roomRef = _firestore.collection('chat_rooms').doc();
        final roomId = roomRef.id;

        // Determine join order based on queue timestamps
        // First player to join queue gets white (index 0)
        final currentUserTimestamp = currentUserData['timestamp'] as Timestamp?;
        final otherUserTimestamp = otherUserData['timestamp'] as Timestamp?;
        
        List<String> orderedParticipants;
        if (currentUserTimestamp != null && otherUserTimestamp != null) {
          // Compare timestamps to determine who joined first
          if (currentUserTimestamp.compareTo(otherUserTimestamp) <= 0) {
            // Current user joined first or at same time, gets white
            orderedParticipants = [user.uid, otherUserId];
          } else {
            // Other user joined first, gets white
            orderedParticipants = [otherUserId, user.uid];
          }
        } else {
          // Fallback to current order if timestamps are missing
          orderedParticipants = [user.uid, otherUserId];
        }

        final chatRoom = ChatRoomModel(
          roomId: roomId,
          participants: orderedParticipants,
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Create the chat room
        transaction.set(roomRef, chatRoom.toMap());

        // Record analytics for room creation
        await _analytics.recordRoomCreation(roomId);
        
        // Start tracking game session
        await _analytics.startGameSession(roomId, [user.uid, otherUserId]);

        // Update both users to matched status
        transaction.update(currentUserDoc.reference, {
          'status': 'matched',
          'roomId': roomId,
          'matchedWith': otherUserId,
        });

        transaction.update(otherUserDoc.reference, {
          'status': 'matched',
          'roomId': roomId,
          'matchedWith': user.uid,
        });

        debugPrint(
            'Successfully matched ${user.uid} with $otherUserId in room $roomId');
      });
    } catch (e) {
      debugPrint('Error during matching: $e');
    }
  }

  // Handle when match is found
  void _handleMatchFound(String roomId) {
    debugPrint('_handleMatchFound called with room ID: $roomId');

    // Cancel timeout timer since match was found
    _timeoutTimer?.cancel();

    // Notify via stream FIRST before any cleanup
    _matchController.add(roomId);
    debugPrint('Added room ID to match stream: $roomId');

    // Delay cleanup to allow navigation to complete
    Future.delayed(Duration(milliseconds: 500), () {
      _queueSubscription?.cancel();
      _waitingUsersSubscription?.cancel();

      // Remove user from queue after navigation
      final user = _auth.currentUser;
      if (user != null) {
        _firestore.collection('matchmaking_queue').doc(user.uid).delete();
        debugPrint('Removed user ${user.uid} from queue after navigation');
      }
    });
  }

  // Handle timeout when no match is found within 1 minute
  Future<void> _handleTimeout() async {
    debugPrint('Handling matchmaking timeout');

    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel subscriptions
    _queueSubscription?.cancel();
    _waitingUsersSubscription?.cancel();

    // Remove user from Firebase queue
    try {
      await _firestore.collection('matchmaking_queue').doc(user.uid).delete();
      debugPrint('Removed user ${user.uid} from queue due to timeout');
    } catch (e) {
      debugPrint('Error removing user from queue: $e');
    }

    // Notify timeout via stream
    _timeoutController.add(null);
    debugPrint('Timeout event sent to stream');
    final controller = Get.put(MatchmakingController());
    controller.handleTimeout();
  }

  // Clean up resources
  void dispose() {
    _timeoutTimer?.cancel();
    _queueSubscription?.cancel();
    _waitingUsersSubscription?.cancel();
    _matchController.close();
    _timeoutController.close();
  }

  // Send a message in chat room
  Future<void> sendMessage(String roomId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      messageId: messageRef.id,
      senderId: user.uid,
      content: content,
      timestamp: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // Update chat room with last message
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream for a chat room
  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  // End chat session
  Future<void> endChat(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Mark chat room as inactive
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'isActive': false,
    });

    // Remove user from queue if still there
    await leaveQueue();
  }
}

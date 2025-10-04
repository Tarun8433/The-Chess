import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_chess/home/model/game_status.dart';

class GameHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add game to user's history when game is created
  Future<void> addGameToHistory(
      String gameId, String opponentId, String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final gameHistoryData = {
      'gameId': gameId,
      'opponentId': opponentId,
      'roomId': roomId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'playerColor': 'white', // Creator is always white
    };

    // Add to current user's history
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('game_history')
        .doc(gameId)
        .set(gameHistoryData);

    // Add to opponent's history
    final opponentGameHistoryData = {
      'gameId': gameId,
      'opponentId': user.uid,
      'roomId': roomId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'playerColor': 'black', // Opponent is always black
    };

    await _firestore
        .collection('users')
        .doc(opponentId)
        .collection('game_history')
        .doc(gameId)
        .set(opponentGameHistoryData);
  }

  // Update game status in history (completed, abandoned, etc.)
  Future<void> updateGameHistoryStatus(String gameId, String status,
      {String? winner}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Get the game to find both players
    final gameDoc =
        await _firestore.collection('chess_games').doc(gameId).get();
    if (!gameDoc.exists) return;

    final gameData = gameDoc.data()!;
    final players = List<String>.from(gameData['players']);

    // Update history for both players
    for (final playerId in players) {
      final updateData = {
        'status': status,
        'lastActivity': FieldValue.serverTimestamp(),
      };

      if (winner != null) {
        updateData['winner'] = winner;
        updateData['result'] = winner == playerId ? 'won' : 'lost';
      }

      await _firestore
          .collection('users')
          .doc(playerId)
          .collection('game_history')
          .doc(gameId)
          .update(updateData);
    }
  }

  // Get user's game history
  Stream<List<GameHistoryItem>> getUserGameHistory() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('game_history')
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameHistoryItem.fromMap(doc.data()))
            .toList());
  }

  // Get active games for user
  Stream<List<GameHistoryItem>> getActiveGames() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('game_history')
        .where('status', isEqualTo: 'active')
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameHistoryItem.fromMap(doc.data()))
            .toList());
  }

  // Check if user can rejoin a specific game
  Future<bool> canRejoinGame(String gameId) async {
    try {
      final gameDoc =
          await _firestore.collection('chess_games').doc(gameId).get();
      if (!gameDoc.exists) return false;

      final gameData = gameDoc.data()!;
      final gameStatus = gameData['gameStatus'];

      // Can only rejoin active games
      return gameStatus == GameStatus.active.value;
    } catch (e) {
      return false;
    }
  }

  // Mark player as rejoined
  Future<void> markPlayerRejoined(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore.collection('chess_games').doc(gameId).update({
      'playerLastSeen.${user.uid}': FieldValue.serverTimestamp(),
    });

    // Update game history
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('game_history')
        .doc(gameId)
        .update({
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }
}

class GameHistoryItem {
  final String gameId;
  final String opponentId;
  final String roomId;
  final String status;
  final DateTime createdAt;
  final DateTime lastActivity;
  final String playerColor;
  final String? winner;
  final String? result;

  GameHistoryItem({
    required this.gameId,
    required this.opponentId,
    required this.roomId,
    required this.status,
    required this.createdAt,
    required this.lastActivity,
    required this.playerColor,
    this.winner,
    this.result,
  });

  factory GameHistoryItem.fromMap(Map<String, dynamic> map) {
    return GameHistoryItem(
      gameId: map['gameId'] ?? '',
      opponentId: map['opponentId'] ?? '',
      roomId: map['roomId'] ?? '',
      status: map['status'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActivity: map['lastActivity'] != null
          ? (map['lastActivity'] as Timestamp).toDate()
          : DateTime.now(),
      playerColor: map['playerColor'] ?? '',
      winner: map['winner'],
      result: map['result'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'opponentId': opponentId,
      'roomId': roomId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'playerColor': playerColor,
      'winner': winner,
      'result': result,
    };
  }
}

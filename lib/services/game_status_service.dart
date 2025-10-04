import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../home/model/game_status.dart';

enum GameEndReason {
  checkmate,
  resignation,
  timeout,
  draw,
  stalemate,
  insufficientMaterial,
  threefoldRepetition,
  disconnect,
}

class GameStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update game status to server
  Future<void> updateGameStatus({
    required String gameId,
    required GameStatus status,
    String? winner,
    String? endReason,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'gameStatus': status.value,
        'lastUpdate': FieldValue.serverTimestamp(),
      };

      if (winner != null) {
        updates['winner'] = winner;
      }

      if (endReason != null) {
        updates['endReason'] = endReason;
      }

      if (status.isGameOver) {
        updates['endedAt'] = FieldValue.serverTimestamp();
      }

      if (additionalData != null) {
        updates.addAll(additionalData);
      }

      await _firestore.collection('chess_games').doc(gameId).update(updates);

      debugPrint('✅ Game status updated: $status');
      debugPrint('   Game ID: $gameId');
      debugPrint('   Winner: $winner');
      debugPrint('   Reason: $endReason');
    } catch (e) {
      debugPrint('❌ Error updating game status: $e');
      rethrow;
    }
  }

  /// End game with checkmate
  Future<void> endGameWithCheckmate({
    required String gameId,
    required String winnerId,
    required bool isWhiteWinner,
  }) async {
    await updateGameStatus(
      gameId: gameId,
      status: GameStatus.checkmate,
      winner: isWhiteWinner ? 'white' : 'black',
      endReason: 'Checkmate - ${isWhiteWinner ? 'White' : 'Black'} wins',
      additionalData: {
        'winnerId': winnerId,
      },
    );
  }

  /// End game with resignation
  Future<void> endGameWithResignation({
    required String gameId,
    required String resignedPlayerId,
    required String winnerId,
    required bool isWhiteWinner,
  }) async {
    await updateGameStatus(
      gameId: gameId,
      status: GameStatus.resigned,
      winner: isWhiteWinner ? 'white' : 'black',
      endReason: 'Resignation',
      additionalData: {
        'resignedBy': resignedPlayerId,
        'winnerId': winnerId,
      },
    );
  }

  /// End game with timeout
  Future<void> endGameWithTimeout({
    required String gameId,
    required String loserId,
    required String winnerId,
    required bool isWhiteWinner,
  }) async {
    await updateGameStatus(
      gameId: gameId,
      status: GameStatus.timeout,
      winner: isWhiteWinner ? 'white' : 'black',
      endReason: '${isWhiteWinner ? 'Black' : 'White'} lost on time',
      additionalData: {
        'loserId': loserId,
        'winnerId': winnerId,
      },
    );
  }

  /// End game with draw
  Future<void> endGameWithDraw({
    required String gameId,
    required String drawReason,
  }) async {
    await updateGameStatus(
      gameId: gameId,
      status: GameStatus.draw,
      endReason: 'Draw - $drawReason',
    );
  }

  /// End game with stalemate
  Future<void> endGameWithStalemate({
    required String gameId,
  }) async {
    await endGameWithDraw(
      gameId: gameId,
      drawReason: 'Stalemate - No legal moves available',
    );
  }

  /// End game with insufficient material
  Future<void> endGameWithInsufficientMaterial({
    required String gameId,
  }) async {
    await endGameWithDraw(
      gameId: gameId,
      drawReason: 'Insufficient material to checkmate',
    );
  }

  /// End game with disconnection
  Future<void> endGameWithDisconnection({
    required String gameId,
    required String disconnectedPlayerId,
    required String winnerId,
    required bool isWhiteWinner,
  }) async {
    await updateGameStatus(
      gameId: gameId,
      status: GameStatus.disconnected,
      winner: isWhiteWinner ? 'white' : 'black',
      endReason: 'Player disconnected',
      additionalData: {
        'disconnectedBy': disconnectedPlayerId,
        'winnerId': winnerId,
      },
    );
  }

  /// Update game to active (game started)
  Future<void> startGame({required String gameId}) async {
    await updateGameStatus(
      gameId: gameId,
      status: GameStatus.active,
      additionalData: {
        'startedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Get current game status
  Future<GameStatus?> getGameStatus(String gameId) async {
    try {
      final doc = await _firestore.collection('chess_games').doc(gameId).get();

      if (!doc.exists) {
        debugPrint('❌ Game not found: $gameId');
        return null;
      }

      final data = doc.data()!;
      final statusString = data['gameStatus'] as String?;

      if (statusString == null) {
        return GameStatus.active;
      }

      return GameStatus.fromString(statusString);
    } catch (e) {
      debugPrint('❌ Error getting game status: $e');
      return null;
    }
  }

  /// Listen to game status changes
  Stream<GameStatus?> listenToGameStatus(String gameId) {
    return _firestore
        .collection('chess_games')
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      final data = snapshot.data()!;
      final statusString = data['gameStatus'] as String?;

      if (statusString == null) {
        return GameStatus.active;
      }

      return GameStatus.fromString(statusString);
    });
  }

  /// Check if game has ended
  Future<bool> isGameEnded(String gameId) async {
    final status = await getGameStatus(gameId);
    return status?.isGameOver ?? false;
  }

  /// Get game winner
  Future<String?> getGameWinner(String gameId) async {
    try {
      final doc = await _firestore.collection('chess_games').doc(gameId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return data['winner'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting game winner: $e');
      return null;
    }
  }

  /// Get game end reason
  Future<String?> getGameEndReason(String gameId) async {
    try {
      final doc = await _firestore.collection('chess_games').doc(gameId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return data['endReason'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting game end reason: $e');
      return null;
    }
  }
}

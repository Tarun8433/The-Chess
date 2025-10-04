import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'chess_timer.dart';

class ChessTimerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final Map<String, ChessTimer> _activeTimers = {};

  // Create and start a timer for a new game
  static Future<ChessTimer> createGameTimer({
    required String gameId,
    TimerVariant variant = TimerVariant.blitz5_0,
  }) async {
    final timer = ChessTimer(
      gameId: gameId,
      variant: variant,
    );

    _activeTimers[gameId] = timer;

    // Initialize timer data in Firestore
    await FirebaseFirestore.instance
        .collection('chess_games')
        .doc(gameId)
        .update({
      'timer': {
        'whiteTimeRemaining': variant.initialTime,
        'blackTimeRemaining': variant.initialTime,
        'isWhiteTurn': true,
        'isGameActive': false, // Will be started when both players are ready
        'variant': variant.displayName,
        'moveCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }
    });

    debugPrint('Created timer for game $gameId with variant ${variant.displayName}');
    return timer;
  }

  // Get existing timer for a game
  static ChessTimer? getGameTimer(String gameId) {
    return _activeTimers[gameId];
  }

  // Load timer from Firestore and add to active timers
  static Future<ChessTimer?> loadGameTimer({
    required String gameId,
    TimerVariant fallbackVariant = TimerVariant.blitz5_0,
  }) async {
    try {
      final gameDoc = await FirebaseFirestore.instance
          .collection('chess_games')
          .doc(gameId)
          .get();

      if (!gameDoc.exists) return null;

      final gameData = gameDoc.data()!;
      final timerData = gameData['timer'] as Map<String, dynamic>?;

      // Determine variant
      TimerVariant variant = fallbackVariant;
      if (timerData != null && timerData['variant'] != null) {
        final variantName = timerData['variant'] as String;
        variant = TimerVariant.values.firstWhere(
          (v) => v.displayName == variantName,
          orElse: () => fallbackVariant,
        );
      }

      final timer = ChessTimer(
        gameId: gameId,
        variant: variant,
      );

      await timer.loadFromFirestore();
      timer.startListeningToFirestore();

      _activeTimers[gameId] = timer;

      debugPrint('Loaded timer for game $gameId');
      return timer;
    } catch (e) {
      debugPrint('Error loading timer for game $gameId: $e');
      return null;
    }
  }

  // Start the game timer (called when both players are ready)
  static Future<void> startGameTimer(String gameId) async {
    final timer = _activeTimers[gameId];
    if (timer == null) {
      debugPrint('No timer found for game $gameId');
      return;
    }

    await timer.startGame();
    debugPrint('Started timer for game $gameId');
  }

  // Handle a move made in the game
  static Future<void> handleMove({
    required String gameId,
    required String playerId,
  }) async {
    final timer = _activeTimers[gameId];
    if (timer == null) {
      debugPrint('No timer found for game $gameId');
      return;
    }

    // Determine if the player is white
    final isWhitePlayer = await _isPlayerWhite(gameId, playerId);
    await timer.makeMove(isWhitePlayer: isWhitePlayer);

    debugPrint('Move handled for $playerId in game $gameId');
  }

  // Pause a game timer
  static Future<void> pauseGameTimer(String gameId, String reason) async {
    final timer = _activeTimers[gameId];
    if (timer == null) return;

    await timer.pauseGame(reason: reason);
    debugPrint('Paused timer for game $gameId: $reason');
  }

  // Resume a game timer
  static Future<void> resumeGameTimer(String gameId) async {
    final timer = _activeTimers[gameId];
    if (timer == null) return;

    await timer.resumeGame();
    debugPrint('Resumed timer for game $gameId');
  }

  // End a game timer
  static Future<void> endGameTimer(String gameId, {GameResult? result, String? reason}) async {
    final timer = _activeTimers[gameId];
    if (timer == null) return;

    await timer.endGame(
      result: result ?? GameResult.draw,
      reason: reason,
    );

    debugPrint('Ended timer for game $gameId');
  }

  // Clean up timer when game ends
  static void disposeGameTimer(String gameId) {
    final timer = _activeTimers.remove(gameId);
    timer?.dispose();
    debugPrint('Disposed timer for game $gameId');
  }

  // Helper method to determine if a player is white
  static Future<bool> _isPlayerWhite(String gameId, String playerId) async {
    try {
      final gameDoc = await FirebaseFirestore.instance
          .collection('chess_games')
          .doc(gameId)
          .get();

      if (!gameDoc.exists) return false;

      final gameData = gameDoc.data()!;
      final whitePlayerId = gameData['whitePlayerId'] as String?;

      return whitePlayerId == playerId;
    } catch (e) {
      debugPrint('Error determining player color: $e');
      return false;
    }
  }

  // Get timer variant from string
  static TimerVariant getVariantFromString(String variantString) {
    return TimerVariant.values.firstWhere(
      (variant) => variant.displayName == variantString,
      orElse: () => TimerVariant.blitz5_0,
    );
  }

  // Auto-handle disconnected players
  static void handlePlayerDisconnection({
    required String gameId,
    required String playerId,
  }) {
    final timer = _activeTimers[gameId];
    if (timer == null) return;

    // Timer continues running - no special handling for disconnections
    // This enforces fair play - players can't pause by disconnecting
    debugPrint('Player $playerId disconnected from game $gameId - timer continues');
  }

  // Handle player reconnection
  static void handlePlayerReconnection({
    required String gameId,
    required String playerId,
  }) {
    final timer = _activeTimers[gameId];
    if (timer == null) return;

    // Update last activity but don't affect timer
    debugPrint('Player $playerId reconnected to game $gameId');
  }

  // Get all active timers (for debugging)
  static Map<String, ChessTimer> getActiveTimers() {
    return Map.unmodifiable(_activeTimers);
  }

  // Clean up all timers (app shutdown)
  static void disposeAllTimers() {
    for (final timer in _activeTimers.values) {
      timer.dispose();
    }
    _activeTimers.clear();
    debugPrint('Disposed all timers');
  }
}
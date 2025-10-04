import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum TimerVariant {
  blitz5_0(initialTime: 300, increment: 0, displayName: '5 | 0'),
  blitz5_2(initialTime: 300, increment: 2, displayName: '5 | 2'),
  blitz5_3(initialTime: 300, increment: 3, displayName: '5 | 3'),
  rapid10_0(initialTime: 600, increment: 0, displayName: '10 | 0'),
  rapid10_5(initialTime: 600, increment: 5, displayName: '10 | 5'),
  rapid15_10(initialTime: 900, increment: 10, displayName: '15 | 10');

  const TimerVariant({
    required this.initialTime,
    required this.increment,
    required this.displayName,
  });

  final int initialTime; // seconds
  final int increment; // seconds added per move
  final String displayName;
}

enum GameResult {
  whiteWins,
  blackWins,
  draw,
  ongoing,
}

enum TimeoutReason {
  timeExpired,
  insufficientMaterial,
  disconnection,
}

class ChessTimer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String gameId;
  final TimerVariant variant;

  Timer? _countdownTimer;
  bool _isGameActive = false;
  bool _isWhiteTurn = true;

  // Time remaining in seconds
  int _whiteTimeRemaining;
  int _blackTimeRemaining;

  // Move tracking
  int _moveCount = 0;
  DateTime? _turnStartTime;
  DateTime? _gameStartTime;

  // Connection tracking
  Map<String, DateTime> _lastPlayerActivity = {};
  static const int _connectionTimeoutSeconds = 60;

  // Streams for UI updates
  final StreamController<TimerState> _timerStateController =
      StreamController<TimerState>.broadcast();
  final StreamController<GameResult> _gameResultController =
      StreamController<GameResult>.broadcast();

  ChessTimer({
    required this.gameId,
    this.variant = TimerVariant.blitz5_0,
  }) : _whiteTimeRemaining = variant.initialTime,
       _blackTimeRemaining = variant.initialTime;

  // Getters
  Stream<TimerState> get timerStateStream => _timerStateController.stream;
  Stream<GameResult> get gameResultStream => _gameResultController.stream;

  bool get isGameActive => _isGameActive;
  bool get isWhiteTurn => _isWhiteTurn;
  TimerState get currentState => TimerState(
    whiteTimeRemaining: _whiteTimeRemaining,
    blackTimeRemaining: _blackTimeRemaining,
    isWhiteTurn: _isWhiteTurn,
    isGameActive: _isGameActive,
    variant: variant,
    moveCount: _moveCount,
  );

  // Start the game - White's clock begins automatically
  Future<void> startGame() async {
    if (_isGameActive) return;

    _isGameActive = true;
    _isWhiteTurn = true;
    _gameStartTime = DateTime.now();
    _turnStartTime = DateTime.now();
    _lastSyncedMoveCount = _moveCount; // Initialize to current move count

    await _syncToFirestore();
    _startCountdown();
    _notifyTimerUpdate();

    debugPrint('Chess timer started - White to move first');
  }

  // Make a move - automatically switches clocks
  Future<void> makeMove({required bool isWhitePlayer}) async {
    if (!_isGameActive) return;
    if (_isWhiteTurn != isWhitePlayer) return; // Not your turn

    _stopCountdown();

    // Don't recalculate time - the countdown has already been tracking it accurately
    // Just check for time expiry
    if ((_isWhiteTurn && _whiteTimeRemaining <= 0) ||
        (!_isWhiteTurn && _blackTimeRemaining <= 0)) {
      await _handleTimeExpiry();
      return;
    }

    // Add increment before switching turns
    if (variant.increment > 0) {
      if (_isWhiteTurn) {
        _whiteTimeRemaining += variant.increment;
      } else {
        _blackTimeRemaining += variant.increment;
      }
    }

    // Switch turns
    _isWhiteTurn = !_isWhiteTurn;
    _moveCount++;
    _lastSyncedMoveCount = _moveCount; // Update to prevent processing our own update
    _turnStartTime = DateTime.now();

    // Update player activity
    _updatePlayerActivity(isWhitePlayer ? 'white' : 'black');

    await _syncToFirestore();
    _startCountdown();
    _notifyTimerUpdate();

    debugPrint('Move made by ${isWhitePlayer ? 'White' : 'Black'} - Clock switched');
  }

  // Pause the game (for emergencies only - fair play enforced)
  Future<void> pauseGame({required String reason}) async {
    if (!_isGameActive) return;

    _stopCountdown();
    _isGameActive = false;

    await _syncToFirestore();
    _notifyTimerUpdate();

    debugPrint('Game paused: $reason');
  }

  // Resume the game
  Future<void> resumeGame() async {
    if (_isGameActive) return;

    _isGameActive = true;
    _turnStartTime = DateTime.now();

    await _syncToFirestore();
    _startCountdown();
    _notifyTimerUpdate();

    debugPrint('Game resumed');
  }

  // End the game
  Future<void> endGame({required GameResult result, String? reason}) async {
    _stopCountdown();
    _isGameActive = false;

    // Update both timer data and main game status
    await _syncGameEndToFirestore(result, reason);
    _gameResultController.add(result);

    debugPrint('Game ended: $result${reason != null ? ' - $reason' : ''}');
  }

  // Update player activity (for connection tracking)
  void _updatePlayerActivity(String player) {
    _lastPlayerActivity[player] = DateTime.now();
  }

  // Check for disconnected players
  void _checkPlayerConnections() {
    final now = DateTime.now();

    for (final entry in _lastPlayerActivity.entries) {
      final timeSinceActivity = now.difference(entry.value).inSeconds;

      if (timeSinceActivity > _connectionTimeoutSeconds) {
        debugPrint('Player ${entry.key} appears disconnected (${timeSinceActivity}s)');
        // Continue running their clock - connection issues don't pause the game
      }
    }
  }

  // Start the countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isGameActive) {
        timer.cancel();
        return;
      }

      // Decrease time for current player
      if (_isWhiteTurn) {
        _whiteTimeRemaining = (_whiteTimeRemaining - 1).clamp(0, double.infinity).toInt();
        if (_whiteTimeRemaining <= 0) {
          _handleTimeExpiry();
          return;
        }
      } else {
        _blackTimeRemaining = (_blackTimeRemaining - 1).clamp(0, double.infinity).toInt();
        if (_blackTimeRemaining <= 0) {
          _handleTimeExpiry();
          return;
        }
      }

      // Check connections periodically
      if (_moveCount % 10 == 0) {
        _checkPlayerConnections();
      }

      _notifyTimerUpdate();
    });
  }

  // Stop the countdown timer
  void _stopCountdown() {
    _countdownTimer?.cancel();
  }

  // Handle time expiry
  Future<void> _handleTimeExpiry() async {
    _stopCountdown();

    final losingPlayer = _isWhiteTurn ? 'White' : 'Black';
    final winningPlayer = _isWhiteTurn ? 'Black' : 'White';

    // Check for insufficient material (simplified check)
    final hasInsufficientMaterial = await _checkInsufficientMaterial();

    if (hasInsufficientMaterial) {
      await endGame(
        result: GameResult.draw,
        reason: 'Draw - $losingPlayer flagged but $winningPlayer has insufficient material'
      );
    } else {
      final result = _isWhiteTurn ? GameResult.blackWins : GameResult.whiteWins;
      await endGame(
        result: result,
        reason: '$losingPlayer lost on time'
      );
    }
  }

  // Check if the winning player has insufficient material to checkmate
  Future<bool> _checkInsufficientMaterial() async {
    try {
      final gameDoc = await _firestore.collection('chess_games').doc(gameId).get();
      if (!gameDoc.exists) return false;

      final gameData = gameDoc.data()!;
      final fen = gameData['fen'] as String?;

      if (fen == null) return false;

      // Basic insufficient material check
      // This would need to be expanded based on your chess engine
      return _hasInsufficientMaterialFromFEN(fen);
    } catch (e) {
      debugPrint('Error checking insufficient material: $e');
      return false;
    }
  }

  // Simplified insufficient material check from FEN
  bool _hasInsufficientMaterialFromFEN(String fen) {
    final pieces = fen.split(' ')[0];
    final winningColor = _isWhiteTurn ? 'b' : 'w'; // Opposite of player who ran out of time

    // Count pieces for winning player
    int queens = 0, rooks = 0, bishops = 0, knights = 0, pawns = 0;

    for (final char in pieces.split('')) {
      if (winningColor == 'w' && char.toUpperCase() == char) {
        switch (char) {
          case 'Q': queens++; break;
          case 'R': rooks++; break;
          case 'B': bishops++; break;
          case 'N': knights++; break;
          case 'P': pawns++; break;
        }
      } else if (winningColor == 'b' && char.toLowerCase() == char && char != char.toUpperCase()) {
        switch (char.toLowerCase()) {
          case 'q': queens++; break;
          case 'r': rooks++; break;
          case 'b': bishops++; break;
          case 'n': knights++; break;
          case 'p': pawns++; break;
        }
      }
    }

    // Insufficient material combinations
    if (queens > 0 || rooks > 0 || pawns > 0) return false;
    if (bishops >= 2 || knights >= 3) return false;
    if (bishops == 1 && knights >= 1) return false;

    return true; // King alone, King + Bishop, King + Knight, or King + 2 Knights
  }

  // Sync timer state to Firestore
  Future<void> _syncToFirestore() async {
    try {
      await _firestore.collection('chess_games').doc(gameId).update({
        'timer': {
          'whiteTimeRemaining': _whiteTimeRemaining,
          'blackTimeRemaining': _blackTimeRemaining,
          'isWhiteTurn': _isWhiteTurn,
          'isGameActive': _isGameActive,
          'variant': variant.displayName,
          'moveCount': _moveCount,
          'lastUpdate': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      debugPrint('Error syncing timer to Firestore: $e');
    }
  }

  // Sync game end state to Firestore (both timer and main game status)
  Future<void> _syncGameEndToFirestore(GameResult result, String? reason) async {
    try {
      Map<String, dynamic> updates = {
        'timer': {
          'whiteTimeRemaining': _whiteTimeRemaining,
          'blackTimeRemaining': _blackTimeRemaining,
          'isWhiteTurn': _isWhiteTurn,
          'isGameActive': false, // Game is no longer active
          'variant': variant.displayName,
          'moveCount': _moveCount,
          'lastUpdate': FieldValue.serverTimestamp(),
        },
        // Update main game status so both players get notified
        'gameStatus': _getGameStatusFromResult(result),
        'endReason': reason ?? 'Timer expired',
        'endedAt': FieldValue.serverTimestamp(),
      };

      // Set winner if applicable
      if (result == GameResult.whiteWins) {
        updates['winner'] = 'white';
      } else if (result == GameResult.blackWins) {
        updates['winner'] = 'black';
      }

      await _firestore.collection('chess_games').doc(gameId).update(updates);
      debugPrint('✅ Game end state synced to Firestore: $result');
    } catch (e) {
      debugPrint('❌ Error syncing game end to Firestore: $e');
    }
  }

  // Convert GameResult to game status string
  String _getGameStatusFromResult(GameResult result) {
    switch (result) {
      case GameResult.whiteWins:
      case GameResult.blackWins:
        return 'timeout'; // Use timeout status for timer-based wins
      case GameResult.draw:
        return 'draw';
      case GameResult.ongoing:
        return 'active';
    }
  }

  // Load timer state from Firestore
  Future<void> loadFromFirestore() async {
    try {
      final gameDoc = await _firestore.collection('chess_games').doc(gameId).get();
      if (!gameDoc.exists) return;

      final gameData = gameDoc.data()!;
      final timerData = gameData['timer'] as Map<String, dynamic>?;

      if (timerData != null) {
        _whiteTimeRemaining = timerData['whiteTimeRemaining'] ?? variant.initialTime;
        _blackTimeRemaining = timerData['blackTimeRemaining'] ?? variant.initialTime;
        _isWhiteTurn = timerData['isWhiteTurn'] ?? true;
        _isGameActive = timerData['isGameActive'] ?? false;
        _moveCount = timerData['moveCount'] ?? 0;
        _lastSyncedMoveCount = _moveCount; // Initialize to prevent duplicate processing

        if (_isGameActive) {
          _turnStartTime = DateTime.now();
          _startCountdown();
        }

        _notifyTimerUpdate();
      }
    } catch (e) {
      debugPrint('Error loading timer from Firestore: $e');
    }
  }

  // Listen to Firestore changes for real-time sync
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int _lastSyncedMoveCount = -1;

  void startListeningToFirestore() {
    _firestoreSubscription = _firestore
        .collection('chess_games')
        .doc(gameId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final gameData = snapshot.data()! as Map<String, dynamic>;
      final timerData = gameData['timer'] as Map<String, dynamic>?;

      if (timerData != null) {
        final incomingMoveCount = timerData['moveCount'] ?? 0;
        final incomingIsGameActive = timerData['isGameActive'] ?? false;

        // Update if:
        // 1. New move (opponent made a move), OR
        // 2. Game ended (isGameActive changed to false)
        final shouldUpdate = incomingMoveCount > _lastSyncedMoveCount ||
                           (!incomingIsGameActive && _isGameActive);

        if (shouldUpdate) {
          _lastSyncedMoveCount = incomingMoveCount;

          _whiteTimeRemaining = timerData['whiteTimeRemaining'] ?? _whiteTimeRemaining;
          _blackTimeRemaining = timerData['blackTimeRemaining'] ?? _blackTimeRemaining;
          _isWhiteTurn = timerData['isWhiteTurn'] ?? _isWhiteTurn;

          final wasActive = _isGameActive;
          _isGameActive = incomingIsGameActive;
          _moveCount = incomingMoveCount;

          // Stop countdown if game ended
          if (wasActive && !_isGameActive) {
            _stopCountdown();
            debugPrint('⏱️ Timer stopped - game ended via Firestore sync');
          }
          // Restart countdown if game is active and turn changed
          else if (_isGameActive) {
            _turnStartTime = DateTime.now();
            _startCountdown();
          }

          _notifyTimerUpdate();
        }
      }
    });
  }

  // Notify UI of timer updates
  void _notifyTimerUpdate() {
    _timerStateController.add(currentState);
  }

  // Format time for display (MM:SS)
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Dispose resources
  void dispose() {
    _countdownTimer?.cancel();
    _firestoreSubscription?.cancel();
    _timerStateController.close();
    _gameResultController.close();
  }
}

class TimerState {
  final int whiteTimeRemaining;
  final int blackTimeRemaining;
  final bool isWhiteTurn;
  final bool isGameActive;
  final TimerVariant variant;
  final int moveCount;

  TimerState({
    required this.whiteTimeRemaining,
    required this.blackTimeRemaining,
    required this.isWhiteTurn,
    required this.isGameActive,
    required this.variant,
    required this.moveCount,
  });

  String get whiteTimeFormatted => ChessTimer.formatTime(whiteTimeRemaining);
  String get blackTimeFormatted => ChessTimer.formatTime(blackTimeRemaining);

  bool get isWhiteInDanger => whiteTimeRemaining <= 30;
  bool get isBlackInDanger => blackTimeRemaining <= 30;
}
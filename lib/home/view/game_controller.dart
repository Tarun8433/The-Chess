import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/game_status.dart';
import 'online_game.dart';

class GameStatusManager extends StatefulWidget {
  final String gameId;
  final String roomId;
  final Widget child;
  final ChessGameService gameService;

  const GameStatusManager({
    super.key,
    required this.gameId,
    required this.roomId,
    required this.child,
    required this.gameService,
  });

  @override
  State<GameStatusManager> createState() => _GameStatusManagerState();
}

class _GameStatusManagerState extends State<GameStatusManager> {
  GameStatus? _previousStatus;
  String? _currentUserId;
  bool _dialogShown = false;
  Timer? _disconnectTimer;
  static const Duration _disconnectTimeout = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _startHeartbeat();
  }

  @override
  void dispose() {
    _disconnectTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    if (_currentUserId == null) return;

    // Update player last seen every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updatePlayerLastSeen();
    });
  }

  void _updatePlayerLastSeen() async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chess_games')
          .doc(widget.gameId)
          .update({
        'playerLastSeen.$_currentUserId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently handle errors to avoid disrupting gameplay
    }
  }

  void _checkForDisconnectedPlayers(ChessGameState gameState) {
    if (gameState.gameStatus != GameStatus.active) return;

    final now = DateTime.now();
    final players = gameState.players;

    for (final playerId in players) {
      if (playerId == _currentUserId) continue; // Skip current user

      final lastSeen = gameState.playerLastSeen[playerId];
      if (lastSeen != null) {
        final timeSinceLastSeen = now.difference(lastSeen);

        if (timeSinceLastSeen > _disconnectTimeout) {
          _handlePlayerDisconnect(playerId);
          break;
        }
      }
    }
  }

  void _handlePlayerDisconnect(String playerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chess_games')
          .doc(widget.gameId)
          .update({
        'gameStatus': GameStatus.disconnected.value,
        'disconnectedPlayer': playerId,
        'lastMoveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleStatusChange(ChessGameState gameState) {
    final currentStatus = gameState.gameStatus;

    // Skip if status hasn't changed or if it's the initial load
    if (_previousStatus == currentStatus || _previousStatus == null) {
      _previousStatus = currentStatus;
      return;
    }

    // Show snackbar for status changes
    _showStatusSnackbar(gameState, _previousStatus!, currentStatus);

    // Show dialog for game end scenarios
    if (currentStatus.isGameOver && !_dialogShown) {
      _showGameEndDialog(gameState);
      _dialogShown = true;
    }

    _previousStatus = currentStatus;
  }

  // void _showMoveSnackbar(String playerName, String move) {
  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$playerName played $move'),
  //       backgroundColor: Colors.blue,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }

  // void _showConnectionSnackbar(String playerName, bool connected) {
  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(connected ? '$playerName reconnected' : '$playerName disconnected'),
  //       backgroundColor: connected ? Colors.green : Colors.orange,
  //       duration: const Duration(seconds: 3),
  //     ),
  //   );
  // }

  void _showStatusSnackbar(
      ChessGameState gameState, GameStatus oldStatus, GameStatus newStatus) {
    if (!mounted) return;

    String message;
    Color backgroundColor;

    switch (newStatus) {
      case GameStatus.resigned:
        final resignedBy = gameState.resignedBy;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isCurrentUserResigned = resignedBy == currentUserId;
        message = isCurrentUserResigned ? 'You resigned' : 'Opponent resigned';
        backgroundColor = Colors.red;
        break;

      case GameStatus.checkmate:
        final winner = gameState.getWinner();
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isWin = winner == currentUserId;
        message = isWin ? 'Checkmate! You won!' : 'Checkmate! You lost!';
        backgroundColor = isWin ? Colors.green : Colors.red;
        break;

      case GameStatus.draw:
        message = 'Game ended in a draw';
        backgroundColor = Colors.grey;
        break;

      case GameStatus.disconnected:
        message = 'Player disconnected';
        backgroundColor = Colors.orange;
        break;

      case GameStatus.timeout:
        final winner = gameState.getWinner();
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isWin = winner == currentUserId;
        message = isWin ? 'You won by timeout!' : 'You lost by timeout!';
        backgroundColor = isWin ? Colors.green : Colors.red;
        break;

      case GameStatus.active:
        if (oldStatus != GameStatus.active) {
          message = 'Game resumed';
          backgroundColor = Colors.green;
        } else {
          return; // Don't show snackbar for initial active state
        }
        break;

      case GameStatus.abandoned:
        message = 'Game abandoned';
        backgroundColor = Colors.grey;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showGameEndDialog(ChessGameState gameState) {
    if (!mounted) return;

    final status = gameState.gameStatus;
    final winner = gameState.getWinner();
    final isWinner = winner == _currentUserId;

    String title = 'Game Over';
    //String message = status.getDisplayMessage(isWinner);
    Color titleColor = Colors.white;
    IconData icon = Icons.info;

    switch (status) {
      case GameStatus.checkmate:
        title = isWinner ? 'Victory!' : 'Defeat';
        titleColor = isWinner ? Colors.green : Colors.red;
        icon = isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied;
        break;
      case GameStatus.resigned:
        title = isWinner ? 'Victory!' : 'Game Over';
        titleColor = isWinner ? Colors.green : Colors.orange;
        icon = isWinner ? Icons.emoji_events : Icons.flag;
        break;
      case GameStatus.draw:
        title = 'Draw';
        titleColor = Colors.grey;
        icon = Icons.handshake;
        break;
      case GameStatus.disconnected:
      case GameStatus.timeout:
        title = isWinner ? 'Victory!' : 'Disconnected';
        titleColor = isWinner ? Colors.green : Colors.grey;
        icon = isWinner ? Icons.emoji_events : Icons.wifi_off;
        break;
      default:
        break;
    }

    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) => AlertDialog(
    //     backgroundColor: const Color(0xFF2C2C2C),
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    //     title: Row(
    //       children: [
    //         Icon(icon, color: titleColor, size: 28),
    //         const SizedBox(width: 12),
    //         Text(
    //           title,
    //           style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
    //         ),
    //       ],
    //     ),
    //     content: Text(
    //       message,
    //       style: const TextStyle(color: Colors.white, fontSize: 16),
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () {
    //           Navigator.of(context).pop(); // Close dialog
    //           Navigator.of(context).pop(); // Go back to previous screen
    //         },
    //         child: const Text(
    //           'Back to Lobby',
    //           style: TextStyle(color: Colors.blue),
    //         ),
    //       ),
    //       if (status == GameStatus.checkmate || status == GameStatus.draw)
    //         TextButton(
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //             _showGameReview(gameState);
    //           },
    //           child: const Text(
    //             'Review Game',
    //             style: TextStyle(color: Colors.green),
    //           ),
    //         ),
    //     ],
    //   ),
    // );
  }

  void _showGameReview(ChessGameState gameState) {
    // TODO: Implement game review functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game review feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // String? _getResignedPlayer(ChessGameState gameState) {
  //   // This would need to be tracked in the game state
  //   // For now, we'll return null and handle it in the service layer
  //   return null;
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChessGameState>(
      stream: widget.gameService.getChessGame(widget.gameId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final gameState = snapshot.data!;
          // Only process if this is a new state update
          if (_previousStatus != gameState.gameStatus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Check for disconnected players
              _checkForDisconnectedPlayers(gameState);
              _handleStatusChange(gameState);
            });
          }
        }
        return widget.child;
      },
    );
  }
}

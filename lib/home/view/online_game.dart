// File: lib/models/game_message_model.dart
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
// File: lib/screens/enhanced_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:the_chess/components/dead_piece.dart';

import 'package:the_chess/components/pieces.dart';
import 'package:the_chess/components/square.dart';
import 'package:the_chess/home/model/game_status.dart';
import 'package:the_chess/home/view/home_screen.dart';
import 'package:the_chess/screens/game_board_screen.dart';
import 'package:the_chess/values/colors.dart';
import 'game_controller.dart';
import '../../services/game_history_service.dart';
import 'match_macking/match_macking_service.dart';
import '../../services/chess_timer.dart';
import '../../services/chess_timer_service.dart';
import '../../widgets/chess_timer_widget.dart';

class GameMessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String type; // 'text', 'chess_move', 'chess_invite', 'chess_resign'
  final Map<String, dynamic>? gameData;

  GameMessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.gameData,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'gameData': gameData,
    };
  }

  factory GameMessageModel.fromMap(Map<String, dynamic> map) {
    return GameMessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: map['type'] ?? 'text',
      gameData: map['gameData'] != null
          ? Map<String, dynamic>.from(map['gameData'])
          : null,
    );
  }
}

// File: lib/models/chess_game_state.dart
class ChessGameState {
  final String gameId;
  final List<String> players;
  final String whitePlayerId;
  final String blackPlayerId;
  final Map<String, Map<String, dynamic>?>
      board; // Flattened: "0-0", "0-1", etc.
  final bool isWhiteTurn;
  final GameStatus gameStatus;
  final List<Map<String, dynamic>> moveHistory;
  final DateTime createdAt;
  final DateTime lastMoveAt;
  final Map<String, DateTime> playerLastSeen;
  final String? resignedBy;

  ChessGameState({
    required this.gameId,
    required this.players,
    required this.whitePlayerId,
    required this.blackPlayerId,
    required this.board,
    required this.isWhiteTurn,
    required this.gameStatus,
    required this.moveHistory,
    required this.createdAt,
    required this.lastMoveAt,
    this.playerLastSeen = const {},
    this.resignedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'players': players,
      'board': board,
      'isWhiteTurn': isWhiteTurn,
      'gameStatus': gameStatus.value,
      'moveHistory': moveHistory,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMoveAt': lastMoveAt.millisecondsSinceEpoch,
      'playerLastSeen':
          playerLastSeen.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      'resignedBy': resignedBy,
    };
  }

  factory ChessGameState.fromMap(Map<String, dynamic> map) {
    return ChessGameState(
      gameId: map['gameId'] ?? '',
      players: List<String>.from(map['players'] ?? []),
      whitePlayerId: map['whitePlayerId'] ?? '',
      blackPlayerId: map['blackPlayerId'] ?? '',
      board: _parseBoardData(map['board']),
      isWhiteTurn: map['isWhiteTurn'] ?? true,
      gameStatus: GameStatus.fromString(map['gameStatus'] ?? 'active'),
      moveHistory: List<Map<String, dynamic>>.from(map['moveHistory'] ?? []),
      createdAt: _parseTimestamp(map['createdAt']),
      lastMoveAt: _parseTimestamp(map['lastMoveAt']),
      playerLastSeen: _parsePlayerLastSeen(map['playerLastSeen']),
      resignedBy: map['resignedBy'],
    );
  }

  static Map<String, Map<String, dynamic>?> _parseBoardData(dynamic boardData) {
    if (boardData == null) return {};

    Map<String, Map<String, dynamic>?> result = {};
    Map<String, dynamic> rawBoard = Map<String, dynamic>.from(boardData);

    rawBoard.forEach((key, value) {
      if (value != null) {
        result[key] = Map<String, dynamic>.from(value);
      } else {
        result[key] = null;
      }
    });

    return result;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is firestore.Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  static Map<String, DateTime> _parsePlayerLastSeen(dynamic data) {
    if (data == null) return {};
    Map<String, DateTime> result = {};
    Map<String, dynamic> rawData = Map<String, dynamic>.from(data);
    rawData.forEach((key, value) {
      if (value is int) {
        result[key] = DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is firestore.Timestamp) {
        result[key] = value.toDate();
      }
    });
    return result;
  }

  bool isPlayerDisconnected(String playerId,
      {Duration timeout = const Duration(minutes: 2)}) {
    final lastSeen = playerLastSeen[playerId];
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen) > timeout;
  }

  String? getWinner() {
    if (!gameStatus.isGameOver) return null;
    if (gameStatus.isDraw) return null;

    // For checkmate, the winner is the player whose turn it's NOT
    if (gameStatus == GameStatus.checkmate) {
      return isWhiteTurn
          ? players[1]
          : players[0]; // Black wins if white's turn, vice versa
    }

    // For resignation, the other player wins
    if (gameStatus == GameStatus.resigned && resignedBy != null) {
      // The winner is the player who didn't resign
      return players.firstWhere((player) => player != resignedBy);
    }

    // For disconnection, timeout - the other player wins
    if (gameStatus.isDisconnected) {
      // Need to determine who resigned/disconnected based on context
      return null; // Will be determined by the service layer
    }

    return null;
  }

  List<List<Map<String, dynamic>?>> get boardAs2D {
    List<List<Map<String, dynamic>?>> result = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    );

    board.forEach((key, value) {
      final coords = key.split('-');
      final row = int.parse(coords[0]);
      final col = int.parse(coords[1]);
      result[row][col] = value;
    });

    return result;
  }

  static Map<String, Map<String, dynamic>?> board2DToFlat(
      List<List<Map<String, dynamic>?>> board2D) {
    Map<String, Map<String, dynamic>?> flatBoard = {};

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        flatBoard['$row-$col'] = board2D[row][col];
      }
    }

    return flatBoard;
  }
}

class ChessGameService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GameHistoryService _gameHistoryService = GameHistoryService();

  Future<String> createChessGame(String roomId, String opponentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Use a transaction to prevent race conditions
    return await _firestore.runTransaction<String>((transaction) async {
      // First check if a game already exists for this room
      final existingGamesQuery = await _firestore
          .collection('chess_games')
          .where('roomId', isEqualTo: roomId)
          .where('gameStatus', isEqualTo: GameStatus.active.value)
          .limit(1)
          .get();

      if (existingGamesQuery.docs.isNotEmpty) {
        // Game already exists, return its ID
        return existingGamesQuery.docs.first.id;
      }

      final gameRef = _firestore.collection('chess_games').doc();
      final gameId = gameRef.id;

      Map<String, Map<String, dynamic>?> initialBoard =
          _createInitialBoardFlat();

      // Deterministic color assignment based on user IDs
      // The user with the lexicographically smaller UID gets white
      String whitePlayerId, blackPlayerId;
      List<String> sortedPlayers = [user.uid, opponentId]..sort();

      whitePlayerId = sortedPlayers[0]; // First in sorted order gets white
      blackPlayerId = sortedPlayers[1]; // Second in sorted order gets black

      Map<String, dynamic> chessGameData = {
        'gameId': gameId,
        'roomId': roomId,
        'players': [whitePlayerId, blackPlayerId], // Store in white-first order
        'whitePlayerId': whitePlayerId,
        'blackPlayerId': blackPlayerId,
        'board': initialBoard,
        'isWhiteTurn': true,
        'gameStatus': GameStatus.active.value,
        'moveHistory': [],
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'lastMoveAt': firestore.FieldValue.serverTimestamp(),
      };

      transaction.set(gameRef, chessGameData);
      return gameId;
    }).then((gameId) async {
      // Send invite message and add to history after transaction
      await _sendChessInviteMessage(roomId, gameId);
      await _gameHistoryService.addGameToHistory(gameId, opponentId, roomId);
      return gameId;
    });
  }

  Future<String> createChessGameWithTransaction(
      firestore.Transaction transaction,
      String roomId,
      String opponentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Check if a game already exists for this room within the transaction
    final existingGamesQuery = await _firestore
        .collection('chess_games')
        .where('roomId', isEqualTo: roomId)
        .where('gameStatus', isEqualTo: GameStatus.active.value)
        .limit(1)
        .get();

    if (existingGamesQuery.docs.isNotEmpty) {
      // Game already exists, return its ID
      return existingGamesQuery.docs.first.id;
    }

    final gameRef = _firestore.collection('chess_games').doc();
    final gameId = gameRef.id;

    Map<String, Map<String, dynamic>?> initialBoard = _createInitialBoardFlat();

    // Deterministic color assignment based on user IDs
    String whitePlayerId, blackPlayerId;
    List<String> sortedPlayers = [user.uid, opponentId]..sort();

    whitePlayerId = sortedPlayers[0]; // First in sorted order gets white
    blackPlayerId = sortedPlayers[1]; // Second in sorted order gets black

    Map<String, dynamic> chessGameData = {
      'gameId': gameId,
      'roomId': roomId,
      'players': [whitePlayerId, blackPlayerId], // Store in white-first order
      'whitePlayerId': whitePlayerId,
      'blackPlayerId': blackPlayerId,
      'board': initialBoard,
      'isWhiteTurn': true,
      'gameStatus': GameStatus.active.value,
      'moveHistory': [],
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'lastMoveAt': firestore.FieldValue.serverTimestamp(),
    };

    transaction.set(gameRef, chessGameData);

    // Send invite message after transaction (outside of transaction)
    Future.delayed(
        Duration.zero, () => _sendChessInviteMessage(roomId, gameId));

    // Add game to history for both players (outside of transaction)
    Future.delayed(Duration.zero,
        () => _gameHistoryService.addGameToHistory(gameId, opponentId, roomId));

    return gameId;
  }

  // Also fix the makeChessMove method to ensure proper turn checking
  Future<void> makeChessMove(
      String gameId, String roomId, Map<String, dynamic> moveData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    debugPrint('Making chess move in Firestore for gameId: $gameId');
    debugPrint(
        'Move data: ${moveData['fromRow']},${moveData['fromCol']} -> ${moveData['toRow']},${moveData['toCol']}');

    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('chess_games').doc(gameId);
      final gameDoc = await transaction.get(gameRef);

      if (!gameDoc.exists) throw Exception('Game not found');

      final gameState = ChessGameState.fromMap(gameDoc.data()!);

      // Check if it's the player's turn based on their actual color
      bool isWhitePlayer = gameState.whitePlayerId == user.uid;
      bool isBlackPlayer = gameState.blackPlayerId == user.uid;

      if (!isWhitePlayer && !isBlackPlayer) {
        throw Exception('You are not a player in this game');
      }

      // Check if it's actually their turn
      if ((isWhitePlayer && !gameState.isWhiteTurn) ||
          (isBlackPlayer && gameState.isWhiteTurn)) {
        throw Exception('Not your turn');
      }

      List<Map<String, dynamic>> updatedHistory =
          List.from(gameState.moveHistory);
      updatedHistory.add({
        ...moveData,
        'playerId': user.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      Map<String, dynamic> updates = {
        'board': moveData['newBoard'],
        'isWhiteTurn': !gameState.isWhiteTurn,
        'moveHistory': updatedHistory,
        'lastMoveAt': firestore.FieldValue.serverTimestamp(),
      };

      if (moveData['isCheckmate'] == true) {
        updates['gameStatus'] = GameStatus.checkmate.value;
      } else if (moveData['isDraw'] == true) {
        updates['gameStatus'] = GameStatus.draw.value;
      }

      // Update player last seen
      updates['playerLastSeen.${user.uid}'] =
          firestore.FieldValue.serverTimestamp();

      transaction.update(gameRef, updates);
      debugPrint('Game state updated successfully in Firestore');
    });

    debugPrint('Sending chess move message to chat...');
    await _sendChessMoveMessage(roomId, gameId, moveData);
    debugPrint('Chess move completed successfully');
  }

  // Rest of the methods remain the same...
  Map<String, Map<String, dynamic>?> _createInitialBoardFlat() {
    Map<String, Map<String, dynamic>?> board = {};

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        board['$row-$col'] = null;
      }
    }

    for (int i = 0; i < 8; i++) {
      board['1-$i'] = {
        'type': 'pawn',
        'isWhite': false,
        'imagePath': 'assets/images/figures/black/pawn.png',
      };
      board['6-$i'] = {
        'type': 'pawn',
        'isWhite': true,
        'imagePath': 'assets/images/figures/white/pawn.png',
      };
    }

    final pieceOrder = [
      'rook',
      'knight',
      'bishop',
      'queen',
      'king',
      'bishop',
      'knight',
      'rook'
    ];

    for (int i = 0; i < 8; i++) {
      board['0-$i'] = {
        'type': pieceOrder[i],
        'isWhite': false,
        'imagePath': 'assets/images/figures/black/${pieceOrder[i]}.png',
      };
      board['7-$i'] = {
        'type': pieceOrder[i],
        'isWhite': true,
        'imagePath': 'assets/images/figures/white/${pieceOrder[i]}.png',
      };
    }

    return board;
  }

  Stream<ChessGameState> getChessGame(String gameId) {
    return _firestore
        .collection('chess_games')
        .doc(gameId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        throw Exception('Game not found');
      }
      return ChessGameState.fromMap(doc.data()!);
    });
  }

  Future<void> _sendChessInviteMessage(String roomId, String gameId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final message = GameMessageModel(
      messageId: messageRef.id,
      senderId: user.uid,
      content: 'Chess game invitation',
      timestamp: DateTime.now(),
      type: 'chess_invite',
      gameData: {'gameId': gameId},
    );

    await messageRef.set(message.toMap());
  }

  Future<void> _sendChessMoveMessage(
      String roomId, String gameId, Map<String, dynamic> moveData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final message = GameMessageModel(
      messageId: messageRef.id,
      senderId: user.uid,
      content: 'Made a chess move: ${moveData['moveNotation'] ?? 'Move'}',
      timestamp: DateTime.now(),
      type: 'chess_move',
      gameData: {'gameId': gameId, 'move': moveData},
    );

    await messageRef.set(message.toMap());
  }

  Future<void> resignChessGame(String gameId, String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('chess_games').doc(gameId).update({
      'gameStatus': GameStatus.resigned.value,
      'resignedBy': user.uid,
      'lastMoveAt': firestore.FieldValue.serverTimestamp(),
    });

    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final message = GameMessageModel(
      messageId: messageRef.id,
      senderId: user.uid,
      content: 'Resigned from the chess game',
      timestamp: DateTime.now(),
      type: 'chess_resign',
      gameData: {'gameId': gameId},
    );

    await messageRef.set(message.toMap());
  }
}

class EnhancedChatScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;

  const EnhancedChatScreen(
      {super.key, required this.roomId, required this.partnerName});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final ChessGameService _chessGameService = ChessGameService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? activeChessGameId;
  bool isCreatingGame = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _sendTextMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendTextMessage(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messageRef = firestore.FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageId': messageRef.id,
      'senderId': user.uid,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'text',
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startChessGame() async {
    if (isCreatingGame) return;

    setState(() {
      isCreatingGame = true;
    });

    try {
      final roomDoc = await firestore.FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .get();

      if (roomDoc.exists) {
        final roomData = roomDoc.data()!;
        final participants = List<String>.from(roomData['participants']);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final opponentId = participants.firstWhere((id) => id != currentUserId);

        final gameId =
            await _chessGameService.createChessGame(widget.roomId, opponentId);

        setState(() {
          activeChessGameId = gameId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chess game started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chess game: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isCreatingGame = false;
      });
    }
  }

  void _openChessGame(String gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameBoardScreen(
          roomId: widget.roomId,
          partnerName: widget.partnerName,
        ),
      ),
    );
  }

  Widget _buildGameMessage(GameMessageModel message) {
    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;

    if (message.type == 'chess_invite') {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          color: Colors.blue[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sports_esports,
                          color: Colors.blue[800], size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe
                                ? 'You sent a chess invitation'
                                : 'Chess invitation received!',
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[800],
                            ),
                          ),
                          Text(
                            'Ready to play chess?',
                            style:
                                GoogleFonts.orbitron(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final gameId = message.gameData!['gameId'];
                        _openChessGame(gameId);
                      },
                      icon: Icon(Icons.play_arrow),
                      label: Text(isMe ? 'View Game' : 'Accept & Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (message.type == 'chess_move') {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_esports,
                          size: 16, color: Colors.green[800]),
                      SizedBox(width: 4),
                      Text(
                        'Chess Move',
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  Text(message.content),
                  TextButton(
                    onPressed: () =>
                        _openChessGame(message.gameData!['gameId']),
                    child: Text('View Game'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: GoogleFonts.orbitron(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Chat with ${widget.partnerName}'),
      //   actions: [
      //     Container(
      //       margin: EdgeInsets.only(right: 8),
      //       child: IconButton(
      //         onPressed: activeChessGameId == null && !isCreatingGame
      //             ? _startChessGame
      //             : null,
      //         icon: isCreatingGame
      //             ? SizedBox(
      //                 width: 20,
      //                 height: 20,
      //                 child: CircularProgressIndicator(
      //                   strokeWidth: 2,
      //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      //                 ),
      //               )
      //             : Icon(
      //                 Icons.sports_esports,
      //                 color: activeChessGameId != null
      //                     ? Colors.grey
      //                     : Colors.white,
      //               ),
      //         tooltip: activeChessGameId != null
      //             ? 'Game already started'
      //             : 'Start Chess Game',
      //         style: IconButton.styleFrom(
      //           backgroundColor: activeChessGameId != null
      //               ? Colors.grey[300]
      //               : Colors.blue[600],
      //           foregroundColor: Colors.white,
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(8),
      //           ),
      //         ),
      //       ),
      //     ),
      //     IconButton(
      //       icon: Icon(Icons.call_end, color: Colors.red),
      //       onPressed: () => Navigator.pop(context),
      //     ),
      //   ],
      // ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GameMessageModel>>(
              stream: _getEnhancedMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildGameMessage(messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<GameMessageModel>> _getEnhancedMessages() {
    return firestore.FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameMessageModel.fromMap(doc.data()))
          .toList();
    });
  }
}

class OnlineBoardGame extends StatefulWidget {
  final String gameId;
  final String roomId;
  final bool isLocalPlayerWhite;
  final String? localPlayerName;
  final String? opponentName;

  const OnlineBoardGame({
    super.key,
    required this.gameId,
    required this.roomId,
    required this.isLocalPlayerWhite,
    this.localPlayerName,
    this.opponentName,
  });

  @override
  State<OnlineBoardGame> createState() => _OnlineBoardGameState();
}

class _OnlineBoardGameState extends State<OnlineBoardGame> {
  final ChessGameService _chessGameService = ChessGameService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ChessGameState>? _gameSubscription;
  ChessGameState? currentGameState;
  bool isMyTurn = false;
  bool isWhitePlayer = false;
  bool isDrawerOpen = false;
  int unreadMessageCount = 0;
  String localPlayerDisplayName = 'You';
  String opponentDisplayName = 'Opponent';

  // Chess Timer
  ChessTimer? _chessTimer;
  TimerState? _currentTimerState;
  StreamSubscription<TimerState>? _timerSubscription;
  StreamSubscription<GameResult>? _gameResultSubscription;
  bool _timerStarted = false;

  late List<List<ChessPiece?>> board;
  ChessPiece? selectedPiece;
  int selectedRow = -1;
  int selectedCol = -1;
  List<List<int>> validMoves = [];
  List<ChessPiece> whitePiecesTaken = [];
  List<ChessPiece> blackPiecesTaken = [];
  bool isWhiteTurn = true;
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _setupGameListener();
    _setupPlayerNames();
    _initializeTimer();
  }

  void _setupPlayerNames() {
    // Setup local player name
    final currentUser = FirebaseAuth.instance.currentUser;

    log("currentUser==>> uid: ${currentUser?.uid}, email: ${currentUser?.email}, displayName: ${currentUser?.displayName}");

    // Prioritize widget parameter, then user profile data
    if (widget.localPlayerName != null &&
        widget.localPlayerName!.isNotEmpty &&
        widget.localPlayerName != 'Anonymous') {
      localPlayerDisplayName = widget.localPlayerName!;
    } else if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty &&
        currentUser.displayName != 'Anonymous') {
      localPlayerDisplayName = currentUser.displayName!;
    } else if (currentUser?.email != null) {
      localPlayerDisplayName = currentUser!.email!.split('@')[0];
    } else {
      localPlayerDisplayName =
          'You (${currentUser?.uid.substring(0, 6) ?? "Unknown"})';
    }

    // Setup opponent name - this will be updated from room data
    if (widget.opponentName != null &&
        widget.opponentName!.isNotEmpty &&
        widget.opponentName != 'Anonymous') {
      opponentDisplayName = widget.opponentName!;
    } else {
      opponentDisplayName = 'Opponent Player';
    }

    // Ensure names are different
    if (localPlayerDisplayName == opponentDisplayName) {
      opponentDisplayName = 'Opponent';
    }

    debugPrint(
        'Initial player names - Local: $localPlayerDisplayName, Opponent: $opponentDisplayName');

    // Fetch actual opponent name from chat room
    _fetchOpponentNameFromRoom();
  }

  void _fetchOpponentNameFromRoom() async {
    try {
      final roomDoc = await firestore.FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .get();

      if (roomDoc.exists) {
        final roomData = roomDoc.data()!;
        final participants = List<String>.from(roomData['participants']);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final opponentId = participants.firstWhere((id) => id != currentUserId);

        // Try multiple sources to get opponent name
        String? foundOpponentName;

        // 1. Try matchmaking queue first
        try {
          final opponentDoc = await firestore.FirebaseFirestore.instance
              .collection('matchmaking_queue')
              .doc(opponentId)
              .get();

          if (opponentDoc.exists) {
            final opponentData = opponentDoc.data()!;
            foundOpponentName = opponentData['displayName'] as String?;
          }
        } catch (e) {
          debugPrint('Error fetching from matchmaking_queue: $e');
        }

        // 2. Try users collection if matchmaking didn't work
        if (foundOpponentName == null ||
            foundOpponentName.isEmpty ||
            foundOpponentName == 'Anonymous') {
          try {
            final userDoc = await firestore.FirebaseFirestore.instance
                .collection('users')
                .doc(opponentId)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;
              foundOpponentName = userData['displayName'] as String? ??
                  userData['name'] as String?;
            }
          } catch (e) {
            debugPrint('Error fetching from users collection: $e');
          }
        }

        // 3. Generate a fallback name based on opponent ID
        if (foundOpponentName == null ||
            foundOpponentName.isEmpty ||
            foundOpponentName == 'Anonymous') {
          foundOpponentName = 'Player ${opponentId.substring(0, 6)}';
        }

        // Update the UI with the found name
        if (foundOpponentName != opponentDisplayName) {
          setState(() {
            opponentDisplayName = foundOpponentName!;
          });
          debugPrint('Updated opponent name to: $foundOpponentName');
        }
      }
    } catch (e) {
      debugPrint('Error fetching opponent name: $e');
      // Fallback to a generic name
      setState(() {
        opponentDisplayName = 'Opponent Player';
      });
    }
  }

  // Initialize chess timer
  void _initializeTimer() async {
    try {
      // Try to load existing timer or create new one
      _chessTimer = await ChessTimerService.loadGameTimer(
        gameId: widget.gameId,
        fallbackVariant: TimerVariant.blitz5_0,
      );

      if (_chessTimer == null) {
        // Create new timer if none exists
        _chessTimer = await ChessTimerService.createGameTimer(
          gameId: widget.gameId,
          variant: TimerVariant.blitz5_0,
        );
      }

      // Listen to timer state changes
      _timerSubscription = _chessTimer!.timerStateStream.listen((timerState) {
        setState(() {
          _currentTimerState = timerState;
        });
      });

      // Listen to game result changes from timer
      _gameResultSubscription = _chessTimer!.gameResultStream.listen((result) {
        _handleTimerGameResult(result);
      });

      debugPrint('Chess timer initialized for game ${widget.gameId}');
    } catch (e) {
      debugPrint('Error initializing timer: $e');
    }
  }

  // Handle game results from timer (timeouts, etc.)
  void _handleTimerGameResult(GameResult result) {
    String title;
    String message;
    Color color;

    switch (result) {
      case GameResult.whiteWins:
        title = 'White Wins!';
        message = widget.isLocalPlayerWhite
            ? 'You won the game!'
            : 'Your opponent won on time';
        color = widget.isLocalPlayerWhite ? Colors.green : Colors.red;
        break;
      case GameResult.blackWins:
        title = 'Black Wins!';
        message = !widget.isLocalPlayerWhite
            ? 'You won the game!'
            : 'Your opponent won on time';
        color = !widget.isLocalPlayerWhite ? Colors.green : Colors.red;
        break;
      case GameResult.draw:
        title = 'Draw!';
        message = 'Game ended in a draw due to insufficient material';
        color = Colors.orange;
        break;
      case GameResult.ongoing:
        return; // No action needed
    }

    _showGameEndDialog(title, message, color);
  }

  // Start the game timer
  void _startGameTimer() async {
    if (_timerStarted) return;

    try {
      await ChessTimerService.startGameTimer(widget.gameId);
      _timerStarted = true;
      debugPrint('Game timer started for ${widget.gameId}');
    } catch (e) {
      debugPrint('Error starting game timer: $e');
    }
  }

  void _updateOpponentNameFromGameState(ChessGameState gameState) {
    // If we still have a generic opponent name, try to get a better one from game state
    if (opponentDisplayName == 'Opponent Player' ||
        opponentDisplayName == 'Opponent') {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final opponentId = gameState.players
          .firstWhere((id) => id != currentUserId, orElse: () => '');

      if (opponentId.isNotEmpty) {
        setState(() {
          opponentDisplayName = 'Player ${opponentId.substring(0, 6)}';
        });
        debugPrint(
            'Updated opponent name from game state: $opponentDisplayName');
      }
    }
  }

  void _setupGameListener() {
    debugPrint('Setting up game listener for gameId: ${widget.gameId}');
    _gameSubscription =
        _chessGameService.getChessGame(widget.gameId).listen((gameState) {
      debugPrint(
          'Received game state update - Turn: ${gameState.isWhiteTurn ? "White" : "Black"}');
      debugPrint('Local player is white: ${widget.isLocalPlayerWhite}');

      // final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      // Use the widget parameter for color assignment
      final newIsWhitePlayer = widget.isLocalPlayerWhite;
      final newIsMyTurn = (newIsWhitePlayer && gameState.isWhiteTurn) ||
          (!newIsWhitePlayer && !gameState.isWhiteTurn);

      debugPrint('Is my turn: $newIsMyTurn');

      // Check for game end conditions
      _checkGameEndConditions(gameState);

      // Update opponent name if we don't have a good one yet
      _updateOpponentNameFromGameState(gameState);

      setState(() {
        currentGameState = gameState;
        isWhitePlayer = newIsWhitePlayer;
        isMyTurn = newIsMyTurn;
        isWhiteTurn = gameState.isWhiteTurn;
        debugPrint('Syncing board from online state...');
        _syncBoardFromOnlineState(gameState);
        debugPrint('Board sync completed');
      });

      // Start timer when game begins (active status and move history exists)
      if (!_timerStarted &&
          gameState.gameStatus == GameStatus.active &&
          gameState.moveHistory.isNotEmpty) {
        _startGameTimer();
      }
    }, onError: (error) {
      debugPrint('Error in game listener: $error');
    });
  }

  void _checkGameEndConditions(ChessGameState gameState) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (gameState.gameStatus == GameStatus.resigned &&
        gameState.resignedBy != null) {
      // Someone resigned
      final didIResign = gameState.resignedBy == currentUserId;

      if (didIResign) {
        // I resigned - this is handled in _resignGame method
        return;
      } else {
        // Opponent resigned - I win!
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGameEndDialog('Victory!',
              '${opponentDisplayName} resigned. You win!', Colors.green);
        });
      }
    } else if (gameState.gameStatus == GameStatus.checkmate) {
      // Checkmate
      final winner = gameState.getWinner();
      final didIWin = winner == currentUserId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (didIWin) {
          _showGameEndDialog('Victory!', 'Checkmate! You win!', Colors.green);
        } else {
          _showGameEndDialog(
              'Defeat', 'Checkmate! ${opponentDisplayName} wins!', Colors.red);
        }
      });
    } else if (gameState.gameStatus == GameStatus.draw) {
      // Draw
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameEndDialog('Draw', 'The game ended in a draw!', Colors.orange);
      });
    }
  }

  void _showGameEndDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.orbitron(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.orbitron(
              color: MyColors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => ChessAppUI()),
                  (route) => false,
                );
              },
              child: Text(
                'Back to Menu',
                style: GoogleFonts.orbitron(
                  color: MyColors.lightGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _syncBoardFromOnlineState(ChessGameState gameState) {
    debugPrint(
        'Syncing board from online state. Move history length: ${gameState.moveHistory.length}');
    final board2D = gameState.boardAs2D;

    int pieceCount = 0;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final pieceData = board2D[row][col];
        if (pieceData != null) {
          board[row][col] = ChessPiece(
            type: _stringToChessPieceType(pieceData['type']),
            isWhite: pieceData['isWhite'],
            imagePath: pieceData['imagePath'],
          );
          pieceCount++;
        } else {
          board[row][col] = null;
        }
      }
    }
    debugPrint('Board sync completed. Total pieces on board: $pieceCount');

    // Rebuild captured pieces lists from move history
    _rebuildCapturedPiecesFromHistory(gameState.moveHistory);
    _findKingPositions();
  }

  void _rebuildCapturedPiecesFromHistory(
      List<Map<String, dynamic>> moveHistory) {
    // Clear existing captured pieces
    whitePiecesTaken.clear();
    blackPiecesTaken.clear();

    // Rebuild from move history
    for (final move in moveHistory) {
      final capturedPieceData = move['capturedPiece'];
      if (capturedPieceData != null) {
        final capturedPiece = ChessPiece(
          type: _stringToChessPieceType(capturedPieceData['type']),
          isWhite: capturedPieceData['isWhite'],
          imagePath: capturedPieceData['imagePath'],
        );

        if (capturedPiece.isWhite) {
          whitePiecesTaken.add(capturedPiece);
        } else {
          blackPiecesTaken.add(capturedPiece);
        }
      }
    }
  }

  void _findKingPositions() {
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece != null && piece.type == ChessPiecesType.king) {
          if (piece.isWhite) {
            whiteKingPosition = [row, col];
          } else {
            blackKingPosition = [row, col];
          }
        }
      }
    }
  }

  ChessPiecesType _stringToChessPieceType(String typeString) {
    switch (typeString) {
      case 'pawn':
        return ChessPiecesType.pawn;
      case 'rook':
        return ChessPiecesType.rook;
      case 'knight':
        return ChessPiecesType.knight;
      case 'bishop':
        return ChessPiecesType.bishop;
      case 'queen':
        return ChessPiecesType.queen;
      case 'king':
        return ChessPiecesType.king;
      default:
        return ChessPiecesType.pawn;
    }
  }

  String _chessPieceTypeToString(ChessPiecesType type) {
    return type.toString().split('.').last;
  }

  void _initializeBoard() {
    List<List<ChessPiece?>> newBoard = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    );

    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: false,
        imagePath: 'assets/images/figures/black/pawn.png',
      );
      newBoard[6][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: true,
        imagePath: 'assets/images/figures/white/pawn.png',
      );
    }

    final pieceOrder = [
      ChessPiecesType.rook,
      ChessPiecesType.knight,
      ChessPiecesType.bishop,
      ChessPiecesType.queen,
      ChessPiecesType.king,
      ChessPiecesType.bishop,
      ChessPiecesType.knight,
      ChessPiecesType.rook
    ];

    for (int i = 0; i < 8; i++) {
      newBoard[0][i] = ChessPiece(
        type: pieceOrder[i],
        isWhite: false,
        imagePath:
            'assets/images/figures/black/${_chessPieceTypeToString(pieceOrder[i])}.png',
      );
      newBoard[7][i] = ChessPiece(
        type: pieceOrder[i],
        isWhite: true,
        imagePath:
            'assets/images/figures/white/${_chessPieceTypeToString(pieceOrder[i])}.png',
      );
    }

    board = newBoard;
  }

  void pieceSelected(int row, int col) {
    if (!isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wait for your turn!'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      if (selectedPiece == null && board[row][col] != null) {
        final piece = board[row][col]!;
        if ((isWhitePlayer && piece.isWhite) ||
            (!isWhitePlayer && !piece.isWhite)) {
          selectedPiece = piece;
          selectedRow = row;
          selectedCol = col;
        }
      } else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      } else if (selectedPiece != null &&
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        _makeOnlineMove(row, col);
      }

      validMoves = calculateRealValidMoves(
          selectedRow, selectedCol, selectedPiece, true);
    });
  }

  void _makeOnlineMove(int newRow, int newCol) async {
    if (selectedPiece == null) return;

    debugPrint(
        'Making online move from ($selectedRow, $selectedCol) to ($newRow, $newCol)');

    final fromRow = selectedRow;
    final fromCol = selectedCol;
    final piece = selectedPiece!;
    final capturedPiece = board[newRow][newCol];

    board[newRow][newCol] = piece;
    board[fromRow][fromCol] = null;

    if (piece.type == ChessPiecesType.king) {
      if (piece.isWhite) {
        whiteKingPosition = [newRow, newCol];
      } else {
        blackKingPosition = [newRow, newCol];
      }
    }

    if (capturedPiece != null) {
      if (capturedPiece.isWhite) {
        whitePiecesTaken.add(capturedPiece);
      } else {
        blackPiecesTaken.add(capturedPiece);
      }
    }

    bool isCheckmate = isCheckMate(!isWhiteTurn);
    Map<String, Map<String, dynamic>?> serializedBoard = _serializeBoardFlat();

    Map<String, dynamic> moveData = {
      'fromRow': fromRow,
      'fromCol': fromCol,
      'toRow': newRow,
      'toCol': newCol,
      'piece': {
        'type': _chessPieceTypeToString(piece.type),
        'isWhite': piece.isWhite,
        'imagePath': piece.imagePath,
      },
      'capturedPiece': capturedPiece != null
          ? {
              'type': _chessPieceTypeToString(capturedPiece.type),
              'isWhite': capturedPiece.isWhite,
              'imagePath': capturedPiece.imagePath,
            }
          : null,
      'newBoard': serializedBoard,
      'isCheckmate': isCheckmate,
      'isDraw': false,
      'moveNotation': _generateMoveNotation(
          piece, fromRow, fromCol, newRow, newCol, capturedPiece != null),
    };

    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    try {
      await _chessGameService.makeChessMove(
          widget.gameId, widget.roomId, moveData);

      // Handle timer move
      await ChessTimerService.handleMove(
        gameId: widget.gameId,
        playerId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      if (isCheckmate) {
        // End game timer on checkmate
        final result =
            isWhitePlayer ? GameResult.whiteWins : GameResult.blackWins;
        await ChessTimerService.endGameTimer(widget.gameId,
            result: result, reason: 'Checkmate');

        if (isWhitePlayer) {
          _showGameEndDialog('Victory!', 'Checkmate! You won!', Colors.green);
        } else {
          _showGameEndDialog('Defeat', 'Checkmate! You lost!', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Error making online move: $e');
      _revertMove(fromRow, fromCol, newRow, newCol, piece, capturedPiece);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make move: $e')),
      );
    }
  }

  void _revertMove(int fromRow, int fromCol, int newRow, int newCol,
      ChessPiece piece, ChessPiece? capturedPiece) {
    setState(() {
      board[fromRow][fromCol] = piece;
      board[newRow][newCol] = capturedPiece;

      if (piece.type == ChessPiecesType.king) {
        if (piece.isWhite) {
          whiteKingPosition = [fromRow, fromCol];
        } else {
          blackKingPosition = [fromRow, fromCol];
        }
      }

      if (capturedPiece != null) {
        if (capturedPiece.isWhite) {
          whitePiecesTaken.removeLast();
        } else {
          blackPiecesTaken.removeLast();
        }
      }
    });
  }

  Map<String, Map<String, dynamic>?> _serializeBoardFlat() {
    Map<String, Map<String, dynamic>?> flatBoard = {};

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final key = '$row-$col';
        final piece = board[row][col];
        flatBoard[key] = piece != null
            ? {
                'type': _chessPieceTypeToString(piece.type),
                'isWhite': piece.isWhite,
                'imagePath': piece.imagePath,
              }
            : null;
      }
    }

    return flatBoard;
  }

  String _generateMoveNotation(ChessPiece piece, int fromRow, int fromCol,
      int toRow, int toCol, bool isCapture) {
    String fromPos =
        '${String.fromCharCode('a'.codeUnitAt(0) + fromCol)}${8 - fromRow}';
    String toPos =
        '${String.fromCharCode('a'.codeUnitAt(0) + toCol)}${8 - toRow}';
    String pieceSymbol =
        piece.type.toString().split('.').last.substring(0, 1).toUpperCase();

    if (piece.type == ChessPiecesType.pawn) {
      return isCapture ? '${fromPos.substring(0, 1)}x$toPos' : toPos;
    }

    return isCapture
        ? '$pieceSymbol${fromPos}x$toPos'
        : '$pieceSymbol$fromPos-$toPos';
  }

  List<List<int>> calculateRowValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];
    if (piece == null) return [];

    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPiecesType.pawn:
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
          if ((row == 6 && piece.isWhite) || (row == 1 && !piece.isWhite)) {
            if (board[row + 2 * direction][col] == null) {
              candidateMoves.add([row + 2 * direction, col]);
            }
          }
        }
        for (int sideCol in [col - 1, col + 1]) {
          if (isInBoard(row + direction, sideCol) &&
              board[row + direction][sideCol] != null &&
              board[row + direction][sideCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([row + direction, sideCol]);
          }
        }
        break;

      case ChessPiecesType.rook:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ];
        for (var dir in directions) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) break;
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.knight:
        var moves = [
          [-2, -1],
          [-2, 1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
          [2, -1],
          [2, 1]
        ];
        for (var move in moves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) continue;
          if (board[newRow][newCol] == null ||
              board[newRow][newCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([newRow, newCol]);
          }
        }
        break;

      case ChessPiecesType.bishop:
        var directions = [
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];
        for (var dir in directions) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) break;
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.queen:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];
        for (var dir in directions) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) break;
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.king:
        var moves = [
          [-1, -1],
          [-1, 0],
          [-1, 1],
          [0, -1],
          [0, 1],
          [1, -1],
          [1, 0],
          [1, 1]
        ];
        for (var move in moves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) continue;
          if (board[newRow][newCol] == null ||
              board[newRow][newCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([newRow, newCol]);
          }
        }
        break;
    }

    return candidateMoves;
  }

  bool simulatedMoveIsSafe(
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    List<int>? originalKingPosition;
    if (piece.type == ChessPiecesType.king) {
      originalKingPosition =
          piece.isWhite ? whiteKingPosition : blackKingPosition;

      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    bool kingInCheck = isKingInCheck(piece.isWhite);

    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    if (piece.type == ChessPiecesType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }
    return !kingInCheck;
  }

  bool isKingInCheck(bool isWhiteKing) {
    List<int> kingPosition =
        isWhiteKing ? whiteKingPosition : blackKingPosition;

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }
        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], false);

        for (List<int> move in pieceValidMoves) {
          if (move[0] == kingPosition[0] && move[1] == kingPosition[1]) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool isCheckMate(bool isWhiteKing) {
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }
        List<List<int>> validMoves =
            calculateRealValidMoves(i, j, board[i][j]!, true);
        if (validMoves.isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  List<List<int>> calculateRealValidMoves(
      int row, int col, ChessPiece? piece, bool checkSimulation) {
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRowValidMoves(row, col, piece);

    if (checkSimulation) {
      for (var move in candidateMoves) {
        int endRow = move[0];
        int endCol = move[1];
        if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candidateMoves;
    }
    return realValidMoves;
  }

  bool isInBoard(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  bool isWhite(int index) {
    int row = index ~/ 8;
    int col = index % 8;
    return (row + col) % 2 == 0;
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _matchmakingService.sendMessage(
        widget.roomId,
        _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildChatDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Game Chat',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Room: ${widget.roomId}',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GameMessageModel>>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots()
                  .map((snapshot) {
                return snapshot.docs
                    .map((doc) => GameMessageModel.fromMap(doc.data()))
                    .toList();
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                              child: Text(
                                'O',
                                style: GoogleFonts.orbitron(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          if (!isMe) SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: GoogleFonts.orbitron(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) SizedBox(width: 8),
                          if (isMe)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Text(
                                'Y',
                                style: GoogleFonts.orbitron(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _timerSubscription?.cancel();
    _gameResultSubscription?.cancel();
    ChessTimerService.disposeGameTimer(widget.gameId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentGameState == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        return await _showResignConfirmationDialog();
      },
      child: GameStatusManager(
        gameId: widget.gameId,
        roomId: widget.roomId,
        gameService: _chessGameService,
        child: Scaffold(
          key: _scaffoldKey,
          // backgroundColor: MyColors.lightGray,
          endDrawer: _buildChatDrawer(),
          onEndDrawerChanged: (isOpened) {
            setState(() {
              isDrawerOpen = isOpened;
              if (!isOpened) {
                unreadMessageCount = 0;
              }
            });
          },
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.7),
                radius: 1.2,
                colors: [
                  MyColors.tealGray.withValues(alpha: 0.15),
                  MyColors.lightGray,
                  MyColors.tealGray,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: CirclePatternPainter(),
                  ),
                ),

                // Chess board pattern overlay
                Positioned(
                  top: 100,
                  right: -50,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: MyColors.lightGray.withValues(alpha: 0.05),
                      ),
                      child: CustomPaint(
                        painter: ChessPatternPainter(),
                      ),
                    ),
                  ),
                ),

                // Floating geometric shapes
                Positioned(
                  top: 200,
                  left: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          MyColors.tealGray.withValues(alpha: 0.1),
                          MyColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 150,
                  right: 20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          MyColors.lightGray.withValues(alpha: 0.1),
                          MyColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            //  _buildTopPlayerBar(),
                            _buildCapturedPiecesRow(whitePiecesTaken),
                            const SizedBox(height: 8),
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white, width: 2)),
                                padding: EdgeInsets.all(2),
                                child: _buildBoard()),
                            const SizedBox(height: 8),
                            _buildCapturedPiecesRow(blackPiecesTaken),
                          ],
                        ),
                        Column(
                          children: [
                            // Opponent always at top
                            _buildPlayerInfo2(
                                opponentDisplayName,
                                isWhitePlayer ? "Black" : "White",
                                isWhitePlayer ? !isWhiteTurn : isWhiteTurn),

                            // Chess Timer Display
                            // if (_currentTimerState != null)
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 16.0, vertical: 8.0),
                            //   child: ChessTimerWidget(
                            //     timerState: _currentTimerState!,
                            //     whitePlayerName: isWhitePlayer
                            //         ? localPlayerDisplayName
                            //         : opponentDisplayName,
                            //     blackPlayerName: isWhitePlayer
                            //         ? opponentDisplayName
                            //         : localPlayerDisplayName,
                            //     isLocalPlayerWhite: widget.isLocalPlayerWhite,
                            //   ),
                            // ),

                            Spacer(),
                            // Local player always at bottom
                            _buildPlayerInfo(
                                localPlayerDisplayName,
                                isWhitePlayer ? "White" : "Black",
                                isWhitePlayer ? isWhiteTurn : !isWhiteTurn),
                            // _buildBottomActionBar(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showResignConfirmationDialog() async {
    // If game is already over, allow back press
    if (currentGameState?.gameStatus != GameStatus.active) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Resign Game?',
            style: GoogleFonts.orbitron(
              color: MyColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to resign? Your opponent will win the match.',
            style: GoogleFonts.orbitron(
              color: MyColors.mediumGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Continue Playing',
                style: GoogleFonts.orbitron(
                  color: MyColors.lightGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                await _resignGame();
              },
              child: Text(
                'Resign',
                style: GoogleFonts.orbitron(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _resignGame() async {
    try {
      await _chessGameService.resignChessGame(widget.gameId, widget.roomId);

      // Show resignation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You resigned. ${opponentDisplayName} wins!',
            style: GoogleFonts.orbitron(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back after a short delay
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resign: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTopPlayerBar() {
    String turnText;
    Color turnColor;

    if (currentGameState?.gameStatus != GameStatus.active) {
      turnText = 'Game Over';
      turnColor = Colors.red;
    } else if (isMyTurn) {
      turnText = 'Your Turn';
      turnColor = Colors.green;
    } else {
      turnText = 'Opponent\'s Turn';
      turnColor = Colors.orange;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          'Chess Match',
          style: GoogleFonts.orbitron(
              color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: turnColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            turnText,
            style: GoogleFonts.orbitron(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo(String name, String color, bool isTurn) {
    return Stack(
      children: [
        Image.asset('assets/game/bottomone.PNG'),
        Positioned(
          right: 8,
          top: 8,
          child: Column(
            children: [
              Container(
                height: 60,
                width: 60,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.darkPrimaryVariant,
                  border: Border.all(
                    color: isTurn ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style:
                        GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              if (_currentTimerState != null)
                buildPlayerTimer(
                  playerName: isWhitePlayer
                      ? localPlayerDisplayName
                      : opponentDisplayName,
                  timeRemaining: _currentTimerState!.whiteTimeFormatted,
                  isActive: _currentTimerState!.isWhiteTurn &&
                      _currentTimerState!.isGameActive,
                  isInDanger: _currentTimerState!.isWhiteInDanger,
                  isLocalPlayer: !widget.isLocalPlayerWhite,
                ),
            ],
          ),
        ),
        Positioned(
          top: 32,
          left: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 5,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                color,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo2(String name, String color, bool isTurn) {
    return Stack(
      children: [
        Image.asset('assets/game/topone.png'),
        Positioned(
          right: 8,
          bottom: 8,
          child: Column(
            children: [
              Container(
                height: 60,
                width: 60,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  border: Border.all(
                    color: isTurn ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style:
                        GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              if (_currentTimerState != null)
                buildPlayerTimer(
                  playerName: isWhitePlayer
                      ? localPlayerDisplayName
                      : opponentDisplayName,
                  timeRemaining: _currentTimerState!.blackTimeFormatted,
                  isActive: !_currentTimerState!.isWhiteTurn &&
                      _currentTimerState!.isGameActive,
                  isInDanger: _currentTimerState!.isBlackInDanger,
                  isLocalPlayer: widget.isLocalPlayerWhite,
                ),
            ],
          ),
        ),
        Positioned(
          left: 8,
          bottom: 33,
          child: Text(
            name,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: 80,
          top: 18,
          child: Text(
            color,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemBuilder: (context, index) {
          int row = index ~/ 8;
          int col = index % 8;

          int displayRow = isWhitePlayer ? row : 7 - row;
          int displayCol = isWhitePlayer ? col : 7 - col;

          bool isSelected =
              selectedCol == displayCol && selectedRow == displayRow;
          bool isValidMove = validMoves
              .any((pos) => pos[0] == displayRow && pos[1] == displayCol);

          return Square(
            isWhite: isWhite(index),
            piece: board[displayRow][displayCol],
            isSelected: isSelected,
            isValidMove: isValidMove,
            onTap: () => pieceSelected(displayRow, displayCol),
            isKingInCheck: board[displayRow][displayCol] != null &&
                board[displayRow][displayCol]!.type == ChessPiecesType.king &&
                isKingInCheck(board[displayRow][displayCol]!.isWhite),
            boardBColor: const Color(0xFF4A644D),
            boardWColor: const Color(0xFF9EAD87),
            row: displayRow,
            col: displayCol,
          );
        },
      ),
    );
  }

  // Widget _buildCapturedPieces() {
  //   // Show captured pieces of both colors to both players
  //   return Column(
  //     children: [
  //       _buildCapturedPiecesRow(whitePiecesTaken),
  //       const SizedBox(height: 4),
  //       _buildCapturedPiecesRow(blackPiecesTaken),
  //     ],
  //   );
  // }

  Widget _buildCapturedPiecesRow(List<ChessPiece> pieces) {
    if (pieces.isEmpty) return const SizedBox(height: 30);
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pieces.length,
        itemBuilder: (context, index) => DeadPiece(
          imagePath: pieces[index].imagePath,
          isWhite: pieces[index].isWhite,
        ),
      ),
    );
  }

  // Widget _buildBottomActionBar() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.black.withValues(alpha: 0.2),
  //       borderRadius: BorderRadius.circular(50),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         IconButton(
  //           icon: const Icon(Icons.flag, color: Colors.red),
  //           onPressed: () => _showResignDialog(),
  //           tooltip: 'Resign',
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.chat, color: Colors.blue),
  //           onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
  //           tooltip: 'Open Chat',
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

// Custom painters for background patterns
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MyColors.lightGray.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        canvas.drawCircle(
          Offset(i * 100.0, j * 100.0),
          20.0,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ChessPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MyColors.lightGray.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final squareSize = size.width / 8;
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if ((i + j) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
                i * squareSize, j * squareSize, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/*
========================================
🎮 TOP GAMING FONTS RECOMMENDATIONS 🎮
========================================

1. 🚀 ORBITRON - Perfect for player names and UI text
   - Futuristic, sci-fi feel
   - Great readability
   - GoogleFonts.orbitron()

2. ⚡ RAJDHANI - Excellent for labels and buttons
   - Bold, military-style
   - Clean and modern
   - GoogleFonts.rajdhani()

3. 🎯 BUNGEE - Ideal for scores and numbers
   - Bold, impactful
   - Great for highlighting
   - GoogleFonts.bungee()

4. 🔥 EXOPLANET - Alternative futuristic option
   - GoogleFonts.exo()

5. ⭐ PLAY - Gaming-inspired, clean
   - GoogleFonts.play()

6. 🎲 RUSSO ONE - Bold gaming feel
   - GoogleFonts.russoOne()

7. 🏆 QUANTICO - Military/tech style
   - GoogleFonts.quantico()

8. 💫 ELECTROLIZE - Electric/neon feel
   - GoogleFonts.electrolize()

USAGE EXAMPLES:
================

// For Player Names:
GoogleFonts.orbitron(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
)

// For Labels (YOU, WIN, etc.):
GoogleFonts.rajdhani(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.0,
)

// For Scores/Numbers:
GoogleFonts.bungee(
  fontSize: 24,
  fontWeight: FontWeight.bold,
)

// For Buttons:
GoogleFonts.play(
  fontSize: 16,
  fontWeight: FontWeight.w700,
)

// For Titles/Headers:
GoogleFonts.russoOne(
  fontSize: 20,
  fontWeight: FontWeight.w400,
)

INSTALLATION:
=============
Add to pubspec.yaml:
dependencies:
  google_fonts: ^6.3.1

Then run: flutter pub get

TIPS:
=====
- Use letterSpacing for better readability
- Combine 2-3 fonts max for cohesive design
- Use Orbitron for main text, Rajdhani for labels
- Bungee works great for numbers and scores
- Test fonts on different screen sizes
*/

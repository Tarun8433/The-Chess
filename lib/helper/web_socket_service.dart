// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:the_chess/components/chess_timer.dart';
// import 'package:the_chess/components/dead_piece.dart';
// import 'package:the_chess/components/review_game.dart';
// import 'package:the_chess/components/square.dart';
// import 'package:the_chess/components/timer_widget.dart';
// import 'package:the_chess/values/colors.dart';
// import 'package:the_chess/components/pieces.dart';
// import 'package:the_chess/components/move_history.dart';
// import 'package:uuid/uuid.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';
// import 'dart:async';
// import 'package:web_socket_channel/io.dart';

// // Stores all active game rooms. The key is the room ID.
// final Map<String, GameRoom> gameRooms = {};

// class GameRoom {
//   WebSocketChannel? player1;
//   WebSocketChannel? player2;
//   String? player1Name;
//   String? player2Name;

//   bool get isFull => player1 != null && player2 != null;

//   void addPlayer(WebSocketChannel player, String playerName) {
//     if (player1 == null) {
//       player1 = player;
//       player1Name = playerName;
//       print('Player 1 ($player1Name) joined room.');
//     } else if (player2 == null) {
//       player2 = player;
//       player2Name = playerName;
//       print('Player 2 ($player2Name) joined room.');
//     }
//   }

//   // Send a message to the other player in the room.
//   void relayMessage(WebSocketChannel from, String message) {
//     try {
//       if (from == player1 && player2 != null) {
//         player2!.sink.add(message);
//       } else if (from == player2 && player1 != null) {
//         player1!.sink.add(message);
//       }
//     } catch (e) {
//       print('Error relaying message: $e');
//     }
//   }

//   // Remove a player from the room and notify the other.
//   void removePlayer(WebSocketChannel player) {
//     final Map<String, dynamic> disconnectMessage = {
//       'type': 'opponent_disconnected',
//       'data': {'message': 'Your opponent has disconnected.'}
//     };
//     final String disconnectPayload = jsonEncode(disconnectMessage);

//     try {
//       if (player == player1) {
//         player1 = null;
//         if (player2 != null) player2!.sink.add(disconnectPayload);
//       } else if (player == player2) {
//         player2 = null;
//         if (player1 != null) player1!.sink.add(disconnectPayload);
//       }
//     } catch (e) {
//       print('Error removing player: $e');
//     }
//   }
// }

// // Generates a simple 4-digit room code.
// String generateRoomId() {
//   var r = Random();
//   var id = r.nextInt(9000) + 1000;
//   return id.toString();
// }

// class PlayerAssignment {
//   bool _isLocalPlayerWhite = true;

//   void assignRandomColors() {
//     final random = Random();
//     _isLocalPlayerWhite = random.nextBool();
//   }

//   bool get isLocalPlayerWhite => _isLocalPlayerWhite;

//   bool canSelectPiece(bool isPieceWhite, bool isWhiteTurn) {
//     if (isWhiteTurn) {
//       return _isLocalPlayerWhite && isPieceWhite;
//     } else {
//       return !_isLocalPlayerWhite && !isPieceWhite;
//     }
//   }
// }

// class Message {
//   final String id;
//   final String content;
//   final String senderId;
//   final String senderName;
//   final DateTime timestamp;
//   final bool isMe;

//   Message({
//     required this.id,
//     required this.content,
//     required this.senderId,
//     required this.senderName,
//     required this.timestamp,
//     required this.isMe,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'content': content,
//       'senderId': senderId,
//       'senderName': senderName,
//       'timestamp': timestamp.millisecondsSinceEpoch,
//       'isMe': isMe,
//     };
//   }

//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id'] ?? '',
//       content: json['content'] ?? '',
//       senderId: json['senderId'] ?? '',
//       senderName: json['senderName'] ?? '',
//       timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
//       isMe: json['isMe'] ?? false,
//     );
//   }
// }

// class GameStatePayload {
//   final List<List<Map<String, dynamic>?>> board;
//   final List<Map<String, dynamic>> whitePiecesTaken;
//   final List<Map<String, dynamic>> blackPiecesTaken;
//   final bool isWhiteTurn;
//   final List<int> whiteKingPosition;
//   final List<int> blackKingPosition;
//   final bool checkStatus;
//   final List<int>? enPassantTarget;
//   final Map<String, dynamic>? lastMoveJson;

//   GameStatePayload({
//     required this.board,
//     required this.whitePiecesTaken,
//     required this.blackPiecesTaken,
//     required this.isWhiteTurn,
//     required this.whiteKingPosition,
//     required this.blackKingPosition,
//     required this.checkStatus,
//     this.enPassantTarget,
//     this.lastMoveJson,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'board': board,
//       'whitePiecesTaken': whitePiecesTaken,
//       'blackPiecesTaken': blackPiecesTaken,
//       'isWhiteTurn': isWhiteTurn,
//       'whiteKingPosition': whiteKingPosition,
//       'blackKingPosition': blackKingPosition,
//       'checkStatus': checkStatus,
//       'enPassantTarget': enPassantTarget,
//       'lastMove': lastMoveJson,
//     };
//   }

//   factory GameStatePayload.fromJson(Map<String, dynamic> json) {
//     try {
//       return GameStatePayload(
//         board: (json['board'] as List)
//             .map((row) => (row as List)
//                 .map((pieceJson) => pieceJson != null
//                     ? Map<String, dynamic>.from(pieceJson)
//                     : null)
//                 .toList())
//             .toList(),
//         whitePiecesTaken: (json['whitePiecesTaken'] as List)
//             .map((e) => Map<String, dynamic>.from(e))
//             .toList(),
//         blackPiecesTaken: (json['blackPiecesTaken'] as List)
//             .map((e) => Map<String, dynamic>.from(e))
//             .toList(),
//         isWhiteTurn: json['isWhiteTurn'] ?? true,
//         whiteKingPosition: List<int>.from(json['whiteKingPosition'] ?? [7, 4]),
//         blackKingPosition: List<int>.from(json['blackKingPosition'] ?? [0, 4]),
//         checkStatus: json['checkStatus'] ?? false,
//         enPassantTarget: json['enPassantTarget'] != null
//             ? List<int>.from(json['enPassantTarget'])
//             : null,
//         lastMoveJson: json['lastMove'] != null
//             ? Map<String, dynamic>.from(json['lastMove'])
//             : null,
//       );
//     } catch (e) {
//       print('Error parsing GameStatePayload: $e');
//       rethrow;
//     }
//   }
// }

// class WebSocketService {
//   IOWebSocketChannel? _channel;
//   final StreamController<Map<String, dynamic>> _messageController =
//       StreamController.broadcast();

//   String? roomId;
//   final String userName;
//   bool _isConnected = false;

//   // IMPORTANT: Replace with your server's IP address.
//   static const String SERVER_URL = 'ws://10.0.2.2:8080';

//   Stream<Map<String, dynamic>> get messages => _messageController.stream;
//   bool get isConnected => _isConnected;

//   WebSocketService({required this.userName});

//   Future<void> connect() async {
//     try {
//       print('🔄 Attempting to connect to $SERVER_URL...');
//       _channel = IOWebSocketChannel.connect(Uri.parse(SERVER_URL));

//       // Wait for connection to be established
//       await _channel!.ready;
//       _isConnected = true;

//       _channel!.stream.listen(
//         (message) {
//           try {
//             final decodedMessage = jsonDecode(message);
//             _messageController.add(decodedMessage);
//           } catch (e) {
//             print('Error decoding message: $e');
//           }
//         },
//         onDone: () {
//           print('🔌 WebSocket connection closed');
//           _isConnected = false;
//           _messageController.add({'type': 'disconnected'});
//         },
//         onError: (error) {
//           print('❌ WebSocket error: $error');
//           _isConnected = false;
//           _messageController.add({
//             'type': 'error',
//             'data': {'message': 'Connection error: $error'}
//           });
//         },
//       );

//       print('✅ WebSocket connected to $SERVER_URL');
//     } catch (e) {
//       print('❌ WebSocket connection error: $e');
//       _isConnected = false;
//       _messageController.add({
//         'type': 'error',
//         'data': {'message': 'Failed to connect to the server: $e'}
//       });
//     }
//   }

//   void _send(Map<String, dynamic> message) {
//     if (_channel != null && _isConnected) {
//       try {
//         _channel!.sink.add(jsonEncode(message));
//       } catch (e) {
//         print('Error sending message: $e');
//       }
//     } else {
//       print('Cannot send message: WebSocket not connected');
//     }
//   }

//   void createRoom() {
//     _send({
//       'type': 'create_room',
//       'data': {'userName': userName}
//     });
//   }

//   void joinRoom(String newRoomId) {
//     roomId = newRoomId;
//     _send({
//       'type': 'join_room',
//       'data': {'roomId': roomId, 'userName': userName}
//     });
//   }

//   void sendMessage(Message message) {
//     _send({
//       'type': 'chat_message',
//       'data': {
//         'roomId': roomId,
//         'message': message.toJson(),
//       }
//     });
//   }

//   void sendGameState(GameStatePayload gameState) {
//     _send({
//       'type': 'game_state',
//       'data': {
//         'roomId': roomId,
//         ...gameState.toJson(),
//       }
//     });
//   }

//   void dispose() {
//     _isConnected = false;
//     _channel?.sink.close();
//     _messageController.close();
//   }
// }

// class MultiplayerGameScreen extends StatefulWidget {
//   final String userName;
//   const MultiplayerGameScreen({super.key, required this.userName});

//   @override
//   State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
// }

// class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
//   late WebSocketService _webSocketService;
//   StreamSubscription? _socketSubscription;

//   final List<Message> _messages = [];
//   final TextEditingController _messageController = TextEditingController();
//   final TextEditingController _roomIdController = TextEditingController();
//   final ScrollController _chatScrollController = ScrollController();

//   // Game state variables
//   bool _isInGame = false;
//   String _connectedPeerName = '';
//   String _connectionStatusMessage = 'Connecting to server...';
//   String? _roomId;
//   bool _isLocalPlayerWhite = true;
//   bool _isWaitingForOpponent = false;
//   bool _isConnecting = true;

//   final GlobalKey<BoardGameState> _boardGameKey = GlobalKey<BoardGameState>();

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebSocket();
//   }

//   Future<void> _initializeWebSocket() async {
//     _webSocketService = WebSocketService(userName: widget.userName);

//     try {
//       await _webSocketService.connect();
//       _socketSubscription =
//           _webSocketService.messages.listen(_handleServerMessage);

//       if (mounted) {
//         setState(() {
//           _isConnecting = false;
//           _connectionStatusMessage = _webSocketService.isConnected
//               ? 'Connected to server. Create or join a game!'
//               : 'Failed to connect to server';
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isConnecting = false;
//           _connectionStatusMessage = 'Failed to connect to server: $e';
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _socketSubscription?.cancel();
//     _webSocketService.dispose();
//     _messageController.dispose();
//     _roomIdController.dispose();
//     _chatScrollController.dispose();
//     super.dispose();
//   }

//   void _handleServerMessage(Map<String, dynamic> message) {
//     if (!mounted) return;

//     final String type = message['type'] ?? '';
//     final dynamic data = message['data'];

//     setState(() {
//       switch (type) {
//         case 'room_created':
//           _roomId = data['roomId'];
//           _connectionStatusMessage =
//               'Room created! Code: $_roomId. Waiting for opponent...';
//           _isWaitingForOpponent = true;
//           Clipboard.setData(ClipboardData(text: _roomId!)).then((_) =>
//               _showSnackBar(
//                   'Room ID $_roomId copied to clipboard!', Colors.green));
//           break;

//         case 'game_start':
//           _isInGame = true;
//           _isWaitingForOpponent = false;
//           _connectedPeerName = data['opponentName'] ?? 'Unknown';
//           _connectionStatusMessage = 'Connected to $_connectedPeerName';
//           break;

//         case 'assign_color':
//           _isLocalPlayerWhite = data['isWhite'] ?? true;
//           _showSnackBar(
//               'Game started! You are playing as ${_isLocalPlayerWhite ? "White" : "Black"}.',
//               Colors.green);
//           break;

//         case 'game_state':
//           try {
//             final payload = GameStatePayload.fromJson(data);
//             _handleGameStateReceived(payload);
//           } catch (e) {
//             print('Error handling game state: $e');
//           }
//           break;

//         case 'chat_message':
//           try {
//             final msg = Message.fromJson(data['message']);
//             _handleMessageReceived(msg);
//           } catch (e) {
//             print('Error handling chat message: $e');
//           }
//           break;

//         case 'opponent_disconnected':
//           _resetGameState();
//           _connectionStatusMessage =
//               'Opponent disconnected. Create or join a new game.';
//           _showSnackBar('Opponent has disconnected.', Colors.orange);
//           break;

//         case 'error':
//           _connectionStatusMessage =
//               'Error: ${data['message'] ?? 'Unknown error'}';
//           _isWaitingForOpponent = false;
//           _showSnackBar(
//               'Error: ${data['message'] ?? 'Unknown error'}', Colors.red);
//           break;

//         case 'disconnected':
//           _resetGameState();
//           _connectionStatusMessage = 'Disconnected from server.';
//           break;
//       }
//     });
//   }

//   void _resetGameState() {
//     _isInGame = false;
//     _isWaitingForOpponent = false;
//     _roomId = null;
//     _connectedPeerName = '';
//   }

//   void _showSnackBar(String message, Color backgroundColor) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: backgroundColor,
//         ),
//       );
//     }
//   }

//   void _handleMessageReceived(Message message) {
//     setState(() {
//       _messages.add(message);
//     });
//     _scrollToBottom();
//     HapticFeedback.lightImpact();
//   }

//   void _handleGameStateReceived(GameStatePayload payload) {
//     ChessMove? lastMove;
//     if (payload.lastMoveJson != null) {
//       try {
//         lastMove = ChessMove.fromJson(payload.lastMoveJson!);
//       } catch (e) {
//         print('Error parsing last move: $e');
//       }
//     }

//     _boardGameKey.currentState?.applyGameState(
//       payload.board,
//       payload.whitePiecesTaken,
//       payload.blackPiecesTaken,
//       payload.isWhiteTurn,
//       payload.whiteKingPosition,
//       payload.blackKingPosition,
//       payload.checkStatus,
//       payload.enPassantTarget,
//       lastMove,
//     );
//   }

//   void _createGame() {
//     if (_webSocketService.isConnected) {
//       _webSocketService.createRoom();
//     } else {
//       _showSnackBar('Not connected to server', Colors.red);
//     }
//   }

//   void _joinGame() {
//     final roomIdToJoin = _roomIdController.text.trim();
//     if (roomIdToJoin.isEmpty) {
//       _showSnackBar('Please enter a Room ID.', Colors.red);
//       return;
//     }

//     if (_webSocketService.isConnected) {
//       _webSocketService.joinRoom(roomIdToJoin);
//     } else {
//       _showSnackBar('Not connected to server', Colors.red);
//     }
//   }

//   void _sendMessage() {
//     final messageText = _messageController.text.trim();
//     if (messageText.isEmpty || !_isInGame) return;

//     final message = Message(
//       id: const Uuid().v4(),
//       content: messageText,
//       senderId: 'me',
//       senderName: widget.userName,
//       timestamp: DateTime.now(),
//       isMe: true,
//     );

//     setState(() {
//       _messages.add(message);
//     });

//     _webSocketService.sendMessage(message);
//     _messageController.clear();
//     _scrollToBottom();
//   }

//   void _sendGameStateUpdate(
//     List<List<ChessPiece?>> board,
//     List<ChessPiece> whitePiecesTaken,
//     List<ChessPiece> blackPiecesTaken,
//     bool isWhiteTurn,
//     List<int> whiteKingPosition,
//     List<int> blackKingPosition,
//     bool checkStatus,
//     List<int>? enPassantTarget,
//     ChessMove? lastMove,
//   ) {
//     if (!_isInGame) return;

//     try {
//       List<List<Map<String, dynamic>?>> serializableBoard = board.map((row) {
//         return row.map((piece) => piece?.toJson()).toList();
//       }).toList();

//       List<Map<String, dynamic>> serializableWhiteTaken =
//           whitePiecesTaken.map((piece) => piece.toJson()).toList();
//       List<Map<String, dynamic>> serializableBlackTaken =
//           blackPiecesTaken.map((piece) => piece.toJson()).toList();

//       final gameStatePayload = GameStatePayload(
//         board: serializableBoard,
//         whitePiecesTaken: serializableWhiteTaken,
//         blackPiecesTaken: serializableBlackTaken,
//         isWhiteTurn: isWhiteTurn,
//         whiteKingPosition: whiteKingPosition,
//         blackKingPosition: blackKingPosition,
//         checkStatus: checkStatus,
//         enPassantTarget: enPassantTarget,
//         lastMoveJson: lastMove?.toJson(),
//       );

//       _webSocketService.sendGameState(gameStatePayload);
//     } catch (e) {
//       print('Error sending game state: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:
//             Text(_isInGame ? 'vs. $_connectedPeerName' : 'Multiplayer Chess'),
//         backgroundColor: _isInGame ? Colors.green : Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: _isConnecting
//           ? const Center(child: CircularProgressIndicator())
//           : _isInGame
//               ? _buildGameAndChatInterface()
//               : _buildConnectionOptions(),
//     );
//   }

//   Widget _buildGameAndChatInterface() {
//     return Column(
//       children: [
//         Expanded(
//           flex: 5,
//           child: BoardGame(
//             key: _boardGameKey,
//             onGameStateUpdate: _sendGameStateUpdate,
//             isMultiplayer: true,
//             isLocalPlayerWhite: _isLocalPlayerWhite,
//             name: widget.userName,
//           ),
//         ),
//         const Divider(height: 1),
//         Expanded(
//           flex: 2,
//           child: Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   controller: _chatScrollController,
//                   itemCount: _messages.length,
//                   itemBuilder: (context, index) {
//                     final message = _messages[index];
//                     return _buildMessageBubble(message);
//                   },
//                 ),
//               ),
//               _buildMessageInput(),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildConnectionOptions() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.wifi, size: 100, color: Colors.blue),
//               const SizedBox(height: 20),
//               const Text(
//                 'Multiplayer Chess',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withValues(alpha:0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.withValues(alpha:0.3)),
//                 ),
//                 child: Text(
//                   _connectionStatusMessage,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 16, color: Colors.blue),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               if (_isWaitingForOpponent)
//                 const CircularProgressIndicator()
//               else if (_webSocketService.isConnected)
//                 Column(
//                   children: [
//                     // Create Game
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _createGame,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Create Game'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 15),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Text('OR', style: TextStyle(fontSize: 16)),
//                     const SizedBox(height: 20),
//                     // Join Game
//                     TextField(
//                       controller: _roomIdController,
//                       decoration: const InputDecoration(
//                         labelText: 'Enter Room ID',
//                         border: OutlineInputBorder(),
//                       ),
//                       keyboardType: TextInputType.number,
//                     ),
//                     const SizedBox(height: 10),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _joinGame,
//                         icon: const Icon(Icons.connect_without_contact),
//                         label: const Text('Join Game'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 15),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               else
//                 ElevatedButton.icon(
//                   onPressed: _initializeWebSocket,
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('Retry Connection'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_chatScrollController.hasClients) {
//         _chatScrollController.animateTo(
//           _chatScrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   Widget _buildMessageBubble(Message message) {
//     return Align(
//       alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: message.isMe ? Colors.green : Colors.grey[300],
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!message.isMe)
//               Text(
//                 message.senderName,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             Text(
//               message.content,
//               style: TextStyle(
//                 color: message.isMe ? Colors.white : Colors.black,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               DateFormat('HH:mm').format(message.timestamp),
//               style: TextStyle(
//                 fontSize: 10,
//                 color: message.isMe ? Colors.white70 : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withValues(alpha:0.2),
//             blurRadius: 4,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: const InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(),
//                 contentPadding:
//                     EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               ),
//               onSubmitted: (_) => _sendMessage(),
//             ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             onPressed: _sendMessage,
//             icon: const Icon(Icons.send),
//             color: Colors.green,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Note: The BoardGame class and its state would continue here.
// // Since it's quite large, I'm focusing on the main issues that could cause the Flutter logo freeze.
// // Make sure all your imports are correct and all referenced classes exist.

// // The rest of your code (BoardGame, BoardGameState, etc.) can remain largely the same.
// // The key changes are in how the game is initiated and how state is sent/received.
// // All the logic inside BoardGame for piece movement, validation, etc., does not need to change.
// // Ensure your BoardGame widget and its state are included below this point.

// class BoardGame extends StatefulWidget {
//   final Function(
//     List<List<ChessPiece?>> board,
//     List<ChessPiece> whitePiecesTaken,
//     List<ChessPiece> blackPiecesTaken,
//     bool isWhiteTurn,
//     List<int> whiteKingPosition,
//     List<int> blackKingPosition,
//     bool checkStatus,
//     List<int>? enPassantTarget,
//     ChessMove? lastMove,
//   )? onGameStateUpdate;
//   final bool isMultiplayer;
//   final bool
//       isLocalPlayerWhite; // Indicates if the local player is white in multiplayer
//   final String name;
//   const BoardGame({
//     super.key,
//     this.onGameStateUpdate,
//     this.isMultiplayer = false,
//     this.isLocalPlayerWhite = true,
//     required this.name, // Default to white if not multiplayer
//   });

//   @override
//   State<BoardGame> createState() => BoardGameState();
// }

// class BoardGameState extends State<BoardGame> {
//   // ... All your existing BoardGameState code from the original file ...
//   // No changes are required here, as the logic is self-contained.
//   // Just copy and paste the entire BoardGameState class here.
//   late List<List<ChessPiece?>> board;
//   late ChessTimer chessTimer;
//   Duration whiteTime = Duration(minutes: 10);
//   Duration blackTime = Duration(minutes: 10);
//   bool gameEnded = false;
//   ChessPiece? selectedPiece;
//   int selectedRow = -1;
//   int selectedCol = -1;
//   List<List<int>> validMoves = [];
//   List<ChessPiece> whitePiecesTaken = [];
//   List<ChessPiece> blackPiecesTaken = [];
//   bool isWhiteTurn = true;
//   List<int> whiteKingPosition = [7, 4];
//   List<int> blackKingPosition = [0, 4];
//   bool checkStatus = false;
//   List<int>? enPassantTarget;
//   late PlayerAssignment
//       playerAssignment; // Keep PlayerAssignment for single player logic
//   late ReviewController reviewController;
//   List<List<ChessPiece?>>? reviewBoard;
//   List<ChessPiece>? reviewWhitePiecesTaken;
//   List<ChessPiece>? reviewBlackPiecesTaken;
//   bool? reviewIsWhiteTurn;
//   List<int>? reviewWhiteKingPosition;
//   List<int>? reviewBlackKingPosition;
//   bool? reviewCheckStatus;
//   List<int>? reviewEnPassantTarget;

//   @override
//   void initState() {
//     super.initState();
//     _initializeBoard();
//     _initializeTimer();

//     reviewController = ReviewController();
//     playerAssignment = PlayerAssignment();

//     if (!widget.isMultiplayer) {
//       playerAssignment.assignRandomColors();
//     }
//   }

//   void applyGameState(
//     List<List<Map<String, dynamic>?>> receivedBoard,
//     List<Map<String, dynamic>> receivedWhitePiecesTaken,
//     List<Map<String, dynamic>> receivedBlackPiecesTaken,
//     bool receivedIsWhiteTurn,
//     List<int> receivedWhiteKingPosition,
//     List<int> receivedBlackKingPosition,
//     bool receivedCheckStatus,
//     List<int>? receivedEnPassantTarget,
//     ChessMove? receivedLastMove,
//   ) {
//     setState(() {
//       board = receivedBoard.map((row) {
//         return row
//             .map((pieceJson) =>
//                 pieceJson != null ? ChessPiece.fromJson(pieceJson) : null)
//             .toList();
//       }).toList();
//       whitePiecesTaken =
//           receivedWhitePiecesTaken.map((e) => ChessPiece.fromJson(e)).toList();
//       blackPiecesTaken =
//           receivedBlackPiecesTaken.map((e) => ChessPiece.fromJson(e)).toList();
//       isWhiteTurn = receivedIsWhiteTurn;
//       whiteKingPosition = receivedWhiteKingPosition;
//       blackKingPosition = receivedBlackKingPosition;
//       checkStatus = receivedCheckStatus;
//       enPassantTarget = receivedEnPassantTarget;

//       if (chessTimer.isRunning) {
//         if (isWhiteTurn != chessTimer.isWhiteTurn) {
//           chessTimer.switchTurn();
//         }
//       }

//       if (receivedLastMove != null) {
//         reviewController.addMove(receivedLastMove);
//       }
//     });
//   }

//   void movePiece(int newRow, int newCol) {
//     if (reviewController.isInReviewMode) return;

//     ChessPiece? capturedPiece;
//     ChessPiece? enPassantCapturedPiece;
//     bool wasEnPassant = false;
//     bool wasPromotion = false;
//     ChessPiecesType? promotedToType;
//     List<int> previousKingPosition = selectedPiece!.type == ChessPiecesType.king
//         ? (selectedPiece!.isWhite
//             ? List<int>.from(whiteKingPosition)
//             : List<int>.from(blackKingPosition))
//         : [];

//     List<int>? previousEnPassantTarget =
//         enPassantTarget != null ? List<int>.from(enPassantTarget!) : null;

//     if (selectedPiece?.type == ChessPiecesType.pawn &&
//         enPassantTarget != null &&
//         newRow == enPassantTarget![0] &&
//         newCol == enPassantTarget![1]) {
//       wasEnPassant = true;
//       int capturedPawnRow = selectedPiece!.isWhite ? newRow + 1 : newRow - 1;
//       enPassantCapturedPiece = board[capturedPawnRow][newCol];
//       board[capturedPawnRow][newCol] = null;
//     } else if (board[newRow][newCol] != null) {
//       capturedPiece = board[newRow][newCol];
//     }

//     if (capturedPiece != null) {
//       if (capturedPiece.isWhite) {
//         whitePiecesTaken.add(capturedPiece);
//       } else {
//         blackPiecesTaken.add(capturedPiece);
//       }
//     }

//     List<int>? newEnPassantTarget;
//     if (selectedPiece?.type == ChessPiecesType.pawn) {
//       int moveDistance = (newRow - selectedRow).abs();
//       if (moveDistance == 2) {
//         int enPassantRow = selectedPiece!.isWhite ? newRow + 1 : newRow - 1;
//         newEnPassantTarget = [enPassantRow, newCol];
//       }
//     }

//     if (selectedPiece?.type == ChessPiecesType.king) {
//       if (selectedPiece!.isWhite) {
//         whiteKingPosition = [newRow, newCol];
//       } else {
//         blackKingPosition = [newRow, newCol];
//       }
//     }

//     board[newRow][newCol] = selectedPiece;
//     board[selectedRow][selectedCol] = null;

//     if (selectedPiece?.type == ChessPiecesType.pawn &&
//         ((selectedPiece!.isWhite && newRow == 0) ||
//             (!selectedPiece!.isWhite && newRow == 7))) {
//       wasPromotion = true;
//       promotedToType = ChessPiecesType.queen;
//       board[newRow][newCol] = ChessPiece(
//         type: ChessPiecesType.queen,
//         isWhite: selectedPiece!.isWhite,
//         imagePath: 'images/queen.png',
//       );
//     }

//     enPassantTarget = newEnPassantTarget;
//     bool wasCheck = isKingInCheck(!isWhiteTurn);
//     bool wasCheckmate = false;

//     if (wasCheck) {
//       checkStatus = true;
//       wasCheckmate = isCheckMate(!isWhiteTurn);
//     } else {
//       checkStatus = false;
//     }

//     ChessMove move = ChessMove(
//       piece: selectedPiece!,
//       fromRow: selectedRow,
//       fromCol: selectedCol,
//       toRow: newRow,
//       toCol: newCol,
//       capturedPiece: capturedPiece,
//       wasEnPassant: wasEnPassant,
//       enPassantCapturedPiece: enPassantCapturedPiece,
//       previousEnPassantTarget: previousEnPassantTarget,
//       newEnPassantTarget: newEnPassantTarget,
//       wasPromotion: wasPromotion,
//       promotedToType: promotedToType,
//       wasCheck: wasCheck,
//       wasCheckmate: wasCheckmate,
//       previousKingPosition: previousKingPosition,
//       moveNotation: _generateMoveNotation(selectedPiece!, selectedRow,
//           selectedCol, newRow, newCol, capturedPiece != null),
//       moveTime: DateTime.now().difference(DateTime.now()),
//     );

//     reviewController.addMove(move);

//     if (chessTimer.isRunning) {
//       chessTimer.switchTurn();
//     }

//     setState(() {
//       selectedPiece = null;
//       selectedRow = -1;
//       selectedCol = -1;
//       validMoves = [];
//     });

//     if (wasCheckmate) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("CHECK MATE"),
//           actions: [
//             TextButton(
//                 onPressed: resetGame, child: const Text("Restart The Game"))
//           ],
//         ),
//       );
//     }
//     isWhiteTurn = !isWhiteTurn;
//     widget.onGameStateUpdate?.call(
//       board,
//       whitePiecesTaken,
//       blackPiecesTaken,
//       isWhiteTurn,
//       whiteKingPosition,
//       blackKingPosition,
//       checkStatus,
//       enPassantTarget,
//       move,
//     );
//   }

//   void pieceSelected(int row, int col) {
//     if (gameEnded) return;

//     int actualRow = row;
//     int actualCol = col;

//     if (widget.isMultiplayer && !widget.isLocalPlayerWhite) {
//       actualRow = 7 - row;
//       actualCol = 7 - col;
//     }
//     ChessPiece? pieceAtLocation = currentBoard[actualRow][actualCol];

//     if (reviewController.isInReviewMode) return;

//     setState(() {
//       bool canSelect = false;

//       if (widget.isMultiplayer) {
//         if (pieceAtLocation != null) {
//           bool isPieceOwnedByLocalPlayer =
//               pieceAtLocation.isWhite == widget.isLocalPlayerWhite;
//           bool isLocalPlayersTurn = isWhiteTurn == widget.isLocalPlayerWhite;
//           canSelect = isPieceOwnedByLocalPlayer && isLocalPlayersTurn;
//         }
//       } else {
//         canSelect = (pieceAtLocation != null &&
//             playerAssignment.canSelectPiece(
//                 pieceAtLocation.isWhite, isWhiteTurn));
//       }

//       if (selectedPiece == null && canSelect) {
//         selectedPiece = pieceAtLocation;
//         selectedRow = actualRow;
//         selectedCol = actualCol;
//         if (chessTimer.isStopped) {
//           chessTimer.startTimer();
//         }
//       } else if (pieceAtLocation != null &&
//           selectedPiece != null &&
//           canSelect) {
//         selectedPiece = pieceAtLocation;
//         selectedRow = actualRow;
//         selectedCol = actualCol;
//       } else if (selectedPiece != null &&
//           validMoves.any((element) =>
//               element[0] == actualRow && element[1] == actualCol)) {
//         bool canMakeMove = false;
//         if (widget.isMultiplayer) {
//           bool pieceOwnedByLocalPlayer =
//               selectedPiece!.isWhite == widget.isLocalPlayerWhite;
//           bool isLocalPlayersTurn = isWhiteTurn == widget.isLocalPlayerWhite;
//           canMakeMove = pieceOwnedByLocalPlayer && isLocalPlayersTurn;
//         } else {
//           canMakeMove = playerAssignment.canSelectPiece(
//               selectedPiece!.isWhite, isWhiteTurn);
//         }

//         if (canMakeMove) {
//           movePiece(actualRow, actualCol);
//         }
//       }

//       if (selectedPiece != null) {
//         validMoves = calculateRealValidMoves(
//             selectedRow, selectedCol, selectedPiece, true);
//       } else {
//         validMoves = [];
//       }
//     });
//   }

//   void startReview() {
//     if (!reviewController.canStartReview()) return;

//     reviewController.startReview(
//       board,
//       whitePiecesTaken,
//       blackPiecesTaken,
//       isWhiteTurn,
//       whiteKingPosition,
//       blackKingPosition,
//       checkStatus,
//       enPassantTarget,
//     );
//     _updateReviewState();
//     setState(() {});
//   }

//   void endReview() {
//     reviewController.endReview();
//     reviewBoard = null;
//     reviewWhitePiecesTaken = null;
//     reviewBlackPiecesTaken = null;
//     reviewIsWhiteTurn = null;
//     reviewWhiteKingPosition = null;
//     reviewBlackKingPosition = null;
//     reviewCheckStatus = null;
//     reviewEnPassantTarget = null;
//     setState(() {});
//   }

//   void goToPreviousMove() {
//     reviewController.goToPreviousMove();
//     _updateReviewState();
//     setState(() {});
//   }

//   void goToNextMove() {
//     reviewController.goToNextMove();
//     _updateReviewState();
//     setState(() {});
//   }

//   void goToSpecificMove(int moveIndex) {
//     if (reviewController.isInReviewMode &&
//         moveIndex >= 0 &&
//         moveIndex < reviewController.moveHistory.length) {
//       reviewController.goToMove(moveIndex);
//       _updateReviewState();
//       setState(() {});
//     }
//   }

//   void _updateReviewState() {
//     if (!reviewController.isInReviewMode) return;

//     Map<String, dynamic> boardState = reviewController
//         .getBoardStateAtMove(reviewController.currentReviewIndex);

//     if (boardState.isNotEmpty) {
//       reviewBoard = boardState['board'];
//       reviewWhitePiecesTaken = boardState['whitePiecesTaken'];
//       reviewBlackPiecesTaken = boardState['blackPiecesTaken'];
//       reviewIsWhiteTurn = boardState['isWhiteTurn'];
//       reviewWhiteKingPosition = boardState['whiteKingPosition'];
//       reviewBlackKingPosition = boardState['blackKingPosition'];
//       reviewCheckStatus = boardState['checkStatus'];
//       reviewEnPassantTarget = boardState['enPassantTarget'];
//     }
//   }

//   String _generateMoveNotation(ChessPiece piece, int fromRow, int fromCol,
//       int toRow, int toCol, bool isCapture) {
//     String fromPos =
//         '${String.fromCharCode('a'.codeUnitAt(0) + fromCol)}${8 - fromRow}';
//     String toPos =
//         '${String.fromCharCode('a'.codeUnitAt(0) + toCol)}${8 - toRow}';
//     String pieceSymbol =
//         piece.type.toString().split('.').last.substring(0, 1).toUpperCase();

//     if (piece.type == ChessPiecesType.pawn) {
//       return isCapture ? '${fromPos.substring(0, 1)}x$toPos' : toPos;
//     }

//     return isCapture
//         ? '$pieceSymbol${fromPos}x$toPos'
//         : '$pieceSymbol$fromPos-$toPos';
//   }

//   List<List<ChessPiece?>> get currentBoard =>
//       reviewController.isInReviewMode ? reviewBoard ?? board : board;
//   List<ChessPiece> get currentWhitePiecesTaken =>
//       reviewController.isInReviewMode
//           ? reviewWhitePiecesTaken ?? whitePiecesTaken
//           : whitePiecesTaken;
//   List<ChessPiece> get currentBlackPiecesTaken =>
//       reviewController.isInReviewMode
//           ? reviewBlackPiecesTaken ?? blackPiecesTaken
//           : blackPiecesTaken;
//   bool get currentIsWhiteTurn => reviewController.isInReviewMode
//       ? reviewIsWhiteTurn ?? isWhiteTurn
//       : isWhiteTurn;
//   bool get currentCheckStatus => reviewController.isInReviewMode
//       ? reviewCheckStatus ?? checkStatus
//       : checkStatus;
//   List<int> get currentWhiteKingPosition => reviewController.isInReviewMode
//       ? reviewWhiteKingPosition ?? whiteKingPosition
//       : whiteKingPosition;
//   List<int> get currentBlackKingPosition => reviewController.isInReviewMode
//       ? reviewBlackKingPosition ?? blackKingPosition
//       : blackKingPosition;

//   void _initializeTimer() {
//     chessTimer = ChessTimer.customTimer(
//       onTimeUpdate: (Duration white, Duration black) {
//         if (mounted) {
//           setState(() {
//             whiteTime = white;
//             blackTime = black;
//           });
//         }
//       },
//       onTimeUp: (bool isWhiteWinner) {
//         if (mounted) {
//           setState(() {
//             gameEnded = true;
//           });
//           _showTimeUpDialog(isWhiteWinner);
//         }
//       },
//       initialTime: Duration(minutes: 5),
//     );

//     whiteTime = chessTimer.whiteTime;
//     blackTime = chessTimer.blackTime;
//   }

//   void _initializeBoard() {
//     List<List<ChessPiece?>> newBoard =
//         List.generate(8, (index) => List.generate(8, (index) => null));

//     for (int i = 0; i < 8; i++) {
//       newBoard[1][i] = ChessPiece(
//         type: ChessPiecesType.pawn,
//         isWhite: false,
//         imagePath: 'images/pawn.png',
//       );

//       newBoard[6][i] = ChessPiece(
//         type: ChessPiecesType.pawn,
//         isWhite: true,
//         imagePath: 'images/pawn.png',
//       );
//     }

//     newBoard[0][0] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: false,
//         imagePath: "images/rook.png");
//     newBoard[0][7] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: false,
//         imagePath: "images/rook.png");
//     newBoard[7][0] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: true,
//         imagePath: "images/rook.png");
//     newBoard[7][7] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: true,
//         imagePath: "images/rook.png");

//     newBoard[0][1] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: false,
//         imagePath: "images/knight.png");
//     newBoard[0][6] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: false,
//         imagePath: "images/knight.png");
//     newBoard[7][1] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: true,
//         imagePath: "images/knight.png");
//     newBoard[7][6] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: true,
//         imagePath: "images/knight.png");

//     newBoard[0][2] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: false,
//         imagePath: "images/bishop.png");

//     newBoard[0][5] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: false,
//         imagePath: "images/bishop.png");
//     newBoard[7][2] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: true,
//         imagePath: "images/bishop.png");
//     newBoard[7][5] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: true,
//         imagePath: "images/bishop.png");

//     newBoard[0][3] = ChessPiece(
//       type: ChessPiecesType.queen,
//       isWhite: false,
//       imagePath: 'images/queen.png',
//     );
//     newBoard[7][3] = ChessPiece(
//       type: ChessPiecesType.queen,
//       isWhite: true,
//       imagePath: 'images/queen.png',
//     );
//     newBoard[0][4] = ChessPiece(
//       type: ChessPiecesType.king,
//       isWhite: false,
//       imagePath: 'images/king.png',
//     );
//     newBoard[7][4] = ChessPiece(
//       type: ChessPiecesType.king,
//       isWhite: true,
//       imagePath: 'images/king.png',
//     );
//     board = newBoard;
//   }

//   List<List<int>> calculateRowValidMoves(int row, int col, ChessPiece? piece) {
//     List<List<int>> candidateMoves = [];
//     if (piece == null) return [];
//     int direction = piece.isWhite ? -1 : 1;

//     switch (piece.type) {
//       case ChessPiecesType.pawn:
//         if (isInBoard(row + direction, col) &&
//             board[row + direction][col] == null) {
//           candidateMoves.add([row + direction, col]);
//           if ((row == 6 && piece.isWhite) || (row == 1 && !piece.isWhite)) {
//             if (board[row + 2 * direction][col] == null) {
//               candidateMoves.add([row + 2 * direction, col]);
//             }
//           }
//         }
//         for (int sideCol in [col - 1, col + 1]) {
//           if (isInBoard(row + direction, sideCol) &&
//               board[row + direction][sideCol] != null &&
//               board[row + direction][sideCol]!.isWhite != piece.isWhite) {
//             candidateMoves.add([row + direction, sideCol]);
//           }
//         }
//         if (enPassantTarget != null) {
//           int targetRow = enPassantTarget![0];
//           int targetCol = enPassantTarget![1];
//           if (row + direction == targetRow &&
//               (col - 1 == targetCol || col + 1 == targetCol)) {
//             candidateMoves.add([targetRow, targetCol]);
//           }
//         }
//         break;
//       case ChessPiecesType.rook:
//       case ChessPiecesType.bishop:
//       case ChessPiecesType.queen:
//         var directions = piece.type == ChessPiecesType.rook
//             ? [
//                 [-1, 0],
//                 [1, 0],
//                 [0, -1],
//                 [0, 1]
//               ]
//             : piece.type == ChessPiecesType.bishop
//                 ? [
//                     [-1, -1],
//                     [-1, 1],
//                     [1, -1],
//                     [1, 1]
//                   ]
//                 : [
//                     [-1, 0],
//                     [1, 0],
//                     [0, -1],
//                     [0, 1],
//                     [-1, -1],
//                     [-1, 1],
//                     [1, -1],
//                     [1, 1]
//                   ];
//         for (var dir in directions) {
//           int i = 1;
//           while (true) {
//             int newRow = row + i * dir[0];
//             int newCol = col + i * dir[1];
//             if (!isInBoard(newRow, newCol)) break;
//             if (board[newRow][newCol] != null) {
//               if (board[newRow][newCol]!.isWhite != piece.isWhite) {
//                 candidateMoves.add([newRow, newCol]);
//               }
//               break;
//             }
//             candidateMoves.add([newRow, newCol]);
//             i++;
//           }
//         }
//         break;
//       case ChessPiecesType.knight:
//         var moves = [
//           [-2, -1],
//           [-2, 1],
//           [-1, -2],
//           [-1, 2],
//           [1, -2],
//           [1, 2],
//           [2, -1],
//           [2, 1],
//         ];
//         for (var move in moves) {
//           int newRow = row + move[0];
//           int newCol = col + move[1];
//           if (!isInBoard(newRow, newCol)) continue;
//           if (board[newRow][newCol] == null ||
//               board[newRow][newCol]!.isWhite != piece.isWhite) {
//             candidateMoves.add([newRow, newCol]);
//           }
//         }
//         break;
//       case ChessPiecesType.king:
//         var moves = [
//           [-1, -1],
//           [-1, 0],
//           [-1, 1],
//           [0, -1],
//           [0, 1],
//           [1, -1],
//           [1, 0],
//           [1, 1]
//         ];
//         for (var move in moves) {
//           int newRow = row + move[0];
//           int newCol = col + move[1];
//           if (!isInBoard(newRow, newCol)) continue;
//           if (board[newRow][newCol] == null ||
//               board[newRow][newCol]!.isWhite != piece.isWhite) {
//             candidateMoves.add([newRow, newCol]);
//           }
//         }
//         break;
//     }
//     return candidateMoves;
//   }

//   List<List<int>> calculateRealValidMoves(
//       int row, int col, ChessPiece? piece, bool checkSimulation) {
//     List<List<int>> realValidMoves = [];
//     List<List<int>> candidateMoves = calculateRowValidMoves(row, col, piece);
//     if (checkSimulation) {
//       for (var move in candidateMoves) {
//         int endRow = move[0];
//         int endCol = move[1];
//         if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
//           realValidMoves.add(move);
//         }
//       }
//     } else {
//       realValidMoves = candidateMoves;
//     }
//     return realValidMoves;
//   }

//   bool isKingInCheck(bool isWhiteKing) {
//     List<int> kingPosition =
//         isWhiteKing ? whiteKingPosition : blackKingPosition;
//     for (int i = 0; i < 8; i++) {
//       for (int j = 0; j < 8; j++) {
//         if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
//           continue;
//         }
//         List<List<int>> pieceValidMoves =
//             calculateRealValidMoves(i, j, board[i][j], false);
//         for (List<int> move in pieceValidMoves) {
//           if (move[0] == kingPosition[0] && move[1] == kingPosition[1]) {
//             return true;
//           }
//         }
//       }
//     }
//     return false;
//   }

//   bool simulatedMoveIsSafe(
//       ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
//     ChessPiece? originalDestinationPiece = board[endRow][endCol];
//     ChessPiece? originalEnPassantPiece;
//     bool isSimulatedEnPassant = false;
//     if (piece.type == ChessPiecesType.pawn &&
//         enPassantTarget != null &&
//         endRow == enPassantTarget![0] &&
//         endCol == enPassantTarget![1]) {
//       isSimulatedEnPassant = true;
//       int capturedPawnRow = piece.isWhite ? endRow + 1 : endRow - 1;
//       originalEnPassantPiece = board[capturedPawnRow][endCol];
//       board[capturedPawnRow][endCol] = null;
//     }
//     List<int>? originalKingPosition;
//     if (piece.type == ChessPiecesType.king) {
//       originalKingPosition =
//           piece.isWhite ? whiteKingPosition : blackKingPosition;
//       if (piece.isWhite) {
//         whiteKingPosition = [endRow, endCol];
//       } else {
//         blackKingPosition = [endRow, endCol];
//       }
//     }
//     board[endRow][endCol] = piece;
//     board[startRow][startCol] = null;
//     bool kingInCheck = isKingInCheck(piece.isWhite);
//     board[startRow][startCol] = piece;
//     board[endRow][endCol] = originalDestinationPiece;
//     if (isSimulatedEnPassant) {
//       int capturedPawnRow = piece.isWhite ? endRow + 1 : endRow - 1;
//       board[capturedPawnRow][endCol] = originalEnPassantPiece;
//     }
//     if (piece.type == ChessPiecesType.king) {
//       if (piece.isWhite) {
//         whiteKingPosition = originalKingPosition!;
//       } else {
//         blackKingPosition = originalKingPosition!;
//       }
//     }
//     return !kingInCheck;
//   }

//   bool isWhite(int index) {
//     int row = index ~/ 8;
//     int col = index % 8;
//     if (widget.isMultiplayer && !widget.isLocalPlayerWhite) {
//       row = 7 - row;
//     }
//     return (row + col) % 2 == 0;
//   }

//   bool isInBoard(int row, int col) {
//     return row >= 0 && row < 8 && col >= 0 && col < 8;
//   }

//   bool isCheckMate(bool isWhiteKing) {
//     if (!isKingInCheck(isWhiteKing)) {
//       return false;
//     }
//     for (int i = 0; i < 8; i++) {
//       for (int j = 0; j < 8; j++) {
//         if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
//           continue;
//         }
//         List<List<int>> validMoves =
//             calculateRealValidMoves(i, j, board[i][j]!, true);
//         if (validMoves.isNotEmpty) {
//           return false;
//         }
//       }
//     }
//     return true;
//   }

//   void resetGame() {
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     }
//     _initializeBoard();
//     checkStatus = false;
//     whitePiecesTaken.clear();
//     blackPiecesTaken.clear();
//     whiteKingPosition = [7, 4];
//     blackKingPosition = [0, 4];
//     isWhiteTurn = true;
//     enPassantTarget = null;
//     gameEnded = false;
//     chessTimer.reset();
//     whiteTime = chessTimer.whiteTime;
//     blackTime = chessTimer.blackTime;
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     chessTimer.dispose();
//     super.dispose();
//   }

//   void _showTimeUpDialog(bool isWhiteWinner) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text("Time's Up!"),
//         content: Text(isWhiteWinner
//             ? "Black ran out of time. White wins!"
//             : "White ran out of time. Black wins!"),
//         actions: [
//           TextButton(
//             onPressed: resetGame,
//             child: const Text("New Game"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: reviewController.isInReviewMode
//           ? Colors.orange[200]
//           : Colors.grey[800],
//       body: Column(
//         children: [
//           if (widget.isMultiplayer)
//             _buildPlayerInfo(
//               isTop: true, // Opponent is always at the top
//               playerName: "Opponent", // Replace with opponent name from server
//               isWhitePlayer: !widget.isLocalPlayerWhite,
//               capturedPieces: widget.isLocalPlayerWhite
//                   ? currentBlackPiecesTaken
//                   : currentWhitePiecesTaken,
//               chessTimerDisplay: widget.isLocalPlayerWhite
//                   ? ChessTimerDisplayForBlack(
//                       chessTimer: chessTimer,
//                       whiteTime: whiteTime,
//                       blackTime: blackTime)
//                   : ChessTimerDisplayForWhite(
//                       chessTimer: chessTimer,
//                       whiteTime: whiteTime,
//                       blackTime: blackTime),
//             ),
//           Expanded(
//             child: GridView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: 64,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 8),
//               itemBuilder: (context, index) {
//                 int row = index ~/ 8;
//                 int col = index % 8;
//                 int displayRow = widget.isLocalPlayerWhite ? row : 7 - row;
//                 int displayCol = widget.isLocalPlayerWhite ? col : 7 - col;

//                 bool isSelected = !reviewController.isInReviewMode &&
//                     selectedRow == displayRow &&
//                     selectedCol == displayCol;

//                 bool isValidMove = !reviewController.isInReviewMode &&
//                     validMoves.any((move) =>
//                         move[0] == displayRow && move[1] == displayCol);

//                 return Square(
//                   isWhite: (displayRow + displayCol) % 2 == 0,
//                   piece: currentBoard[displayRow][displayCol],
//                   isSelected: isSelected,
//                   isValidMove: isValidMove,
//                   onTap: reviewController.isInReviewMode
//                       ? null
//                       : () => pieceSelected(displayRow, displayCol),
//                   isKingInCheck: currentBoard[displayRow][displayCol] != null &&
//                       currentBoard[displayRow][displayCol]!.type ==
//                           ChessPiecesType.king &&
//                       _isKingInCheckAtCurrentState(
//                           currentBoard[displayRow][displayCol]!.isWhite),
//                   boardBColor: reviewController.isInReviewMode
//                       ? Colors.orange
//                       : forgroundColor,
//                   boardWColor: backgroundColor,
//                 );
//               },
//             ),
//           ),
//           if (widget.isMultiplayer)
//             _buildPlayerInfo(
//               isTop: false, // Local player is always at the bottom
//               playerName: widget.name,
//               isWhitePlayer: widget.isLocalPlayerWhite,
//               capturedPieces: widget.isLocalPlayerWhite
//                   ? currentWhitePiecesTaken
//                   : currentBlackPiecesTaken,
//               chessTimerDisplay: widget.isLocalPlayerWhite
//                   ? ChessTimerDisplayForWhite(
//                       chessTimer: chessTimer,
//                       whiteTime: whiteTime,
//                       blackTime: blackTime)
//                   : ChessTimerDisplayForBlack(
//                       chessTimer: chessTimer,
//                       whiteTime: whiteTime,
//                       blackTime: blackTime),
//             ),
//           ReviewControls(
//             onPrevious: goToPreviousMove,
//             onNext: goToNextMove,
//             canGoBack: reviewController.canGoBack(),
//             canGoForward: reviewController.canGoForward(),
//             currentMoveInfo: reviewController.getCurrentMoveInfo(),
//             onExitReview: endReview,
//             startReview:
//                 reviewController.isInReviewMode ? endReview : startReview,
//             canStartReview: reviewController.canStartReview(),
//             isInReviewMode: reviewController.isInReviewMode,
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildPlayerInfo({
//     required bool isTop,
//     required String playerName,
//     required bool isWhitePlayer,
//     required List<ChessPiece> capturedPieces,
//     required Widget chessTimerDisplay,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Container(
//                 height: 50,
//                 width: 50,
//                 decoration:
//                     BoxDecoration(border: Border.all(color: Colors.white)),
//                 child: Image.asset(
//                   isWhitePlayer
//                       ? "assets/images/figures/white/queen.png"
//                       : "assets/images/figures/black/queen.png",
//                   color: isWhitePlayer
//                       ? null
//                       : Colors
//                           .black, // Apply color filter for black piece image if needed
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     playerName,
//                     style: TextStyle(
//                       color: reviewController.isInReviewMode
//                           ? Colors.black
//                           : Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                   SizedBox(
//                     height: 30,
//                     width: MediaQuery.of(context).size.width * 0.5,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: capturedPieces.length,
//                       itemBuilder: (context, index) => DeadPiece(
//                         imagePath: capturedPieces[index].imagePath,
//                         isWhite: capturedPieces[index].isWhite,
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ],
//           ),
//           chessTimerDisplay,
//         ],
//       ),
//     );
//   }

//   bool _isKingInCheckAtCurrentState(bool isWhiteKing) {
//     if (reviewController.isInReviewMode) {
//       return currentCheckStatus &&
//           ((isWhiteKing && !currentIsWhiteTurn) ||
//               (!isWhiteKing && currentIsWhiteTurn));
//     }
//     return checkStatus &&
//         ((isWhiteKing && !isWhiteTurn) || (!isWhiteKing && isWhiteTurn));
//   }
// }

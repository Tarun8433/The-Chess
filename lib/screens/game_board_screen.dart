import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_chess/home/view/online_game.dart';

class GameBoardScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;

  const GameBoardScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
  });

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ChessGameService _chessGameService = ChessGameService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? activeChessGameId;
  bool isCreatingGame = false;
  int unreadMessageCount = 0;
  bool isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _listenToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeGame() async {
    // Use a transaction to prevent race conditions when multiple players enter simultaneously
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Check if there's already an active chess game in this room
        final gamesQuery = await FirebaseFirestore.instance
            .collection('chess_games')
            .where('roomId', isEqualTo: widget.roomId)
            .where('gameStatus', isEqualTo: 'active')
            .limit(1)
            .get();

        if (gamesQuery.docs.isNotEmpty) {
          setState(() {
            activeChessGameId = gamesQuery.docs.first.id;
          });
        } else {
          // Auto-create a chess game when entering the room
          await _startChessGameWithTransaction(transaction);
        }
      });
    } catch (e) {
      // If transaction fails, try to find existing game again
      final gamesQuery = await FirebaseFirestore.instance
          .collection('chess_games')
          .where('roomId', isEqualTo: widget.roomId)
          .where('gameStatus', isEqualTo: 'active')
          .limit(1)
          .get();

      if (gamesQuery.docs.isNotEmpty) {
        setState(() {
          activeChessGameId = gamesQuery.docs.first.id;
        });
      }
    }
  }

  void _listenToMessages() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!isDrawerOpen) {
        // Only count unread messages when drawer is closed
        setState(() {
          unreadMessageCount = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _startChessGame() async {
    if (isCreatingGame) return;

    setState(() {
      isCreatingGame = true;
    });

    try {
      final roomDoc = await FirebaseFirestore.instance
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

  Future<void> _startChessGameWithTransaction(Transaction transaction) async {
    if (isCreatingGame) return;

    setState(() {
      isCreatingGame = true;
    });

    try {
      final roomDoc = await transaction.get(FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId));

      if (roomDoc.exists) {
        final roomData = roomDoc.data()!;
        final participants = List<String>.from(roomData['participants']);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final opponentId = participants.firstWhere((id) => id != currentUserId);

        final gameId = await _chessGameService.createChessGameWithTransaction(
            transaction, widget.roomId, opponentId);

        setState(() {
          activeChessGameId = gameId;
        });
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

  void _openChatDrawer() {
    setState(() {
      isDrawerOpen = true;
      unreadMessageCount = 0; // Reset count when opening drawer
    });
    _scaffoldKey.currentState?.openEndDrawer();
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

    final messageRef = FirebaseFirestore.instance
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
                        'Chat with ${widget.partnerName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Room: ${widget.roomId}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isDrawerOpen = false;
                    });
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return GameMessageModel.fromMap(data);
                }).toList();

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
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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

  Widget _buildGameMessage(GameMessageModel message) {
    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: TextStyle(
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
      key: _scaffoldKey,
      // appBar: AppBar(
      //   title: Text('Chess Game'),
      //   backgroundColor: Colors.blue,
      //   foregroundColor: Colors.white,
      //   actions: [
      //     Stack(
      //       children: [
      //         IconButton(
      //           onPressed: _openChatDrawer,
      //           icon: Icon(Icons.chat),
      //           tooltip: 'Open Chat',
      //         ),
      //         if (unreadMessageCount > 0)
      //           Positioned(
      //             right: 8,
      //             top: 8,
      //             child: Container(
      //               padding: EdgeInsets.all(2),
      //               decoration: BoxDecoration(
      //                 color: Colors.red,
      //                 borderRadius: BorderRadius.circular(10),
      //               ),
      //               constraints: BoxConstraints(
      //                 minWidth: 16,
      //                 minHeight: 16,
      //               ),
      //               child: Text(
      //                 unreadMessageCount > 99
      //                     ? '99+'
      //                     : unreadMessageCount.toString(),
      //                 style: TextStyle(
      //                   color: Colors.white,
      //                   fontSize: 10,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //                 textAlign: TextAlign.center,
      //               ),
      //             ),
      //           ),
      //       ],
      //     ),
      //   ],
      // ),

      endDrawer: _buildChatDrawer(),
      onEndDrawerChanged: (isOpened) {
        setState(() {
          isDrawerOpen = isOpened;
          if (!isOpened) {
            unreadMessageCount = 0;
          }
        });
      },
      body: activeChessGameId != null
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chess_games')
                  .doc(activeChessGameId!)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text('Game not found'),
                  );
                }

                // Determine if current user is white player
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isLocalPlayerWhite =
                    snapshot.data!['whitePlayerId'] == currentUserId;

                return OnlineBoardGame(
                  gameId: activeChessGameId!,
                  roomId: widget.roomId,
                  isLocalPlayerWhite: isLocalPlayerWhite,
                  localPlayerName: FirebaseAuth
                          .instance.currentUser?.displayName ??
                      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
                      'Player',
                  opponentName: widget.partnerName,
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCreatingGame) ...[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Setting up chess game...'),
                  ] else ...[
                    Icon(Icons.sports_esports, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Preparing game board...'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startChessGame,
                      child: Text('Start Game'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

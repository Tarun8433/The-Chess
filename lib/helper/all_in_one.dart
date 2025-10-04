// // ignore_for_file: constant_identifier_names
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
// import 'dart:convert';
// import 'package:nearby_connections/nearby_connections.dart'
//     as nearby_connections;
// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:math';

// class PlayerAssignment {
//   // True if the local player is white, false if black.
//   bool _isLocalPlayerWhite = true;

//   /// Initializes the player assignment by randomly assigning colors.
//   ///
//   /// After calling this, use [isLocalPlayerWhite] to determine the local player's color.
//   void assignRandomColors() {
//     final random = Random();
//     _isLocalPlayerWhite = random.nextBool(); // true for white, false for black
//     print('Local player is: ${_isLocalPlayerWhite ? "White" : "Black"}');
//   }

//   /// Returns true if the local player is assigned to play as White, false otherwise.
//   bool get isLocalPlayerWhite => _isLocalPlayerWhite;

//   /// Determines if a player can select a piece based on the current turn and
//   /// the local player's assigned color.
//   ///
//   /// [isPieceWhite]: The color of the piece being selected (true for white, false for black).
//   /// [isWhiteTurn]: Indicates if it's currently White's turn.
//   ///
//   /// Returns `true` if the piece can be selected, `false` otherwise.
//   bool canSelectPiece(bool isPieceWhite, bool isWhiteTurn) {
//     // If it's White's turn:
//     //   - Local player is White AND the piece is White, OR
//     //   - Local player is Black AND the piece is Black (this condition is currently impossible
//     //     if it's White's turn and the local player is black, but included for completeness
//     //     if game logic changes to allow selection of opponent's pieces for certain actions).
//     // If it's Black's turn:
//     //   - Local player is Black AND the piece is Black, OR
//     //   - Local player is White AND the piece is White (similarly, currently impossible).

//     // The core logic: A player can only select a piece if it's their turn
//     // AND the piece belongs to their assigned color.
//     if (isWhiteTurn) {
//       return _isLocalPlayerWhite && isPieceWhite;
//     } else {
//       return !_isLocalPlayerWhite && !isPieceWhite;
//     }
//   }
// }

// class PermissionsService {
//   static Future<bool> requestNearbyPermissions() async {
//     List<Permission> permissions = [];

//     if (Platform.isAndroid) {
//       final androidInfo = await DeviceInfoPlugin().androidInfo;
//       print('Android SDK: ${androidInfo.version.sdkInt}');

//       if (androidInfo.version.sdkInt >= 31) {
//         // Android 12+ (API 31+) permissions
//         permissions.addAll([
//           Permission.bluetoothScan,
//           Permission.bluetoothConnect,
//           Permission.bluetoothAdvertise,
//           Permission.locationWhenInUse,
//         ]);

//         // NEARBY_WIFI_DEVICES is only available on Android 13+ (API 33+)
//         if (androidInfo.version.sdkInt >= 33) {
//           try {
//             permissions.add(Permission.nearbyWifiDevices);
//           } catch (e) {
//             print('nearbyWifiDevices permission not available: $e');
//           }
//         }
//       } else if (androidInfo.version.sdkInt >= 23) {
//         // Android 6+ (API 23+) but less than 31
//         permissions.addAll([
//           Permission.bluetooth,
//           Permission.locationWhenInUse,
//         ]);
//       } else {
//         // Older Android versions
//         permissions.add(Permission.bluetooth);
//       }
//     } else {
//       // iOS permissions
//       permissions.addAll([
//         Permission.bluetooth,
//         Permission.locationWhenInUse,
//       ]);
//     }

//     print(
//         'Requesting permissions: ${permissions.map((p) => p.toString()).toList()}');

//     Map<Permission, PermissionStatus> statuses = await permissions.request();

//     // Log the results
//     statuses.forEach((permission, status) {
//       print('$permission: $status');
//     });

//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     print('All permissions granted: $allGranted');

//     return allGranted;
//   }

//   static Future<void> checkPermissionStatus() async {
//     final permissions = [
//       Permission.bluetooth,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.locationWhenInUse,
//       Permission.nearbyWifiDevices,
//     ];

//     for (Permission permission in permissions) {
//       try {
//         final status = await permission.status;
//         print('$permission: $status');
//       } catch (e) {
//         print('Error checking $permission: $e');
//       }
//     }
//   }
// }

// // Alias to avoid conflict
// // models/message.dart
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
//       id: json['id'],
//       content: json['content'],
//       senderId: json['senderId'],
//       senderName: json['senderName'],
//       timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
//       isMe: json['isMe'] ?? false,
//     );
//   }
// }

// // Enum to differentiate payload types for our custom messages
// enum CustomPayloadType {
//   chatMessage,
//   gameMove,
//   gameState, // For initial sync or full board updates
// }

// // Data model for game state synchronization
// class GameStatePayload {
//   final List<List<Map<String, dynamic>?>> board;
//   final List<Map<String, dynamic>> whitePiecesTaken;
//   final List<Map<String, dynamic>> blackPiecesTaken;
//   final bool isWhiteTurn;
//   final List<int> whiteKingPosition;
//   final List<int> blackKingPosition;
//   final bool checkStatus;
//   final List<int>? enPassantTarget;
//   final Map<String, dynamic>?
//       lastMoveJson; // To send the last move made as JSON

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
//     return GameStatePayload(
//       board: (json['board'] as List)
//           .map((row) => (row as List)
//               .map((pieceJson) => pieceJson != null
//                   ? Map<String, dynamic>.from(pieceJson)
//                   : null)
//               .toList())
//           .toList(),
//       whitePiecesTaken: (json['whitePiecesTaken'] as List)
//           .map((e) => Map<String, dynamic>.from(e))
//           .toList(),
//       blackPiecesTaken: (json['blackPiecesTaken'] as List)
//           .map((e) => Map<String, dynamic>.from(e))
//           .toList(),
//       isWhiteTurn: json['isWhiteTurn'],
//       whiteKingPosition: List<int>.from(json['whiteKingPosition']),
//       blackKingPosition: List<int>.from(json['blackKingPosition']),
//       checkStatus: json['checkStatus'],
//       enPassantTarget: json['enPassantTarget'] != null
//           ? List<int>.from(json['enPassantTarget'])
//           : null,
//       lastMoveJson: json['lastMove'] != null
//           ? Map<String, dynamic>.from(json['lastMove'])
//           : null,
//     );
//   }
// }

// class NearbyService {
//   final Function(String, Message) onMessageReceived;
//   final Function(String, GameStatePayload) onGameStateReceived;
//   final Function(String) onPeerConnected;
//   final Function() onPeerDisconnected;
//   final Function(String, String, String) onEndpointFound;
//   final Function(String endpointId, String endpointName, String serviceId)
//       onConnectionRequest;

//   String? _connectedEndpointId;
//   String? _connectedEndpointName;
//   bool _isAdvertising = false;
//   bool _isDiscovering = false;
//   final nearby_connections.Strategy strategy =
//       nearby_connections.Strategy.P2P_STAR;

//   // Add timeout and retry mechanism
//   Timer? _connectionTimeout;
//   static const int CONNECTION_TIMEOUT_SECONDS = 30;

//   // Track connection attempts to prevent spam
//   final Map<String, DateTime> _connectionAttempts = {};
//   static const int MIN_CONNECTION_RETRY_DELAY_MS = 2000; // 2 seconds

//   NearbyService({
//     required this.onMessageReceived,
//     required this.onGameStateReceived,
//     required this.onPeerConnected,
//     required this.onPeerDisconnected,
//     required this.onEndpointFound,
//     required this.onConnectionRequest,
//   });

//   String? get connectedEndpointId => _connectedEndpointId;
//   String? get connectedEndpointName => _connectedEndpointName;
//   bool get isConnected => _connectedEndpointId != null;
//   bool get isAdvertising => _isAdvertising;
//   bool get isDiscovering => _isDiscovering;

//   Future<void> startAdvertising(String userName) async {
//     try {
//       if (!await PermissionsService.requestNearbyPermissions()) {
//         print('Permissions not granted for advertising.');
//         return;
//       }

//       // Clean stop any existing operations
//       await _cleanStop();

//       // Small delay to ensure clean state
//       await Future.delayed(Duration(milliseconds: 500));

//       await nearby_connections.Nearby().startAdvertising(
//         userName,
//         strategy,
//         onConnectionInitiated:
//             (String endpointId, nearby_connections.ConnectionInfo info) {
//           print(
//               '🔄 Connection initiated from ${info.endpointName} (${info.authenticationToken})');
//           _handleConnectionInitiated(endpointId, info, userName);
//         },
//         onConnectionResult:
//             (String endpointId, nearby_connections.Status status) {
//           print('📡 Connection result for $endpointId: $status');
//           _handleConnectionResult(endpointId, status);
//         },
//         onDisconnected: (String endpointId) {
//           print('❌ Disconnected from $endpointId');
//           _handleDisconnected(endpointId);
//         },
//       );
//       _isAdvertising = true;
//       print('✅ Advertising started by $userName');
//     } catch (e) {
//       print('❌ Error starting advertising: $e');
//       _isAdvertising = false;
//     }
//   }

//   Future<void> startDiscovery(String userName) async {
//     try {
//       if (!await PermissionsService.requestNearbyPermissions()) {
//         print('Permissions not granted for discovery.');
//         return;
//       }

//       // Clean stop any existing operations
//       await _cleanStop();

//       // Small delay to ensure clean state
//       await Future.delayed(Duration(milliseconds: 500));

//       await nearby_connections.Nearby().startDiscovery(
//         userName,
//         strategy,
//         onEndpointFound:
//             (String endpointId, String endpointName, String serviceId) {
//           print('🔍 Endpoint found: $endpointName ($endpointId)');
//           onEndpointFound(endpointId, endpointName, serviceId);
//         },
//         onEndpointLost: (endpointId) {
//           print('📍 Endpoint lost: $endpointId');
//           // Clean up any pending connection attempts for this endpoint
//           _connectionAttempts.remove(endpointId);
//         },
//       );
//       _isDiscovering = true;
//       print('✅ Discovery started by $userName');
//     } catch (e) {
//       print('❌ Error starting discovery: $e');
//       _isDiscovering = false;
//     }
//   }

//   void requestConnection(String userName, String endpointId) {
//     // Check if we recently attempted to connect to this endpoint
//     if (_connectionAttempts.containsKey(endpointId)) {
//       DateTime lastAttempt = _connectionAttempts[endpointId]!;
//       int timeSinceLastAttempt = DateTime.now().millisecondsSinceEpoch -
//           lastAttempt.millisecondsSinceEpoch;

//       if (timeSinceLastAttempt < MIN_CONNECTION_RETRY_DELAY_MS) {
//         print(
//             '⏰ Skipping connection request to $endpointId - too soon after last attempt');
//         return;
//       }
//     }

//     print('🤝 Requesting connection to $endpointId as $userName');
//     _connectionAttempts[endpointId] = DateTime.now();

//     // Set connection timeout
//     _connectionTimeout?.cancel();
//     _connectionTimeout =
//         Timer(Duration(seconds: CONNECTION_TIMEOUT_SECONDS), () {
//       print('⏱️ Connection timeout for $endpointId');
//       _connectionAttempts.remove(endpointId);
//     });

//     nearby_connections.Nearby().requestConnection(
//       userName,
//       endpointId,
//       onConnectionInitiated:
//           (String endpointId, nearby_connections.ConnectionInfo info) {
//         print(
//             '🔄 Connection initiated to ${info.endpointName} (${info.authenticationToken})');
//         _handleConnectionInitiated(endpointId, info, userName);
//       },
//       onConnectionResult:
//           (String endpointId, nearby_connections.Status status) {
//         print('📡 Connection result for $endpointId: $status');
//         _connectionTimeout?.cancel();
//         _connectionAttempts.remove(endpointId);
//         _handleConnectionResult(endpointId, status);
//       },
//       onDisconnected: (String endpointId) {
//         print('❌ Disconnected from $endpointId');
//         _connectionTimeout?.cancel();
//         _connectionAttempts.remove(endpointId);
//         _handleDisconnected(endpointId);
//       },
//     );
//   }

//   void acceptConnection(String endpointId) {
//     print('✅ Accepting connection from $endpointId');
//     nearby_connections.Nearby().acceptConnection(endpointId,
//         onPayLoadRecieved: (endpointId, payload) {
//       _handlePayloadReceived(endpointId, payload);
//     });
//   }

//   void rejectConnection(String endpointId) {
//     print('❌ Rejecting connection from $endpointId');
//     nearby_connections.Nearby().rejectConnection(endpointId);
//     _connectionAttempts.remove(endpointId);
//   }

//   void _handleConnectionInitiated(String endpointId,
//       nearby_connections.ConnectionInfo info, String userName) {
//     print('🔗 Connection initiated with ${info.endpointName}');
//     _connectedEndpointName = info.endpointName; // Store the name early

//     // For debugging - show the authentication token
//     print('🔐 Authentication token: ${info.authenticationToken}');

//     // Notify UI for user confirmation
//     onConnectionRequest(
//         endpointId, info.endpointName, info.authenticationToken);
//   }

//   void _handleConnectionResult(
//       String endpointId, nearby_connections.Status status) {
//     if (status == nearby_connections.Status.CONNECTED) {
//       _connectedEndpointId = endpointId;
//       _connectedEndpointName = _connectedEndpointName ?? 'Unknown Peer';

//       print(
//           '✅ Successfully connected to $_connectedEndpointName ($endpointId)');
//       onPeerConnected(_connectedEndpointName!);

//       // Stop advertising/discovery once connected
//       _stopOperations();
//     } else {
//       print(
//           '❌ Connection to $_connectedEndpointName ($endpointId) failed: $status');
//       _connectedEndpointId = null;
//       _connectedEndpointName = null;
//     }
//   }

//   void _handleDisconnected(String endpointId) {
//     print('🔌 Disconnected from $_connectedEndpointName ($endpointId)');
//     _connectedEndpointId = null;
//     _connectedEndpointName = null;
//     _connectionTimeout?.cancel();
//     onPeerDisconnected();
//   }

//   void _handlePayloadReceived(
//       String endpointId, nearby_connections.Payload payload) {
//     if (payload.type == nearby_connections.PayloadType.BYTES) {
//       String data = String.fromCharCodes(payload.bytes!);
//       try {
//         Map<String, dynamic> decoded = jsonDecode(data);
//         String type = decoded['type'];

//         if (type == CustomPayloadType.chatMessage.name) {
//           Message msg = Message.fromJson(decoded['data']);
//           onMessageReceived(endpointId, msg);
//         } else if (type == CustomPayloadType.gameState.name) {
//           GameStatePayload gameState =
//               GameStatePayload.fromJson(decoded['data']);
//           onGameStateReceived(endpointId, gameState);
//         }
//       } catch (e) {
//         print('❌ Error decoding payload: $e, Raw data: $data');
//       }
//     }
//   }

//   void sendMessage(Message message) {
//     if (_connectedEndpointId != null) {
//       final payloadData = {
//         'type': CustomPayloadType.chatMessage.name,
//         'data': message.toJson(),
//       };
//       nearby_connections.Nearby().sendBytesPayload(_connectedEndpointId!,
//           Uint8List.fromList(jsonEncode(payloadData).codeUnits));
//       print('💬 Message sent to $_connectedEndpointId');
//     } else {
//       print('❌ Not connected to any peer to send message.');
//     }
//   }

//   void sendGameState(GameStatePayload gameState) {
//     if (_connectedEndpointId != null) {
//       final payloadData = {
//         'type': CustomPayloadType.gameState.name,
//         'data': gameState.toJson(),
//       };
//       nearby_connections.Nearby().sendBytesPayload(_connectedEndpointId!,
//           Uint8List.fromList(jsonEncode(payloadData).codeUnits));
//       print('🎮 Game state sent to $_connectedEndpointId');
//     } else {
//       print('❌ Not connected to any peer to send game state.');
//     }
//   }

//   Future<void> _cleanStop() async {
//     try {
//       nearby_connections.Nearby().stopAdvertising();
//       nearby_connections.Nearby().stopDiscovery();

//       // Small delay to ensure operations are stopped
//       await Future.delayed(Duration(milliseconds: 200));
//     } catch (e) {
//       print('⚠️ Error during clean stop: $e');
//     }
//   }

//   void _stopOperations() {
//     if (_isAdvertising) {
//       nearby_connections.Nearby().stopAdvertising();
//       _isAdvertising = false;
//       print('🛑 Advertising stopped.');
//     }

//     if (_isDiscovering) {
//       nearby_connections.Nearby().stopDiscovery();
//       _isDiscovering = false;
//       print('🛑 Discovery stopped.');
//     }

//     // Clear connection attempts
//     _connectionAttempts.clear();
//   }

//   void stopAdvertising() {
//     if (_isAdvertising) {
//       nearby_connections.Nearby().stopAdvertising();
//       _isAdvertising = false;
//       print('🛑 Advertising stopped.');
//     }
//   }

//   void stopDiscovery() {
//     if (_isDiscovering) {
//       nearby_connections.Nearby().stopDiscovery();
//       _isDiscovering = false;
//       print('🛑 Discovery stopped.');
//     }
//   }

//   void disconnect() {
//     _connectionTimeout?.cancel();

//     if (_connectedEndpointId != null) {
//       nearby_connections.Nearby().disconnectFromEndpoint(_connectedEndpointId!);
//       _connectedEndpointId = null;
//       _connectedEndpointName = null;
//       print('🔌 Disconnected from current peer.');
//     }

//     _stopOperations();
//     _connectionAttempts.clear();
//   }

//   void dispose() {
//     _connectionTimeout?.cancel();
//     disconnect();
//   }
// }

// // Main screen for multiplayer game and chat
// class MultiplayerGameScreen extends StatefulWidget {
//   final String userName;

//   const MultiplayerGameScreen({super.key, required this.userName});

//   @override
//   State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
// }

// class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
//   late NearbyService _nearbyService;
//   final List<Message> _messages = [];
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _chatScrollController = ScrollController();
//   bool _isConnected = false;
//   String _connectedPeerName = '';
//   String _connectionStatusMessage = 'Not connected';
//   bool _isAdvertising = false;
//   bool _isDiscovering = false;
//   final Map<String, String> _foundEndpoints =
//       {}; // endpointId: endpointName (for discovery)
//   final Map<String, String> _incomingConnections =
//       {}; // endpointId: endpointName (for advertising)

//   // Reference to the BoardGame state to send updates
//   final GlobalKey<BoardGameState> _boardGameKey = GlobalKey<BoardGameState>();

//   bool _isLocalPlayerWhite = true; // Track local player color explicitly

//   @override
//   void initState() {
//     super.initState();
//     _nearbyService = NearbyService(
//       onMessageReceived: _handleMessageReceived,
//       onGameStateReceived: _handleGameStateReceived,
//       onPeerConnected: _handlePeerConnected,
//       onPeerDisconnected: _handlePeerDisconnected,
//       onEndpointFound: _handleEndpointFound,
//       onConnectionRequest: _handleConnectionRequest, // Pass the new callback
//     );
//   }

//   @override
//   void dispose() {
//     _nearbyService.dispose();
//     _messageController.dispose();
//     _chatScrollController.dispose();
//     super.dispose();
//   }

//   // In _handlePeerConnected method, add this logic:
//   void _handlePeerConnected(String peerName) {
//     setState(() {
//       _isConnected = true;
//       _connectedPeerName = peerName;
//       _connectionStatusMessage = 'Connected to $peerName';
//       _isAdvertising = false;
//       _isDiscovering = false;
//       _foundEndpoints.clear();
//       _incomingConnections.clear();

//       // Set local player color based on who initiated the connection
//       // Host (advertiser) gets white, joiner gets black
//       _isLocalPlayerWhite =
//           _nearbyService.isAdvertising; // Use the stored advertising state
//       _showColorAssignmentDialog(_isLocalPlayerWhite); // Show dialog
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//             'Connected to $peerName - You are ${_isLocalPlayerWhite ? "White" : "Black"}'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showColorAssignmentDialog(bool isWhite) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text('Player Color Assigned!'),
//         content: Text(
//           'You will be playing as ${isWhite ? "White" : "Black"}.',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: isWhite
//                 ? Colors.white
//                 : Colors.black, // Adjust color based on player
//           ),
//         ),
//         backgroundColor: isWhite
//             ? Colors.blue[100]
//             : Colors.grey[800], // Adjust dialog background
//         titleTextStyle: TextStyle(
//           color: isWhite ? Colors.black : Colors.white, // Adjust title color
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//         contentTextStyle: TextStyle(
//           color: isWhite ? Colors.black : Colors.white, // Adjust content color
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: Text(
//               'OK',
//               style:
//                   TextStyle(color: isWhite ? Colors.blue[900] : Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Update the BoardGame widget call:
//   Widget _buildGameAndChatInterface() {
//     return Column(
//       children: [
//         // // Opponent's captured pieces and timer (will be at the top for local white, bottom for local black)
//         // if (!_isLocalPlayerWhite) // If local player is black, show white pieces at top
//         //   _buildPlayerInfo(
//         //     playerName: "Tarun Ku. Sahani", // Opponent's name
//         //     capturedPieces:
//         //         _boardGameKey.currentState?.currentWhitePiecesTaken ?? [],
//         //     isWhitePlayer: true,
//         //     chessTimerDisplay: ChessTimerDisplayForWhite(
//         //       chessTimer: _boardGameKey.currentState?.chessTimer ??
//         //           ChessTimer.customTimer(
//         //             onTimeUpdate: (w, b) {},
//         //             onTimeUp: (w) {},
//         //             initialTime: Duration(minutes: 5),
//         //           ), // Pass a dummy if null
//         //       whiteTime: _boardGameKey.currentState?.whiteTime ??
//         //           Duration(minutes: 10),
//         //       blackTime: _boardGameKey.currentState?.blackTime ??
//         //           Duration(minutes: 10),
//         //     ),
//         //     isInReviewMode:
//         //         _boardGameKey.currentState?.reviewController.isInReviewMode ??
//         //             false,
//         //   )
//         // else // If local player is white, show black pieces at top
//         //   _buildPlayerInfo(
//         //     playerName: "Tarun Ku. Sahani", // Opponent's name
//         //     capturedPieces:
//         //         _boardGameKey.currentState?.currentBlackPiecesTaken ?? [],
//         //     isWhitePlayer: false,
//         //     chessTimerDisplay: ChessTimerDisplayForBlack(
//         //       chessTimer: _boardGameKey.currentState?.chessTimer ??
//         //           ChessTimer.customTimer(
//         //             onTimeUpdate: (w, b) {},
//         //             onTimeUp: (w) {},
//         //             initialTime: Duration(minutes: 5),
//         //           ), // Pass a dummy if null
//         //       whiteTime: _boardGameKey.currentState?.whiteTime ??
//         //           Duration(minutes: 10),
//         //       blackTime: _boardGameKey.currentState?.blackTime ??
//         //           Duration(minutes: 10),
//         //     ),
//         //     isInReviewMode:
//         //         _boardGameKey.currentState?.reviewController.isInReviewMode ??
//         //             false,
//         //   ),

//         // Spacer(),

//         Expanded(
//           flex: 3,
//           child: BoardGame(
//             key: _boardGameKey,
//             onGameStateUpdate: _sendGameStateUpdate,
//             isMultiplayer: true,
//             isLocalPlayerWhite:
//                 _isLocalPlayerWhite, // Use the explicit variable
//             name: widget.userName,
//           ),
//         ),

//         // Spacer(),

//         // Local player's captured pieces and timer (will be at the bottom)
//         if (_isLocalPlayerWhite) // If local player is white, show white pieces at bottom
//           _buildPlayerInfo(
//             playerName: widget.userName, // Local player's name
//             capturedPieces:
//                 _boardGameKey.currentState?.currentWhitePiecesTaken ?? [],
//             isWhitePlayer: true,
//             chessTimerDisplay: ChessTimerDisplayForWhite(
//               chessTimer: _boardGameKey.currentState?.chessTimer ??
//                   ChessTimer.customTimer(
//                     onTimeUpdate: (w, b) {},
//                     onTimeUp: (w) {},
//                     initialTime: Duration(minutes: 5),
//                   ), // Pass a dummy if null
//               whiteTime: _boardGameKey.currentState?.whiteTime ??
//                   Duration(minutes: 10),
//               blackTime: _boardGameKey.currentState?.blackTime ??
//                   Duration(minutes: 10),
//             ),
//             isInReviewMode:
//                 _boardGameKey.currentState?.reviewController.isInReviewMode ??
//                     false,
//           )
//         else // If local player is black, show black pieces at bottom
//           _buildPlayerInfo(
//             playerName: widget.userName, // Local player's name
//             capturedPieces:
//                 _boardGameKey.currentState?.currentBlackPiecesTaken ?? [],
//             isWhitePlayer: false,
//             chessTimerDisplay: ChessTimerDisplayForBlack(
//               chessTimer: _boardGameKey.currentState?.chessTimer ??
//                   ChessTimer.customTimer(
//                     onTimeUpdate: (w, b) {},
//                     onTimeUp: (w) {},
//                     initialTime: Duration(minutes: 5),
//                   ), // Pass a dummy if null
//               whiteTime: _boardGameKey.currentState?.whiteTime ??
//                   Duration(minutes: 10),
//               blackTime: _boardGameKey.currentState?.blackTime ??
//                   Duration(minutes: 10),
//             ),
//             isInReviewMode:
//                 _boardGameKey.currentState?.reviewController.isInReviewMode ??
//                     false,
//           ),

//         // const Divider(height: 1, color: Colors.grey),
//         // Expanded(
//         //   flex: 1, // Allocate space for chat
//         //   child: Column(
//         //     children: [
//         //       Expanded(
//         //         child: ListView.builder(
//         //           controller: _chatScrollController,
//         //           itemCount: _messages.length,
//         //           itemBuilder: (context, index) {
//         //             final message = _messages[index];
//         //             return _buildMessageBubble(message);
//         //           },
//         //         ),
//         //       ),
//         //       //  _buildMessageInput(),
//         //     ],
//         //   ),
//         // ),
//       ],
//     );
//   }

//   // Helper widget to build player info rows (replaces duplicated code)
//   Widget _buildPlayerInfo({
//     required String playerName,
//     required List<ChessPiece> capturedPieces,
//     required bool isWhitePlayer,
//     required Widget chessTimerDisplay,
//     required bool isInReviewMode,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 decoration:
//                     BoxDecoration(border: Border.all(color: Colors.white)),
//                 child: Image.asset(
//                   "assets/images/figures/white/queen.png", // This image might need to be dynamic based on player color
//                   height: 50,
//                 ),
//               ),
//               SizedBox(width: 8),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     playerName,
//                     style: TextStyle(
//                       color: isInReviewMode ? Colors.black : Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                   SizedBox(
//                     height: 30,
//                     width: MediaQuery.of(context).size.width * .6,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       shrinkWrap: true,
//                       physics: const BouncingScrollPhysics(),
//                       itemCount: capturedPieces.length,
//                       itemBuilder: (context, index) => DeadPiece(
//                         imagePath: capturedPieces[index].imagePath,
//                         isWhite: isWhitePlayer,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           chessTimerDisplay,
//         ],
//       ),
//     );
//   }

//   // Also store the advertising state when starting to advertise
//   void _startAdvertising() async {
//     bool granted = await PermissionsService.requestNearbyPermissions();
//     if (granted) {
//       _nearbyService.stopDiscovery();
//       await _nearbyService.startAdvertising(widget.userName);
//       setState(() {
//         _isAdvertising = true;
//         _isDiscovering = false;
//         _connectionStatusMessage = 'Advertising... Waiting for connections';
//         _foundEndpoints.clear();
//         _isLocalPlayerWhite = true; // Host is always white
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Hosting game as White player...'),
//           backgroundColor: Colors.blue,
//         ),
//       );
//     } else {
//       _showPermissionError();
//     }
//   }

//   void _startDiscovery() async {
//     bool granted = await PermissionsService.requestNearbyPermissions();
//     if (granted) {
//       _nearbyService.stopAdvertising();
//       await _nearbyService.startDiscovery(widget.userName);
//       setState(() {
//         _isDiscovering = true;
//         _isAdvertising = false;
//         _connectionStatusMessage = 'Discovering nearby devices...';
//         _incomingConnections.clear();
//         _isLocalPlayerWhite = false; // Joiner is always black
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Looking to join as Black player...'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } else {
//       _showPermissionError();
//     }
//   }

//   void _handleMessageReceived(String endpointId, Message message) {
//     setState(() {
//       _messages.add(message);
//     });
//     _scrollToBottom();
//     HapticFeedback.lightImpact(); // Vibrate on message
//   }

//   void _handleGameStateReceived(String endpointId, GameStatePayload payload) {
//     // Apply the received game state to the BoardGame
//     // Convert lastMoveJson back to ChessMove if present
//     ChessMove? lastMove;
//     if (payload.lastMoveJson != null) {
//       lastMove = ChessMove.fromJson(payload.lastMoveJson!);
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

//   void _handlePeerDisconnected() {
//     setState(() {
//       _isConnected = false;
//       _connectedPeerName = '';
//       _connectionStatusMessage = 'Disconnected';
//       _isAdvertising = false;
//       _isDiscovering = false;
//       _foundEndpoints.clear();
//       _incomingConnections.clear();
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Peer disconnected'),
//         backgroundColor: Colors.orange,
//       ),
//     );
//   }

//   void _handleEndpointFound(
//       String endpointId, String endpointName, String serviceId) {
//     setState(() {
//       // Only add to foundEndpoints if not already connected and not an incoming connection (which is handled separately)
//       if (!_isConnected && !_incomingConnections.containsKey(endpointId)) {
//         _foundEndpoints[endpointId] = endpointName;
//       }
//     });
//   }

//   void _handleConnectionRequest(
//       String endpointId, String endpointName, String serviceId) {
//     setState(() {
//       _incomingConnections[endpointId] = endpointName;
//       // Optionally show a dialog here for the user to accept/reject
//       _showConnectionRequestDialog(endpointId, endpointName);
//     });
//   }

//   void _showConnectionRequestDialog(String endpointId, String endpointName) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Connection Request'),
//         content: Text('Do you want to accept a connection from $endpointName?'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               _nearbyService.rejectConnection(endpointId);
//               setState(() {
//                 _incomingConnections.remove(endpointId);
//               });
//               Navigator.of(context).pop();
//             },
//             child: const Text('Reject'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _nearbyService.acceptConnection(endpointId);
//               setState(() {
//                 _incomingConnections.remove(
//                     endpointId); // Will be cleared by _handlePeerConnected too
//               });
//               Navigator.of(context).pop();
//             },
//             child: const Text('Accept'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _requestConnection(String endpointId) {
//     _nearbyService.requestConnection(widget.userName, endpointId);
//     setState(() {
//       _connectionStatusMessage =
//           'Requesting connection to ${_foundEndpoints[endpointId]}...';
//     });
//   }

//   void _sendMessage() {
//     final messageText = _messageController.text.trim();
//     if (messageText.isEmpty || !_isConnected) return;

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

//     _nearbyService.sendMessage(message);
//     _messageController.clear();
//     _scrollToBottom();
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

//   void _showPermissionError() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Nearby permissions are required to use this feature'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   // Callback from BoardGame to send game state
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
//     if (!_isConnected) return;

//     // Convert ChessPiece objects to a serializable format (Map<String, dynamic>)
//     List<List<Map<String, dynamic>?>> serializableBoard = board.map((row) {
//       return row.map((piece) => piece?.toJson()).toList();
//     }).toList();

//     List<Map<String, dynamic>> serializableWhiteTaken =
//         whitePiecesTaken.map((piece) => piece.toJson()).toList();
//     List<Map<String, dynamic>> serializableBlackTaken =
//         blackPiecesTaken.map((piece) => piece.toJson()).toList();

//     final gameStatePayload = GameStatePayload(
//       board: serializableBoard,
//       whitePiecesTaken: serializableWhiteTaken,
//       blackPiecesTaken: serializableBlackTaken,
//       isWhiteTurn: isWhiteTurn,
//       whiteKingPosition: whiteKingPosition,
//       blackKingPosition: blackKingPosition,
//       checkStatus: checkStatus,
//       enPassantTarget: enPassantTarget,
//       lastMoveJson: lastMove?.toJson(), // Send the last move made as JSON
//     );
//     _nearbyService.sendGameState(gameStatePayload);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isConnected
//             ? 'Connected: $_connectedPeerName'
//             : 'Multiplayer Chess'),
//         backgroundColor: _isConnected ? Colors.green : Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           if (_isConnected)
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: () {
//                 _nearbyService.disconnect();
//                 _handlePeerDisconnected();
//               },
//             ),
//         ],
//       ),
//       body: _isConnected
//           ? _buildGameAndChatInterface()
//           : _buildConnectionOptions(),
//     );
//   }

// // Enhanced connection options UI with better status tracking
//   Widget _buildConnectionOptions() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.wifi_tethering, size: 100, color: Colors.blue),
//             const SizedBox(height: 20),
//             const Text(
//               'Multiplayer Chess Connection',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _getStatusColor().withValues(alpha:0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: _getStatusColor().withValues(alpha:0.3)),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
//                   SizedBox(width: 8),
//                   Flexible(
//                     child: Text(
//                       _connectionStatusMessage,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: _getStatusColor(),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 40),
//             if (!_isAdvertising && !_isDiscovering) // Show buttons initially
//               Column(
//                 children: [
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: _startAdvertising,
//                       icon: const Icon(Icons.broadcast_on_personal),
//                       label: const Text('Host Game (Play as White)'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: _startDiscovery,
//                       icon: const Icon(Icons.search),
//                       label: const Text('Join Game (Play as Black)'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Make sure both devices have Bluetooth and Location enabled',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                       fontStyle: FontStyle.italic,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             if (_isAdvertising) // Show current advertising status and incoming requests
//               Column(
//                 children: [
//                   const CircularProgressIndicator(color: Colors.blue),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Waiting for players to join...',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(height: 20),
//                   if (_incomingConnections.isNotEmpty)
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withValues(alpha:0.1),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.blue.withValues(alpha:0.3)),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.person_add,
//                                   color: Colors.blue, size: 20),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Connection Requests:',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[800],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 12),
//                           ..._incomingConnections.entries
//                               .map((entry) => Container(
//                                     margin: EdgeInsets.only(bottom: 8),
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(8),
//                                       border: Border.all(
//                                           color: Colors.grey.withValues(alpha:0.3)),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 16,
//                                           backgroundColor: Colors.green,
//                                           child: Icon(Icons.person,
//                                               color: Colors.white, size: 16),
//                                         ),
//                                         SizedBox(width: 12),
//                                         Expanded(
//                                           child: Text(
//                                             entry.value,
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.w500),
//                                           ),
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.check_circle,
//                                               color: Colors.green),
//                                           onPressed: () {
//                                             _nearbyService
//                                                 .acceptConnection(entry.key);
//                                             setState(() {
//                                               _incomingConnections
//                                                   .remove(entry.key);
//                                             });
//                                           },
//                                           tooltip: 'Accept',
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.cancel,
//                                               color: Colors.red),
//                                           onPressed: () {
//                                             _nearbyService
//                                                 .rejectConnection(entry.key);
//                                             setState(() {
//                                               _incomingConnections
//                                                   .remove(entry.key);
//                                             });
//                                           },
//                                           tooltip: 'Decline',
//                                         ),
//                                       ],
//                                     ),
//                                   )),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 20),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       _nearbyService.stopAdvertising();
//                       setState(() {
//                         _isAdvertising = false;
//                         _connectionStatusMessage = 'Stopped hosting';
//                         _incomingConnections.clear();
//                       });
//                     },
//                     icon: const Icon(Icons.stop),
//                     label: const Text('Stop Hosting'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[600],
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             if (_isDiscovering) // Show current discovering status and found devices
//               Column(
//                 children: [
//                   const CircularProgressIndicator(color: Colors.green),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Searching for nearby games...',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(height: 20),
//                   if (_foundEndpoints.isNotEmpty)
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withValues(alpha:0.1),
//                         borderRadius: BorderRadius.circular(12),
//                         border:
//                             Border.all(color: Colors.green.withValues(alpha:0.3)),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.wifi_find,
//                                   color: Colors.green, size: 20),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Available Games:',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.green[800],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 12),
//                           ..._foundEndpoints.entries.map((entry) => Container(
//                                 margin: EdgeInsets.only(bottom: 8),
//                                 padding: EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                       color: Colors.grey.withValues(alpha:0.3)),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     CircleAvatar(
//                                       radius: 16,
//                                       backgroundColor: Colors.blue,
//                                       child: Icon(Icons.sports_esports,
//                                           color: Colors.white, size: 16),
//                                     ),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             entry.value,
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.w500),
//                                           ),
//                                           Text(
//                                             'Tap to join as Black player',
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     ElevatedButton(
//                                       onPressed: () =>
//                                           _requestConnection(entry.key),
//                                       child: const Text('Join'),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.green,
//                                         foregroundColor: Colors.white,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )),
//                         ],
//                       ),
//                     )
//                   else
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.orange.withValues(alpha:0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border:
//                             Border.all(color: Colors.orange.withValues(alpha:0.3)),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.orange),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'No games found yet. Make sure the host is advertising nearby.',
//                               style: TextStyle(color: Colors.orange[800]),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 20),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       _nearbyService.stopDiscovery();
//                       setState(() {
//                         _isDiscovering = false;
//                         _connectionStatusMessage = 'Stopped searching';
//                         _foundEndpoints.clear();
//                       });
//                     },
//                     icon: const Icon(Icons.stop),
//                     label: const Text('Stop Searching'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[600],
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

// // Helper methods for status indication
//   Color _getStatusColor() {
//     if (_isConnected) return Colors.green;
//     if (_isAdvertising) return Colors.blue;
//     if (_isDiscovering) return Colors.orange;
//     return Colors.grey;
//   }

//   IconData _getStatusIcon() {
//     if (_isConnected) return Icons.check_circle;
//     if (_isAdvertising) return Icons.broadcast_on_personal;
//     if (_isDiscovering) return Icons.search;
//     return Icons.info_outline;
//   }
//   // Widget _buildConnectionOptions() {
//   //   return Center(
//   //     child: Padding(
//   //       padding: const EdgeInsets.all(20.0),
//   //       child: Column(
//   //         mainAxisAlignment: MainAxisAlignment.center,
//   //         children: [
//   //           const Icon(Icons.wifi_tethering, size: 100, color: Colors.blue),
//   //           const SizedBox(height: 20),
//   //           const Text(
//   //             'Multiplayer Chess Connection',
//   //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//   //           ),
//   //           const SizedBox(height: 10),
//   //           Text(
//   //             _connectionStatusMessage,
//   //             textAlign: TextAlign.center,
//   //             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//   //           ),
//   //           const SizedBox(height: 40),
//   //           if (!_isAdvertising && !_isDiscovering) // Show buttons initially
//   //             Column(
//   //               children: [
//   //                 SizedBox(
//   //                   width: double.infinity,
//   //                   child: ElevatedButton.icon(
//   //                     onPressed: _startAdvertising,
//   //                     icon: const Icon(Icons.broadcast_on_personal),
//   //                     label: const Text('Host Game'),
//   //                     style: ElevatedButton.styleFrom(
//   //                       backgroundColor: Colors.blue,
//   //                       foregroundColor: Colors.white,
//   //                       padding: const EdgeInsets.symmetric(vertical: 15),
//   //                     ),
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 SizedBox(
//   //                   width: double.infinity,
//   //                   child: ElevatedButton.icon(
//   //                     onPressed: _startDiscovery,
//   //                     icon: const Icon(Icons.search),
//   //                     label: const Text('Join Game'),
//   //                     style: ElevatedButton.styleFrom(
//   //                       backgroundColor: Colors.green,
//   //                       foregroundColor: Colors.white,
//   //                       padding: const EdgeInsets.symmetric(vertical: 15),
//   //                     ),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           if (_isAdvertising) // Show current advertising status and incoming requests
//   //             Column(
//   //               children: [
//   //                 const CircularProgressIndicator(color: Colors.blue),
//   //                 const SizedBox(height: 10),
//   //                 Text(_connectionStatusMessage),
//   //                 const SizedBox(height: 20),
//   //                 if (_incomingConnections.isNotEmpty)
//   //                   Column(
//   //                     crossAxisAlignment: CrossAxisAlignment.start,
//   //                     children: [
//   //                       const Text('Incoming Connection Requests:',
//   //                           style: TextStyle(fontWeight: FontWeight.bold)),
//   //                       ..._incomingConnections.entries.map((entry) => ListTile(
//   //                             title: Text(entry.value),
//   //                             trailing: Row(
//   //                               mainAxisSize: MainAxisSize.min,
//   //                               children: [
//   //                                 IconButton(
//   //                                   icon: const Icon(Icons.check,
//   //                                       color: Colors.green),
//   //                                   onPressed: () => _nearbyService
//   //                                       .acceptConnection(entry.key),
//   //                                 ),
//   //                                 IconButton(
//   //                                   icon: const Icon(Icons.close,
//   //                                       color: Colors.red),
//   //                                   onPressed: () => _nearbyService
//   //                                       .rejectConnection(entry.key),
//   //                                 ),
//   //                               ],
//   //                             ),
//   //                           )),
//   //                     ],
//   //                   ),
//   //                 const SizedBox(height: 20),
//   //                 ElevatedButton(
//   //                   onPressed: () {
//   //                     _nearbyService.stopAdvertising();
//   //                     setState(() {
//   //                       _isAdvertising = false;
//   //                       _connectionStatusMessage = 'Advertising stopped.';
//   //                       _incomingConnections.clear();
//   //                     });
//   //                   },
//   //                   child: const Text('Stop Hosting'),
//   //                 ),
//   //               ],
//   //             ),
//   //           if (_isDiscovering) // Show current discovering status and found devices
//   //             Column(
//   //               children: [
//   //                 const CircularProgressIndicator(color: Colors.green),
//   //                 const SizedBox(height: 10),
//   //                 Text(_connectionStatusMessage),
//   //                 const SizedBox(height: 20),
//   //                 if (_foundEndpoints.isNotEmpty)
//   //                   Column(
//   //                     crossAxisAlignment: CrossAxisAlignment.start,
//   //                     children: [
//   //                       const Text('Found Devices:',
//   //                           style: TextStyle(fontWeight: FontWeight.bold)),
//   //                       ..._foundEndpoints.entries.map((entry) => ListTile(
//   //                             title: Text(entry.value),
//   //                             trailing: ElevatedButton(
//   //                               onPressed: () => _requestConnection(entry.key),
//   //                               child: const Text('Connect'),
//   //                             ),
//   //                           )),
//   //                     ],
//   //                   ),
//   //                 const SizedBox(height: 20),
//   //                 ElevatedButton(
//   //                   onPressed: () {
//   //                     _nearbyService.stopDiscovery();
//   //                     setState(() {
//   //                       _isDiscovering = false;
//   //                       _connectionStatusMessage = 'Discovery stopped.';
//   //                       _foundEndpoints.clear();
//   //                     });
//   //                   },
//   //                   child: const Text('Stop Discovery'),
//   //                 ),
//   //               ],
//   //             ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }

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
//         color: Colors.white,
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

// // Extend BoardGame to accept a callback for sending game state updates
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
//   // ... existing variables ...
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

//   // Variables to store review state
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
//     playerAssignment = PlayerAssignment(); // Initialize PlayerAssignment

//     // Set local player's color based on multiplayer flag
//     if (widget.isMultiplayer) {
//       // For multiplayer, directly set the internal state for player turn checking
//       // Note: PlayerAssignment's _isLocalPlayerWhite is private.
//       // We will bypass PlayerAssignment's _isLocalPlayerWhite for turn checking in multiplayer.
//       // The `canSelectPiece` logic below will use `widget.isLocalPlayerWhite` directly.
//     } else {
//       playerAssignment
//           .assignRandomColors(); // For single player, assign randomly
//     }
//   }

//   // Method to apply received game state
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

//       // Update timer based on the received turn
//       // Assuming ChessTimer has an internal mechanism to manage turns and pause/start
//       // based on `switchTurn()` and its `isWhiteTurn` property.
//       // If the received turn is different from the current timer's active turn, switch it.
//       if (chessTimer.isRunning) {
//         // This assumes ChessTimer has a public getter for its current turn state.
//         // If not, you'd need to add it to ChessTimer or manage this state here.
//         // For now, assuming `chessTimer.isWhiteTurn` exists or `switchTurn` is smart.
//         // The `isWhiteTurn` in `_BoardGameState` is the source of truth for the game logic.
//         // The ChessTimer should just reflect this.
//         if (isWhiteTurn != chessTimer.isWhiteTurn) {
//           // Assuming chessTimer.isWhiteTurn exists
//           chessTimer.switchTurn();
//         }
//       }

//       // Add the move to review history if it's a new move
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

//     // Send game state update to the connected peer
//     widget.onGameStateUpdate?.call(
//       board,
//       whitePiecesTaken,
//       blackPiecesTaken,
//       isWhiteTurn,
//       whiteKingPosition,
//       blackKingPosition,
//       checkStatus,
//       enPassantTarget,
//       move, // Send the last move made
//     );
//   }

//   void pieceSelected(int row, int col) {
//     if (gameEnded) return;

//     // Convert visual coordinates to actual board coordinates
//     int actualRow = row;
//     int actualCol = col;

//     if (!widget.isLocalPlayerWhite) {
//       actualRow = 7 - row; // Convert flipped row back to actual row
//       actualCol = 7 - col; // Convert flipped col back to actual col
//     }

//     // Get the piece at the actual board position
//     ChessPiece? pieceAtLocation = currentBoard[actualRow][actualCol];

//     // Disable selection if in review mode
//     if (reviewController.isInReviewMode) return;

//     setState(() {
//       // Logic for piece selection based on game mode (single vs multiplayer) and turn
//       bool canSelect = false;

//       if (widget.isMultiplayer) {
//         // In multiplayer, a player can only select their own pieces when it's their turn
//         if (pieceAtLocation != null) {
//           bool isPieceOwnedByLocalPlayer =
//               pieceAtLocation.isWhite == widget.isLocalPlayerWhite;
//           bool isLocalPlayersTurn = isWhiteTurn == widget.isLocalPlayerWhite;
//           canSelect = isPieceOwnedByLocalPlayer && isLocalPlayersTurn;

//           // Debug debugPrints
//           debugPrint('Multiplayer piece selection:');
//           debugPrint('  Piece is white: ${pieceAtLocation.isWhite}');
//           debugPrint('  Local player is white: ${widget.isLocalPlayerWhite}');
//           debugPrint('  Current turn is white: $isWhiteTurn');
//           debugPrint(
//               '  Piece owned by local player: $isPieceOwnedByLocalPlayer');
//           debugPrint('  Is local players turn: $isLocalPlayersTurn');
//           debugPrint('  Can select: $canSelect');
//           debugPrint(
//               '  Visual position: ($row, $col), Actual position: ($actualRow, $actualCol)');
//         }
//       } else {
//         // In single player, use the PlayerAssignment logic
//         canSelect = (pieceAtLocation != null &&
//             playerAssignment.canSelectPiece(
//                 pieceAtLocation.isWhite, isWhiteTurn));
//       }

//       // Condition 1: No piece currently selected, and a piece is tapped
//       if (selectedPiece == null && canSelect) {
//         selectedPiece = pieceAtLocation;
//         selectedRow = actualRow; // Store actual row
//         selectedCol = actualCol; // Store actual col
//         debugPrint(
//             'Piece selected: ${selectedPiece!.type} at actual position ($actualRow, $actualCol), visual position ($row, $col)');

//         // Start timer only if it's not running and a piece is selected for the first time
//         if (chessTimer.isStopped) {
//           chessTimer.startTimer();
//         }
//       }
//       // Condition 2: A piece is already selected, and a new piece of the same color is tapped
//       else if (pieceAtLocation != null && selectedPiece != null && canSelect) {
//         // Allow re-selection of own pieces
//         selectedPiece = pieceAtLocation;
//         selectedRow = actualRow; // Store actual row
//         selectedCol = actualCol; // Store actual col
//         debugPrint(
//             'Piece re-selected: ${selectedPiece!.type} at actual position ($actualRow, $actualCol), visual position ($row, $col)');
//       }
//       // Condition 3: A piece is selected, and a valid empty square or opponent's piece is tapped
//       else if (selectedPiece != null &&
//           validMoves.any((element) =>
//               element[0] == actualRow && element[1] == actualCol)) {
//         // Double-check that it's the local player's turn and they own the selected piece
//         bool canMakeMove = false;
//         if (widget.isMultiplayer) {
//           bool pieceOwnedByLocalPlayer =
//               selectedPiece!.isWhite == widget.isLocalPlayerWhite;
//           bool isLocalPlayersTurn = isWhiteTurn == widget.isLocalPlayerWhite;
//           canMakeMove = pieceOwnedByLocalPlayer && isLocalPlayersTurn;

//           debugPrint('Attempting move:');
//           debugPrint('  Selected piece is white: ${selectedPiece!.isWhite}');
//           debugPrint('  Local player is white: ${widget.isLocalPlayerWhite}');
//           debugPrint('  Current turn is white: $isWhiteTurn');
//           debugPrint('  Can make move: $canMakeMove');
//           debugPrint(
//               '  Moving to actual position: ($actualRow, $actualCol), visual position: ($row, $col)');
//         } else {
//           canMakeMove = playerAssignment.canSelectPiece(
//               selectedPiece!.isWhite, isWhiteTurn);
//         }

//         if (canMakeMove) {
//           debugPrint(
//               'Making move from ($selectedRow, $selectedCol) to ($actualRow, $actualCol)');
//           movePiece(
//               actualRow, actualCol); // Use actual coordinates for the move
//         } else {
//           debugPrint('Move blocked - not local player\'s turn or piece');
//         }
//       }

//       // Always recalculate valid moves for the currently selected piece (if any)
//       if (selectedPiece != null) {
//         validMoves = calculateRealValidMoves(
//             selectedRow, selectedCol, selectedPiece, true);
//         debugPrint('Valid moves calculated: ${validMoves.length} moves');
//         debugPrint('Valid moves: $validMoves');
//       } else {
//         validMoves = []; // Clear valid moves if no piece is selected
//       }
//     });
//   }
//   // void pieceSelected(int row, int col) {
//   //   if (gameEnded) return;

//   //   // Get the piece at the selected position
//   //   ChessPiece? pieceAtLocation = currentBoard[row][col];

//   //   // Disable selection if in review mode
//   //   if (reviewController.isInReviewMode) return;

//   //   setState(() {
//   //     // Logic for piece selection based on game mode (single vs multiplayer) and turn
//   //     bool canSelect = false;

//   //     if (widget.isMultiplayer) {
//   //       // In multiplayer, a player can only select their own pieces when it's their turn
//   //       if (pieceAtLocation != null) {
//   //         bool isPieceOwnedByLocalPlayer =
//   //             pieceAtLocation.isWhite == widget.isLocalPlayerWhite;
//   //         bool isLocalPlayersTurn = isWhiteTurn == widget.isLocalPlayerWhite;
//   //         canSelect = isPieceOwnedByLocalPlayer && isLocalPlayersTurn;

//   //         // Debug debugPrints to help diagnose issues
//   //         debugPrint('Multiplayer piece selection:');
//   //         debugPrint('  Piece is white: ${pieceAtLocation.isWhite}');
//   //         debugPrint('  Local player is white: ${widget.isLocalPlayerWhite}');
//   //         debugPrint('  Current turn is white: $isWhiteTurn');
//   //         debugPrint('  Piece owned by local player: $isPieceOwnedByLocalPlayer');
//   //         debugPrint('  Is local players turn: $isLocalPlayersTurn');
//   //         debugPrint('  Can select: $canSelect');
//   //       }
//   //     } else {
//   //       // In single player, use the PlayerAssignment logic
//   //       canSelect = (pieceAtLocation != null &&
//   //           playerAssignment.canSelectPiece(
//   //               pieceAtLocation.isWhite, isWhiteTurn));
//   //     }

//   //     // Condition 1: No piece currently selected, and a piece is tapped
//   //     if (selectedPiece == null && canSelect) {
//   //       selectedPiece = pieceAtLocation;
//   //       selectedRow = row;
//   //       selectedCol = col;
//   //       debugPrint('Piece selected: ${selectedPiece!.type} at ($row, $col)');

//   //       // Start timer only if it's not running and a piece is selected for the first time
//   //       if (chessTimer.isStopped) {
//   //         chessTimer.startTimer();
//   //       }
//   //     }
//   //     // Condition 2: A piece is already selected, and a new piece of the same color is tapped
//   //     else if (pieceAtLocation != null && selectedPiece != null && canSelect) {
//   //       // Allow re-selection of own pieces
//   //       selectedPiece = pieceAtLocation;
//   //       selectedRow = row;
//   //       selectedCol = col;
//   //       debugPrint('Piece re-selected: ${selectedPiece!.type} at ($row, $col)');
//   //     }
//   //     // Condition 3: A piece is selected, and a valid empty square or opponent's piece is tapped
//   //     else if (selectedPiece != null &&
//   //         validMoves.any((element) => element[0] == row && element[1] == col)) {
//   //       // Double-check that it's the local player's turn and they own the selected piece
//   //       bool canMakeMove = false;
//   //       if (widget.isMultiplayer) {
//   //         bool pieceOwnedByLocalPlayer =
//   //             selectedPiece!.isWhite == widget.isLocalPlayerWhite;
//   //         bool isLocalPlayersTurn = isWhiteTurn == widget.isLocalPlayerWhite;
//   //         canMakeMove = pieceOwnedByLocalPlayer && isLocalPlayersTurn;

//   //         debugPrint('Attempting move:');
//   //         debugPrint('  Selected piece is white: ${selectedPiece!.isWhite}');
//   //         debugPrint('  Local player is white: ${widget.isLocalPlayerWhite}');
//   //         debugPrint('  Current turn is white: $isWhiteTurn');
//   //         debugPrint('  Can make move: $canMakeMove');
//   //       } else {
//   //         canMakeMove = playerAssignment.canSelectPiece(
//   //             selectedPiece!.isWhite, isWhiteTurn);
//   //       }

//   //       if (canMakeMove) {
//   //         debugPrint(
//   //             'Making move from ($selectedRow, $selectedCol) to ($row, $col)');
//   //         movePiece(row, col);
//   //       } else {
//   //         debugPrint('Move blocked - not local player\'s turn or piece');
//   //       }
//   //     }

//   //     // Always recalculate valid moves for the currently selected piece (if any)
//   //     if (selectedPiece != null) {
//   //       validMoves = calculateRealValidMoves(
//   //           selectedRow, selectedCol, selectedPiece, true);
//   //       debugPrint('Valid moves calculated: ${validMoves.length} moves');
//   //     } else {
//   //       validMoves = []; // Clear valid moves if no piece is selected
//   //     }
//   //   });
//   // }

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

//     // Clear review state
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
//         var directions = [
//           [-1, 0],
//           [1, 0],
//           [0, -1],
//           [0, 1]
//         ];
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

//       case ChessPiecesType.bishop:
//         var directions = [
//           [-1, -1],
//           [-1, 1],
//           [1, -1],
//           [1, 1]
//         ];
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

//       case ChessPiecesType.queen:
//         var directions = [
//           [-1, 0],
//           [1, 0],
//           [0, -1],
//           [0, 1],
//           [-1, -1],
//           [-1, 1],
//           [1, -1],
//           [1, 1]
//         ];
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
//     // Invert row if local player is black
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
//     // Check if the current context is still valid before popping
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
//         title: Row(
//           children: [
//             Icon(
//               Icons.timer_off,
//               color: Colors.red,
//               size: 24,
//             ),
//             SizedBox(width: 8),
//             Text(
//               "Time's Up!",
//               style: TextStyle(
//                 color: Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               isWhiteWinner ? Icons.emoji_events : Icons.emoji_events,
//               color: isWhiteWinner ? Colors.amber : Colors.grey,
//               size: 48,
//             ),
//             SizedBox(height: 16),
//             Text(
//               isWhiteWinner
//                   ? "Black ran out of time.\nWhite wins!"
//                   : "White ran out of time.\nBlack wins!",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             SizedBox(height: 12),
//             Text(
//               "Game Over",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: Text(
//               "View Board",
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               resetGame();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//             ),
//             child: Text("New Game"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           reviewController.isInReviewMode ? Colors.orange[200] : Colors.white30,
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           SafeArea(
//             child: ReviewStatusBanner(
//               isInReviewMode: reviewController.isInReviewMode,
//               statusText: reviewController.isInReviewMode
//                   ? 'REVIEWING MOVES - TIMER CONTINUES'
//                   : 'Game On',
//             ),
//           ),
//           // Player info at the top (opponent for local white, self for local black)
//           if (widget
//               .isLocalPlayerWhite) // Local player is White, opponent is Black (top)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.white)),
//                         child: Image.asset(
//                           "assets/images/figures/white/queen.png",
//                           height: 50,
//                           color: Colors.black, // Opponent is black
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Opponent", // Replace with actual opponent name if available
//                             style: TextStyle(
//                               color: reviewController.isInReviewMode
//                                   ? Colors.black
//                                   : Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           SizedBox(
//                             height: 30,
//                             width: MediaQuery.of(context).size.width * .6,
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               shrinkWrap: true,
//                               physics: const BouncingScrollPhysics(),
//                               itemCount: currentBlackPiecesTaken.length,
//                               itemBuilder: (context, index) => DeadPiece(
//                                 imagePath:
//                                     currentBlackPiecesTaken[index].imagePath,
//                                 isWhite: false,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   ChessTimerDisplayForBlack(
//                     chessTimer: chessTimer,
//                     whiteTime: whiteTime,
//                     blackTime: blackTime,
//                   ),
//                 ],
//               ),
//             )
//           else // Local player is Black, opponent is White (top)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.white)),
//                         child: Image.asset(
//                           "assets/images/figures/white/queen.png",
//                           height: 50,
//                           color: Colors.white, // Opponent is white
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Opponent", // Replace with actual opponent name if available
//                             style: TextStyle(
//                               color: reviewController.isInReviewMode
//                                   ? Colors.black
//                                   : Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           SizedBox(
//                             height: 30,
//                             width: MediaQuery.of(context).size.width * .6,
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               shrinkWrap: true,
//                               physics: const BouncingScrollPhysics(),
//                               itemCount: currentWhitePiecesTaken.length,
//                               itemBuilder: (context, index) => DeadPiece(
//                                 imagePath:
//                                     currentWhitePiecesTaken[index].imagePath,
//                                 isWhite: true,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   ChessTimerDisplayForWhite(
//                     chessTimer: chessTimer,
//                     whiteTime: whiteTime,
//                     blackTime: blackTime,
//                   ),
//                 ],
//               ),
//             ),

//           Spacer(),
// // Updated GridView.builder in the build method
//           AspectRatio(
//             aspectRatio: .9,
//             child: GridView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: 64,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 8),
//               itemBuilder: (context, index) {
//                 int row = index ~/ 8;
//                 int col = index % 8;

//                 // These are the visual coordinates after potential flipping
//                 int visualRow = row;
//                 int visualCol = col;

//                 // Calculate actual board coordinates based on player orientation
//                 int actualRow = row;
//                 int actualCol = col;

//                 // If local player is black, flip the board so black pieces appear at bottom
//                 if (!widget.isLocalPlayerWhite) {
//                   actualRow = 7 - row; // Flip rows
//                   actualCol =
//                       7 - col; // Flip columns too for proper orientation

//                   // Update visual coordinates for display
//                   visualRow = row;
//                   visualCol = col;
//                 }

//                 bool isSelected = !reviewController.isInReviewMode &&
//                     selectedCol == actualCol &&
//                     selectedRow == actualRow;

//                 bool isValidMove = false;

//                 if (!reviewController.isInReviewMode) {
//                   for (var position in validMoves) {
//                     // position contains actual board coordinates
//                     if (position[0] == actualRow && position[1] == actualCol) {
//                       isValidMove = true;
//                       break;
//                     }
//                   }
//                 }

//                 return Square(
//                   isValidMove: isValidMove,
//                   onTap: reviewController.isInReviewMode
//                       ? null
//                       : () => pieceSelected(visualRow, visualCol),
//                   isSelected: isSelected,
//                   isWhite: isWhite(index), // Board square color pattern
//                   piece: currentBoard[actualRow]
//                       [actualCol], // Piece from actual position
//                   isKingInCheck: currentBoard[actualRow][actualCol] != null &&
//                       currentBoard[actualRow][actualCol]!.type ==
//                           ChessPiecesType.king &&
//                       _isKingInCheckAtCurrentState(
//                           currentBoard[actualRow][actualCol]!.isWhite),
//                   boardBColor: reviewController.isInReviewMode
//                       ? Colors.orange
//                       : forgroundColor,
//                   boardWColor: backgroundColor,
//                 );
//               },
//             ),
//           ),
//           // AspectRatio(
//           //   aspectRatio: .9,
//           //   child: GridView.builder(
//           //     physics: const NeverScrollableScrollPhysics(),
//           //     itemCount: 64,
//           //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           //         crossAxisCount: 8),
//           //     itemBuilder: (context, index) {
//           //       int row = index ~/ 8;
//           //       int col = index % 8;

//           //       // Flip the board if the local player is Black
//           //       if (!widget.isLocalPlayerWhite) {
//           //         row = 7 - row;
//           //         // col = 7 - col; // Only flip rows, not columns typically for chess
//           //       }

//           //       bool isSelected = !reviewController.isInReviewMode &&
//           //           selectedCol == col &&
//           //           selectedRow == row;
//           //       bool isValidMove = false;

//           //       if (!reviewController.isInReviewMode) {
//           //         for (var position in validMoves) {
//           //           // Adjust valid move positions if the board is flipped
//           //           int validMoveRow = widget.isLocalPlayerWhite
//           //               ? position[0]
//           //               : 7 - position[0];
//           //           // int validMoveCol = widget.isLocalPlayerWhite ? position[1] : 7 - position[1]; // Not flipping columns

//           //           if (validMoveRow == row && position[1] == col) {
//           //             isValidMove = true;
//           //           }
//           //         }
//           //       }

//           //       return Square(
//           //         isValidMove: isValidMove,
//           //         onTap: reviewController.isInReviewMode
//           //             ? null
//           //             : () => pieceSelected(row, col),
//           //         isSelected: isSelected,
//           //         isWhite: isWhite(
//           //             index), // isWhite considers the original board layout
//           //         piece: currentBoard[row]
//           //             [col], // Pass piece from the original board layout
//           //         isKingInCheck: currentBoard[row][col] != null &&
//           //             currentBoard[row][col]!.type == ChessPiecesType.king &&
//           //             _isKingInCheckAtCurrentState(
//           //                 currentBoard[row][col]!.isWhite),
//           //         boardBColor: reviewController.isInReviewMode
//           //             ? Colors.orange
//           //             : forgroundColor,
//           //         boardWColor: backgroundColor,
//           //       );
//           //     },
//           //   ),
//           // ),

//           Spacer(),

//           // Player info at the bottom (self for local white, opponent for local black)
//           if (widget.isLocalPlayerWhite) // Local player is White (bottom)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.white)),
//                         child: Image.asset(
//                           "assets/images/figures/white/queen.png",
//                           height: 50,
//                           color: Colors.white, // Local player is white
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.name,
//                             style: TextStyle(
//                               color: reviewController.isInReviewMode
//                                   ? Colors.black
//                                   : Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           SizedBox(
//                             height: 30,
//                             width: MediaQuery.of(context).size.width * .6,
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               shrinkWrap: true,
//                               physics: const BouncingScrollPhysics(),
//                               itemCount: currentWhitePiecesTaken.length,
//                               itemBuilder: (context, index) => DeadPiece(
//                                 imagePath:
//                                     currentWhitePiecesTaken[index].imagePath,
//                                 isWhite: true,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   ChessTimerDisplayForWhite(
//                     chessTimer: chessTimer,
//                     whiteTime: whiteTime,
//                     blackTime: blackTime,
//                   ),
//                 ],
//               ),
//             )
//           else // Local player is Black (bottom)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.white)),
//                         child: Image.asset(
//                           "assets/images/figures/white/queen.png",
//                           height: 50,
//                           color: Colors.black, // Local player is black
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.name,
//                             style: TextStyle(
//                               color: reviewController.isInReviewMode
//                                   ? Colors.black
//                                   : Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           SizedBox(
//                             height: 30,
//                             width: MediaQuery.of(context).size.width * .6,
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               shrinkWrap: true,
//                               physics: const BouncingScrollPhysics(),
//                               itemCount: currentBlackPiecesTaken.length,
//                               itemBuilder: (context, index) => DeadPiece(
//                                 imagePath:
//                                     currentBlackPiecesTaken[index].imagePath,
//                                 isWhite: false,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   ChessTimerDisplayForBlack(
//                     chessTimer: chessTimer,
//                     whiteTime: whiteTime,
//                     blackTime: blackTime,
//                   ),
//                 ],
//               ),
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

//   bool _isKingInCheckAtCurrentState(bool isWhiteKing) {
//     if (reviewController.isInReviewMode) {
//       return currentCheckStatus &&
//           ((isWhiteKing && !currentIsWhiteTurn) ||
//               (!isWhiteKing && currentIsWhiteTurn));
//     }
//     return isKingInCheck(isWhiteKing);
//   }
// }

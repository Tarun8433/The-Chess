// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:the_chess/chat/chat_room.dart';
// import 'package:the_chess/chat/image_silde.dart';
// import 'package:the_chess/chat/online_game.dart';

// // Fixed Controller for matchmaking state
// class MatchmakingController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   final MatchmakingService _matchmakingService = MatchmakingService();

//   // Reactive variables
//   final _isSearching = false.obs;
//   final _searchStatus = 'Ready to find opponent'.obs;
//   final _isMatchFound = false.obs;
//   final _isNavigating = false.obs;

//   // Animation controller
//   late AnimationController _animationController;

//   // Subscriptions
//   StreamSubscription<String>? _matchSubscription;
//   StreamSubscription<DocumentSnapshot>? _userQueueSubscription;
//   Timer? _fallbackTimer;

//   // Getters
//   bool get isSearching => _isSearching.value;
//   String get searchStatus => _searchStatus.value;
//   bool get isMatchFound => _isMatchFound.value;
//   bool get isNavigating => _isNavigating.value;
//   AnimationController get animationController => _animationController;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeAnimation();
//     _setupMatchListener();
//   }

//   @override
//   void onClose() {
//     _animationController.dispose();
//     _matchSubscription?.cancel();
//     _userQueueSubscription?.cancel();
//     _fallbackTimer?.cancel();
//     if (_isSearching.value) {
//       _matchmakingService.leaveQueue();
//     }
//     super.onClose();
//   }

//   void _initializeAnimation() {
//     _animationController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
//   }

//   void _setupMatchListener() {
//     print('Setting up match stream listener');
//     _matchSubscription = _matchmakingService.matchStream.listen(
//       (roomId) {
//         print('Match stream received room ID: $roomId');
//         if (!_isNavigating.value) {
//           _handleMatchFound(roomId);
//         }
//       },
//       onError: (error) {
//         print('Match stream error: $error');
//         _updateSearchStatus('Error occurred. Please try again.');
//         _resetState();
//       },
//     );
//   }

//   void _handleMatchFound(String roomId) {
//     if (roomId.isEmpty || !_isSearching.value || _isNavigating.value) {
//       print('Ignoring duplicate match found event');
//       return;
//     }

//     print('Processing match found: $roomId');
//     _isNavigating.value = true;
//     _isMatchFound.value = true;
//     _updateSearchStatus('Match found! Starting animation...');

//     // Cancel ongoing timers and subscriptions
//     _userQueueSubscription?.cancel();
//     _fallbackTimer?.cancel();

//     // Get and control animation controllers
//     _startMatchFoundAnimation().then((_) {
//       _navigateToChat(roomId);
//     });
//   }

//   Future<void> _startMatchFoundAnimation() async {
//     try {
//       // Get controllers - use findOrNull to avoid errors if not found
//       final imageController =
//           Get.isRegistered<ImageSliderController>(tag: 'opponent_slider')
//               ? Get.find<ImageSliderController>(tag: 'opponent_slider')
//               : null;

//       final vsController = Get.isRegistered<VSBattleController>()
//           ? Get.find<VSBattleController>()
//           : null;

//       print('Starting match found animation sequence');

//       // Stop image slider
//       if (imageController != null) {
//         imageController.stopSlideShow();
//         print('Stopped image slider');
//       }

//       // Start VS battle animation
//       if (vsController != null) {
//         _updateSearchStatus('Battle animation starting...');
//         vsController.restartAnimation();
//         print('Started VS battle animation');

//         // Wait for animation to complete
//         await Future.delayed(Duration(seconds: 3));
//         print('Animation sequence completed');
//       } else {
//         // Fallback delay if VS controller not found
//         await Future.delayed(Duration(seconds: 2));
//       }

//       _updateSearchStatus('Entering chat room...');
//     } catch (e) {
//       print('Error during animation: $e');
//       // Continue with navigation even if animation fails
//     }
//   }

//   void _navigateToChat(String roomId) {
//     if (_isNavigating.value) {
//       print('Navigating to chat screen with room: $roomId');
//       _stopSearching();

//       Get.to(() => EnhancedChatScreen(
//             roomId: roomId,
//             partnerName: 'Anonymous User',
//           ))?.then((_) {
//         // Reset state when returning from chat
//         _resetState();
//       });
//     }
//   }

//   void startSearching() {
//     if (_isSearching.value || _isNavigating.value) return;

//     _resetState();
//     _isSearching.value = true;
//     _updateSearchStatus('Searching for opponent...');

//     print('Starting search...');
//     _matchmakingService.joinQueue();
//     _startDirectQueueListener();
//     _startFallbackTimer();
//   }

//   void stopSearching() {
//     _stopSearching();
//   }

//   void _stopSearching() {
//     _isSearching.value = false;
//     _updateSearchStatus('Search stopped');
//     _userQueueSubscription?.cancel();
//     _fallbackTimer?.cancel();
//     _matchmakingService.leaveQueue();
//   }

//   void _resetState() {
//     _isMatchFound.value = false;
//     _isNavigating.value = false;
//     _updateSearchStatus('Ready to find opponent');
//   }

//   void _startDirectQueueListener() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     print('Setting up direct queue listener for user: ${user.uid}');
//     _userQueueSubscription = FirebaseFirestore.instance
//         .collection('matchmaking_queue')
//         .doc(user.uid)
//         .snapshots()
//         .listen((snapshot) {
//       if (!_isSearching.value || _isNavigating.value) return;

//       print('Queue document changed for ${user.uid}');
//       if (snapshot.exists) {
//         final data = snapshot.data() as Map<String, dynamic>;
//         final status = data['status'] as String?;
//         final roomId = data['roomId'] as String?;

//         print('Direct queue listener - Status: $status, RoomId: $roomId');

//         if (status == 'matched' && roomId != null && !_isNavigating.value) {
//           print('Direct match detected! Processing room: $roomId');
//           _handleMatchFound(roomId);
//         }
//       }
//     });
//   }

//   void _startFallbackTimer() {
//     _fallbackTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
//       if (!_isSearching.value || _isNavigating.value) {
//         timer.cancel();
//         return;
//       }

//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         try {
//           final doc = await FirebaseFirestore.instance
//               .collection('matchmaking_queue')
//               .doc(user.uid)
//               .get();

//           if (doc.exists) {
//             final data = doc.data() as Map<String, dynamic>;
//             final status = data['status'] as String?;
//             final roomId = data['roomId'] as String?;

//             print('Timer check - Status: $status, RoomId: $roomId');

//             if (status == 'matched' && roomId != null && !_isNavigating.value) {
//               print('Timer found match! Processing room: $roomId');
//               timer.cancel();
//               _handleMatchFound(roomId);
//             }
//           }
//         } catch (e) {
//           print('Timer check error: $e');
//         }
//       }
//     });
//   }

//   void _updateSearchStatus(String status) {
//     _searchStatus.value = status;
//     print('Status updated: $status');
//   }
// }

// // Updated MatchmakingScreen with better state handling
// class MatchmakingScreen extends StatelessWidget {
//   const MatchmakingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Initialize controller
//     final controller = Get.put(MatchmakingController());

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Obx(() {
//         return Stack(
//           children: [
//             // VS Battle Animation background when searching
//             if (controller.isSearching)
//               VSBattleWidget(showRestartButton: false),

//             // Main content overlay
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   if (controller.isSearching) ...[
//                     SizedBox(),

//                     _buildSearchingHeader(controller),

//                     SizedBox(height: 10),

//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _buildPlayerSlots(),
//                         SizedBox(height: 130),
//                         _buildOpponentSlider(),
//                       ],
//                     ),
//                     SizedBox(),

//                     // Show stop button only if not navigating
//                     !controller.isNavigating
//                         ? _buildStopButton(controller)
//                         : SizedBox(height: 45),
//                     SizedBox(),
//                   ] else ...[
//                     Spacer(),
//                     _buildStartButton(controller),
//                     SizedBox(height: 100),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildSearchingHeader(MatchmakingController controller) {
//     return Obx(() {
//       return Column(
//         children: [
//           Text(
//             controller.isMatchFound
//                 ? 'Match Found!'
//                 : 'Looking for someone to join',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.white,
//             ),
//           ),
//           Text(
//             controller.searchStatus,
//             style: TextStyle(
//                 fontSize: 14,
//                 color: controller.isMatchFound
//                     ? Colors.green.shade300
//                     : Colors.white),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildPlayerSlots() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 40),
//       child: Row(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             height: 100,
//             width: 100,
//             clipBehavior: Clip.hardEdge,
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 500),
//               transitionBuilder: (Widget child, Animation<double> animation) {
//                 return SlideTransition(
//                   position: Tween<Offset>(
//                     begin: const Offset(0.0, 1.0),
//                     end: const Offset(0.0, 0.0),
//                   ).animate(animation),
//                   child: child,
//                 );
//               },
//               child: Image.asset(
//                 imageList[0],
//                 key: ValueKey<int>(0),
//                 fit: BoxFit.cover,
//                 height: 100,
//                 width: 100,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOpponentSlider() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 40),
//       child: SimpleVerticalImageSlider(
//         imagePaths: imageList,
//         height: 100,
//         width: 100,
//         tag: 'opponent_slider',
//       ),
//     );
//   }

//   Widget _buildStopButton(MatchmakingController controller) {
//     return Center(
//       child: ElevatedButton(
//         onPressed: controller.stopSearching,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red.withValues(alpha:0.2),
//           foregroundColor: Colors.red,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(25),
//             side: const BorderSide(color: Colors.red, width: 2),
//           ),
//         ),
//         child: const Text(
//           'Stop Searching',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStartButton(MatchmakingController controller) {
//     return ElevatedButton(
//       onPressed: controller.startSearching,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(25),
//         ),
//       ),
//       child: Text('Start Chatting'),
//     );
//   }
// }

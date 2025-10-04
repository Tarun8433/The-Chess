import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:the_chess/drawer/controllers/page_controller.dart';
 import 'package:the_chess/home/view/match_macking/match_macking_animations.dart';
 import 'package:the_chess/home/view/match_macking/match_macking_service.dart';
import 'package:the_chess/home/view/match_macking/match_not_found_screen.dart';
import 'package:the_chess/home/service/analytics_service.dart';
import 'package:the_chess/screens/game_board_screen.dart';

// Fixed Controller for matchmaking state
class MatchmakingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Reactive variables
  final _isSearching = false.obs;
  final _searchStatus = 'Ready to find opponent'.obs;
  final _isMatchFound = false.obs;
  final _isNavigating = false.obs;
  final _hasNavigatedToGame = false.obs;

  // Animation controller
  late AnimationController _animationController;

  // Subscriptions
  StreamSubscription<String>? _matchSubscription;
  StreamSubscription<void>? _timeoutSubscription;
  StreamSubscription<DocumentSnapshot>? _userQueueSubscription;
  Timer? _fallbackTimer;

  // Getters
  bool get isSearching => _isSearching.value;
  String get searchStatus => _searchStatus.value;
  bool get isMatchFound => _isMatchFound.value;
  bool get isNavigating => _isNavigating.value;
  bool get hasNavigatedToGame => _hasNavigatedToGame.value;
  AnimationController get animationController => _animationController;

  // Player count methods
  Future<int> getQueuePlayerCount() async {
    return await _matchmakingService.getQueuePlayerCount();
  }

  Future<int> getActivePlayerCount() async {
    return await _matchmakingService.getActivePlayerCount();
  }

  Future<Map<String, int>> getPlayerCounts() async {
    return await _matchmakingService.getPlayerCounts();
  }

  // Game statistics methods
  Future<int> getTodayGamesCount() async {
    try {
      final analytics = await _analyticsService.getTodayAnalytics();
      return analytics?.matchesCompleted ?? 0;
    } catch (e) {
      debugPrint('Error getting today games count: $e');
      return 0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAnimation();
    _setupMatchListener();
  }

  @override
  void onClose() {
    _animationController.dispose();
    _matchSubscription?.cancel();
    _timeoutSubscription?.cancel();
    _userQueueSubscription?.cancel();
    _fallbackTimer?.cancel();
    if (_isSearching.value) {
      _matchmakingService.leaveQueue();
    }
    super.onClose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _setupMatchListener() {
    debugPrint('Setting up match stream listener');
    _matchSubscription = _matchmakingService.matchStream.listen(
      (roomId) {
        debugPrint('Match stream received room ID: $roomId');
        if (!_isNavigating.value) {
          _handleMatchFound(roomId);
        }
      },
      onError: (error) {
        debugPrint('Match stream error: $error');
        _updateSearchStatus('Error occurred. Please try again.');
        _resetState();
      },
    );

    // Setup timeout listener
    debugPrint('Setting up timeout stream listener');
    _timeoutSubscription = _matchmakingService.timeoutStream.listen(
      (_) {
        debugPrint('Timeout event received');
        if (_isSearching.value && !_isNavigating.value) {
          handleTimeout();
        }
      },
      onError: (error) {
        debugPrint('Timeout stream error: $error');
      },
    );
  }

  void _handleMatchFound(String roomId) {
    if (roomId.isEmpty || !_isSearching.value || _isNavigating.value) {
      debugPrint(
          'Ignoring duplicate match found event - roomId: $roomId, isSearching: ${_isSearching.value}, isNavigating: ${_isNavigating.value}');
      return;
    }

    debugPrint('Processing match found: $roomId');
    _isNavigating.value = true;
    _isMatchFound.value = true;
    _updateSearchStatus('Match found! Starting animation...');

    // Cancel ongoing timers and subscriptions immediately
    _userQueueSubscription?.cancel();
    _fallbackTimer?.cancel();
    _matchSubscription
        ?.cancel(); // Also cancel main match subscription to prevent duplicates

    // Get and control animation controllers
    _startMatchFoundAnimation().then((_) {
      _navigateToChat(roomId);
    });
  }

  Future<void> _startMatchFoundAnimation() async {
    try {
      // Get controllers - use findOrNull to avoid errors if not found
      final imageController =
          Get.isRegistered<ImageSliderController>(tag: 'opponent_slider')
              ? Get.find<ImageSliderController>(tag: 'opponent_slider')
              : null;

      final vsController = Get.isRegistered<VSBattleController>()
          ? Get.find<VSBattleController>()
          : null;

      debugPrint('Starting match found animation sequence');

      // Stop image slider
      if (imageController != null) {
        imageController.stopSlideShow();
        debugPrint('Stopped image slider');
      }

      // Start VS battle animation
      if (vsController != null) {
        _updateSearchStatus('Battle animation starting...');
        vsController.restartAnimation();
        debugPrint('Started VS battle animation');

        // Wait for animation to complete
        await Future.delayed(Duration(seconds: 3));
        debugPrint('Animation sequence completed');
      } else {
        // Fallback delay if VS controller not found
        await Future.delayed(Duration(seconds: 2));
      }

      _updateSearchStatus('Entering chat room...');
    } catch (e) {
      debugPrint('Error during animation: $e');
      // Continue with navigation even if animation fails
    }
  }

  void _navigateToChat(String roomId) {
    if (_isNavigating.value) {
      debugPrint('Navigating directly to OnlineBoardGame with room: $roomId');
      _stopSearching();

      // Get the current user's display name or fallback to a default
      final user = FirebaseAuth.instance.currentUser;
      String username = 'Anonymous User'; // fallback

      if (user != null) {
        // Try display name first, then email, then fallback
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          username = user.displayName!;
        } else if (user.email != null && user.email!.isNotEmpty) {
          // Use part of email before @ as username
          username = user.email!.split('@')[0];
        } else {
          username = 'Player ${user.uid.substring(0, 6)}';
        }
      }

      debugPrint('Using username: $username');

      // Navigate directly to OnlineBoardGame instead of GameBoardScreen
      // First we need to create a chess game and get the gameId
      _createAndNavigateToOnlineGame(roomId, username);

      debugPrint('Navigation to online game initiated');
      _resetState();

      // Reset navigation flag after initiating navigation
      _isNavigating.value = false;
    } else {
      debugPrint('_navigateToChat called but _isNavigating is false');
    }
  }

  void _createAndNavigateToOnlineGame(String roomId, String username) async {
    try {
      // Set flag to indicate navigation to game
      _hasNavigatedToGame.value = true;

      // Navigate and replace the current route stack to prevent back button issues
      Get.off(() => GameBoardScreen(
        roomId: roomId,
        partnerName: username,
      ));
    } catch (e) {
      debugPrint('Error navigating to online game: $e');
      // Reset flag on error
      _hasNavigatedToGame.value = false;
      // Fallback to original navigation if there's an error
      final pageController = Get.find<MyPageController>();
      pageController.navigateToGame(roomId, username);
    }
  }

//   void _navigateToChat(String roomId) {
//   if (_isNavigating.value) {
//     debugPrint('Navigating to game screen with room: $roomId');
//     _stopSearching();

//     // Store parameters in MyPageController and navigate
//     final myPageController = Get.find<MyPageController>();
//     myPageController.navigateToGame(roomId, 'Anonymous User');

//     _isNavigating.value = false;
//   }
// }

  void startSearching() {
    if (_isSearching.value || _isNavigating.value) return;

    _resetState();
    _isSearching.value = true;
    _updateSearchStatus('Searching for opponent...');

    debugPrint('Starting search...');
    _matchmakingService.joinQueue();
    _startDirectQueueListener();
    _startFallbackTimer();
  }

  void stopSearching() {
    _stopSearching();
    // Navigate back to home screen when user stops searching
    Get.until((route) => route.isFirst);
  }

  void _stopSearching() {
    _isSearching.value = false;
    _updateSearchStatus('Search stopped');
    _userQueueSubscription?.cancel();
    _fallbackTimer?.cancel();
    _matchmakingService.leaveQueue();
  }

  void _resetState() {
    _isMatchFound.value = false;
    _isNavigating.value = false;
    _updateSearchStatus('Ready to find opponent');
  }

  // Method to reset navigation flag (can be called when returning to matchmaking)
  void resetNavigationState() {
    _hasNavigatedToGame.value = false;
    _resetState();
  }

  void _startDirectQueueListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint('Setting up direct queue listener for user: ${user.uid}');
    _userQueueSubscription = FirebaseFirestore.instance
        .collection('matchmaking_queue')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      debugPrint(
          'Queue document changed for ${user.uid} - exists: ${snapshot.exists}');

      if (!_isSearching.value) {
        debugPrint('Not searching anymore, ignoring queue update');
        return;
      }

      if (_isNavigating.value) {
        debugPrint('Already navigating, ignoring queue update');
        return;
      }

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        final roomId = data['roomId'] as String?;

        debugPrint('Direct queue listener - Status: $status, RoomId: $roomId');

        if (status == 'matched' && roomId != null && roomId.isNotEmpty) {
          debugPrint('Direct match detected! Processing room: $roomId');
          _handleMatchFound(roomId);
        }
      } else {
        debugPrint('Queue document deleted for user ${user.uid}');
      }
    }, onError: (error) {
      debugPrint('Error in direct queue listener: $error');
    });
  }

  void _startFallbackTimer() {
    _fallbackTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!_isSearching.value) {
        debugPrint('Canceling fallback timer - not searching');
        timer.cancel();
        return;
      }

      if (_isNavigating.value) {
        debugPrint('Canceling fallback timer - already navigating');
        timer.cancel();
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('matchmaking_queue')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            final roomId = data['roomId'] as String?;

            debugPrint(
                'Fallback timer check - Status: $status, RoomId: $roomId');

            if (status == 'matched' &&
                roomId != null &&
                roomId.isNotEmpty &&
                !_isNavigating.value) {
              debugPrint(
                  'Fallback timer found match! Processing room: $roomId');
              timer.cancel();
              _handleMatchFound(roomId);
            }
          } else {
            debugPrint('Fallback timer - queue document does not exist');
          }
        } catch (e) {
          debugPrint('Fallback timer check error: $e');
        }
      }
    });
  }

  void _updateSearchStatus(String status) {
    _searchStatus.value = status;
    debugPrint('Status updated: $status');
  }

  // Handle timeout when no match is found within 1 minute
  void handleTimeout() {
    debugPrint('Handling matchmaking timeout in controller');
    _isNavigating.value = true;
    _stopSearching();

    // Navigate to match not found screen
    Get.to(() => const MatchNotFoundScreen())?.then((_) {
      // Reset state when returning from match not found screen
      _resetState();
    });
  }
}

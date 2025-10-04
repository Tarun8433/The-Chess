import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/home/controller/matchmaking_controller.dart';
import 'package:the_chess/home/view/match_macking/match_macking_service.dart';

/// Example usage of the player count functionality
/// This demonstrates how to get the number of players in queue and active players
class PlayerCountExample {
  
  /// Method 1: Using MatchmakingController (recommended for UI)
  static Future<void> getPlayerCountsViaController() async {
    // Get the controller instance
    final controller = Get.find<MatchmakingController>();
    
    // Get individual counts
    final queueCount = await controller.getQueuePlayerCount();
    final activeCount = await controller.getActivePlayerCount();
    
    debugPrint('Players in queue: $queueCount');
    debugPrint('Active players: $activeCount');
    
    // Get both counts at once (more efficient)
    final counts = await controller.getPlayerCounts();
    debugPrint('Queue: ${counts['queue']}, Active: ${counts['active']}');
  }
  
  /// Method 2: Using MatchmakingService directly
  static Future<void> getPlayerCountsViaService() async {
    final service = MatchmakingService();
    
    // Get individual counts
    final queueCount = await service.getQueuePlayerCount();
    final activeCount = await service.getActivePlayerCount();
    
    debugPrint('Players in queue: $queueCount');
    debugPrint('Active players: $activeCount');
    
    // Get both counts at once
    final counts = await service.getPlayerCounts();
    debugPrint('Queue: ${counts['queue']}, Active: ${counts['active']}');
  }
  
  /// Example widget that displays player counts
  static Widget buildPlayerCountWidget() {
    return FutureBuilder<Map<String, int>>(
      future: Get.find<MatchmakingController>().getPlayerCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        final counts = snapshot.data ?? {'queue': 0, 'active': 0};
        
        return Column(
          children: [
            Text('Players in Queue: ${counts['queue']}'),
            Text('Active Players: ${counts['active']}'),
            Text('Total Online: ${(counts['queue'] ?? 0) + (counts['active'] ?? 0)}'),
          ],
        );
      },
    );
  }
}

/// Usage examples:
/// 
/// 1. In a StatefulWidget:
/// ```dart
/// void _loadPlayerCounts() async {
///   final counts = await Get.find<MatchmakingController>().getPlayerCounts();
///   setState(() {
///     queueCount = counts['queue'] ?? 0;
///     activeCount = counts['active'] ?? 0;
///   });
/// }
/// ```
/// 
/// 2. In a GetX controller:
/// ```dart
/// final queueCount = 0.obs;
/// final activeCount = 0.obs;
/// 
/// void updatePlayerCounts() async {
///   final counts = await _matchmakingService.getPlayerCounts();
///   queueCount.value = counts['queue'] ?? 0;
///   activeCount.value = counts['active'] ?? 0;
/// }
/// ```
/// 
/// 3. Real-time updates with Stream:
/// ```dart
/// Stream<Map<String, int>> playerCountStream() async* {
///   while (true) {
///     yield await getPlayerCounts();
///     await Future.delayed(Duration(seconds: 5));
///   }
/// }
/// ```
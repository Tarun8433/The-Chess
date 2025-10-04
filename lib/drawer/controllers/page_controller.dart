import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:the_chess/routs.dart';

 
class MyPageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  
  RxString pageController = Routes.HOME.obs;
  RxBool isOpen = false.obs;
  
  // Add navigation parameters
  String? currentRoomId;
  String? currentPartnerName;
  
  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      value: -1.0,
    );
  }

  // Method to navigate to game with parameters
  void navigateToGame(String roomId, String partnerName) {
    debugPrint('MyPageController.navigateToGame called with roomId: $roomId, partnerName: $partnerName');
    currentRoomId = roomId;
    currentPartnerName = partnerName;
    debugPrint('Setting pageController.value to Routes.GAME: ${Routes.GAME}');
    pageController.value = Routes.GAME;
    debugPrint('pageController.value is now: ${pageController.value}');
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}

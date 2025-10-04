import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/drawer/animation/animation.dart';
import 'package:the_chess/drawer/controllers/page_controller.dart';
import 'package:the_chess/drawer/screen/zoom_drawer.dart';
import 'package:the_chess/screens/game_board_screen.dart';
import 'package:the_chess/routs.dart';
import 'package:the_chess/values/colors.dart';

Widget pageChange(MyPageController controller) {
  debugPrint(
      'pageChange called with pageController.value: ${controller.pageController.value}');
  switch (controller.pageController.value) {
    case Routes.GAME:
      debugPrint(
          'Routes.GAME case matched! roomId: ${controller.currentRoomId}, partnerName: ${controller.currentPartnerName}');
      // Use the stored parameters
      if (controller.currentRoomId != null &&
          controller.currentPartnerName != null) {
        debugPrint('Returning ZoomDrawerD with parameters');
        return ZoomDrawerD(
          roomId: controller.currentRoomId!,
          partnerName: controller.currentPartnerName!,
        );
      }
      debugPrint(
          'Returning ZoomDrawerD without parameters (parameters are null)');
      return ZoomDrawerD();
    default:
      debugPrint('Default case matched, returning Container');
      if (controller.currentRoomId != null &&
          controller.currentPartnerName != null) {
        return GameBoardScreen(
          roomId: controller.currentRoomId!,
          partnerName: controller.currentPartnerName!,
        );
      } else {
        return Scaffold(
          appBar: AppBar(
            title: Text('Game'),
            leading: GestureDetector(
              onTap: () {
                if (MyAnimation.z.open != null) {
                  MyAnimation.z.open!();
                }
              },
              child: const Icon(
                Icons.menu,
                color: MyColors.white,
                size: 24,
              ),
            ),
          ),
          body: Center(
            child: Text("No Game Found"),
          ),
        );
      }
  }
}

class GameScreen extends StatelessWidget {
  final String roomId;
  final String partnerName;

  const GameScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerD(
      roomId: roomId,
      partnerName: partnerName,
    );
  }
}

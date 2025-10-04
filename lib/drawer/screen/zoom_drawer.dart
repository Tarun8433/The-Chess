 
import 'package:flutter/material.dart';
 import 'package:get/get.dart';
import 'package:the_chess/drawer/animation/animation.dart';
import 'package:the_chess/drawer/controllers/page_controller.dart';
import 'package:the_chess/drawer/helper/drawer.dart';
import 'package:the_chess/drawer/routes/routs.dart';
import 'package:the_chess/values/colors.dart';
import 'package:the_chess/widgets/chat_drawer_widget.dart';

class ZoomDrawerD extends GetView<MyPageController> {
  final String? roomId;
  final String? partnerName;
  
    ZoomDrawerD({
    super.key,
    this.roomId,
    this.partnerName,
  }) {
    debugPrint('ZoomDrawerD constructor called with roomId: $roomId, partnerName: $partnerName');
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      borderRadius: 16,
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.5),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
      style: DrawerStyle.defaultStyle, // Classic style for mobile
      showShadow: true,
      openCurve: Curves.fastOutSlowIn,
      closeCurve: Curves.fastOutSlowIn,
      slideWidth: Get.width,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 450),
      angle: 0,
      mainScreenScale: Get.width,
      shadowLayer1Color: Colors.white.withValues(alpha: .0),
      shadowLayer2Color: MyColors.lightGray.withValues(alpha: .0),
      menuBackgroundColor: MyColors.background,
      moveMenuScreen: true,

      slideHeight: 0,
      menuScreenWidth: Get.width, //* .7,
      dragOffset: 60.0,
      alwaysVisible: false, // Traditional drawer behavior
      enableInteraction: true, // Allow interaction when open
      responsiveBreakpoint: 768,
      mainScreenAbsorbPointer: false, // Allow interaction with main screen
      mainScreenTapClose: true, // Close on tap for mobile
      controller: MyAnimation.z as ZoomDrawerController?,
      mainScreen:   Body(),
      menuScreen: roomId != null && partnerName != null
          ? ChatDrawerWidget(
              roomId: roomId!,
              partnerName: partnerName!,
            )
          : const SizedBox(),
      disableDragGesture: true, // Disable gestures for tablet
    );
  }
}

class Body extends GetView<MyPageController> {
    Body({
    super.key,
  }) {
    debugPrint('Body widget constructor called');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () {
          debugPrint('Obx triggered - pageController.value: ${controller.pageController.value}');
          return pageChange(controller);
        },
      ),
    );
  }
}

void showLogoutDialogBoX(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Logout?"),
      content: const Text("Are you sure you want to logout?"),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // await LocalStorage.removePre();
            // Get.offAllNamed(Routes.LOGIN);
            // LocalStorage.putBool(isSeenOnboarding, true);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class Drawer extends StatelessWidget {
  const Drawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30),
            child: InkWell(
              onTap: () {
                MyAnimation.z.close!();
                showLogoutDialogBoX(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Logout",
                    style: const TextStyle(
                      fontSize: 18,
                      color: MyColors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.logout,
                    size: 20,
                    color: MyColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: MyColors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helper/drawer.dart';

class MyAnimation {
  static final ZoomDrawerController z = ZoomDrawerController();
  static const double headerHeight = 32.0;

  static Animation<RelativeRect> getPanelAnimation(context, controller) {
    final height = Get.height;
    final backPanelHeight = height - MyAnimation.headerHeight;
    const frontPanelHeight = -MyAnimation.headerHeight;

    return RelativeRectTween(
      begin: RelativeRect.fromLTRB(
        0.0,
        backPanelHeight,
        0.0,
        frontPanelHeight,
      ),
      end: const RelativeRect.fromLTRB(0.0, 80, 0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }
}

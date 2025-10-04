import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/home/view/match_macking/match_macking_animations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:the_chess/home/view/splash_screen.dart';
import 'package:the_chess/services/theme_service.dart';
import 'package:the_chess/values/app_theme.dart';
import 'package:the_chess/drawer/controllers/page_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize controllers
  Get.put(VSBattleController());
  Get.put(ImageSliderController());
  Get.put(MyPageController());
  // Initialize theme service
  Get.put(ThemeService());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {


    return GetMaterialApp(
      
      title: 'Pixel Pawn',
      debugShowCheckedModeBanner: false,
      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Get.find<ThemeService>().themeMode,
      // App Configuration
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      home: SplashScreen(),
    );
  }
}

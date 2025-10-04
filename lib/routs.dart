import 'package:get/get.dart';
import 'package:the_chess/drawer/screen/zoom_drawer.dart';
import 'package:the_chess/home/view/splash_screen.dart';

class Routes {
  // COMMON MODULE
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const DASHBOARD = '/zoom_drawer';

  static const String GAME = '/game';
  static final routes = [
    GetPage(
      name: SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: HOME,
      page: () =>   ZoomDrawerD(),
    ),
    GetPage(
      name: DASHBOARD,
      page: () =>   ZoomDrawerD(),
    ),
  ];
}

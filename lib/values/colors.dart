import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF2a3f5f);
  static const Color lightPrimaryVariant = Color(0xFF1a2f4f);
  static const Color lightSecondary = Color(0xFFffa500);
  static const Color lightSecondaryVariant = Color(0xFFe69500);
  static const Color lightBackground = Color(0xFFf5f5f5);
  static const Color lightSurface = Color(0xFFffffff);
  static const Color lightError = Color(0xFFd32f2f);
  static const Color lightOnPrimary = Color(0xFFffffff);
  static const Color lightOnSecondary = Color(0xFF000000);
  static const Color lightOnBackground = Color(0xFF000000);
  static const Color lightOnSurface = Color(0xFF000000);
  static const Color lightOnError = Color(0xFFffffff);

  // Chess Board Light Colors
  static const Color lightSquareLight = Color(0xFFf0d9b5);
  static const Color lightSquareDark = Color(0xFFb58863);
  static const Color lightBoardBorder = Color(0xFF8b7355);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF155058);
  static const Color darkPrimaryVariant = Color(0xFF0d3d42);

  static const Color darkBackground = Color(0xFF0d0d0d);
  static const Color darkSurface = Color(0xFF1a1a2e);
  static const Color darkError = Color(0xFFcf6679);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFffffff);
  static const Color darkOnSurface = Color(0xFFffffff);
  static const Color darkOnError = Color(0xFF000000);

  // Chess Board Dark Colors
  static const Color darkSquareLight = Color(0xFF3c3c3c);
  static const Color darkSquareDark = Color(0xFF2a2a2a);
  static const Color darkBoardBorder = Color(0xFF555555);
}

// // Legacy MyColors class for backward compatibility
// @Deprecated('Use AppColors instead')
class MyColors {
  static const Color lightGray = AppColors.darkPrimary;
  static const Color lightGraydark = Color.fromARGB(255, 9, 49, 54);
  static const Color white = Color.fromARGB(255, 255, 255, 255);
  static const Color mediumGray = Color(0xFF8AA5AB);
  static const Color tealGray = Color(0xFF51797F);
  static const Color darkBackground = AppColors.darkBackground;
  static const Color cardBackground = const Color(0xFF404040);
  static const Color amber = Colors.amber;
  static const Color transparent = Colors.transparent;
  static const Color orange = Colors.orange;
  static const Color cyan = Colors.cyan;
  static const Color red = Color(0xFFFF0000);
  static const Color historyBackground = AppColors.darkSurface;
  static const Color background = AppColors.darkSurface;
  static const Color primary = AppColors.lightPrimary;
  static const Color accent = AppColors.lightSecondary;
}

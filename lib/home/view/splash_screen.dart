import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/home/view/auth/auth_screen.dart';
import 'package:the_chess/values/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(Duration(seconds: 3), () {
      Get.offAll(() => AuthWrapper());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Get.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyColors.lightGray,
              MyColors.lightGray,
              MyColors.tealGray,
              MyColors.mediumGray,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo and Title
                Column(
                  children: [
                    Container(
                        width: 350,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child:
                            Image.asset("assets/images/Pixel-Pawn-Logo.png")),
                    Text(
                      'Play • Compete',
                      style: TextStyle(
                        fontSize: 18,
                        color: MyColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

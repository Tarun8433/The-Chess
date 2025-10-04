import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/values/colors.dart';

class MatchNotFoundScreen extends StatelessWidget {
  const MatchNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.3, -0.7),
            radius: 1.2,
            colors: [
              MyColors.lightGray.withValues(alpha: 0.15),
              MyColors.darkBackground,
              MyColors.cardBackground,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: CirclePatternPainter(),
              ),
            ),

            // Chess board pattern overlay
            Positioned(
              top: 100,
              right: -50,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: MyColors.lightGray.withValues(alpha: 0.05),
                  ),
                  child: CustomPaint(
                    painter: ChessPatternPainter(),
                  ),
                ),
              ),
            ),

            // Floating geometric shapes
            Positioned(
              top: 200,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      MyColors.tealGray.withValues(alpha: 0.1),
                      MyColors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 150,
              right: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      MyColors.lightGray.withValues(alpha: 0.1),
                      MyColors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated search icon with gradient background
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            MyColors.lightGray.withValues(alpha: 0.3),
                            MyColors.tealGray.withValues(alpha: 0.1),
                            MyColors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: MyColors.lightGray.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MyColors.lightGray.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing background circle
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MyColors.lightGray.withValues(alpha: 0.1),
                            ),
                          ),
                          const Icon(
                            Icons.search_off,
                            size: 65,
                            color: MyColors.lightGray,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Title with gradient text effect
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          MyColors.white,
                          MyColors.mediumGray,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'No Match Found',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: MyColors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Text(
                        'We couldn\'t find an opponent within the time limit.\nTry searching again or check your connection.',
                        style: TextStyle(
                          fontSize: 16,
                          color: MyColors.mediumGray,
                          height: 1.6,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Try Again Button with gradient
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MyColors.lightGray,
                            MyColors.tealGray,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: MyColors.lightGray.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.transparent,
                          shadowColor: MyColors.transparent,
                          foregroundColor: MyColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Back to Home Button
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          width: 2,
                          color: MyColors.tealGray.withValues(alpha: 0.6),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            MyColors.cardBackground.withValues(alpha: 0.5),
                            MyColors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          Get.until((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: MyColors.transparent,
                          foregroundColor: MyColors.mediumGray,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Enhanced Tips section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MyColors.cardBackground.withValues(alpha: 0.8),
                            MyColors.lightGray.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: MyColors.tealGray.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                MyColors.darkBackground.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      MyColors.lightGray.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: MyColors.lightGray,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Tips for better matchmaking:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MyColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '• Try searching during peak hours\n• Check your internet connection\n• Make sure you have the latest app version',
                            style: TextStyle(
                              fontSize: 14,
                              color: MyColors.mediumGray,
                              height: 1.6,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for circle patterns
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MyColors.lightGray.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final double radius = (i * 30).toDouble();
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }

    for (int i = 0; i < 15; i++) {
      final double radius = (i * 25).toDouble();
      canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.7),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for chess pattern
class ChessPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = MyColors.tealGray.withValues(alpha: 0.1);

    const int squares = 8;
    final double squareSize = size.width / squares;

    for (int row = 0; row < squares; row++) {
      for (int col = 0; col < squares; col++) {
        if ((row + col) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * squareSize,
              row * squareSize,
              squareSize,
              squareSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

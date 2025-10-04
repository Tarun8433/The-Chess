import 'package:flutter/material.dart';
import 'package:the_chess/values/colors.dart';

class BackgroundColor extends StatelessWidget {
  final Widget child;
  const BackgroundColor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.3, -0.7),
          radius: 1.2,
          colors: [
            MyColors.lightGraydark.withValues(alpha: 0.15),
            MyColors.darkBackground,
            MyColors.lightGraydark,
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
          child
        ],
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

import 'package:the_chess/components/pieces.dart';
import 'package:flutter/material.dart';
import 'package:the_chess/values/app_theme.dart';
import 'package:the_chess/values/colors.dart';

class Square extends StatelessWidget {
  final void Function()? onTap;
  final bool isValidMove;
  final bool isWhite;
  final ChessPiece? piece;
  final bool isSelected;
  final bool isKingInCheck;
  final Color boardBColor;
  final Color boardWColor;
  final int row;
  final int col;

  const Square({
    super.key,
    required this.onTap,
    required this.isValidMove,
    required this.isWhite,
    required this.piece,
    required this.isSelected,
    this.isKingInCheck = false,
    required this.boardBColor,
    required this.boardWColor,
    required this.row,
    required this.col,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? squareColor;

    // Determine square color based on state and theme
    if (isKingInCheck) {
      squareColor = theme.colorScheme.error.withValues(alpha: 0.8);
    } else if (isSelected) {
      squareColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    } else {
      // Use chess theme extension if available, otherwise fallback to provided colors
      try {
        squareColor = isWhite ? MyColors.mediumGray : MyColors.tealGray;
      } catch (e) {
        // Fallback to provided colors if theme extension is not available
        squareColor = isWhite ? boardWColor : boardBColor;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Display piece
            if (piece != null)
              Image.asset(
                piece!.imagePath,
                fit: BoxFit.contain,
              ),

            // Display valid move indicator
            if (isValidMove)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),

            // Display coordinates on edge squares
            if (col == 0)
              Positioned(
                top: 2,
                left: 2,
                child: Text(
                  '${8 - row}',
                  style: TextStyle(
                    color: isWhite
                        ? squareColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white70
                        : squareColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (row == 7)
              Positioned(
                bottom: 2,
                right: 2,
                child: Text(
                  String.fromCharCode('a'.codeUnitAt(0) + col),
                  style: TextStyle(
                    color: isWhite
                        ? squareColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white70
                        : squareColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

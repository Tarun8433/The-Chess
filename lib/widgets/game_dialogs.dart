import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/pieces.dart';
import '../home/view/home_screen.dart';
import '../values/colors.dart';

class GameDialogs {
  static bool _dialogShown = false;

  /// Reset dialog state (call when starting a new game)
  static void reset() {
    _dialogShown = false;
  }

  /// Show game end dialog (victory, defeat, draw, timeout)
  static void showGameEndDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    String? gameId,
    VoidCallback? onReviewGame,
  }) {
    // Prevent showing multiple dialogs
    if (_dialogShown) {
      debugPrint('⚠️ Game end dialog already shown, skipping');
      return;
    }

    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.orbitron(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: GoogleFonts.orbitron(
              color: MyColors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => ChessAppUI()),
                  (route) => false,
                );
              },
              child: Text(
                'Back to Menu',
                style: GoogleFonts.orbitron(
                  color: MyColors.lightGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show pawn promotion dialog
  static Future<ChessPiecesType?> showPromotionDialog(
    BuildContext context, {
    required bool isWhite,
  }) async {
    return await showDialog<ChessPiecesType>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Promote Pawn',
            style: GoogleFonts.orbitron(
              color: MyColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: Wrap(
            children: [
              _buildPromotionOption(context, ChessPiecesType.queen, isWhite),
              _buildPromotionOption(context, ChessPiecesType.rook, isWhite),
              _buildPromotionOption(context, ChessPiecesType.bishop, isWhite),
              _buildPromotionOption(context, ChessPiecesType.knight, isWhite),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildPromotionOption(
    BuildContext context,
    ChessPiecesType type,
    bool isWhite,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(type),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkOnBackground.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.darkOnBackground, width: 2),
          ),
          child: Image.asset(
            getPromotionImagePath(type, isWhite),
            width: 50,
            height: 50,
          ),
        ),
      ),
    );
  }

  /// Show resignation confirmation dialog
  static Future<bool?> showResignConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Resign Game?',
            style: GoogleFonts.orbitron(
              color: MyColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to resign? This will count as a loss.',
            style: GoogleFonts.orbitron(
              color: MyColors.lightGray,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.orbitron(
                  color: MyColors.lightGray,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Resign',
                style: GoogleFonts.orbitron(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.orbitron(
              color: MyColors.white,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.orbitron(
                  color: MyColors.lightGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String getPromotionImagePath(ChessPiecesType type, bool isWhite) {
  String color = isWhite ? 'white' : 'black';
  switch (type) {
    case ChessPiecesType.queen:
      return 'assets/images/figures/$color/queen.png';
    case ChessPiecesType.rook:
      return 'assets/images/figures/$color/rook.png';
    case ChessPiecesType.bishop:
      return 'assets/images/figures/$color/bishop.png';
    case ChessPiecesType.knight:
      return 'assets/images/figures/$color/knight.png';
    default:
      return 'assets/images/figures/$color/queen.png';
  }
}

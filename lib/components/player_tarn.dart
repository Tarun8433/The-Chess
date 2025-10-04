// Add this widget to your chess game file or create a separate file

import 'package:flutter/material.dart';

class PlayerTurnIndicator extends StatelessWidget {
  final bool isWhiteTurn;
  final bool gameEnded;
  final bool checkStatus;

  const PlayerTurnIndicator({
    super.key,
    required this.isWhiteTurn,
    this.gameEnded = false,
    this.checkStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWhiteTurn
              ? [Colors.grey[100]!, Colors.white]
              : [Colors.grey[800]!, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checkStatus
              ? Colors.red
              : (isWhiteTurn ? Colors.grey[300]! : Colors.grey[600]!),
          width: checkStatus ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: gameEnded ? _buildGameEndedWidget() : _buildCurrentTurnWidget(),
    );
  }

  Widget _buildCurrentTurnWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player piece icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWhiteTurn ? Colors.white : Colors.black,
            border: Border.all(
              color: isWhiteTurn ? Colors.black : Colors.white,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.chair,
            color: isWhiteTurn ? Colors.black : Colors.white,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        // Turn text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              checkStatus ? "CHECK!" : "Current Turn",
              style: TextStyle(
                color: isWhiteTurn ? Colors.grey[600] : Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isWhiteTurn ? "WHITE PLAYER" : "BLACK PLAYER",
              style: TextStyle(
                color: isWhiteTurn ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: checkStatus
                ? Colors.red.withValues(alpha: 0.1)
                : (isWhiteTurn
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: checkStatus
                  ? Colors.red
                  : (isWhiteTurn ? Colors.black26 : Colors.white24),
            ),
          ),
          child: Text(
            checkStatus ? "IN CHECK" : "TO MOVE",
            style: TextStyle(
              color: checkStatus
                  ? Colors.red
                  : (isWhiteTurn ? Colors.black54 : Colors.white70),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameEndedWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.flag,
          color: Colors.grey[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          "GAME ENDED",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

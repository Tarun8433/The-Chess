import 'package:flutter/material.dart';
import '../services/chess_timer.dart';

class ChessTimerWidget extends StatelessWidget {
  final TimerState timerState;
  final String whitePlayerName;
  final String blackPlayerName;
  final bool isLocalPlayerWhite;

  const ChessTimerWidget({
    super.key,
    required this.timerState,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.isLocalPlayerWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // White player timer
          Expanded(
            child: buildPlayerTimer(
              playerName: whitePlayerName,
              timeRemaining: timerState.whiteTimeFormatted,
              isActive: timerState.isWhiteTurn && timerState.isGameActive,
              isInDanger: timerState.isWhiteInDanger,
              isLocalPlayer: isLocalPlayerWhite,
            ),
          ),

          // Game variant and status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timerState.variant.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Move ${timerState.moveCount + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (!timerState.isGameActive) ...[
                  SizedBox(height: 4),
                  Icon(
                    Icons.pause,
                    size: 16,
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),

          // Black player timer
          Expanded(
            child: buildPlayerTimer(
              playerName: blackPlayerName,
              timeRemaining: timerState.blackTimeFormatted,
              isActive: !timerState.isWhiteTurn && timerState.isGameActive,
              isInDanger: timerState.isBlackInDanger,
              isLocalPlayer: !isLocalPlayerWhite,
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildPlayerTimer({
  required String playerName,
  required String timeRemaining,
  required bool isActive,
  required bool isInDanger,
  required bool isLocalPlayer,
}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    decoration: BoxDecoration(
      color: getTimerBackgroundColor(isActive, isInDanger, isLocalPlayer),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: getTimerBorderColor(isActive, isInDanger, isLocalPlayer),
        width: isActive ? 2 : 1,
      ),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: getTimerBorderColor(isActive, isInDanger, isLocalPlayer)
                    .withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player name
        // Text(
        //   playerName,
        //   style: TextStyle(
        //     fontSize: 14,
        //     fontWeight: isLocalPlayer ? FontWeight.bold : FontWeight.w500,
        //     color: getTextColor(isActive, isInDanger),
        //   ),
        //   maxLines: 1,
        //   overflow: TextOverflow.ellipsis,
        // ),

        // SizedBox(height: 4),

        // Time display
        Text(
          timeRemaining,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: getTextColor(isActive, isInDanger),
          ),
        ),

        // // Active indicator
        // if (isActive) ...[
        //   SizedBox(height: 4),
        //   Container(
        //     width: 8,
        //     height: 8,
        //     decoration: BoxDecoration(
        //       color: isInDanger ? Colors.red : Colors.green,
        //       shape: BoxShape.circle,
        //     ),
        //   ),
        // ],

        // // Local player indicator
        // if (isLocalPlayer) ...[
        //   SizedBox(height: 4),
        //   Text(
        //     'YOU',
        //     style: TextStyle(
        //       fontSize: 10,
        //       fontWeight: FontWeight.bold,
        //       color: Colors.blue[700],
        //     ),
        //   ),
        // ],
      ],
    ),
  );
}

Color getTimerBackgroundColor(
    bool isActive, bool isInDanger, bool isLocalPlayer) {
  if (isInDanger && isActive) {
    return Colors.red[50]!;
  }
  if (isActive) {
    return Colors.green[50]!;
  }
  if (isLocalPlayer) {
    return Colors.blue[50]!;
  }
  return Colors.grey[100]!;
}

Color getTimerBorderColor(bool isActive, bool isInDanger, bool isLocalPlayer) {
  if (isInDanger && isActive) {
    return Colors.red;
  }
  if (isActive) {
    return Colors.green;
  }
  if (isLocalPlayer) {
    return Colors.blue;
  }
  return Colors.grey[400]!;
}

Color getTextColor(bool isActive, bool isInDanger) {
  if (isInDanger && isActive) {
    return Colors.red[800]!;
  }
  if (isActive) {
    return Colors.green[800]!;
  }
  return Colors.grey[800]!;
}

class CompactChessTimerWidget extends StatelessWidget {
  final TimerState timerState;
  final bool isLocalPlayerWhite;

  const CompactChessTimerWidget({
    super.key,
    required this.timerState,
    required this.isLocalPlayerWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White timer
          _buildCompactTimer(
            time: timerState.whiteTimeFormatted,
            isActive: timerState.isWhiteTurn && timerState.isGameActive,
            isInDanger: timerState.isWhiteInDanger,
            isWhite: true,
          ),

          SizedBox(width: 8),

          // Variant
          Text(
            timerState.variant.displayName,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(width: 8),

          // Black timer
          _buildCompactTimer(
            time: timerState.blackTimeFormatted,
            isActive: !timerState.isWhiteTurn && timerState.isGameActive,
            isInDanger: timerState.isBlackInDanger,
            isWhite: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimer({
    required String time,
    required bool isActive,
    required bool isInDanger,
    required bool isWhite,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? (isInDanger ? Colors.red[100] : Colors.green[100])
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? (isInDanger ? Colors.red : Colors.green)
              : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isWhite ? Colors.white : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[400]!),
            ),
          ),

          SizedBox(width: 4),

          // Time
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isActive
                  ? (isInDanger ? Colors.red[800] : Colors.green[800])
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// File: lib/components/timer_widget.dart
import 'package:flutter/material.dart';
import 'chess_timer.dart';

class TimerWidget extends StatelessWidget {
  final Duration time;
  final bool isActive;
  final bool isWhite;
  final VoidCallback? onTap;
  final bool isTimeRunningOut; // When time < 30 seconds

  const TimerWidget({
    super.key,
    required this.time,
    required this.isActive,
    required this.isWhite,
    this.onTap,
    this.isTimeRunningOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;

    if (isTimeRunningOut && isActive) {
      backgroundColor = theme.colorScheme.error;
      textColor = theme.colorScheme.onError;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else {
      backgroundColor = isWhite 
          ? theme.colorScheme.surfaceContainerHighest 
          : theme.colorScheme.surfaceContainerHigh;
      textColor = theme.colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isActive
              ? Border.all(color: theme.colorScheme.outline, width: 1)
              : Border.all(color: theme.colorScheme.outlineVariant, width: 1),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.26),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ChessTimer.formatTime(time),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChessTimerDisplayForBlack extends StatelessWidget {
  final ChessTimer chessTimer;
  final Duration whiteTime;
  final Duration blackTime;

  const ChessTimerDisplayForBlack({
    super.key,
    required this.chessTimer,
    required this.whiteTime,
    required this.blackTime,
  });

  @override
  Widget build(BuildContext context) {
    return TimerWidget(
      time: blackTime,
      isActive: !chessTimer.isWhiteTurn && chessTimer.isRunning,
      isWhite: false,
      isTimeRunningOut: blackTime.inSeconds < 30,
    );
  }
}

class ChessTimerDisplayForWhite extends StatelessWidget {
  final ChessTimer chessTimer;
  final Duration whiteTime;
  final Duration blackTime;

  const ChessTimerDisplayForWhite({
    super.key,
    required this.chessTimer,
    required this.whiteTime,
    required this.blackTime,
  });

  @override
  Widget build(BuildContext context) {
    return TimerWidget(
      time: whiteTime,
      isActive: chessTimer.isWhiteTurn && chessTimer.isRunning,
      isWhite: true,
      isTimeRunningOut: whiteTime.inSeconds < 30,
    );
  }
}

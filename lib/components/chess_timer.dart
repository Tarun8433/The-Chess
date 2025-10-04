// File: lib/components/chess_timer.dart - CORRECTED VERSION
import 'dart:async';

enum TimerState { stopped, running, paused }

class ChessTimer {
  // Timer configurations
  final Duration initialTime;
  final Duration increment; // Time added after each move

  // Current state
  Duration _whiteTime;
  Duration _blackTime;
  bool _isWhiteTurn;
  TimerState _state;

  // Timer instances
  Timer? _timer;

  // Track when turn started to calculate time used
  DateTime? _turnStartTime;

  // Callbacks
  Function(Duration whiteTime, Duration blackTime)? onTimeUpdate;
  Function(bool isWhiteWinner)? onTimeUp;
  Function()? onTimerStart;
  Function()? onTimerPause;

  ChessTimer({
    required this.initialTime,
    this.increment = Duration.zero,
    this.onTimeUpdate,
    this.onTimeUp,
    this.onTimerStart,
    this.onTimerPause,
  })  : _whiteTime = initialTime,
        _blackTime = initialTime,
        _isWhiteTurn = true,
        _state = TimerState.stopped;

  // Getters
  Duration get whiteTime => _whiteTime;
  Duration get blackTime => _blackTime;
  bool get isWhiteTurn => _isWhiteTurn;
  TimerState get state => _state;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isStopped => _state == TimerState.stopped;

  // Start the timer
  void startTimer() {
    if (_state == TimerState.running) return;

    _state = TimerState.running;
    _turnStartTime = DateTime.now(); // Record when current turn started
    onTimerStart?.call();

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _updateTime();
    });
  }

  // Pause the timer
  void pauseTimer() {
    if (_state != TimerState.running) return;

    // Save the time used during current turn before pausing
    if (_turnStartTime != null) {
      Duration timeUsedThisTurn = DateTime.now().difference(_turnStartTime!);
      if (_isWhiteTurn) {
        _whiteTime -= timeUsedThisTurn;
        if (_whiteTime < Duration.zero) _whiteTime = Duration.zero;
      } else {
        _blackTime -= timeUsedThisTurn;
        if (_blackTime < Duration.zero) _blackTime = Duration.zero;
      }
      _turnStartTime = null;
    }

    _state = TimerState.paused;
    _timer?.cancel();
    onTimerPause?.call();
    onTimeUpdate?.call(_whiteTime, _blackTime);
  }

  // Resume the timer
  void resumeTimer() {
    if (_state != TimerState.paused) return;
    _turnStartTime = DateTime.now(); // Reset turn start time
    startTimer();
  }

  // Stop and reset the timer
  void stopTimer() {
    _timer?.cancel();
    _state = TimerState.stopped;
    _whiteTime = initialTime;
    _blackTime = initialTime;
    _isWhiteTurn = true;
    _turnStartTime = null;
    onTimeUpdate?.call(_whiteTime, _blackTime);
  }

  // Switch turns (called when a move is made)
  void switchTurn() {
    if (_state != TimerState.running || _turnStartTime == null) return;

    // Calculate time used during this turn
    Duration timeUsedThisTurn = DateTime.now().difference(_turnStartTime!);

    // Subtract time used and add increment to the player who just moved
    if (_isWhiteTurn) {
      _whiteTime -= timeUsedThisTurn;
      _whiteTime += increment; // Add increment bonus

      // Check if white ran out of time
      if (_whiteTime <= Duration.zero) {
        _whiteTime = Duration.zero;
        _handleTimeUp(false); // White lost
        return;
      }
    } else {
      _blackTime -= timeUsedThisTurn;
      _blackTime += increment; // Add increment bonus

      // Check if black ran out of time
      if (_blackTime <= Duration.zero) {
        _blackTime = Duration.zero;
        _handleTimeUp(true); // Black lost, white wins
        return;
      }
    }

    // Switch to the other player and record new turn start time
    _isWhiteTurn = !_isWhiteTurn;
    _turnStartTime = DateTime.now();

    onTimeUpdate?.call(_whiteTime, _blackTime);
  }

  // Update time for display (shows real-time countdown)
  void _updateTime() {
    if (_turnStartTime == null) return;

    Duration timeUsedThisTurn = DateTime.now().difference(_turnStartTime!);
    Duration currentPlayerTime;

    if (_isWhiteTurn) {
      currentPlayerTime = _whiteTime - timeUsedThisTurn;
      if (currentPlayerTime <= Duration.zero) {
        currentPlayerTime = Duration.zero;
        _handleTimeUp(false); // White lost
        return;
      }
    } else {
      currentPlayerTime = _blackTime - timeUsedThisTurn;
      if (currentPlayerTime <= Duration.zero) {
        currentPlayerTime = Duration.zero;
        _handleTimeUp(true); // Black lost, white wins
        return;
      }
    }

    // Update display with real-time countdown
    if (_isWhiteTurn) {
      onTimeUpdate?.call(currentPlayerTime, _blackTime);
    } else {
      onTimeUpdate?.call(_whiteTime, currentPlayerTime);
    }
  }

  // Handle when time runs out
  void _handleTimeUp(bool isWhiteWinner) {
    _timer?.cancel();
    _state = TimerState.stopped;
    _turnStartTime = null;

    // Update final times
    if (isWhiteWinner) {
      _blackTime = Duration.zero;
    } else {
      _whiteTime = Duration.zero;
    }

    onTimeUpdate?.call(_whiteTime, _blackTime);
    onTimeUp?.call(isWhiteWinner);
  }

  // Reset to initial state
  void reset() {
    stopTimer();
  }

  // Get current displayed time for active player (real-time)
  Duration getCurrentPlayerDisplayTime() {
    if (_state != TimerState.running || _turnStartTime == null) {
      return _isWhiteTurn ? _whiteTime : _blackTime;
    }

    Duration timeUsedThisTurn = DateTime.now().difference(_turnStartTime!);
    Duration currentTime = _isWhiteTurn ? _whiteTime : _blackTime;
    Duration remainingTime = currentTime - timeUsedThisTurn;

    return remainingTime < Duration.zero ? Duration.zero : remainingTime;
  }

  // Dispose resources
  void dispose() {
    _timer?.cancel();
  }

  // Format duration for display
  static String formatTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    int milliseconds = duration.inMilliseconds % 1000;

    if (duration.inMinutes >= 1) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds.toString().padLeft(2, '0')}.${(milliseconds ~/ 100).toString()}';
    }
  }

  // Preset timer configurations
  static ChessTimer blitzTimer({
    Function(Duration, Duration)? onTimeUpdate,
    Function(bool)? onTimeUp,
    Function()? onTimerStart,
    Function()? onTimerPause,
  }) {
    return ChessTimer(
      initialTime: Duration(minutes: 3),
      increment: Duration(seconds: 2),
      onTimeUpdate: onTimeUpdate,
      onTimeUp: onTimeUp,
      onTimerStart: onTimerStart,
      onTimerPause: onTimerPause,
    );
  }

  static ChessTimer rapidTimer({
    Function(Duration, Duration)? onTimeUpdate,
    Function(bool)? onTimeUp,
    Function()? onTimerStart,
    Function()? onTimerPause,
  }) {
    return ChessTimer(
      initialTime: Duration(minutes: 10),
      increment: Duration(seconds: 5),
      onTimeUpdate: onTimeUpdate,
      onTimeUp: onTimeUp,
      onTimerStart: onTimerStart,
      onTimerPause: onTimerPause,
    );
  }

  static ChessTimer classicalTimer({
    Function(Duration, Duration)? onTimeUpdate,
    Function(bool)? onTimeUp,
    Function()? onTimerStart,
    Function()? onTimerPause,
  }) {
    return ChessTimer(
      initialTime: Duration(minutes: 30),
      increment: Duration(seconds: 30),
      onTimeUpdate: onTimeUpdate,
      onTimeUp: onTimeUp,
      onTimerStart: onTimerStart,
      onTimerPause: onTimerPause,
    );
  }

  // Custom timer for testing
  static ChessTimer customTimer({
    required Duration initialTime,
    Duration increment = Duration.zero,
    Function(Duration, Duration)? onTimeUpdate,
    Function(bool)? onTimeUp,
    Function()? onTimerStart,
    Function()? onTimerPause,
  }) {
    return ChessTimer(
      initialTime: initialTime,
      increment: increment,
      onTimeUpdate: onTimeUpdate,
      onTimeUp: onTimeUp,
      onTimerStart: onTimerStart,
      onTimerPause: onTimerPause,
    );
  }
}

enum GameStatus {
  active('active'),
  resigned('resigned'),
  checkmate('checkmate'),
  draw('draw'),
  disconnected('disconnected'),
  timeout('timeout'),
  abandoned('abandoned');

  const GameStatus(this.value);
  final String value;

  static GameStatus fromString(String status) {
    return GameStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => GameStatus.active,
    );
  }

  bool get isGameOver => this != GameStatus.active;

  bool get isWinLose =>
      this == GameStatus.checkmate || this == GameStatus.resigned;

  bool get isDraw => this == GameStatus.draw;

  bool get isDisconnected =>
      this == GameStatus.disconnected || this == GameStatus.timeout;

  bool get isAbandoned => this == GameStatus.abandoned;

  String getDisplayMessage(bool isWinner) {
    switch (this) {
      case GameStatus.checkmate:
        return isWinner ? 'Checkmate! You won!' : 'Checkmate! You lost!';
      case GameStatus.resigned:
        return isWinner
            ? 'Opponent resigned. You won!'
            : 'You resigned. Game over.';
      case GameStatus.draw:
        return 'Game ended in a draw!';
      case GameStatus.disconnected:
        return isWinner
            ? 'Opponent disconnected. You won!'
            : 'You disconnected from the game.';
      case GameStatus.timeout:
        return isWinner
            ? 'Opponent timed out. You won!'
            : 'You timed out. Game over.';
      case GameStatus.abandoned:
        return 'Game was abandoned.';
      case GameStatus.active:
        return 'Game is active';
    }
  }

  String getSnackbarMessage(String playerName, bool isCurrentPlayer) {
    switch (this) {
      case GameStatus.resigned:
        return isCurrentPlayer
            ? 'You resigned from the game'
            : '$playerName resigned from the game';
      case GameStatus.disconnected:
        return isCurrentPlayer
            ? 'You disconnected'
            : '$playerName disconnected';
      case GameStatus.timeout:
        return isCurrentPlayer
            ? 'Your time ran out'
            : '$playerName\'s time ran out';
      case GameStatus.checkmate:
        return isCurrentPlayer
            ? 'You achieved checkmate!'
            : '$playerName achieved checkmate!';
      case GameStatus.draw:
        return 'Game ended in a draw';
      case GameStatus.abandoned:
        return 'Game was abandoned';
      case GameStatus.active:
        return 'Game resumed';
    }
  }
}

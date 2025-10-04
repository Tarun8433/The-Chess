// Add these imports to your existing board_game.dart file

import 'package:the_chess/components/move_history.dart';
import 'package:the_chess/components/pieces.dart';
import 'package:the_chess/components/square.dart';
import 'package:flutter/material.dart';
import 'package:the_chess/helper/helper_function.dart';
import 'components/chess_timer.dart';
import 'components/timer_widget.dart';
import 'components/dead_piece.dart';

bool isWhite(int index) {
  int row = index ~/ 8;
  int col = index % 8;

  // Don't flip the board square color pattern - keep it consistent
  // The square color pattern should remain the same regardless of player orientation
  return (row + col) % 2 == 0;
}

// how can we keep track
class BoardGame extends StatefulWidget {
  const BoardGame({super.key});

  @override
  State<BoardGame> createState() => _BoardGameState();
}

class _BoardGameState extends State<BoardGame> {
  // ... existing variables ...
  late List<List<ChessPiece?>> board;
  late ChessTimer chessTimer;
  Duration whiteTime = Duration(minutes: 10);
  Duration blackTime = Duration(minutes: 10);
  bool gameEnded = false;
  ChessPiece? selectedPiece;
  int selectedRow = -1;
  int selectedCol = -1;
  List<List<int>> validMoves = [];
  List<ChessPiece> whitePiecesTaken = [];
  List<ChessPiece> blackPiecesTaken = [];
  bool isWhiteTurn = true;
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;
  List<int>? enPassantTarget;
//  late PlayerAssignment playerAssignment;
  // **NEW: Add Review System Variables**
  late ReviewController reviewController;

  // Variables to store review state
  List<List<ChessPiece?>>? reviewBoard;
  List<ChessPiece>? reviewWhitePiecesTaken;
  List<ChessPiece>? reviewBlackPiecesTaken;
  bool? reviewIsWhiteTurn;
  List<int>? reviewWhiteKingPosition;
  List<int>? reviewBlackKingPosition;
  bool? reviewCheckStatus;
  List<int>? reviewEnPassantTarget;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _initializeTimer();

    // **NEW: Initialize Review Controller**
    reviewController = ReviewController();
  }

  // ... existing methods remain the same until movePiece ...

  void movePiece(int newRow, int newCol) {
    // Don't allow moves during review mode
    if (reviewController.isInReviewMode) return;

    //if (selectedPiece!.isWhite) return;  Disable the

    ChessPiece? capturedPiece;
    ChessPiece? enPassantCapturedPiece;
    bool wasEnPassant = false;
    bool wasPromotion = false;
    ChessPiecesType? promotedToType;
    List<int> previousKingPosition = selectedPiece!.type == ChessPiecesType.king
        ? (selectedPiece!.isWhite
            ? List<int>.from(whiteKingPosition)
            : List<int>.from(blackKingPosition))
        : [];

    // **NEW: Store previous state for move history**
    List<int>? previousEnPassantTarget =
        enPassantTarget != null ? List<int>.from(enPassantTarget!) : null;

    // Handle en passant capture
    if (selectedPiece?.type == ChessPiecesType.pawn &&
        enPassantTarget != null &&
        newRow == enPassantTarget![0] &&
        newCol == enPassantTarget![1]) {
      wasEnPassant = true;
      // The captured pawn is at the en passant target position
      enPassantCapturedPiece = board[newRow][newCol];
      board[newRow][newCol] = null;
    }
    // Regular capture
    else if (board[newRow][newCol] != null) {
      capturedPiece = board[newRow][newCol];
    }

    // Add captured piece to appropriate list
    if (capturedPiece != null) {
      if (capturedPiece.isWhite) {
        whitePiecesTaken.add(capturedPiece);
      } else {
        blackPiecesTaken.add(capturedPiece);
      }
    }

    // Check if this is a pawn double move to set up en passant
    List<int>? newEnPassantTarget;
    if (selectedPiece?.type == ChessPiecesType.pawn) {
      int moveDistance = (newRow - selectedRow).abs();
      print(
          '🔵 Pawn move detected: distance=$moveDistance, from=($selectedRow,$selectedCol) to=($newRow,$newCol)');
      if (moveDistance == 2) {
        // En passant target is where the pawn landed, so opponent can move diagonally to it
        newEnPassantTarget = [newRow, newCol];
        print(
            '✅ Setting en passant target to: $newEnPassantTarget (isWhite=${selectedPiece!.isWhite})');
      }
    }

    // Update king position if king moved
    if (selectedPiece?.type == ChessPiecesType.king) {
      if (selectedPiece!.isWhite) {
        whiteKingPosition = [newRow, newCol];
      } else {
        blackKingPosition = [newRow, newCol];
      }
    }

    // Move the piece
    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    // Handle pawn promotion
    if (selectedPiece?.type == ChessPiecesType.pawn &&
        ((selectedPiece!.isWhite && newRow == 0) ||
            (!selectedPiece!.isWhite && newRow == 7))) {
      wasPromotion = true;
      promotedToType = ChessPiecesType.queen;
      board[newRow][newCol] = ChessPiece(
        type: ChessPiecesType.queen,
        isWhite: selectedPiece!.isWhite,
        imagePath: 'images/queen.png',
      );
    }

    // Update en passant target
    enPassantTarget = newEnPassantTarget;
    print('📍 Current enPassantTarget after move: $enPassantTarget');

    // Check for check and checkmate
    bool wasCheck = isKingInCheck(!isWhiteTurn);
    bool wasCheckmate = false;

    if (wasCheck) {
      checkStatus = true;
      wasCheckmate = isCheckMate(!isWhiteTurn);
    } else {
      checkStatus = false;
    }

    // **NEW: Create and add move to history**
    ChessMove move = ChessMove(
      piece: selectedPiece!,
      fromRow: selectedRow,
      fromCol: selectedCol,
      toRow: newRow,
      toCol: newCol,
      capturedPiece: capturedPiece,
      wasEnPassant: wasEnPassant,
      enPassantCapturedPiece: enPassantCapturedPiece,
      previousEnPassantTarget: previousEnPassantTarget,
      newEnPassantTarget: newEnPassantTarget,
      wasPromotion: wasPromotion,
      promotedToType: promotedToType,
      wasCheck: wasCheck,
      wasCheckmate: wasCheckmate,
      previousKingPosition: previousKingPosition,
      moveNotation: _generateMoveNotation(selectedPiece!, selectedRow,
          selectedCol, newRow, newCol, capturedPiece != null),
      moveTime: DateTime.now().difference(DateTime.now()),
    );

    reviewController.addMove(move);

    if (chessTimer.isRunning) {
      chessTimer.switchTurn();
    }

    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    if (wasCheckmate) {
      showDialog(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Column(
              children: [
                Text(
                  "CHECK MATE",
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                Text(
                  isWhiteTurn
                      ? "Black Check Mate.\nWhite wins!"
                      : "White Check Mate.\nBlack wins!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: resetGame,
                  child: Text(
                    "Restart The Game",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ))
            ],
          );
        },
      );
    }

    isWhiteTurn = !isWhiteTurn;
  }

  // **NEW: Review System Methods**
  void startReview() {
    if (!reviewController.canStartReview()) return;

    reviewController.startReview(
      board,
      whitePiecesTaken,
      blackPiecesTaken,
      isWhiteTurn,
      whiteKingPosition,
      blackKingPosition,
      checkStatus,
      enPassantTarget,
    );

    _updateReviewState();
    setState(() {});
  }

  void endReview() {
    reviewController.endReview();

    // Clear review state
    reviewBoard = null;
    reviewWhitePiecesTaken = null;
    reviewBlackPiecesTaken = null;
    reviewIsWhiteTurn = null;
    reviewWhiteKingPosition = null;
    reviewBlackKingPosition = null;
    reviewCheckStatus = null;
    reviewEnPassantTarget = null;

    setState(() {});
  }

  void goToPreviousMove() {
    reviewController.goToPreviousMove();
    _updateReviewState();
    setState(() {});
  }

  void goToNextMove() {
    reviewController.goToNextMove();
    _updateReviewState();
    setState(() {});
  }

  void goToSpecificMove(int moveIndex) {
    reviewController.goToMove(moveIndex);
    _updateReviewState();
    setState(() {});
  }

  void _updateReviewState() {
    if (!reviewController.isInReviewMode) return;

    Map<String, dynamic> boardState = reviewController
        .getBoardStateAtMove(reviewController.currentReviewIndex);

    if (boardState.isNotEmpty) {
      reviewBoard = boardState['board'];
      reviewWhitePiecesTaken = boardState['whitePiecesTaken'];
      reviewBlackPiecesTaken = boardState['blackPiecesTaken'];
      reviewIsWhiteTurn = boardState['isWhiteTurn'];
      reviewWhiteKingPosition = boardState['whiteKingPosition'];
      reviewBlackKingPosition = boardState['blackKingPosition'];
      reviewCheckStatus = boardState['checkStatus'];
      reviewEnPassantTarget = boardState['enPassantTarget'];
    }
  }

  // **NEW: Helper method for move notation**
  String _generateMoveNotation(ChessPiece piece, int fromRow, int fromCol,
      int toRow, int toCol, bool isCapture) {
    String fromPos =
        '${String.fromCharCode('a'.codeUnitAt(0) + fromCol)}${8 - fromRow}';
    String toPos =
        '${String.fromCharCode('a'.codeUnitAt(0) + toCol)}${8 - toRow}';
    String pieceSymbol =
        piece.type.toString().split('.').last.substring(0, 1).toUpperCase();

    if (piece.type == ChessPiecesType.pawn) {
      return isCapture ? '${fromPos.substring(0, 1)}x$toPos' : toPos;
    }

    return isCapture
        ? '$pieceSymbol${fromPos}x$toPos'
        : '$pieceSymbol$fromPos-$toPos';
  }

  // **NEW: Get current display state (either review or actual game state)**
  List<List<ChessPiece?>> get currentBoard =>
      reviewController.isInReviewMode ? reviewBoard ?? board : board;
  List<ChessPiece> get currentWhitePiecesTaken =>
      reviewController.isInReviewMode
          ? reviewWhitePiecesTaken ?? whitePiecesTaken
          : whitePiecesTaken;
  List<ChessPiece> get currentBlackPiecesTaken =>
      reviewController.isInReviewMode
          ? reviewBlackPiecesTaken ?? blackPiecesTaken
          : blackPiecesTaken;
  bool get currentIsWhiteTurn => reviewController.isInReviewMode
      ? reviewIsWhiteTurn ?? isWhiteTurn
      : isWhiteTurn;
  bool get currentCheckStatus => reviewController.isInReviewMode
      ? reviewCheckStatus ?? checkStatus
      : checkStatus;
  List<int> get currentWhiteKingPosition => reviewController.isInReviewMode
      ? reviewWhiteKingPosition ?? whiteKingPosition
      : whiteKingPosition;
  List<int> get currentBlackKingPosition => reviewController.isInReviewMode
      ? reviewBlackKingPosition ?? blackKingPosition
      : blackKingPosition;

  void _initializeTimer() {
    chessTimer = ChessTimer.customTimer(
      onTimeUpdate: (Duration white, Duration black) {
        if (mounted) {
          setState(() {
            whiteTime = white;
            blackTime = black;
          });
        }
      },
      onTimeUp: (bool isWhiteWinner) {
        if (mounted) {
          setState(() {
            gameEnded = true;
          });
          _showTimeUpDialog(isWhiteWinner);
        }
      },
      initialTime: Duration(minutes: 5),
    );

    whiteTime = chessTimer.whiteTime;
    blackTime = chessTimer.blackTime;
  }

  void _initializeBoard() {
    // initialize the board with nulls, meaning no pieces in those positions.
    List<List<ChessPiece?>> newBoard =
        List.generate(8, (index) => List.generate(8, (index) => null));

    // Place pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: false,
        imagePath: 'assets/images/figures/black/pawn.png',
      );

      newBoard[6][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: true,
        imagePath: 'images/pawn.png',
      );
    }

    // Place rooks
    newBoard[0][0] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: false,
        imagePath: "assets/images/figures/black/rook.png");
    newBoard[0][7] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: false,
        imagePath: "assets/images/figures/black/rook.png");
    newBoard[7][0] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: true,
        imagePath: "images/rook.png");
    newBoard[7][7] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: true,
        imagePath: "images/rook.png");

    // Place knights
    newBoard[0][1] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: false,
        imagePath: "assets/images/figures/black/knight.png");
    newBoard[0][6] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: false,
        imagePath: "assets/images/figures/black/knight.png");
    newBoard[7][1] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: true,
        imagePath: "images/knight.png");
    newBoard[7][6] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: true,
        imagePath: "images/knight.png");

    // Place bishops
    // newBoard[0][2] = ChessPiece(
    // type: ChessPiecesType.bishop,
    // isWhite: false,
    // imagePath: "images/bishop.png");

    // newBoard[0][5] = ChessPiece(
    // type: ChessPiecesType.bishop,
    // isWhite: false,
    // imagePath: "images/bishop.png");
    newBoard[0][2] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: false,
        imagePath: "assets/images/figures/black/bishop.png");

    newBoard[0][5] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: false,
        imagePath: "assets/images/figures/black/bishop.png");
    newBoard[7][2] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: true,
        imagePath: "images/bishop.png");
    newBoard[7][5] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: true,
        imagePath: "images/bishop.png");

    // Place queens
    newBoard[0][3] = ChessPiece(
      type: ChessPiecesType.queen,
      isWhite: false,
      imagePath: 'assets/images/figures/black/queen.png',
    );
    newBoard[7][3] = ChessPiece(
      type: ChessPiecesType.queen,
      isWhite: true,
      imagePath: 'images/queen.png',
    );

    // Place kings
    newBoard[0][4] = ChessPiece(
      type: ChessPiecesType.king,
      isWhite: false,
      imagePath: 'assets/images/figures/black/king.png',
    );
    newBoard[7][4] = ChessPiece(
      type: ChessPiecesType.king,
      isWhite: true,
      imagePath: 'images/king.png',
    );

    board = newBoard;
  }

// USER SELECTED A PIECE

  void pieceSelected(int row, int col) {
    // Don't allow moves if game ended

    if (gameEnded) return;
    setState(() {
      if (chessTimer.isStopped &&
          selectedPiece == null &&
          board[row][col] != null) {
        chessTimer.startTimer();
      }
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == isWhiteTurn) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
        }
      } else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      } else if (selectedPiece != null &&
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }

      validMoves = calculateRealValidMoves(
          selectedRow, selectedCol, selectedPiece, true);
    });
  }

  List<List<int>> calculateRowValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];

    if (piece == null) return [];

    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPiecesType.pawn:
        // Move forward
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
          // First move double step
          if ((row == 6 && piece.isWhite) || (row == 1 && !piece.isWhite)) {
            if (board[row + 2 * direction][col] == null) {
              candidateMoves.add([row + 2 * direction, col]);
            }
          }
        }
        // Capture diagonally
        for (int sideCol in [col - 1, col + 1]) {
          if (isInBoard(row + direction, sideCol) &&
              board[row + direction][sideCol] != null &&
              board[row + direction][sideCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([row + direction, sideCol]);
          }
        }

        // EN PASSANT CAPTURE - NEW CODE
        if (enPassantTarget != null) {
          print('🎯 En Passant Debug:');
          print('  - enPassantTarget: $enPassantTarget');
          print('  - Current pawn at: row=$row, col=$col');
          print('  - Direction: $direction');
          int targetRow = enPassantTarget![0];
          int targetCol = enPassantTarget![1];
          print('  - Target square: row=$targetRow, col=$targetCol');
          print(
              '  - Checking if (row + direction == targetRow): ${row + direction} == $targetRow = ${row + direction == targetRow}');
          print(
              '  - Checking adjacent cols: col-1=${col - 1} or col+1=${col + 1} equals $targetCol = ${(col - 1 == targetCol || col + 1 == targetCol)}');

          // Check if this pawn can capture en passant
          if (row + direction == targetRow &&
              (col - 1 == targetCol || col + 1 == targetCol)) {
            candidateMoves.add([targetRow, targetCol]);
            print('  ✅ En Passant move ADDED!');
          } else {
            print('  ❌ En Passant conditions NOT met');
          }
        } else {
          print('⚠️ No en passant target available');
        }
        break;

      case ChessPiecesType.rook:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ];
        for (var dir in directions) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) break;
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.knight:
        var moves = [
          [-2, -1],
          [-2, 1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
          [2, -1],
          [2, 1],
        ];
        for (var move in moves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) continue;
          if (board[newRow][newCol] == null ||
              board[newRow][newCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([newRow, newCol]);
          }
        }
        break;

      case ChessPiecesType.bishop:
        var directions = [
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];
        for (var dir in directions) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) break;
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.queen:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];
        for (var dir in directions) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) break;
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.king:
        var moves = [
          [-1, -1],
          [-1, 0],
          [-1, 1],
          [0, -1],
          /*[0, 0],*/ [0, 1],
          [1, -1],
          [1, 0],
          [1, 1]
        ];
        for (var move in moves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) continue;
          if (board[newRow][newCol] == null ||
              board[newRow][newCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([newRow, newCol]);
          }
        }
        break;
    }

    return candidateMoves;
  }

  List<List<int>> calculateRealValidMoves(
      int row, int col, ChessPiece? piece, bool checkSimulation) {
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRowValidMoves(row, col, piece);
    if (checkSimulation) {
      for (var move in candidateMoves) {
        int endRow = move[0];
        int endCol = move[1];
        if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candidateMoves;
    }
    return realValidMoves;
  }

  bool isKingInCheck(bool isWhiteKing) {
    List<int> kingPosition =
        isWhiteKing ? whiteKingPosition : blackKingPosition;

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }
        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], false);

        for (List<int> move in pieceValidMoves) {
          if (move[0] == kingPosition[0] && move[1] == kingPosition[1]) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool simulatedMoveIsSafe(
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    ChessPiece? originalDestinationPiece = board[endRow][endCol];
    ChessPiece? originalEnPassantPiece;

    // Handle en passant simulation
    bool isSimulatedEnPassant = false;
    if (piece.type == ChessPiecesType.pawn &&
        enPassantTarget != null &&
        endRow == enPassantTarget![0] &&
        endCol == enPassantTarget![1]) {
      isSimulatedEnPassant = true;
      // The captured pawn is at the en passant target position
      originalEnPassantPiece = board[endRow][endCol];
      // We'll handle the capture when we move the piece below
    }

    List<int>? originalKingPosition;
    if (piece.type == ChessPiecesType.king) {
      originalKingPosition =
          piece.isWhite ? whiteKingPosition : blackKingPosition;

      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    bool kingInCheck = isKingInCheck(piece.isWhite);

    // Restore board state
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    // Restore en passant captured piece (it's already restored by the originalDestinationPiece above)
    // No additional restoration needed since en passant target is where the piece is

    if (piece.type == ChessPiecesType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }
    return !kingInCheck;
  }

// 6. ADD the missing isWhite helper function
// Add this method to your _BoardGameState class:

  bool isWhite(int index) {
    int row = index ~/ 8;
    int col = index % 8;
    return (row + col) % 2 == 0;
  }

  bool isCheckMate(bool isWhiteKing) {
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }
        List<List<int>> validMoves =
            calculateRealValidMoves(i, j, board[i][j]!, true);
        if (validMoves.isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void resetGame() {
    Navigator.pop(context);
    _initializeBoard();
    checkStatus = false;
    whitePiecesTaken.clear();
    blackPiecesTaken.clear();
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    enPassantTarget = null;

    // Add these lines:
    gameEnded = false;
    chessTimer.reset();
    whiteTime = chessTimer.whiteTime;
    blackTime = chessTimer.blackTime;

    setState(() {});
  }

  @override
  void dispose() {
    chessTimer.dispose();
    super.dispose();
  }

  // Add these methods to your _BoardGameState class in board_game.dart

// METHOD 1: Show dialog when time runs out
  void _showTimeUpDialog(bool isWhiteWinner) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false, // Player must choose an option
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.timer_off,
              color: theme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              "Time's Up!",
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWhiteWinner ? Icons.emoji_events : Icons.emoji_events,
              color: isWhiteWinner
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              isWhiteWinner
                  ? "Black ran out of time.\nWhite wins!"
                  : "White ran out of time.\nBlack wins!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Game Over",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Optionally navigate back or stay on game screen
            },
            child: Text(
              "View Board",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              resetGame(); // Start new game
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text("New Game"),
          ),
        ],
      ),
    );
  }

  // In file: game_board.dart

// ... (keep all your existing imports and the _BoardGameState class)

// REPLACE the existing build method in _BoardGameState with this one:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark, modern background color from the image
      backgroundColor: const Color(0xFF1F252E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildMoveHistory(),
              // Top bar with player info and timers
              _buildTopPlayerBar(),
              const Spacer(),

              // Chessboard with coordinates
              _buildBoard(),
              const SizedBox(height: 16),

              // Captured pieces display
              _buildCapturedPieces(),
              const SizedBox(height: 8),

              // Move history log

              // Bottom action bar with game controls
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

// ADD the following helper methods inside your _BoardGameState class:

  /// Builds the top bar with player info and timers.
  Widget _buildTopPlayerBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Player 1 (Black)
        _buildPlayerInfo("Jessica", "Junior", !currentIsWhiteTurn),

        // Timers and Turn Indicator
        Column(
          children: [
            Text(
              reviewController.isInReviewMode
                  ? "Review Mode"
                  : (currentIsWhiteTurn ? "Tomasz move" : "Jessica move"),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            ChessTimerDisplayForBlack(
              chessTimer: chessTimer,
              whiteTime: whiteTime,
              blackTime: blackTime,
            ),
            const SizedBox(height: 4),
            ChessTimerDisplayForWhite(
              chessTimer: chessTimer,
              whiteTime: whiteTime,
              blackTime: blackTime,
            ),
          ],
        ),

        // Player 2 (White)
        _buildPlayerInfo("Tomasz", "Master", currentIsWhiteTurn),
      ],
    );
  }

  /// Builds the UI for a single player's information.
  Widget _buildPlayerInfo(String name, String rating, bool isTurn) {
    // NOTE: Add your own avatar images. I'm using a placeholder.
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isTurn && !reviewController.isInReviewMode
                  ? Colors.blue
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey,
            // child: Image.asset("assets/images/your_avatar.png"), // Example
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(rating,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  /// Builds the main chessboard UI.
  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemBuilder: (context, index) {
          int row = index ~/ 8;
          int col = index % 8;

          bool isSelected = !reviewController.isInReviewMode &&
              selectedCol == col &&
              selectedRow == row;
          bool isValidMove = false;

          if (!reviewController.isInReviewMode) {
            isValidMove =
                validMoves.any((pos) => pos[0] == row && pos[1] == col);
          }

          return Square(
            isWhite: isWhite(index),
            piece: currentBoard[row][col],
            isSelected: isSelected,
            isValidMove: isValidMove,
            onTap: reviewController.isInReviewMode
                ? null
                : () => pieceSelected(row, col),
            isKingInCheck: currentBoard[row][col] != null &&
                currentBoard[row][col]!.type == ChessPiecesType.king &&
                _isKingInCheckAtCurrentState(currentBoard[row][col]!.isWhite),
            // Board colors from the image
            boardBColor: const Color(0xFF4A644D),
            boardWColor: const Color(0xFF9EAD87),
            row: row,
            col: col,
          );
        },
      ),
    );
  }

  /// Builds the display for captured pieces.
  Widget _buildCapturedPieces() {
    return Column(
      children: [
        // White pieces captured by Black
        _buildCapturedPiecesRow(currentWhitePiecesTaken),
        const SizedBox(height: 4),
        // Black pieces captured by White
        _buildCapturedPiecesRow(currentBlackPiecesTaken),
      ],
    );
  }

  /// Helper to build a single row of captured pieces.
  Widget _buildCapturedPiecesRow(List<ChessPiece> pieces) {
    if (pieces.isEmpty) return const SizedBox(height: 30);
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pieces.length,
        itemBuilder: (context, index) => DeadPiece(
          imagePath: pieces[index].imagePath,
          isWhite: pieces[index].isWhite,
        ),
      ),
    );
  }

  /// Builds the horizontally scrolling move history log.
  Widget _buildMoveHistory() {
    if (reviewController.moveHistory.isEmpty) {
      return const SizedBox(height: 40); // Placeholder
    }

    List<String> movePairs = [];
    for (int i = 0; i < reviewController.moveHistory.length; i += 2) {
      final moveNumber = (i ~/ 2) + 1;
      final whiteMove = reviewController.moveHistory[i].moveNotation;
      final blackMove = (i + 1 < reviewController.moveHistory.length)
          ? reviewController.moveHistory[i + 1].moveNotation
          : "";
      movePairs.add("$moveNumber. $whiteMove  $blackMove");
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        itemCount: movePairs.length,
        reverse: false,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Center(
            child: Text(
              movePairs.reversed.toList()[index],
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the bottom action bar with game controls.
  Widget _buildBottomActionBar() {
    final canReview = reviewController.canStartReview();
    final inReview = reviewController.isInReviewMode;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(50)),
      child: inReview
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed:
                      reviewController.canGoBack() ? goToPreviousMove : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.orange, size: 28),
                  onPressed: endReview,
                ),
                IconButton(
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed:
                      reviewController.canGoForward() ? goToNextMove : null,
                ),
              ],
            )
          :
          // Review Button
          IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: canReview ? startReview : null,
              style: IconButton.styleFrom(
                backgroundColor: canReview
                    ? Colors.blue
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
    );
  }

  // **NEW: Helper method to check king status in current displayed state**
  bool _isKingInCheckAtCurrentState(bool isWhiteKing) {
    if (reviewController.isInReviewMode) {
      return currentCheckStatus &&
          ((isWhiteKing && !currentIsWhiteTurn) ||
              (!isWhiteKing && currentIsWhiteTurn));
    }
    return isKingInCheck(isWhiteKing);
  }
}


 // // **UPDATED: Build method with review integration**
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor:
  //         reviewController.isInReviewMode ? Colors.orange[200] : Colors.white30,
  //     body: Column(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         // **NEW: Review Status Banner**
  //         SafeArea(
  //           child: ReviewStatusBanner(
  //             isInReviewMode: reviewController.isInReviewMode,
  //             statusText: reviewController.isInReviewMode
  //                 ? 'REVIEWING MOVES - TIMER CONTINUES'
  //                 : 'Game On',
  //           ),
  //         ),

  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Container(
  //                     decoration: BoxDecoration(
  //                         border: Border.all(color: Colors.white)),
  //                     child: Image.asset(
  //                       "assets/images/figures/white/queen.png",
  //                       height: 50,
  //                     ),
  //                   ),
  //                   SizedBox(width: 8),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         "Tarun Ku. Sahani",
  //                         style: TextStyle(
  //                           color: reviewController.isInReviewMode
  //                               ? Colors.black
  //                               : Colors.white,
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 18,
  //                         ),
  //                       ),
  //                       SizedBox(
  //                         height: 30,
  //                         width: MediaQuery.of(context).size.width * .6,
  //                         child: ListView.builder(
  //                           scrollDirection: Axis.horizontal,
  //                           shrinkWrap: true,
  //                           physics: const BouncingScrollPhysics(),
  //                           itemCount: currentBlackPiecesTaken.length,
  //                           itemBuilder: (context, index) => DeadPiece(
  //                             imagePath:
  //                                 currentBlackPiecesTaken[index].imagePath,
  //                             isWhite: false,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),

  //               // Chess Timer
  //               ChessTimerDisplayForBlack(
  //                 chessTimer: chessTimer,
  //                 whiteTime: whiteTime,
  //                 blackTime: blackTime,
  //               ),
  //             ],
  //           ),
  //         ),
  //         Spacer(),

  //         // Chess Board - show current state (review or actual)
  //         AspectRatio(
  //           aspectRatio: .9,
  //           child: GridView.builder(
  //             physics: const NeverScrollableScrollPhysics(),
  //             itemCount: 64,
  //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                 crossAxisCount: 8),
  //             itemBuilder: (context, index) {
  //               int row = index ~/ 8;
  //               int col = index % 8;

  //               bool isSelected = !reviewController.isInReviewMode &&
  //                   selectedCol == col &&
  //                   selectedRow == row;
  //               bool isValidMove = false;

  //               // Only show valid moves during actual game
  //               if (!reviewController.isInReviewMode) {
  //                 for (var position in validMoves) {
  //                   if (position[0] == row && position[1] == col) {
  //                     isValidMove = true;
  //                   }
  //                 }
  //               }

  //               return Square(
  //                 isValidMove: isValidMove,
  //                 onTap: reviewController.isInReviewMode
  //                     ? null
  //                     : () => pieceSelected(row, col),
  //                 isSelected: isSelected,
  //                 isWhite: isWhite(index),
  //                 piece: currentBoard[row][col],
  //                 isKingInCheck: currentBoard[row][col] != null &&
  //                     currentBoard[row][col]!.type == ChessPiecesType.king &&
  //                     _isKingInCheckAtCurrentState(
  //                         currentBoard[row][col]!.isWhite),
  //                 boardBColor: reviewController.isInReviewMode
  //                     ? Colors.orange
  //                     : forgroundColor,
  //                 boardWColor: backgroundColor,
  //               );
  //             },
  //           ),
  //         ),
  //         Spacer(),
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Container(
  //                     decoration: BoxDecoration(
  //                         border: Border.all(color: Colors.white)),
  //                     child: Image.asset(
  //                       "assets/images/figures/white/queen.png",
  //                       height: 50,
  //                     ),
  //                   ),
  //                   SizedBox(width: 8),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         "Sachin Sir",
  //                         style: TextStyle(
  //                           color: reviewController.isInReviewMode
  //                               ? Colors.black
  //                               : Colors.white,
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 18,
  //                         ),
  //                       ),
  //                       SizedBox(
  //                         height: 30,
  //                         width: MediaQuery.of(context).size.width * .6,
  //                         child: ListView.builder(
  //                           scrollDirection: Axis.horizontal,
  //                           shrinkWrap: true,
  //                           physics: const BouncingScrollPhysics(),
  //                           itemCount: currentWhitePiecesTaken.length,
  //                           itemBuilder: (context, index) => DeadPiece(
  //                             imagePath:
  //                                 currentWhitePiecesTaken[index].imagePath,
  //                             isWhite: true,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),

  //               // Chess Timer
  //               ChessTimerDisplayForWhite(
  //                 chessTimer: chessTimer,
  //                 whiteTime: whiteTime,
  //                 blackTime: blackTime,
  //               ),
  //             ],
  //           ),
  //         ),

  //         // **NEW: Review Button**
  //         ReviewControls(
  //           onPrevious: goToPreviousMove,
  //           onNext: goToNextMove,
  //           canGoBack: reviewController.canGoBack(),
  //           canGoForward: reviewController.canGoForward(),
  //           currentMoveInfo: reviewController.getCurrentMoveInfo(),
  //           onExitReview: endReview,
  //           startReview:
  //               reviewController.isInReviewMode ? endReview : startReview,
  //           canStartReview: reviewController.canStartReview(),
  //           isInReviewMode: reviewController.isInReviewMode,
  //         )
  //       ],
  //     ),
  //   );
  // }

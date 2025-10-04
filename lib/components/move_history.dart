// models/chess_move.dart
import 'package:the_chess/components/pieces.dart';

class ChessMove {
  final ChessPiece piece;
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final ChessPiece? capturedPiece;
  final bool wasEnPassant;
  final ChessPiece? enPassantCapturedPiece;
  final List<int>? previousEnPassantTarget;
  final List<int>? newEnPassantTarget;
  final bool wasPromotion;
  final ChessPiecesType? promotedToType;
  final bool wasCheck;
  final bool wasCheckmate;
  final List<int> previousKingPosition;
  final String moveNotation;
  final Duration moveTime;

  ChessMove({
    required this.piece,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.capturedPiece,
    this.wasEnPassant = false,
    this.enPassantCapturedPiece,
    this.previousEnPassantTarget,
    this.newEnPassantTarget,
    this.wasPromotion = false,
    this.promotedToType,
    this.wasCheck = false,
    this.wasCheckmate = false,
    required this.previousKingPosition,
    required this.moveNotation,
    required this.moveTime,
  });

  String get moveDescription {
    String desc = '${piece.isWhite ? 'White' : 'Black'} ';
    desc += '${piece.type.toString().split('.').last} ';
    desc += 'from ${_positionToString(fromRow, fromCol)} ';
    desc += 'to ${_positionToString(toRow, toCol)}';

    if (capturedPiece != null) {
      desc += ' (captured ${capturedPiece!.type.toString().split('.').last})';
    }
    if (wasEnPassant) {
      desc += ' (en passant)';
    }
    if (wasPromotion) {
      desc += ' (promoted to ${promotedToType.toString().split('.').last})';
    }
    if (wasCheckmate) {
      desc += ' - CHECKMATE!';
    } else if (wasCheck) {
      desc += ' - CHECK!';
    }

    return desc;
  }

  String _positionToString(int row, int col) {
    String colLetter = String.fromCharCode('a'.codeUnitAt(0) + col);
    String rowNumber = (8 - row).toString();
    return '$colLetter$rowNumber';
  }

  // Convert ChessMove to JSON
  Map<String, dynamic> toJson() {
    return {
      'piece': piece.toJson(),
      'fromRow': fromRow,
      'fromCol': fromCol,
      'toRow': toRow,
      'toCol': toCol,
      'capturedPiece': capturedPiece?.toJson(),
      'wasEnPassant': wasEnPassant,
      'enPassantCapturedPiece': enPassantCapturedPiece?.toJson(),
      'previousEnPassantTarget': previousEnPassantTarget,
      'newEnPassantTarget': newEnPassantTarget,
      'wasPromotion': wasPromotion,
      'promotedToType': promotedToType?.toString(), // Store enum as string
      'wasCheck': wasCheck,
      'wasCheckmate': wasCheckmate,
      'previousKingPosition': previousKingPosition,
      'moveNotation': moveNotation,
      'moveTime': moveTime.inMilliseconds, // Store duration as milliseconds
    };
  }

  // Create ChessMove from JSON
  factory ChessMove.fromJson(Map<String, dynamic> json) {
    return ChessMove(
      piece: ChessPiece.fromJson(json['piece']),
      fromRow: json['fromRow'],
      fromCol: json['fromCol'],
      toRow: json['toRow'],
      toCol: json['toCol'],
      capturedPiece: json['capturedPiece'] != null
          ? ChessPiece.fromJson(json['capturedPiece'])
          : null,
      wasEnPassant: json['wasEnPassant'],
      enPassantCapturedPiece: json['enPassantCapturedPiece'] != null
          ? ChessPiece.fromJson(json['enPassantCapturedPiece'])
          : null,
      previousEnPassantTarget: json['previousEnPassantTarget'] != null
          ? List<int>.from(json['previousEnPassantTarget'])
          : null,
      newEnPassantTarget: json['newEnPassantTarget'] != null
          ? List<int>.from(json['newEnPassantTarget'])
          : null,
      wasPromotion: json['wasPromotion'],
      promotedToType: json['promotedToType'] != null
          ? ChessPiecesType.values.firstWhere(
              (e) => e.toString() == json['promotedToType'])
          : null,
      wasCheck: json['wasCheck'],
      wasCheckmate: json['wasCheckmate'],
      previousKingPosition: List<int>.from(json['previousKingPosition']),
      moveNotation: json['moveNotation'],
      moveTime: Duration(milliseconds: json['moveTime']),
    );
  }
}

// controllers/review_controller.dart
class ReviewController {
  List<ChessMove> moveHistory = [];
  int currentReviewIndex = -1;
  bool isInReviewMode = false;

  // Original game state to restore after review
  late List<List<ChessPiece?>> originalBoard;
  late List<ChessPiece> originalWhitePiecesTaken;
  late List<ChessPiece> originalBlackPiecesTaken;
  late bool originalIsWhiteTurn;
  late List<int> originalWhiteKingPosition;
  late List<int> originalBlackKingPosition;
  late bool originalCheckStatus;
  late List<int>? originalEnPassantTarget;

  void addMove(ChessMove move) {
    if (!isInReviewMode) {
      moveHistory.add(move);
    }
  }

  void startReview(
    List<List<ChessPiece?>> board,
    List<ChessPiece> whitePiecesTaken,
    List<ChessPiece> blackPiecesTaken,
    bool isWhiteTurn,
    List<int> whiteKingPosition,
    List<int> blackKingPosition,
    bool checkStatus,
    List<int>? enPassantTarget,
  ) {
    if (moveHistory.isEmpty) return;

    isInReviewMode = true;
    currentReviewIndex = moveHistory.length - 1;

    // Store original state
    originalBoard = board.map((row) => List<ChessPiece?>.from(row)).toList();
    originalWhitePiecesTaken = List<ChessPiece>.from(whitePiecesTaken);
    originalBlackPiecesTaken = List<ChessPiece>.from(blackPiecesTaken);
    originalIsWhiteTurn = isWhiteTurn;
    originalWhiteKingPosition = List<int>.from(whiteKingPosition);
    originalBlackKingPosition = List<int>.from(blackKingPosition);
    originalCheckStatus = checkStatus;
    originalEnPassantTarget =
        enPassantTarget != null ? List<int>.from(enPassantTarget) : null;
  }

  void endReview() {
    isInReviewMode = false;
    currentReviewIndex = -1;
  }

  bool canGoBack() {
    return isInReviewMode && currentReviewIndex > 0;
  }

  bool canGoForward() {
    return isInReviewMode && currentReviewIndex < moveHistory.length - 1;
  }

  bool canStartReview() {
    return moveHistory.isNotEmpty && !isInReviewMode;
  }

  ChessMove? getCurrentMove() {
    if (isInReviewMode &&
        currentReviewIndex >= 0 &&
        currentReviewIndex < moveHistory.length) {
      return moveHistory[currentReviewIndex];
    }
    return null;
  }

  void goToPreviousMove() {
    if (canGoBack()) {
      currentReviewIndex--;
    }
  }

  void goToNextMove() {
    if (canGoForward()) {
      currentReviewIndex++;
    }
  }

  void goToMove(int index) {
    if (isInReviewMode && index >= 0 && index < moveHistory.length) {
      currentReviewIndex = index;
    }
  }

  String getCurrentMoveInfo() {
    if (getCurrentMove() != null) {
      return 'Move ${currentReviewIndex + 1}/${moveHistory.length}: ${getCurrentMove()!.moveDescription}';
    }
    return 'Review Mode';
  }

  // Reconstruct board state at specific move index
  Map<String, dynamic> getBoardStateAtMove(int moveIndex) {
    if (moveIndex < 0 || moveIndex >= moveHistory.length) {
      return {};
    }

    // Start with initial board state and replay moves up to moveIndex
    List<List<ChessPiece?>> board =
        List.generate(8, (index) => List.generate(8, (index) => null));
    List<ChessPiece> whitePiecesTaken = [];
    List<ChessPiece> blackPiecesTaken = [];
    bool isWhiteTurn = true;
    List<int> whiteKingPosition = [7, 4];
    List<int> blackKingPosition = [0, 4];
    bool checkStatus = false;
    List<int>? enPassantTarget;

    // Initialize starting board
    _initializeStartingBoard(board);

    // Replay moves up to the specified index
    for (int i = 0; i <= moveIndex; i++) {
      ChessMove move = moveHistory[i];
      _applyMoveToBoard(board, move, whitePiecesTaken, blackPiecesTaken);

      // Update game state
      if (move.piece.type == ChessPiecesType.king) {
        if (move.piece.isWhite) {
          whiteKingPosition = [move.toRow, move.toCol];
        } else {
          blackKingPosition = [move.toRow, move.toCol];
        }
      }

      enPassantTarget = move.newEnPassantTarget;
      checkStatus = move.wasCheck;
      isWhiteTurn = !isWhiteTurn; // Toggle turn after each move
    }

    return {
      'board': board,
      'whitePiecesTaken': whitePiecesTaken,
      'blackPiecesTaken': blackPiecesTaken,
      'isWhiteTurn': isWhiteTurn,
      'whiteKingPosition': whiteKingPosition,
      'blackKingPosition': blackKingPosition,
      'checkStatus': checkStatus,
      'enPassantTarget': enPassantTarget,
    };
  }

  void _initializeStartingBoard(List<List<ChessPiece?>> board) {
    // Place pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: false,
        imagePath: 'images/pawn.png',
      );
      board[6][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: true,
        imagePath: 'images/pawn.png',
      );
    }

    // Place rooks
    board[0][0] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: false,
        imagePath: "images/rook.png");
    board[0][7] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: false,
        imagePath: "images/rook.png");
    board[7][0] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: true,
        imagePath: "images/rook.png");
    board[7][7] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: true,
        imagePath: "images/rook.png");

    // Place knights
    board[0][1] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: false,
        imagePath: "images/knight.png");
    board[0][6] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: false,
        imagePath: "images/knight.png");
    board[7][1] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: true,
        imagePath: "images/knight.png");
    board[7][6] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: true,
        imagePath: "images/knight.png");

    // Place bishops
    board[0][2] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: false,
        imagePath: "images/bishop.png");
    board[0][5] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: false,
        imagePath: "images/bishop.png");
    board[7][2] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: true,
        imagePath: "images/bishop.png");
    board[7][5] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: true,
        imagePath: "images/bishop.png");

    // Place queens
    board[0][3] = ChessPiece(
        type: ChessPiecesType.queen,
        isWhite: false,
        imagePath: 'images/queen.png');
    board[7][3] = ChessPiece(
        type: ChessPiecesType.queen,
        isWhite: true,
        imagePath: 'images/queen.png');

    // Place kings
    board[0][4] = ChessPiece(
        type: ChessPiecesType.king,
        isWhite: false,
        imagePath: 'images/king.png');
    board[7][4] = ChessPiece(
        type: ChessPiecesType.king,
        isWhite: true,
        imagePath: 'images/king.png');
  }

  void _applyMoveToBoard(List<List<ChessPiece?>> board, ChessMove move,
      List<ChessPiece> whitePiecesTaken, List<ChessPiece> blackPiecesTaken) {
    // Handle captures
    if (move.capturedPiece != null) {
      if (move.capturedPiece!.isWhite) {
        whitePiecesTaken.add(move.capturedPiece!);
      } else {
        blackPiecesTaken.add(move.capturedPiece!);
      }
    }

    // Handle en passant capture
    if (move.wasEnPassant && move.enPassantCapturedPiece != null) {
      if (move.enPassantCapturedPiece!.isWhite) {
        whitePiecesTaken.add(move.enPassantCapturedPiece!);
      } else {
        blackPiecesTaken.add(move.enPassantCapturedPiece!);
      }
    }

    // Move the piece
    board[move.toRow][move.toCol] = move.wasPromotion
        ? ChessPiece(
            type: move.promotedToType ?? ChessPiecesType.queen,
            isWhite: move.piece.isWhite,
            imagePath:
                'images/${move.promotedToType?.toString().split('.').last ?? 'queen'}.png',
          )
        : move.piece;
    board[move.fromRow][move.fromCol] = null;
  }
}


// // models/chess_move.dart
// import 'package:the_chess/components/pieces.dart';

// class ChessMove {
//   final ChessPiece piece;
//   final int fromRow;
//   final int fromCol;
//   final int toRow;
//   final int toCol;
//   final ChessPiece? capturedPiece;
//   final bool wasEnPassant;
//   final ChessPiece? enPassantCapturedPiece;
//   final List<int>? previousEnPassantTarget;
//   final List<int>? newEnPassantTarget;
//   final bool wasPromotion;
//   final ChessPiecesType? promotedToType;
//   final bool wasCheck;
//   final bool wasCheckmate;
//   final List<int> previousKingPosition;
//   final String moveNotation;
//   final Duration moveTime;

//   ChessMove({
//     required this.piece,
//     required this.fromRow,
//     required this.fromCol,
//     required this.toRow,
//     required this.toCol,
//     this.capturedPiece,
//     this.wasEnPassant = false,
//     this.enPassantCapturedPiece,
//     this.previousEnPassantTarget,
//     this.newEnPassantTarget,
//     this.wasPromotion = false,
//     this.promotedToType,
//     this.wasCheck = false,
//     this.wasCheckmate = false,
//     required this.previousKingPosition,
//     required this.moveNotation,
//     required this.moveTime,
//   });

//   String get moveDescription {
//     String desc = '${piece.isWhite ? 'White' : 'Black'} ';
//     desc += '${piece.type.toString().split('.').last} ';
//     desc += 'from ${_positionToString(fromRow, fromCol)} ';
//     desc += 'to ${_positionToString(toRow, toCol)}';

//     if (capturedPiece != null) {
//       desc += ' (captured ${capturedPiece!.type.toString().split('.').last})';
//     }
//     if (wasEnPassant) {
//       desc += ' (en passant)';
//     }
//     if (wasPromotion) {
//       desc += ' (promoted to ${promotedToType.toString().split('.').last})';
//     }
//     if (wasCheckmate) {
//       desc += ' - CHECKMATE!';
//     } else if (wasCheck) {
//       desc += ' - CHECK!';
//     }

//     return desc;
//   }

//   String _positionToString(int row, int col) {
//     String colLetter = String.fromCharCode('a'.codeUnitAt(0) + col);
//     String rowNumber = (8 - row).toString();
//     return '$colLetter$rowNumber';
//   }
// }

// // controllers/review_controller.dart
// class ReviewController {
//   List<ChessMove> moveHistory = [];
//   int currentReviewIndex = -1;
//   bool isInReviewMode = false;

//   // Original game state to restore after review
//   late List<List<ChessPiece?>> originalBoard;
//   late List<ChessPiece> originalWhitePiecesTaken;
//   late List<ChessPiece> originalBlackPiecesTaken;
//   late bool originalIsWhiteTurn;
//   late List<int> originalWhiteKingPosition;
//   late List<int> originalBlackKingPosition;
//   late bool originalCheckStatus;
//   late List<int>? originalEnPassantTarget;

//   void addMove(ChessMove move) {
//     if (!isInReviewMode) {
//       moveHistory.add(move);
//     }
//   }

//   void startReview(
//     List<List<ChessPiece?>> board,
//     List<ChessPiece> whitePiecesTaken,
//     List<ChessPiece> blackPiecesTaken,
//     bool isWhiteTurn,
//     List<int> whiteKingPosition,
//     List<int> blackKingPosition,
//     bool checkStatus,
//     List<int>? enPassantTarget,
//   ) {
//     if (moveHistory.isEmpty) return;

//     isInReviewMode = true;
//     currentReviewIndex = moveHistory.length - 1;

//     // Store original state
//     originalBoard = board.map((row) => List<ChessPiece?>.from(row)).toList();
//     originalWhitePiecesTaken = List<ChessPiece>.from(whitePiecesTaken);
//     originalBlackPiecesTaken = List<ChessPiece>.from(blackPiecesTaken);
//     originalIsWhiteTurn = isWhiteTurn;
//     originalWhiteKingPosition = List<int>.from(whiteKingPosition);
//     originalBlackKingPosition = List<int>.from(blackKingPosition);
//     originalCheckStatus = checkStatus;
//     originalEnPassantTarget =
//         enPassantTarget != null ? List<int>.from(enPassantTarget) : null;
//   }

//   void endReview() {
//     isInReviewMode = false;
//     currentReviewIndex = -1;
//   }

//   bool canGoBack() {
//     return isInReviewMode && currentReviewIndex > 0;
//   }

//   bool canGoForward() {
//     return isInReviewMode && currentReviewIndex < moveHistory.length - 1;
//   }

//   bool canStartReview() {
//     return moveHistory.isNotEmpty && !isInReviewMode;
//   }

//   ChessMove? getCurrentMove() {
//     if (isInReviewMode &&
//         currentReviewIndex >= 0 &&
//         currentReviewIndex < moveHistory.length) {
//       return moveHistory[currentReviewIndex];
//     }
//     return null;
//   }

//   void goToPreviousMove() {
//     if (canGoBack()) {
//       currentReviewIndex--;
//     }
//   }

//   void goToNextMove() {
//     if (canGoForward()) {
//       currentReviewIndex++;
//     }
//   }

//   void goToMove(int index) {
//     if (isInReviewMode && index >= 0 && index < moveHistory.length) {
//       currentReviewIndex = index;
//     }
//   }

//   String getCurrentMoveInfo() {
//     if (getCurrentMove() != null) {
//       return 'Move ${currentReviewIndex + 1}/${moveHistory.length}: ${getCurrentMove()!.moveDescription}';
//     }
//     return 'Review Mode';
//   }

//   // Reconstruct board state at specific move index
//   Map<String, dynamic> getBoardStateAtMove(int moveIndex) {
//     if (moveIndex < 0 || moveIndex >= moveHistory.length) {
//       return {};
//     }

//     // Start with initial board state and replay moves up to moveIndex
//     List<List<ChessPiece?>> board =
//         List.generate(8, (index) => List.generate(8, (index) => null));
//     List<ChessPiece> whitePiecesTaken = [];
//     List<ChessPiece> blackPiecesTaken = [];
//     bool isWhiteTurn = true;
//     List<int> whiteKingPosition = [7, 4];
//     List<int> blackKingPosition = [0, 4];
//     bool checkStatus = false;
//     List<int>? enPassantTarget;

//     // Initialize starting board
//     _initializeStartingBoard(board);

//     // Replay moves up to the specified index
//     for (int i = 0; i <= moveIndex; i++) {
//       ChessMove move = moveHistory[i];
//       _applyMoveToBoard(board, move, whitePiecesTaken, blackPiecesTaken);

//       // Update game state
//       if (move.piece.type == ChessPiecesType.king) {
//         if (move.piece.isWhite) {
//           whiteKingPosition = [move.toRow, move.toCol];
//         } else {
//           blackKingPosition = [move.toRow, move.toCol];
//         }
//       }

//       enPassantTarget = move.newEnPassantTarget;
//       checkStatus = move.wasCheck;
//       isWhiteTurn = !isWhiteTurn; // Toggle turn after each move
//     }

//     return {
//       'board': board,
//       'whitePiecesTaken': whitePiecesTaken,
//       'blackPiecesTaken': blackPiecesTaken,
//       'isWhiteTurn': isWhiteTurn,
//       'whiteKingPosition': whiteKingPosition,
//       'blackKingPosition': blackKingPosition,
//       'checkStatus': checkStatus,
//       'enPassantTarget': enPassantTarget,
//     };
//   }

//   void _initializeStartingBoard(List<List<ChessPiece?>> board) {
//     // Place pawns
//     for (int i = 0; i < 8; i++) {
//       board[1][i] = ChessPiece(
//         type: ChessPiecesType.pawn,
//         isWhite: false,
//         imagePath: 'images/pawn.png',
//       );
//       board[6][i] = ChessPiece(
//         type: ChessPiecesType.pawn,
//         isWhite: true,
//         imagePath: 'images/pawn.png',
//       );
//     }

//     // Place rooks
//     board[0][0] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: false,
//         imagePath: "images/rook.png");
//     board[0][7] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: false,
//         imagePath: "images/rook.png");
//     board[7][0] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: true,
//         imagePath: "images/rook.png");
//     board[7][7] = ChessPiece(
//         type: ChessPiecesType.rook,
//         isWhite: true,
//         imagePath: "images/rook.png");

//     // Place knights
//     board[0][1] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: false,
//         imagePath: "images/knight.png");
//     board[0][6] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: false,
//         imagePath: "images/knight.png");
//     board[7][1] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: true,
//         imagePath: "images/knight.png");
//     board[7][6] = ChessPiece(
//         type: ChessPiecesType.knight,
//         isWhite: true,
//         imagePath: "images/knight.png");

//     // Place bishops
//     board[0][2] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: false,
//         imagePath: "images/bishop.png");
//     board[0][5] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: false,
//         imagePath: "images/bishop.png");
//     board[7][2] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: true,
//         imagePath: "images/bishop.png");
//     board[7][5] = ChessPiece(
//         type: ChessPiecesType.bishop,
//         isWhite: true,
//         imagePath: "images/bishop.png");

//     // Place queens
//     board[0][3] = ChessPiece(
//         type: ChessPiecesType.queen,
//         isWhite: false,
//         imagePath: 'images/queen.png');
//     board[7][3] = ChessPiece(
//         type: ChessPiecesType.queen,
//         isWhite: true,
//         imagePath: 'images/queen.png');

//     // Place kings
//     board[0][4] = ChessPiece(
//         type: ChessPiecesType.king,
//         isWhite: false,
//         imagePath: 'images/king.png');
//     board[7][4] = ChessPiece(
//         type: ChessPiecesType.king,
//         isWhite: true,
//         imagePath: 'images/king.png');
//   }

//   void _applyMoveToBoard(List<List<ChessPiece?>> board, ChessMove move,
//       List<ChessPiece> whitePiecesTaken, List<ChessPiece> blackPiecesTaken) {
//     // Handle captures
//     if (move.capturedPiece != null) {
//       if (move.capturedPiece!.isWhite) {
//         whitePiecesTaken.add(move.capturedPiece!);
//       } else {
//         blackPiecesTaken.add(move.capturedPiece!);
//       }
//     }

//     // Handle en passant capture
//     if (move.wasEnPassant && move.enPassantCapturedPiece != null) {
//       if (move.enPassantCapturedPiece!.isWhite) {
//         whitePiecesTaken.add(move.enPassantCapturedPiece!);
//       } else {
//         blackPiecesTaken.add(move.enPassantCapturedPiece!);
//       }
//     }

//     // Move the piece
//     board[move.toRow][move.toCol] = move.wasPromotion
//         ? ChessPiece(
//             type: move.promotedToType ?? ChessPiecesType.queen,
//             isWhite: move.piece.isWhite,
//             imagePath:
//                 'images/${move.promotedToType?.toString().split('.').last ?? 'queen'}.png',
//           )
//         : move.piece;
//     board[move.fromRow][move.fromCol] = null;
//   }
// }

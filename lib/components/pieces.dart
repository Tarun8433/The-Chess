enum ChessPiecesType {
  pawn,
  rook,
  knight,
  bishop,
  king,
  queen,
}

class ChessPiece {
  final ChessPiecesType type;
  final bool isWhite;
  final String imagePath;
  bool? isMe; // Added isMe field

  ChessPiece({
    required this.type,
    required this.isWhite,
    required this.imagePath,
    this.isMe = false, // Initialize with a default value
  });

  // Convert ChessPiece to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(), // Store enum as string
      'isWhite': isWhite,
      'imagePath': imagePath,
      'isMe': isMe, // Include isMe in JSON
    };
  }

  // Create ChessPiece from JSON
  factory ChessPiece.fromJson(Map<String, dynamic> json) {
    return ChessPiece(
      type: ChessPiecesType.values.firstWhere(
          (e) => e.toString() == json['type']), // Convert string back to enum
      isWhite: json['isWhite'],
      imagePath: json['imagePath'],
      isMe: json['isMe'], // Retrieve isMe from JSON
    );
  }
}

// class ChessPiece {
//   final ChessPiecesType type;
//   final bool isWhite;
//   final String imagePath;
//     bool? isMe;

//   ChessPiece({
//     required this.type,
//     required this.isWhite,
//     required this.imagePath,
//     this.isMe = false,
//   });
// }

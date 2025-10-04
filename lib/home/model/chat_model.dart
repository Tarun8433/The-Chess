
// File: lib/models/chat_room_model.dart
class ChatRoomModel {
  final String roomId;
  final List<String> participants;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isActive;

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'participants': participants,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      roomId: map['roomId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      isActive: map['isActive'] ?? false,
    );
  }
}

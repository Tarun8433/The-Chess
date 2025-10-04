// File: lib/models/message_model.dart
class MessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String type; // text, image, etc.

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: map['type'] ?? 'text',
    );
  }
}

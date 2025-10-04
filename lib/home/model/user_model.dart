// File: lib/models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final bool isOnline;
  final DateTime lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.isOnline,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] ?? 0),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for daily game analytics
class GameAnalytics {
  final String date; // Format: YYYY-MM-DD
  final int roomsCreated;
  final int playersJoined;
  final int matchesCompleted;
  final int matchesAbandoned;
  final int totalGameTime; // in minutes
  final int peakConcurrentPlayers;
  final Map<int, int> hourlyActivity; // Hour -> player count
  final DateTime createdAt;
  final DateTime updatedAt;

  GameAnalytics({
    required this.date,
    required this.roomsCreated,
    required this.playersJoined,
    required this.matchesCompleted,
    required this.matchesAbandoned,
    required this.totalGameTime,
    required this.peakConcurrentPlayers,
    required this.hourlyActivity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory GameAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameAnalytics(
      date: data['date'] ?? '',
      roomsCreated: data['roomsCreated'] ?? 0,
      playersJoined: data['playersJoined'] ?? 0,
      matchesCompleted: data['matchesCompleted'] ?? 0,
      matchesAbandoned: data['matchesAbandoned'] ?? 0,
      totalGameTime: data['totalGameTime'] ?? 0,
      peakConcurrentPlayers: data['peakConcurrentPlayers'] ?? 0,
      hourlyActivity: _convertHourlyActivity(data['hourlyActivity']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'roomsCreated': roomsCreated,
      'playersJoined': playersJoined,
      'matchesCompleted': matchesCompleted,
      'matchesAbandoned': matchesAbandoned,
      'totalGameTime': totalGameTime,
      'peakConcurrentPlayers': peakConcurrentPlayers,
      'hourlyActivity': hourlyActivity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create empty analytics for a date
  factory GameAnalytics.empty(String date) {
    return GameAnalytics(
      date: date,
      roomsCreated: 0,
      playersJoined: 0,
      matchesCompleted: 0,
      matchesAbandoned: 0,
      totalGameTime: 0,
      peakConcurrentPlayers: 0,
      hourlyActivity: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copy with updated values
  GameAnalytics copyWith({
    String? date,
    int? roomsCreated,
    int? playersJoined,
    int? matchesCompleted,
    int? matchesAbandoned,
    int? totalGameTime,
    int? peakConcurrentPlayers,
    Map<int, int>? hourlyActivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameAnalytics(
      date: date ?? this.date,
      roomsCreated: roomsCreated ?? this.roomsCreated,
      playersJoined: playersJoined ?? this.playersJoined,
      matchesCompleted: matchesCompleted ?? this.matchesCompleted,
      matchesAbandoned: matchesAbandoned ?? this.matchesAbandoned,
      totalGameTime: totalGameTime ?? this.totalGameTime,
      peakConcurrentPlayers: peakConcurrentPlayers ?? this.peakConcurrentPlayers,
      hourlyActivity: hourlyActivity ?? this.hourlyActivity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Helper method to convert hourly activity from Firestore
  static Map<int, int> _convertHourlyActivity(dynamic data) {
    if (data == null) return {};
    
    final Map<int, int> result = {};
    if (data is Map) {
      data.forEach((key, value) {
        final hourKey = key is String ? int.tryParse(key) ?? 0 : key as int;
        final hourValue = value is int ? value : 0;
        result[hourKey] = hourValue;
      });
    }
    return result;
  }

  /// Get total game time in minutes (alias for totalGameTime)
  double get totalGameTimeMinutes => totalGameTime.toDouble();

  @override
  String toString() {
    return 'GameAnalytics(date: $date, rooms: $roomsCreated, players: $playersJoined, matches: $matchesCompleted)';
  }
}

/// Model for real-time game session tracking
class GameSession {
  final String sessionId;
  final String roomId;
  final List<String> playerIds;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'active', 'completed', 'abandoned'
  final int duration; // in minutes
  final String? winner;

  GameSession({
    required this.sessionId,
    required this.roomId,
    required this.playerIds,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.duration,
    this.winner,
  });

  factory GameSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSession(
      sessionId: doc.id,
      roomId: data['roomId'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      duration: data['duration'] ?? 0,
      winner: data['winner'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'playerIds': playerIds,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
      'duration': duration,
      'winner': winner,
    };
  }
}
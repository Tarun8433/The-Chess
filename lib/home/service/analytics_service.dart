import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/game_analytics.dart';

/// Service for tracking and managing game analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _analyticsCollection = 'game_analytics';
  static const String _sessionsCollection = 'game_sessions';
  static const String _playerActivityCollection = 'player_activity';

  /// Get today's date in YYYY-MM-DD format
  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Get current hour in HH format
  String get _currentHour => DateFormat('HH').format(DateTime.now());

  /// Record room creation
  Future<void> recordRoomCreation(String roomId) async {
    try {
      await _incrementDailyCounter('roomsCreated');
      await _recordPlayerActivity('room_created', {'roomId': roomId});
      debugPrint('Recorded room creation: $roomId');
    } catch (e) {
      debugPrint('Error recording room creation: $e');
    }
  }

  /// Record player joining a room
  Future<void> recordPlayerJoin(String playerId, String roomId) async {
    try {
      await _incrementDailyCounter('playersJoined');
      await _updateHourlyActivity();
      await _recordPlayerActivity('player_joined', {
        'playerId': playerId,
        'roomId': roomId,
      });
      debugPrint('Recorded player join: $playerId to room $roomId');
    } catch (e) {
      debugPrint('Error recording player join: $e');
    }
  }

  /// Record match completion
  Future<void> recordMatchCompletion(String roomId, String? winnerId, int durationMinutes) async {
    try {
      await _incrementDailyCounter('matchesCompleted');
      await _incrementDailyCounter('totalGameTime', durationMinutes);
      await _recordPlayerActivity('match_completed', {
        'roomId': roomId,
        'winnerId': winnerId,
        'duration': durationMinutes,
      });
      debugPrint('Recorded match completion: $roomId, winner: $winnerId, duration: ${durationMinutes}min');
    } catch (e) {
      debugPrint('Error recording match completion: $e');
    }
  }

  /// Record match abandonment
  Future<void> recordMatchAbandonment(String roomId, int durationMinutes) async {
    try {
      await _incrementDailyCounter('matchesAbandoned');
      await _recordPlayerActivity('match_abandoned', {
        'roomId': roomId,
        'duration': durationMinutes,
      });
      debugPrint('Recorded match abandonment: $roomId, duration: ${durationMinutes}min');
    } catch (e) {
      debugPrint('Error recording match abandonment: $e');
    }
  }

  /// Start tracking a game session
  Future<String> startGameSession(String roomId, List<String> playerIds) async {
    try {
      final sessionRef = _firestore.collection(_sessionsCollection).doc();
      final session = GameSession(
        sessionId: sessionRef.id,
        roomId: roomId,
        playerIds: playerIds,
        startTime: DateTime.now(),
        status: 'active',
        duration: 0,
      );

      await sessionRef.set(session.toFirestore());
      debugPrint('Started game session: ${sessionRef.id}');
      return sessionRef.id;
    } catch (e) {
      debugPrint('Error starting game session: $e');
      return '';
    }
  }

  /// End a game session
  Future<void> endGameSession(String sessionId, String status, String? winnerId) async {
    try {
      final sessionRef = _firestore.collection(_sessionsCollection).doc(sessionId);
      final sessionDoc = await sessionRef.get();
      
      if (sessionDoc.exists) {
        final session = GameSession.fromFirestore(sessionDoc);
        final duration = DateTime.now().difference(session.startTime).inMinutes;
        
        await sessionRef.update({
          'endTime': Timestamp.fromDate(DateTime.now()),
          'status': status,
          'duration': duration,
          'winner': winnerId,
        });

        // Record in daily analytics
        if (status == 'completed') {
          await recordMatchCompletion(session.roomId, winnerId, duration);
        } else if (status == 'abandoned') {
          await recordMatchAbandonment(session.roomId, duration);
        }

        debugPrint('Ended game session: $sessionId, status: $status');
      }
    } catch (e) {
      debugPrint('Error ending game session: $e');
    }
  }

  /// Get daily analytics for a specific date
  Future<GameAnalytics?> getDailyAnalytics(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _firestore.collection(_analyticsCollection).doc(dateStr).get();
      if (doc.exists) {
        return GameAnalytics.fromFirestore(doc);
      } else {
        return GameAnalytics.empty(dateStr);
      }
    } catch (e) {
      debugPrint('Error getting daily analytics: $e');
      return null;
    }
  }

  /// Get analytics for a date range
  Future<List<GameAnalytics>> getAnalyticsRange(DateTime startDate, DateTime endDate) async {
    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      
      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => GameAnalytics.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting analytics range: $e');
      return [];
    }
  }

  /// Get current active sessions count
  Future<int> getActiveSessionsCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('status', isEqualTo: 'active')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting active sessions count: $e');
      return 0;
    }
  }

  /// Get today's analytics
  Future<GameAnalytics?> getTodayAnalytics() async {
    return await getDailyAnalytics(DateTime.now());
  }

  /// Get weekly summary
  Future<List<GameAnalytics>?> getWeeklySummary() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final weeklyData = await getAnalyticsRange(startDate, endDate);
      return weeklyData;
    } catch (e) {
      debugPrint('Error getting weekly summary: $e');
      return null;
    }
  }

  /// Private method to increment daily counter
  Future<void> _incrementDailyCounter(String field, [int increment = 1]) async {
    final docRef = _firestore.collection(_analyticsCollection).doc(_todayDate);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        final currentValue = doc.data()?[field] ?? 0;
        transaction.update(docRef, {
          field: currentValue + increment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        final newAnalytics = GameAnalytics.empty(_todayDate).copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final data = newAnalytics.toFirestore();
        data[field] = increment;
        transaction.set(docRef, data);
      }
    });
  }

  /// Private method to update hourly activity
  Future<void> _updateHourlyActivity() async {
    final docRef = _firestore.collection(_analyticsCollection).doc(_todayDate);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      Map<int, int> hourlyActivity = {};
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final rawActivity = data['hourlyActivity'] ?? {};
        // Convert string keys to int keys
        if (rawActivity is Map) {
          rawActivity.forEach((key, value) {
            final hourKey = key is String ? int.tryParse(key) ?? 0 : key as int;
            final hourValue = value is int ? value : 0;
            hourlyActivity[hourKey] = hourValue;
          });
        }
      }
      
      final currentHour = _currentHour;
      final currentHourInt = int.tryParse(currentHour) ?? DateTime.now().hour;
      hourlyActivity[currentHourInt] = (hourlyActivity[currentHourInt] ?? 0) + 1;
      
      // Convert back to string keys for Firestore storage
      final firestoreActivity = <String, int>{};
      hourlyActivity.forEach((key, value) {
        firestoreActivity[key.toString()] = value;
      });
      
      if (doc.exists) {
        transaction.update(docRef, {
          'hourlyActivity': firestoreActivity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newAnalytics = GameAnalytics.empty(_todayDate).copyWith(
          hourlyActivity: hourlyActivity,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        transaction.set(docRef, newAnalytics.toFirestore());
      }
    });
  }

  /// Private method to record player activity
  Future<void> _recordPlayerActivity(String action, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection(_playerActivityCollection).add({
        'userId': user.uid,
        'action': action,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'date': _todayDate,
      });
    } catch (e) {
      debugPrint('Error recording player activity: $e');
    }
  }

  /// Clean up old analytics data (keep last 90 days)
  Future<void> cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final cutoffDateStr = DateFormat('yyyy-MM-dd').format(cutoffDate);
      
      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('date', isLessThan: cutoffDateStr)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('Cleaned up ${querySnapshot.docs.length} old analytics records');
    } catch (e) {
      debugPrint('Error cleaning up old data: $e');
    }
  }
}
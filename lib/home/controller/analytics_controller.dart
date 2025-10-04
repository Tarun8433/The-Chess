import 'package:get/get.dart';
import '../model/game_analytics.dart';
import '../service/analytics_service.dart';

class AnalyticsController extends GetxController {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // Observable variables
  final Rx<GameAnalytics?> todayAnalytics = Rx<GameAnalytics?>(null);
  final RxList<GameAnalytics> weeklyAnalytics = <GameAnalytics>[].obs;
  final RxList<GameAnalytics> monthlyAnalytics = <GameAnalytics>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedPeriod = 'Today'.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
  }

  /// Load analytics data based on selected period
  Future<void> loadAnalytics() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      switch (selectedPeriod.value) {
        case 'Today':
          await _loadTodayAnalytics();
          break;
        case 'Week':
          await _loadWeeklyAnalytics();
          break;
        case 'Month':
          await _loadMonthlyAnalytics();
          break;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load analytics: $e';
      print('Analytics loading error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load today's analytics
  Future<void> _loadTodayAnalytics() async {
    try {
      final today = await _analyticsService.getDailyAnalytics(DateTime.now());
      todayAnalytics.value = today;
    } catch (e) {
      print('Error loading today analytics: $e');
      todayAnalytics.value = null;
      rethrow;
    }
  }

  /// Load weekly analytics
  Future<void> _loadWeeklyAnalytics() async {
    try {
      final weekly = await _analyticsService.getWeeklySummary();
      if (weekly != null) {
        weeklyAnalytics.assignAll(weekly);
      } else {
        weeklyAnalytics.clear();
      }
    } catch (e) {
      print('Error loading weekly analytics: $e');
      weeklyAnalytics.clear();
      rethrow;
    }
  }

  /// Load monthly analytics
  Future<void> _loadMonthlyAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final monthly = await _analyticsService.getAnalyticsRange(
        startOfMonth,
        endOfMonth,
      );
      monthlyAnalytics.assignAll(monthly);
    } catch (e) {
      print('Error loading monthly analytics: $e');
      monthlyAnalytics.clear();
      rethrow;
    }
  }

  /// Change selected period and reload data
  void changePeriod(String period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;
      loadAnalytics();
    }
  }

  /// Refresh current data
  @override
  Future<void> refresh() async {
    await loadAnalytics();
  }

  /// Get total rooms created for current period
  int get totalRoomsCreated {
    switch (selectedPeriod.value) {
      case 'Today':
        return todayAnalytics.value?.roomsCreated ?? 0;
      case 'Week':
        return weeklyAnalytics.fold(0, (sum, analytics) => sum + analytics.roomsCreated);
      case 'Month':
        return monthlyAnalytics.fold(0, (sum, analytics) => sum + analytics.roomsCreated);
      default:
        return 0;
    }
  }

  /// Get total players joined for current period
  int get totalPlayersJoined {
    switch (selectedPeriod.value) {
      case 'Today':
        return todayAnalytics.value?.playersJoined ?? 0;
      case 'Week':
        return weeklyAnalytics.fold(0, (sum, analytics) => sum + analytics.playersJoined);
      case 'Month':
        return monthlyAnalytics.fold(0, (sum, analytics) => sum + analytics.playersJoined);
      default:
        return 0;
    }
  }

  /// Get total matches completed for current period
  int get totalMatchesCompleted {
    switch (selectedPeriod.value) {
      case 'Today':
        return todayAnalytics.value?.matchesCompleted ?? 0;
      case 'Week':
        return weeklyAnalytics.fold(0, (sum, analytics) => sum + analytics.matchesCompleted);
      case 'Month':
        return monthlyAnalytics.fold(0, (sum, analytics) => sum + analytics.matchesCompleted);
      default:
        return 0;
    }
  }

  /// Get total matches abandoned for current period
  int get totalMatchesAbandoned {
    switch (selectedPeriod.value) {
      case 'Today':
        return todayAnalytics.value?.matchesAbandoned ?? 0;
      case 'Week':
        return weeklyAnalytics.fold(0, (sum, analytics) => sum + analytics.matchesAbandoned);
      case 'Month':
        return monthlyAnalytics.fold(0, (sum, analytics) => sum + analytics.matchesAbandoned);
      default:
        return 0;
    }
  }

  /// Get success rate percentage
  double get successRate {
    final completed = totalMatchesCompleted;
    final abandoned = totalMatchesAbandoned;
    final total = completed + abandoned;
    
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  /// Get average session duration in minutes
  double get averageSessionDuration {
    switch (selectedPeriod.value) {
      case 'Today':
        final analytics = todayAnalytics.value;
        if (analytics == null) return 0.0;
        final totalSessions = analytics.matchesCompleted + analytics.matchesAbandoned;
        return totalSessions > 0 ? analytics.totalGameTimeMinutes / totalSessions : 0.0;
      case 'Week':
        final totalTime = weeklyAnalytics.fold(0.0, (sum, analytics) => sum + analytics.totalGameTimeMinutes);
        final totalSessions = weeklyAnalytics.fold(0, (sum, analytics) => sum + analytics.matchesCompleted + analytics.matchesAbandoned);
        return totalSessions > 0 ? totalTime / totalSessions : 0.0;
      case 'Month':
        final totalTime = monthlyAnalytics.fold(0.0, (sum, analytics) => sum + analytics.totalGameTimeMinutes);
        final totalSessions = monthlyAnalytics.fold(0, (sum, analytics) => sum + analytics.matchesCompleted + analytics.matchesAbandoned);
        return totalSessions > 0 ? totalTime / totalSessions : 0.0;
      default:
        return 0.0;
    }
  }

  /// Get peak concurrent players
  int get peakConcurrentPlayers {
    switch (selectedPeriod.value) {
      case 'Today':
        return todayAnalytics.value?.peakConcurrentPlayers ?? 0;
      case 'Week':
        if (weeklyAnalytics.isEmpty) return 0;
        return weeklyAnalytics.fold(weeklyAnalytics.first.peakConcurrentPlayers, (max, analytics) => 
          analytics.peakConcurrentPlayers > max ? analytics.peakConcurrentPlayers : max);
      case 'Month':
        if (monthlyAnalytics.isEmpty) return 0;
        return monthlyAnalytics.fold(monthlyAnalytics.first.peakConcurrentPlayers, (max, analytics) => 
          analytics.peakConcurrentPlayers > max ? analytics.peakConcurrentPlayers : max);
      default:
        return 0;
    }
  }

  /// Get chart data for current period
  List<GameAnalytics> get chartData {
    switch (selectedPeriod.value) {
      case 'Today':
        return todayAnalytics.value != null ? [todayAnalytics.value!] : [];
      case 'Week':
        return weeklyAnalytics;
      case 'Month':
        return monthlyAnalytics;
      default:
        return [];
    }
  }

  /// Get hourly activity data (only for today)
  Map<int, int> get hourlyActivity {
    final analytics = todayAnalytics.value;
    if (analytics == null) {
      // Return empty map with 24 hours initialized to 0
      return { for (var hour in List.generate(24, (index) => index)) hour : 0 };
    }
    return analytics.hourlyActivity;
  }
}
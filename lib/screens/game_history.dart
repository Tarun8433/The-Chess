import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/services/game_history_service.dart';
import 'package:the_chess/values/colors.dart';
import 'package:the_chess/home/model/game_status.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GameHistoryController controller = Get.put(GameHistoryController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.darkBackground,
      appBar: AppBar(
        backgroundColor: MyColors.cardBackground,
        elevation: 0,
        title: const Text(
          'Game History',
          style: TextStyle(
            color: MyColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MyColors.white),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MyColors.lightGray,
          indicatorWeight: 3,
          labelColor: MyColors.white,
          unselectedLabelColor: MyColors.mediumGray,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Won'),
            Tab(text: 'Lost'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Summary
          _buildStatsSection(),

          // Game List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGameList(GameHistoryFilter.all),
                _buildGameList(GameHistoryFilter.won),
                _buildGameList(GameHistoryFilter.lost),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Obx(() {
      final stats = controller.gameStats.value;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Text(
              'Your Statistics',
              style: TextStyle(
                color: MyColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    '${stats.totalGames}', 'Total Games', Icons.games),
                _buildStatItem(
                    '${stats.wins}', 'Wins', Icons.emoji_events, Colors.green),
                _buildStatItem(
                    '${stats.losses}', 'Losses', Icons.close, Colors.red),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String value, String label, IconData icon,
      [Color? iconColor]) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor ?? MyColors.lightGray,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: MyColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: MyColors.mediumGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGameList(GameHistoryFilter filter) {
    return Obx(() {
      final games = controller.getFilteredGames(filter);

      if (games.isEmpty) {
        return _buildEmptyState(filter);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return _buildGameCard(game);
        },
      );
    });
  }

  Widget _buildEmptyState(GameHistoryFilter filter) {
    String message;
    IconData icon;

    switch (filter) {
      case GameHistoryFilter.won:
        message = 'No victories yet.\nKeep playing to earn your wins!';
        icon = Icons.emoji_events_outlined;
        break;
      case GameHistoryFilter.lost:
        message = 'No losses recorded.\nYou\'re doing great!';
        icon = Icons.trending_up;
        break;
      default:
        message = 'No games played yet.\nStart your first game now!';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: MyColors.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: MyColors.mediumGray,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameHistoryItem game) {
    final status = GameStatus.fromString(game.status);
    final isWinner = game.result == 'won';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildStatusChip(status, isWinner),
                  const SizedBox(width: 12),
                  Text(
                    'vs Opponent',
                    style: const TextStyle(
                      color: MyColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(game.lastActivity),
                style: const TextStyle(
                  color: MyColors.mediumGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Game details
          Row(
            children: [
              _buildPlayerInfo('You', game.playerColor, isYou: true),
              const Expanded(
                child: Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: MyColors.lightGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildPlayerInfo(
                  'Opponent', game.playerColor == 'white' ? 'black' : 'white'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(GameStatus status, bool isWinner) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (status == GameStatus.active) {
      backgroundColor = MyColors.lightGray.withValues(alpha: 0.2);
      textColor = MyColors.lightGray;
      text = 'ACTIVE';
    } else if (status.isWinLose) {
      if (isWinner) {
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        text = 'WON';
      } else {
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        text = 'LOST';
      }
    } else if (status.isDraw) {
      backgroundColor = MyColors.amber.withValues(alpha: 0.2);
      textColor = MyColors.amber;
      text = 'DRAW';
    } else {
      backgroundColor = MyColors.mediumGray.withValues(alpha: 0.2);
      textColor = MyColors.mediumGray;
      text = status.value.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(String name, String color, {bool isYou = false}) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color == 'white' ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MyColors.lightGray.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.person,
            color: color == 'white' ? Colors.black : Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            color: isYou ? MyColors.white : MyColors.mediumGray,
            fontSize: 12,
            fontWeight: isYou ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          color.toUpperCase(),
          style: const TextStyle(
            color: MyColors.tealGray,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRejoinButton(GameHistoryItem game) {
    return ElevatedButton(
      onPressed: () => controller.rejoinGame(game.gameId, game.roomId),
      style: ElevatedButton.styleFrom(
        backgroundColor: MyColors.lightGray,
        foregroundColor: MyColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size.zero,
      ),
      child: const Text(
        'Rejoin',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(GameStatus status) {
    if (status == GameStatus.active) return MyColors.lightGray;
    if (status.isDraw) return MyColors.amber;
    return MyColors.mediumGray;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

// Controller for managing game history
class GameHistoryController extends GetxController {
  final GameHistoryService _historyService = GameHistoryService();

  final RxList<GameHistoryItem> _allGames = <GameHistoryItem>[].obs;
  final Rx<GameStats> gameStats = GameStats().obs;

  @override
  void onInit() {
    super.onInit();
    _loadGameHistory();
  }

  void _loadGameHistory() {
    _historyService.getUserGameHistory().listen((games) {
      _allGames.value = games;
      _updateStats(games);
    });
  }

  void _updateStats(List<GameHistoryItem> games) {
    final stats = GameStats();
    stats.totalGames = games.length;

    for (final game in games) {
      if (game.status == 'active') {
        stats.activeGames++;
      } else if (game.result == 'won') {
        stats.wins++;
      } else if (game.result == 'lost') {
        stats.losses++;
      }
    }

    gameStats.value = stats;
  }

  List<GameHistoryItem> getFilteredGames(GameHistoryFilter filter) {
    switch (filter) {
      case GameHistoryFilter.active:
        return _allGames.where((game) => game.status == 'active').toList();
      case GameHistoryFilter.won:
        return _allGames.where((game) => game.result == 'won').toList();
      case GameHistoryFilter.lost:
        return _allGames.where((game) => game.result == 'lost').toList();
      case GameHistoryFilter.all:
      default:
        return _allGames;
    }
  }

  Future<void> rejoinGame(String gameId, String roomId) async {
    try {
      final canRejoin = await _historyService.canRejoinGame(gameId);
      if (canRejoin) {
        await _historyService.markPlayerRejoined(gameId);
        // Navigate to game screen
        Get.toNamed('/chess-game', arguments: {
          'gameId': gameId,
          'roomId': roomId,
        });
      } else {
        Get.snackbar(
          'Cannot Rejoin',
          'This game is no longer active',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to rejoin game: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}

enum GameHistoryFilter {
  all,
  active,
  won,
  lost,
}

class GameStats {
  int totalGames = 0;
  int wins = 0;
  int losses = 0;
  int activeGames = 0;
}

// You'll need to import your existing GameHistoryService and GameHistoryItem classes

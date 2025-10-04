import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/home/controller/matchmaking_controller.dart';
import 'package:the_chess/values/colors.dart';

class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({Key? key}) : super(key: key);

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final MatchmakingController _controller = Get.find<MatchmakingController>();
  int _queueCount = 0;
  int _activeCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerCounts();
  }

  Future<void> _loadPlayerCounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final counts = await _controller.getPlayerCounts();
      setState(() {
        _queueCount = counts['queue'] ?? 0;
        _activeCount = counts['active'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading player counts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: Text(
          'Player Statistics',
          style: TextStyle(color: MyColors.white),
        ),
        backgroundColor: MyColors.primary,
        iconTheme: IconThemeData(color: MyColors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: MyColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Player Counts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MyColors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      CircularProgressIndicator(color: MyColors.accent)
                    else
                      Column(
                        children: [
                          _buildStatRow('Players in Queue', _queueCount, Icons.queue),
                          const SizedBox(height: 16),
                          _buildStatRow('Active Players', _activeCount, Icons.sports_esports),
                          const SizedBox(height: 16),
                          _buildStatRow('Total Online', _queueCount + _activeCount, Icons.people),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _loadPlayerCounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Refresh Stats',
                style: TextStyle(
                  color: MyColors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: MyColors.accent,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: MyColors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: MyColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
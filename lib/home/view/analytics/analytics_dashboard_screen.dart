import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/analytics_controller.dart';
import '../../../values/colors.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());

    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: const Text(
          'Game Analytics',
          style: TextStyle(
            color: MyColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: MyColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MyColors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MyColors.white),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: MyColors.primary),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: MyColors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                  ),
                  child: const Text('Retry',
                      style: TextStyle(color: MyColors.white)),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(controller),
              const SizedBox(height: 20),
              _buildOverviewCards(controller),
              const SizedBox(height: 20),
              _buildMetricsGrid(controller),
              const SizedBox(height: 20),
              _buildChart(controller),
              const SizedBox(height: 20),
              if (controller.selectedPeriod.value == 'Today')
                _buildHourlyActivity(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector(AnalyticsController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: MyColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: ['Today', 'Week', 'Month'].map((period) {
              final isSelected = controller.selectedPeriod.value == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.changePeriod(period),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? MyColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      period,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isSelected ? MyColors.white : MyColors.mediumGray,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget _buildOverviewCards(AnalyticsController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${controller.selectedPeriod.value}\'s Overview',
              style: const TextStyle(
                color: MyColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Rooms Created',
                    controller.totalRoomsCreated.toString(),
                    Icons.add_home,
                    MyColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Players Joined',
                    controller.totalPlayersJoined.toString(),
                    Icons.person_add,
                    MyColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Matches Completed',
                    controller.totalMatchesCompleted.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Peak Players',
                    controller.peakConcurrentPlayers.toString(),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: MyColors.mediumGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(AnalyticsController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Metrics',
              style: TextStyle(
                color: MyColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Matches Abandoned',
                controller.totalMatchesAbandoned.toString()),
            _buildMetricRow('Average Session',
                '${controller.averageSessionDuration.toStringAsFixed(1)} min'),
            _buildMetricRow('Success Rate',
                '${controller.successRate.toStringAsFixed(1)}%'),
          ],
        ),
      );
    });
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: MyColors.mediumGray,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: MyColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(AnalyticsController controller) {
    return Obx(() {
      final chartData = controller.chartData;
      final period = controller.selectedPeriod.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$period Trend',
              style: const TextStyle(
                color: MyColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chartData.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: MyColors.white),
                      ),
                    )
                  : _buildSimpleChart(chartData),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSimpleChart(List<dynamic> data) {
    final maxValue = data
        .map((e) => e.roomsCreated)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((analytics) {
        final height =
            maxValue > 0 ? (analytics.roomsCreated / maxValue) * 150 : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              analytics.roomsCreated.toString(),
              style: const TextStyle(
                color: MyColors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: MyColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateTime.parse(analytics.date).day.toString(),
              style: TextStyle(
                color: MyColors.mediumGray,
                fontSize: 10,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHourlyActivity(AnalyticsController controller) {
    return Obx(() {
      final hourlyData = controller.hourlyActivity;
      if (hourlyData.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly Activity',
              style: TextStyle(
                color: MyColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 24,
                itemBuilder: (context, index) {
                  final activity = hourlyData[index] ?? 0;
                  final maxActivity = hourlyData.values.isNotEmpty
                      ? hourlyData.values.reduce((a, b) => a > b ? a : b)
                      : 0;
                  final height =
                      maxActivity > 0 ? (activity / maxActivity) * 60 : 0.0;

                  return Container(
                    width: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: MyColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: MyColors.mediumGray,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

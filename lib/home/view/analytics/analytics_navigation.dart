import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'analytics_dashboard_screen.dart';
import '../../../values/colors.dart';
 
class AnalyticsNavigation {
  /// Navigate to analytics dashboard
  static void toAnalyticsDashboard() {
    Get.to(() => const AnalyticsDashboardScreen());
  }

  /// Create analytics menu item for drawer or menu
  static Widget buildAnalyticsMenuItem({
    required VoidCallback onTap,
    bool showIcon = true,
  }) {
    return ListTile(
      leading: showIcon
          ? const Icon(
              Icons.analytics,
              color: MyColors.primary,
            )
          : null,
      title: const Text(
        'Game Analytics',
        style: TextStyle(
          color: MyColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text(
        'View game statistics and metrics',
        style: TextStyle(
          color: MyColors.white,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: MyColors.white,
        size: 16,
      ),
    );
  }

  /// Create analytics floating action button
  static Widget buildAnalyticsFAB() {
    return FloatingActionButton(
      onPressed: toAnalyticsDashboard,
      backgroundColor: MyColors.primary,
      child: const Icon(
        Icons.analytics,
        color: Colors.white,
      ),
    );
  }

  /// Create analytics card widget for dashboard
  static Widget buildAnalyticsCard({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      color: MyColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? toAnalyticsDashboard,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MyColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: MyColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: MyColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: MyColors.mediumGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: MyColors.white,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
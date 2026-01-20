import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Statistics page - Productivity analytics and insights
/// TODO: Implement actual statistics and charts
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Track your productivity and progress',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 64,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Statistics Page',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Your productivity stats will appear here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

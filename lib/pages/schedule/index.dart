import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Schedule page - Calendar and scheduling view
/// TODO: Implement actual schedule functionality
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Plan and organize your time',
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
                    Icons.calendar_month_outlined,
                    size: 64,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Schedule Page',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Your schedule will appear here',
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
